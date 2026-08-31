-- bash-like tty for ccLinux. No GUI.

local S = {}

local function tokenize(s)
    local t = {}
    local i, n = 1, #s
    while i <= n do
        while i <= n and s:sub(i, i):match("%s") do
            i = i + 1
        end
        if i > n then
            break
        end
        local c = s:sub(i, i)
        if c == '"' or c == "'" then
            local q = c
            i = i + 1
            local buf = {}
            while i <= n and s:sub(i, i) ~= q do
                if s:sub(i, i) == "\\" and q == '"' then
                    i = i + 1
                    buf[#buf + 1] = s:sub(i, i)
                else
                    buf[#buf + 1] = s:sub(i, i)
                end
                i = i + 1
            end
            t[#t + 1] = table.concat(buf)
            i = i + 1
        elseif c == "|" then
            if s:sub(i + 1, i + 1) == "|" then
                t[#t + 1] = "||"
                i = i + 2
            else
                t[#t + 1] = "|"
                i = i + 1
            end
        elseif c == ";" then
            t[#t + 1] = ";"
            i = i + 1
        elseif c == "&" then
            if s:sub(i + 1, i + 1) == "&" then
                t[#t + 1] = "&&"
                i = i + 2
            else
                t[#t + 1] = "&"
                i = i + 1
            end
        elseif c == ">" then
            if s:sub(i + 1, i + 1) == ">" then
                t[#t + 1] = ">>"
                i = i + 2
            else
                t[#t + 1] = ">"
                i = i + 1
            end
        elseif c == "<" then
            t[#t + 1] = "<"
            i = i + 1
        else
            local j = i
            while j <= n do
                local d = s:sub(j, j)
                if d:match("%s") or d == "|" or d == ">" or d == "<" then
                    break
                end
                j = j + 1
            end
            t[#t + 1] = s:sub(i, j - 1)
            i = j
        end
    end
    return t
end

local function expand(s, ctx)
    s = s:gsub("%$([A-Za-z_][A-Za-z0-9_]*)", function(k)
        return ctx.env[k] or ""
    end)
    s = s:gsub("%${([A-Za-z_][A-Za-z0-9_]*)}", function(k)
        return ctx.env[k] or ""
    end)
    s = s:gsub("~/", "/root/")
    if s == "~" then
        s = "/root"
    end
    return s
end

local function split_token_pipes(tokens)
    local groups = { {} }
    for i = 1, #tokens do
        if tokens[i] == "|" then
            groups[#groups + 1] = {}
        else
            local g = groups[#groups]
            g[#g + 1] = tokens[i]
        end
    end
    return groups
end

local function parse_redir(tokens)
    local args, out, append, input = {}, nil, false, nil
    local i = 1
    while i <= #tokens do
        local t = tokens[i]
        if t == ">" or t == ">>" then
            append = (t == ">>")
            i = i + 1
            out = tokens[i]
        elseif t:sub(1, 2) == ">>" and #t > 2 then
            append = true
            out = t:sub(3)
        elseif t:sub(1, 1) == ">" and #t > 1 then
            out = t:sub(2)
        elseif t == "<" then
            i = i + 1
            input = tokens[i]
        else
            args[#args + 1] = t
        end
        i = i + 1
    end
    return args, out, append, input
end

local function capture(fn)
    local buf = {}
    local old = print
    local oldw = write
    print = function(...)
        local n = select("#", ...)
        local t = {}
        for i = 1, n do
            t[i] = tostring(select(i, ...))
        end
        buf[#buf + 1] = table.concat(t, "\t") .. "\n"
    end
    write = function(s)
        buf[#buf + 1] = tostring(s)
    end
    local ok, err = pcall(fn)
    print = old
    write = oldw
    if not ok then
        old(err)
    end
    return table.concat(buf)
end

local function prompt_str(ctx, K)
    local cwd = ctx.cwd or "/"
    if cwd == "/root" then
        cwd = "~"
    end
    return string.format("root@%s:%s# ", K.hostname, cwd)
end

local function completer_for(cmds, V, ctx)
    return function(partial)
        -- CC passes the whole line? actually the text to the left of cursor as line
        -- completeFn(line) returns suffixes
        local line = partial or ""
        local last = line:match("(%S+)$") or ""
        local prefix = line:sub(1, #line - #last)
        local out = {}
        local first = line:match("^%s*(%S*)")
        local completing_cmd = (line:match("^%s*%S*$") ~= nil)
        if completing_cmd then
            for name in pairs(cmds) do
                if name:sub(1, #last) == last and name:sub(1, 1) ~= "_" then
                    out[#out + 1] = name:sub(#last + 1)
                end
            end
        else
            local dir, file = last:match("^(.*)/([^/]*)$")
            if not file then
                dir, file = ctx.cwd, last
            else
                if dir == "" then
                    dir = "/"
                else
                    dir = V.resolve(ctx.cwd, dir)
                end
            end
            local list = V.list(dir)
            if list then
                for i = 1, #list do
                    local n = list[i]
                    if n:sub(1, #file) == file then
                        local suffix = n:sub(#file + 1)
                        if V.isDir(V.norm(dir .. "/" .. n)) then
                            suffix = suffix .. "/"
                        end
                        out[#out + 1] = suffix
                    end
                end
            end
        end
        table.sort(out)
        return out
    end
end

local function run_pipeline(tokens, cmds, K, V, ctx)
    local groups = split_token_pipes(tokens)
    local stdin = ctx.stdin
    for pi = 1, #groups do
        local part = groups[pi]
        local args, out, append, input = parse_redir(part)
        if #args == 0 then
            ctx.ok = false
            return
        end
        local name = args[1]
        table.remove(args, 1)
        if ctx.aliases and ctx.aliases[name] then
            local at = tokenize(ctx.aliases[name])
            for i = #at, 1, -1 do
                table.insert(args, 1, at[i])
            end
            name = table.remove(args, 1) or name
        end
        ctx.ok = true
        ctx.stdin = stdin
        if input then
            local data, e = V.read(V.resolve(ctx.cwd, input))
            if not data then
                print("bash: " .. input .. ": " .. (e or "error"))
                ctx.ok = false
                return
            end
            ctx.stdin = data
        end
        if not cmds[name] then
            print("bash: " .. name .. ": command not found")
            ctx.ok = false
            return
        end
        local last = pi == #groups
        if out and last then
            local captured = capture(function()
                cmds[name](args, ctx)
            end)
            V.write(V.resolve(ctx.cwd, out), captured, append and "a" or "w")
            stdin = captured
        elseif not last then
            stdin = capture(function()
                cmds[name](args, ctx)
            end)
        else
            cmds[name](args, ctx)
        end
        if ctx.exit then
            return
        end
    end
end

local function split_semicolons(tokens)
    local jobs, cur = {}, {}
    for i = 1, #tokens do
        if tokens[i] == ";" then
            if #cur > 0 then
                jobs[#jobs + 1] = cur
            end
            cur = {}
        else
            cur[#cur + 1] = tokens[i]
        end
    end
    if #cur > 0 then
        jobs[#jobs + 1] = cur
    end
    return jobs
end

local function run_and_or(tokens, cmds, K, V, ctx)
    -- drop trailing &
    if tokens[#tokens] == "&" then
        tokens[#tokens] = nil
    end
    local i = 1
    local skip = false
    while i <= #tokens do
        local pipe_toks = {}
        local op
        while i <= #tokens do
            local t = tokens[i]
            if t == "&&" or t == "||" then
                op = t
                i = i + 1
                break
            end
            pipe_toks[#pipe_toks + 1] = t
            i = i + 1
        end
        if not skip then
            run_pipeline(pipe_toks, cmds, K, V, ctx)
        end
        if ctx.exit then
            return
        end
        if op == "&&" then
            skip = not ctx.ok
        elseif op == "||" then
            skip = ctx.ok and true or false
        else
            skip = false
        end
    end
end

function S.run_line(line, cmds, K, V, ctx)
    line = line:gsub("^%s+", ""):gsub("%s+$", "")
    if line == "" then
        return
    end
    if line:sub(1, 1) == "#" then
        return
    end
    line = expand(line, ctx)
    ctx.aliases = ctx.aliases or {}
    local jobs = split_semicolons(tokenize(line))
    for j = 1, #jobs do
        run_and_or(jobs[j], cmds, K, V, ctx)
        if ctx.exit then
            return
        end
    end
end

function S.loop(cmds, K, V, ctx)
    ctx.history = ctx.history or {}
    local complete = completer_for(cmds, V, ctx)
    while not ctx.exit do
        ctx.env.PWD = ctx.cwd
        ctx.env.HOSTNAME = K.hostname
        if term.isColor and term.isColor() then
            term.setTextColor(colors.green)
            write("root@" .. K.hostname)
            term.setTextColor(colors.lightGray)
            write(":")
            term.setTextColor(colors.blue)
            local cwd = ctx.cwd == "/root" and "~" or ctx.cwd
            write(cwd)
            term.setTextColor(colors.lightGray)
            write("# ")
        else
            write(prompt_str(ctx, K))
        end
        local line
        local ok, res = pcall(function()
            return read(nil, ctx.history, complete)
        end)
        if not ok then
            -- terminated (Ctrl+T) — like Ctrl+C, new prompt
            print("")
        else
            line = res
            if line == nil then
                print("logout")
                ctx.exit = true
            else
                if line ~= "" and ctx.history[#ctx.history] ~= line then
                    ctx.history[#ctx.history + 1] = line
                end
                local ran, e = pcall(S.run_line, line, cmds, K, V, ctx)
                if not ran then
                    print("kernel: oops in userspace: " .. tostring(e))
                    K.oops("userspace fault: " .. tostring(e))
                end
            end
        end
    end
end

return S
