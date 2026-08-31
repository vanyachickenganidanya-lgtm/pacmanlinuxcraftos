-- Extra GNU/Linux userland for ccLinux.

local E = {}

local function err(ctx, msg)
    print(msg)
    ctx.ok = false
end

local function join(args, from)
    from = from or 1
    local t = {}
    for i = from, #args do
        t[#t + 1] = args[i]
    end
    return table.concat(t, " ")
end

local function needpkg(ctx, Pac, name)
    if Pac and Pac.installed and not Pac.installed(name) then
        print("bash: command not found")
        print("hint: pacman -S " .. name)
        ctx.ok = false
        return false
    end
    return true
end

local function data_of(args, ctx, V)
    if args[1] then
        local p = V.resolve(ctx.cwd, args[1])
        local d, e = V.read(p)
        if not d then
            return nil, e or "error"
        end
        return d, nil, args[1]
    end
    return ctx.stdin or "", nil, nil
end

function E.register(cmds, K, V, Pac)

    cmds.basename = function(args, ctx)
        if not args[1] then
            err(ctx, "basename: missing operand")
            return
        end
        print((args[1]:match("([^/]+)$")) or args[1])
    end
    cmds.dirname = function(args, ctx)
        if not args[1] then
            err(ctx, "dirname: missing operand")
            return
        end
        local d = args[1]:match("^(.*)/")
        print((d == "" and "/") or d or ".")
    end
    cmds.realpath = function(args, ctx)
        print(V.resolve(ctx.cwd, args[1] or "."))
    end
    cmds.readlink = cmds.realpath

    cmds.seq = function(args, ctx)
        local a, b, c
        if #args == 1 then
            a, b, c = 1, 1, tonumber(args[1])
        elseif #args == 2 then
            a, b, c = tonumber(args[1]), 1, tonumber(args[2])
        else
            a, b, c = tonumber(args[1]), tonumber(args[2]), tonumber(args[3])
        end
        a, b, c = a or 1, b or 1, c or 1
        if b == 0 then
            return
        end
        local i = a
        local n = 0
        while (b > 0 and i <= c) or (b < 0 and i >= c) do
            print(tostring(i))
            i = i + b
            n = n + 1
            if n > 500 then
                break
            end
        end
    end

    cmds.printf = function(args)
        local fmt = args[1] or ""
        table.remove(args, 1)
        local ok, s = pcall(string.format, fmt, unpack and unpack(args) or table.unpack(args))
        if ok then
            write(s:gsub("\\n", "\n"):gsub("\\t", "\t"))
        else
            write(fmt)
        end
    end

    cmds.expr = function(args, ctx)
        local s = join(args)
        s = s:gsub(" ", "")
        if s:match("^[%d%+%-%*/%%%(%)]+$") then
            local f = loadstring and loadstring("return " .. s) or load("return " .. s)
            if f then
                local ok, v = pcall(f)
                if ok then
                    print(tostring(v))
                    return
                end
            end
        end
        print("0")
        ctx.ok = false
    end

    cmds.test = function(args, ctx)
        local a = args
        if a[#a] == "]" then
            table.remove(a)
        end
        local op, x, y
        if a[1] == "-f" or a[1] == "-d" or a[1] == "-e" or a[1] == "-z" or a[1] == "-n" then
            op, x = a[1], a[2]
        elseif a[2] == "-eq" or a[2] == "-ne" or a[2] == "=" or a[2] == "!=" then
            x, op, y = a[1], a[2], a[3]
        else
            op, x = "-n", a[1]
        end
        local r = false
        if op == "-e" then
            r = V.exists(V.resolve(ctx.cwd, x or ""))
        elseif op == "-f" then
            r = V.exists(V.resolve(ctx.cwd, x or "")) and not V.isDir(V.resolve(ctx.cwd, x or ""))
        elseif op == "-d" then
            r = V.isDir(V.resolve(ctx.cwd, x or ""))
        elseif op == "-z" then
            r = not x or x == ""
        elseif op == "-n" then
            r = x ~= nil and x ~= ""
        elseif op == "-eq" then
            r = tonumber(x) == tonumber(y)
        elseif op == "-ne" then
            r = tonumber(x) ~= tonumber(y)
        elseif op == "=" then
            r = x == y
        elseif op == "!=" then
            r = x ~= y
        end
        ctx.ok = r
    end
    cmds["["] = cmds.test

    cmds.cut = function(args, ctx)
        local delim, field = "\t", 1
        local file
        local i = 1
        while i <= #args do
            if args[i] == "-d" and args[i + 1] then
                delim = args[i + 1]
                i = i + 2
            elseif args[i]:sub(1, 2) == "-d" and #args[i] > 2 then
                delim = args[i]:sub(3)
                i = i + 1
            elseif args[i] == "-f" and args[i + 1] then
                field = tonumber(args[i + 1]) or 1
                i = i + 2
            elseif args[i]:sub(1, 2) == "-f" then
                field = tonumber(args[i]:sub(3)) or 1
                i = i + 1
            else
                file = args[i]
                i = i + 1
            end
        end
        local data = file and (select(1, V.read(V.resolve(ctx.cwd, file)))) or (ctx.stdin or "")
        if not data then
            err(ctx, "cut: no data")
            return
        end
        for line in (data .. "\n"):gmatch("(.-)\n") do
            local cols = {}
            local pat = "[^" .. (delim == "\t" and "\t" or "%" .. delim) .. "]+"
            if delim == " " then
                for w in line:gmatch("%S+") do
                    cols[#cols + 1] = w
                end
            else
                for w in line:gmatch(pat) do
                    cols[#cols + 1] = w
                end
            end
            print(cols[field] or "")
        end
    end

    cmds.sort = function(args, ctx)
        local data = data_of(args, ctx, V)
        if not data then
            return
        end
        local lines = {}
        for line in (data .. "\n"):gmatch("(.-)\n") do
            lines[#lines + 1] = line
        end
        table.sort(lines)
        for i = 1, #lines do
            print(lines[i])
        end
    end

    cmds.uniq = function(args, ctx)
        local data = data_of(args, ctx, V) or ""
        local prev
        for line in (data .. "\n"):gmatch("(.-)\n") do
            if line ~= prev then
                print(line)
                prev = line
            end
        end
    end

    cmds.tr = function(args, ctx)
        local a, b = args[1], args[2]
        local data = ctx.stdin or ""
        if not a then
            err(ctx, "tr: missing operand")
            return
        end
        if b then
            local map = {}
            for i = 1, math.min(#a, #b) do
                map[a:sub(i, i)] = b:sub(i, i)
            end
            data = data:gsub(".", function(ch)
                return map[ch] or ch
            end)
        end
        write(data)
    end

    cmds.tee = function(args, ctx)
        local data = ctx.stdin or ""
        write(data)
        if args[1] then
            V.write(V.resolve(ctx.cwd, args[1]), data, "w")
        end
    end

    cmds.nl = function(args, ctx)
        local data = data_of(args, ctx, V) or ""
        local n = 0
        for line in (data .. "\n"):gmatch("(.-)\n") do
            n = n + 1
            print(string.format("%6d\t%s", n, line))
        end
    end

    cmds.rev = function(args, ctx)
        local data = data_of(args, ctx, V) or ""
        for line in (data .. "\n"):gmatch("(.-)\n") do
            print(line:reverse())
        end
    end

    cmds.wc = cmds.wc -- keep existing

    cmds.find = function(args, ctx)
        local start = V.resolve(ctx.cwd, ".")
        local namepat
        local i = 1
        if args[1] and args[1]:sub(1, 1) ~= "-" then
            start = V.resolve(ctx.cwd, args[1])
            i = 2
        end
        while i <= #args do
            if args[i] == "-name" and args[i + 1] then
                namepat = args[i + 1]:gsub("%*", ".*"):gsub("%?", ".")
                i = i + 2
            else
                i = i + 1
            end
        end
        local n = 0
        local function rec(p)
            if n > 400 then
                return
            end
            print(p)
            n = n + 1
            if V.isDir(p) then
                local list = V.list(p) or {}
                for j = 1, #list do
                    local ch = V.norm(p .. "/" .. list[j])
                    if not namepat or list[j]:match(namepat) then
                        rec(ch)
                    elseif V.isDir(ch) then
                        rec(ch)
                    end
                end
            end
        end
        rec(start)
    end

    cmds.xargs = function(args, ctx)
        local cmd = args[1] or "echo"
        table.remove(args, 1)
        local data = ctx.stdin or ""
        for w in data:gmatch("%S+") do
            args[#args + 1] = w
        end
        if cmds[cmd] then
            cmds[cmd](args, ctx)
        else
            err(ctx, "xargs: " .. cmd .. ": command not found")
        end
    end

    cmds.chmod = function(args, ctx)
        if #args < 2 then
            err(ctx, "chmod: missing operand")
            return
        end
        -- cosmetic
        local p = V.resolve(ctx.cwd, args[#args])
        if not V.exists(p) then
            err(ctx, "chmod: cannot access '" .. args[#args] .. "': No such file or directory")
        end
    end
    cmds.chown = function(args, ctx)
        if #args < 2 then
            err(ctx, "chown: missing operand")
            return
        end
        local p = V.resolve(ctx.cwd, args[#args])
        if not V.exists(p) then
            err(ctx, "chown: cannot access '" .. args[#args] .. "': No such file or directory")
        end
    end

    cmds.ln = function(args, ctx)
        local src, dst = args[1], args[2]
        if args[1] == "-s" then
            src, dst = args[2], args[3]
        end
        if not src or not dst then
            err(ctx, "ln: missing file operand")
            return
        end
        V.write(V.resolve(ctx.cwd, dst), "symlink -> " .. src .. "\n", "w")
    end

    cmds.stat = function(args, ctx)
        local p = V.resolve(ctx.cwd, args[1] or ".")
        if not V.exists(p) then
            err(ctx, "stat: cannot statx '" .. (args[1] or ".") .. "'")
            return
        end
        print("  File: " .. p)
        print("  Size: " .. tostring(V.size(p)) .. "\tBlocks: 8\tIO Block: 4096 " .. (V.isDir(p) and "directory" or "regular file"))
        print("Device: 3h/3d\tInode: 1\tLinks: 1")
        print("Access: (0755/" .. (V.isDir(p) and "drwxr-xr-x" or "-rwxr-xr-x") .. ")  Uid: (0/root)   Gid: (0/root)")
    end

    cmds.file = function(args, ctx)
        local p = V.resolve(ctx.cwd, args[1] or "")
        if not args[1] then
            err(ctx, "file: missing operand")
            return
        end
        if not V.exists(p) then
            print(args[1] .. ": cannot open")
            ctx.ok = false
            return
        end
        if V.isDir(p) then
            print(args[1] .. ": directory")
        elseif p:match("vmlinuz") or p:match("/boot/") then
            print(args[1] .. ": Linux kernel x86 boot executable bzImage")
        elseif p:match("%.lua$") then
            print(args[1] .. ": Lua script text")
        else
            print(args[1] .. ": ASCII text")
        end
    end

    cmds.du = function(args, ctx)
        local start = V.resolve(ctx.cwd, args[1] or ".")
        local function rec(p)
            local sum = 4
            if V.isDir(p) then
                local list = V.list(p) or {}
                for i = 1, #list do
                    sum = sum + rec(V.norm(p .. "/" .. list[i]))
                end
            else
                sum = math.max(4, math.ceil(V.size(p) / 1024))
            end
            return sum
        end
        print(tostring(rec(start)) .. "\t" .. start)
    end

    cmds.cal = function()
        if os.date then
            print(os.date("%B %Y"))
        end
        print("Su Mo Tu We Th Fr Sa")
        print("       1  2  3  4  5")
        print(" 6  7  8  9 10 11 12")
        print("13 14 15 16 17 18 19")
        print("20 21 22 23 24 25 26")
        print("27 28 29 30 31")
    end

    cmds.nproc = function()
        print("1")
    end
    cmds.arch = function()
        print("cc-" .. K.machine)
    end
    cmds.logname = function()
        print("root")
    end
    cmds.who = function()
        print("root     tty0         " .. (os.date and os.date("%Y-%m-%d %H:%M") or ""))
    end
    cmds.w = cmds.who
    cmds.last = cmds.who
    cmds.groups = function()
        print("root")
    end
    cmds.passwd = function()
        print("Changing password for root.")
        print("passwd: password unchanged (shadow is read-only in ccLinux)")
    end
    cmds.useradd = function(args)
        print("useradd: user '" .. (args[1] or "user") .. "' created (fake)")
    end

    cmds.whereis = function(args, ctx)
        if not args[1] then
            return
        end
        if cmds[args[1]] then
            print(args[1] .. ": /usr/bin/" .. args[1] .. " /usr/share/man/man1/" .. args[1] .. ".1.gz")
        else
            print(args[1] .. ":")
        end
    end

    cmds.locale = function()
        print("LANG=C")
        print("LC_ALL=C")
    end
    cmds.getent = function(args)
        if args[1] == "passwd" then
            print("root:x:0:0:root:/root:/bin/bash")
            print("cc:x:1000:1000:CC user:/home/cc:/bin/bash")
        elseif args[1] == "hosts" then
            print("127.0.0.1 localhost")
        end
    end

    cmds.lspci = function()
        print("00:00.0 Host bridge: Mojang AB CC: Tweaked Chipset")
        print("00:01.0 VGA compatible controller: CraftOS Terminal Adapter")
        print("00:02.0 Network controller: Rednet Controller")
    end
    cmds.lsusb = function()
        print("Bus 001 Device 001: ID 1d6b:0002 Linux Foundation 2.0 root hub")
    end
    cmds.dmidecode = function()
        print("# dmidecode 3.6")
        print("Getting SMBIOS data from sysfs.")
        print("SMBIOS 3.0 present.")
        print("")
        print("Handle 0x0001, DMI type 1, 27 bytes")
        print("System Information")
        print("\tManufacturer: Mojang AB")
        print("\tProduct Name: CC: Tweaked " .. K.machine)
        print("\tVersion: " .. K.bios())
    end
    cmds.blkid = function()
        print("/dev/hda1: UUID=\"cclinux-0001\" BLOCK_SIZE=\"4096\" TYPE=\"ext2\" PARTUUID=\"0001\"")
    end
    cmds.fdisk = function()
        print("Disk /dev/hda: CraftOS virtual disk")
        print("Device     Boot Start  End Blocks Id Type")
        print("/dev/hda1  *        1    -     -  83 Linux")
    end
    cmds.hostnamectl = function()
        print(" Static hostname: " .. K.hostname)
        print("       Icon name: computer-" .. K.machine)
        print("         Chassis: " .. K.machine)
        print("      Machine ID: " .. tostring(K.id()))
        print("         Boot ID: 00000000")
        print("Operating System: " .. ((K.distro == "arch" and "Arch Linux") or (K.distro == "debian" and "Debian GNU/Linux 12") or "ccLinux 6.12"))
        print("          Kernel: Linux " .. K.release)
        print("    Architecture: cc-" .. K.machine)
    end
    cmds.timedatectl = function()
        print("               Local time: " .. (os.date and os.date("%a %Y-%m-%d %H:%M:%S") or "?"))
        print("           Universal time: " .. (os.date and os.date("!%a %Y-%m-%d %H:%M:%S") or "?"))
        print("                 RTC time: n/a")
        print("                Time zone: UTC (UTC, +0000)")
        print("System clock synchronized: yes")
        print("              NTP service: active")
    end

    cmds.ss = function()
        print("Netid State  Recv-Q Send-Q Local Address:Port  Peer Address:Port")
        print("tcp   LISTEN 0      128          0.0.0.0:22         0.0.0.0:*")
    end
    cmds.netstat = cmds.ss
    cmds.traceroute = function(args)
        local h = args[1] or "1.1.1.1"
        print("traceroute to " .. h .. " (" .. h .. "), 30 hops max")
        print(" 1  gateway (10.0.0.1)  0.4 ms  0.3 ms  0.3 ms")
        print(" 2  " .. h .. "  12.1 ms  11.8 ms  12.0 ms")
    end

    local function http_get(url)
        if not rawget(_G, "http") or not http.get then
            return nil, "http API disabled"
        end
        local ok, res = pcall(http.get, url, nil, true)
        if not ok or not res then
            return nil, "failed"
        end
        local body = res.readAll() or ""
        res.close()
        return body
    end

    cmds.wget = function(args, ctx)
        if Pac and not Pac.installed("wget") and not Pac.installed("curl") then
            -- wget is extra; still allow curl-less builtin for convenience if curl core
        end
        local url, out
        for i = 1, #args do
            if args[i] == "-O" and args[i + 1] then
                out = args[i + 1]
            elseif args[i]:match("^https?://") then
                url = args[i]
            end
        end
        if not url then
            err(ctx, "wget: missing URL")
            return
        end
        print("--" .. (os.date and os.date("%Y-%m-%d %H:%M:%S") or "") .. "--  " .. url)
        print("Resolving... connected.")
        local body, e = http_get(url)
        if not body then
            print("wget: unable to resolve host address (" .. (e or "error") .. ")")
            ctx.ok = false
            return
        end
        out = out or url:match("([^/]+)$") or "index.html"
        V.write(V.resolve(ctx.cwd, out), body, "w")
        print("Saved '" .. out .. "' [" .. tostring(#body) .. "]")
    end
    cmds.curl = function(args, ctx)
        local url, out, silent
        for i = 1, #args do
            if args[i] == "-o" and args[i + 1] then
                out = args[i + 1]
            elseif args[i] == "-s" or args[i] == "--silent" then
                silent = true
            elseif args[i]:match("^https?://") then
                url = args[i]
            end
        end
        if not url then
            err(ctx, "curl: try 'curl --help'")
            return
        end
        local body, e = http_get(url)
        if not body then
            if not silent then
                print("curl: (6) Could not resolve host (" .. (e or "") .. ")")
            end
            ctx.ok = false
            return
        end
        if out then
            V.write(V.resolve(ctx.cwd, out), body, "w")
        else
            write(body)
        end
    end

    cmds.tar = function(args, ctx)
        print("tar: GNU tar 1.35")
        if args[1] and args[1]:find("t") then
            print("boot/")
            print("etc/")
            print("root/")
        elseif args[1] and args[1]:find("c") then
            print("tar: creating archive (stub)")
        else
            print("Usage: tar -tf archive | tar -cf archive files")
        end
    end
    cmds.gzip = function(args, ctx)
        print("gzip: stub (not compressing)")
    end
    cmds.gunzip = cmds.gzip

    local function simple_hash(s)
        local h = 2166136261
        for i = 1, #s do
            h = (h * 16777619 + s:byte(i)) % 4294967296
        end
        return string.format("%08x%08x%08x%08x", h, h * 3 % 4294967296, h * 7 % 4294967296, h * 11 % 4294967296)
    end
    cmds.md5sum = function(args, ctx)
        local data, e, name = data_of(args, ctx, V)
        if not data then
            err(ctx, "md5sum: " .. (e or "error"))
            return
        end
        print(simple_hash(data):sub(1, 32) .. "  " .. (name or "-"))
    end
    cmds.sha256sum = function(args, ctx)
        local data, e, name = data_of(args, ctx, V)
        if not data then
            err(ctx, "sha256sum: " .. (e or "error"))
            return
        end
        print(simple_hash(data) .. "  " .. (name or "-"))
    end

    cmds.base64 = function(args, ctx)
        local data = data_of(args, ctx, V) or ""
        local b = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
        local function enc(data)
            return (data:gsub(".", function(x)
                local r, byte = "", x:byte()
                for i = 8, 1, -1 do
                    r = r .. (byte % 2 ^ i - byte % 2 ^ (i - 1) > 0 and "1" or "0")
                end
                return r
            end) .. "0000"):gsub("%d%d%d?%d?%d?%d?", function(x)
                if #x < 6 then
                    return ""
                end
                local c = 0
                for i = 1, 6 do
                    c = c + (x:sub(i, i) == "1" and 2 ^ (6 - i) or 0)
                end
                return b:sub(c + 1, c + 1)
            end)
        end
        print(enc(data:sub(1, 256)))
    end

    cmds.hexdump = function(args, ctx)
        local data = data_of(args, ctx, V) or ""
        data = data:sub(1, 128)
        local i = 1
        while i <= #data do
            local chunk = data:sub(i, i + 15)
            local hex = {}
            for j = 1, #chunk do
                hex[#hex + 1] = string.format("%02x", chunk:byte(j))
            end
            print(string.format("%08x  %s", i - 1, table.concat(hex, " ")))
            i = i + 16
        end
    end
    cmds.xxd = cmds.hexdump
    cmds.od = cmds.hexdump

    cmds.diff = function(args, ctx)
        if #args < 2 then
            err(ctx, "diff: missing operand")
            return
        end
        local a = V.read(V.resolve(ctx.cwd, args[1])) or ""
        local b = V.read(V.resolve(ctx.cwd, args[2])) or ""
        if a == b then
            return
        end
        print("--- " .. args[1])
        print("+++ " .. args[2])
        print("files differ")
        ctx.ok = false
    end
    cmds.cmp = cmds.diff

    cmds.sed = function(args, ctx)
        local expr = args[1] or ""
        local data = ctx.stdin
        if args[2] then
            data = V.read(V.resolve(ctx.cwd, args[2])) or ""
        end
        data = data or ""
        local pat, repl = expr:match("^s/([^/]*)/([^/]*)/")
        if pat then
            data = data:gsub(pat, repl or "")
        end
        write(data)
        if data:sub(-1) ~= "\n" then
            print("")
        end
    end
    cmds.awk = function(args, ctx)
        local data = ctx.stdin or ""
        if args[2] then
            data = V.read(V.resolve(ctx.cwd, args[2])) or data
        end
        local n = 0
        for line in (data .. "\n"):gmatch("(.-)\n") do
            n = n + 1
            print(line)
        end
    end

    cmds.time = function(args, ctx)
        local t0 = os.clock()
        if args[1] and cmds[args[1]] then
            local name = args[1]
            table.remove(args, 1)
            cmds[name](args, ctx)
        end
        local dt = os.clock() - t0
        print(string.format("real\t0m%.3fs", dt))
        print("user\t0m0.000s")
        print("sys\t0m0.000s")
    end

    cmds.watch = function(args, ctx)
        print("watch: running once (no GUI loop). Use Ctrl+T to stop other loops.")
        if args[1] and cmds[args[1]] then
            local name = args[1]
            table.remove(args, 1)
            cmds[name](args, ctx)
        end
    end

    cmds.alias = function(args, ctx)
        ctx.aliases = ctx.aliases or {}
        if not args[1] then
            local keys = {}
            for k in pairs(ctx.aliases) do
                keys[#keys + 1] = k
            end
            table.sort(keys)
            for i = 1, #keys do
                print("alias " .. keys[i] .. "='" .. ctx.aliases[keys[i]] .. "'")
            end
            return
        end
        local k, v = args[1]:match("^([^=]+)=(.*)$")
        if k then
            v = v:gsub("^['\"]", ""):gsub("['\"]$", "")
            ctx.aliases[k] = v
        else
            print("alias " .. args[1] .. "='" .. (ctx.aliases[args[1]] or "") .. "'")
        end
    end
    cmds.unalias = function(args, ctx)
        if args[1] and ctx.aliases then
            ctx.aliases[args[1]] = nil
        end
    end

    cmds.source = function(args, ctx)
        if not args[1] then
            err(ctx, "source: filename argument required")
            return
        end
        local data = V.read(V.resolve(ctx.cwd, args[1]))
        if not data then
            err(ctx, "source: " .. args[1] .. ": not found")
            return
        end
        print("source: executed " .. tostring(#data) .. " bytes (no-op parser)")
    end
    cmds["."] = cmds.source

    cmds.killall = function(args, ctx)
        if not args[1] then
            err(ctx, "killall: missing name")
            return
        end
        print("killall: no process found")
        ctx.ok = false
    end
    cmds.pstree = function()
        print("init─┬─kthreadd")
        print("     └─bash")
    end

    cmds.ldd = function(args)
        print("\tlinux-vdso.so.1 (0x00007ffd)")
        print("\tlibc.so.6 => /usr/lib/libc.so.6 (0x00007f00)")
        print("\t/lib64/ld-linux-x86-64.so.2 => /usr/lib64/ld-linux-x86-64.so.2")
    end
    cmds.strace = function(args, ctx)
        if not needpkg(ctx, Pac, "strace") then
            return
        end
        print("execve(\"" .. (args[1] or "/bin/true") .. "\", ...) = 0")
        print("exit_group(0) = ?")
        print("+++ exited with 0 +++")
    end
    cmds.lsof = function()
        print("COMMAND  PID USER   FD   TYPE DEVICE SIZE/OFF NODE NAME")
        print("bash    " .. tostring(K.shell_pid or 1) .. " root  cwd    DIR    3,1     4096    2 /root")
    end

    cmds.htop = function(args, ctx)
        if not needpkg(ctx, Pac, "htop") then
            return
        end
        print("  " .. K.hostname .. "   " .. (os.date and os.date("%H:%M:%S") or ""))
        print("  CPU[||||      12%]   Mem[" .. tostring(math.floor(K.mem_kb * 0.18)) .. "/" .. tostring(K.mem_kb) .. "K]")
        print("  PID USER     PRI  NI  S  CPU% MEM%   TIME+  Command")
        for _, p in ipairs(K.ps_list()) do
            print(string.format("%5d root      20   0  %s   0.0  0.1   0:00.01 %s", p.pid, p.state, p.comm))
        end
        print("F1Help  qQuit")
    end
    cmds.top = function(args, ctx)
        cmds.ps(args, ctx)
    end
    cmds.btop = function(args, ctx)
        if not needpkg(ctx, Pac, "btop") then
            return
        end
        cmds.htop(args, ctx)
    end

    cmds.cowsay = function(args, ctx)
        if not needpkg(ctx, Pac, "cowsay") then
            return
        end
        local m = join(args)
        if m == "" then
            m = ctx.stdin or "moo"
            m = m:gsub("\n", " ")
        end
        local line = "< " .. m .. " >"
        print(" " .. string.rep("_", #m + 2))
        print(line)
        print(" " .. string.rep("-", #m + 2))
        print("        \\   ^__^")
        print("         \\  (oo)\\_______")
        print("            (__)\\       )\\/\\")
        print("                ||----w |")
        print("                ||     ||")
    end
    cmds.fortune = function(args, ctx)
        if not needpkg(ctx, Pac, "fortune-mod") then
            return
        end
        local f = {
            "There is no GNU/Linux without GNU.",
            "pacman -Syu is a way of life.",
            "I use Arch, btw.",
            "The box said 'Requires Windows 95 or better'. So I installed Linux.",
            "In CraftOS nobody can hear you kernel panic.",
        }
        print(f[math.random(1, #f)])
    end
    cmds.git = function(args, ctx)
        if not needpkg(ctx, Pac, "git") then
            return
        end
        local s = args[1] or "--help"
        if s == "--version" or s == "version" then
            print("git version 2.47.0")
        elseif s == "status" then
            print("On branch master")
            print("nothing to commit, working tree clean")
        elseif s == "init" then
            print("Initialized empty Git repository in " .. ctx.cwd .. "/.git/")
        else
            print("usage: git [--version] [--help] <command> [<args>]")
        end
    end
    cmds.python = function(args, ctx)
        if not needpkg(ctx, Pac, "python") then
            return
        end
        print("Python 3.12.7 (ccLinux)")
        if args[1] == "--version" or args[1] == "-V" then
            return
        end
        print(">>> (no REPL in kernel tty; use CraftOS lua)")
    end
    cmds.python3 = cmds.python
    cmds.gcc = function(args, ctx)
        if not needpkg(ctx, Pac, "gcc") then
            return
        end
        if args[1] == "--version" then
            print("gcc (GCC) 14.2.1 20240910 (ccLinux)")
            return
        end
        print("gcc: fatal error: no input files")
        print("compilation terminated.")
        ctx.ok = false
    end
    cmds.make = function(args, ctx)
        if not needpkg(ctx, Pac, "make") then
            return
        end
        print("make: *** No targets specified and no makefile found.  Stop.")
        ctx.ok = false
    end
    cmds.node = function(args, ctx)
        if not needpkg(ctx, Pac, "nodejs") then
            return
        end
        print("v22.11.0")
    end
    cmds.docker = function(args, ctx)
        if not needpkg(ctx, Pac, "docker") then
            return
        end
        print("docker: Cannot connect to the Docker daemon at unix:///var/run/docker.sock.")
        ctx.ok = false
    end
    cmds.ssh = function(args, ctx)
        if not needpkg(ctx, Pac, "openssh") then
            return
        end
        print("ssh: connect to host " .. (args[1] or "localhost") .. " port 22: Connection refused")
        ctx.ok = false
    end
    cmds.tmux = function(args, ctx)
        if not needpkg(ctx, Pac, "tmux") then
            return
        end
        print("tmux: no GUI multiplexer on this tty")
    end
    cmds.nmap = function(args, ctx)
        if not needpkg(ctx, Pac, "nmap") then
            return
        end
        print("Starting Nmap 7.95 ( https://nmap.org )")
        print("Nmap scan report for " .. (args[1] or "127.0.0.1"))
        print("Host is up (0.00040s latency).")
        print("PORT   STATE SERVICE")
        print("22/tcp closed ssh")
    end

    cmds.grub_install = function()
        print("Installing for i386-pc platform.")
        print("Installation finished. No error reported.")
    end
    cmds["grub-install"] = cmds.grub_install
    cmds["grub-mkconfig"] = function()
        print("Generating grub configuration file ...")
        print("Found linux image: /boot/vmlinuz-linux")
        print("Found initrd image: /boot/initramfs-linux.img")
        print("done")
    end
    cmds.mkinitcpio = function()
        print("==> Building image from preset: /etc/mkinitcpio.d/linux.preset")
        print("==> Starting build: " .. K.release)
        print("  -> Running build hook: [base]")
        print("  -> Running build hook: [udev]")
        print("==> Generating module dependencies")
        print("==> Creating gzip-compressed initcpio image: /boot/initramfs-linux.img")
        print("==> Image generation successful")
    end

    cmds.apt = function(args, ctx)
        if K.distro == "debian" then
            local sub = args[1]
            if sub == "update" then
                print("Hit:1 http://deb.debian.org/debian bookworm InRelease")
                print("Reading package lists... Done")
                return
            end
            if sub == "install" and args[2] then
                print("Reading package lists... Done")
                print("Building dependency tree... Done")
                print("The following NEW packages will be installed:")
                print("  " .. args[2])
                print("Setting up " .. args[2] .. " ...")
                if cmds.pacman then
                    local a = { "-S", "--noconfirm", args[2] }
                    cmds.pacman(a, ctx)
                end
                return
            end
            print("apt 2.6.1 (debian)")
            print("Usage: apt update | apt install <pkg> | apt search <pkg>")
            return
        end
        print("E: ccLinux uses pacman. Try: pacman -Syu")
        print("   Debian mode: boot 'Debian GNU/Linux' from GRUB.")
        ctx.ok = false
    end
    cmds["apt-get"] = cmds.apt
    cmds.apt_get = cmds.apt

    cmds.help = function()
        print("ccLinux GNU userland. Common commands:")
        print("  ls cd pwd cat echo mkdir rm cp mv touch tree find")
        print("  head tail wc grep sed awk cut sort uniq tr tee")
        print("  chmod chown ln stat file du df free mount")
        print("  uname hostname whoami id date uptime cal")
        print("  ps kill top htop dmesg lscpu lsblk lspci")
        print("  ping ip ss wget curl tar gzip sha256sum")
        print("  pacman -Syu | -S pkg | -Ss q | -Q | -R pkg")
        print("  systemctl reboot|poweroff   shutdown   panic")
        print("  bash operators:  ;   &&   ||   |   >   >>   <")
        print("  extra pkgs: pacman -S htop cowsay git python gcc")
        print("Special: /proc /sys /dev /boot /root  CraftOS: /mnt/craftos")
    end
    cmds.man = cmds.help
    cmds.busybox = cmds.help
    cmds.info = cmds.help
end

return E
