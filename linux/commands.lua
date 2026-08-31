-- BusyBox-style builtins for ccLinux.

local C = {}

local function err(ctx, msg)
    print(msg)
    ctx.ok = false
end

local function need(K, V, ctx)
    return K, V, ctx
end

local function join(args, from)
    from = from or 1
    local t = {}
    for i = from, #args do
        t[#t + 1] = args[i]
    end
    return table.concat(t, " ")
end

local function parse_flags(args)
    local flags, rest = {}, {}
    for i = 1, #args do
        local a = args[i]
        if a == "--" then
            for j = i + 1, #args do
                rest[#rest + 1] = args[j]
            end
            break
        elseif a:sub(1, 1) == "-" and #a > 1 and a:sub(1, 2) ~= "-" then
            for k = 2, #a do
                flags[a:sub(k, k)] = true
            end
        else
            rest[#rest + 1] = a
        end
    end
    return flags, rest
end

local function month_day(ms)
    local sec = math.floor((ms or 0) / 1000)
    if os.date then
        return os.date("%b %d %H:%M", sec)
    end
    return "Jan  1 00:00"
end

local function ls_color(name, isDir)
    if not (term.isColor and term.isColor()) then
        return name
    end
    local reset = colors.lightGray
    if isDir then
        term.setTextColor(colors.blue)
    elseif name:match("%.lua$") or name == "panic" then
        term.setTextColor(colors.green)
    elseif name:match("^vmlinuz") or name:match("^init") then
        term.setTextColor(colors.green)
    else
        term.setTextColor(reset)
        return name
    end
    write(name)
    term.setTextColor(reset)
    return nil
end

function C.register(cmds, K, V)

    cmds.true_ = function() end
    cmds["true"] = function() end
    cmds["false"] = function(args, ctx) ctx.ok = false end

    cmds.help = function()
        print("ccLinux busybox. Commands:")
        print("  ls cd pwd cat echo mkdir rm rmdir cp mv touch tree")
        print("  head tail wc grep clear date uname hostname whoami id")
        print("  ps kill dmesg free df mount lsmod uptime env export")
        print("  shutdown reboot halt poweroff panic oops sysrq")
        print("  neofetch lscpu lsblk which history sleep sync")
        print("  journalctl systemctl sysctl uname login logout exit")
        print("  edit nano vim less more ping ip")
        print("Special files: /proc /sys /dev  |  CraftOS disk: /mnt/craftos")
        print("Panic:  panic   or   echo c > /proc/sysrq-trigger")
    end
    cmds.man = cmds.help
    cmds.busybox = cmds.help

    cmds.clear = function()
        term.clear()
        term.setCursorPos(1, 1)
    end
    cmds.reset = cmds.clear

    cmds.pwd = function(args, ctx)
        print(ctx.cwd)
    end

    cmds.cd = function(args, ctx)
        local t = args[1] or "/root"
        local p = V.resolve(ctx.cwd, t)
        if not V.exists(p) then
            err(ctx, "cd: " .. t .. ": No such file or directory")
            return
        end
        if not V.isDir(p) then
            err(ctx, "cd: " .. t .. ": Not a directory")
            return
        end
        ctx.cwd = p
    end

    cmds.ls = function(args, ctx)
        local flags, rest = parse_flags(args)
        local target = V.resolve(ctx.cwd, rest[1] or ".")
        if not V.exists(target) then
            err(ctx, "ls: cannot access '" .. (rest[1] or ".") .. "': No such file or directory")
            return
        end
        local names
        if V.isDir(target) then
            names = V.list(target) or {}
        else
            names = { fs.getName and fs.getName(V.real(target)) or rest[1] }
        end
        table.sort(names)
        local show = {}
        for i = 1, #names do
            local n = names[i]
            if flags.a or n:sub(1, 1) ~= "." then
                show[#show + 1] = n
            end
        end
        if flags.l then
            print("total " .. tostring(#show * 4))
            for i = 1, #show do
                local n = show[i]
                local p = V.isDir(target) and V.norm(target .. "/" .. n) or target
                local d = V.isDir(p)
                local mode = d and "drwxr-xr-x" or "-rw-r--r--"
                local sz = V.size(p)
                local mt = month_day(V.modified(p))
                write(string.format("%s 1 root root %6d %s ", mode, sz, mt))
                local colored = ls_color(n, d)
                if colored then
                    print(colored)
                else
                    print("")
                end
            end
        else
            local w, _ = term.getSize()
            local col, x = 12, 0
            for i = 1, #show do
                local n = show[i]
                local p = V.isDir(target) and V.norm(target .. "/" .. n) or target
                local d = V.isDir(p)
                if x + col > w then
                    print("")
                    x = 0
                end
                local colored = ls_color(n, d)
                if colored then
                    write(n)
                end
                if #n < col - 1 then
                    write(string.rep(" ", col - #n))
                else
                    write(" ")
                end
                x = x + col
            end
            if x > 0 then
                print("")
            end
        end
    end
    cmds.ll = function(args, ctx)
        local a = { "-l" }
        for i = 1, #args do
            a[#a + 1] = args[i]
        end
        cmds.ls(a, ctx)
    end
    cmds.dir = cmds.ls

    cmds.cat = function(args, ctx)
        if #args == 0 then
            if ctx.stdin then
                write(ctx.stdin)
                if ctx.stdin:sub(-1) ~= "\n" then
                    print("")
                end
            end
            return
        end
        for i = 1, #args do
            if args[i] == "-" then
                if ctx.stdin then
                    write(ctx.stdin)
                end
            else
                local p = V.resolve(ctx.cwd, args[i])
                local data, e = V.read(p)
                if not data then
                    err(ctx, "cat: " .. args[i] .. ": " .. (e or "error"))
                else
                    write(data)
                    if data ~= "" and data:sub(-1) ~= "\n" then
                        print("")
                    end
                end
            end
        end
    end

    cmds.echo = function(args)
        local nolf = false
        local start = 1
        if args[1] == "-n" then
            nolf = true
            start = 2
        end
        local s = join(args, start)
        if nolf then
            write(s)
        else
            print(s)
        end
    end

    cmds.mkdir = function(args, ctx)
        local flags, rest = parse_flags(args)
        if #rest == 0 then
            err(ctx, "mkdir: missing operand")
            return
        end
        for i = 1, #rest do
            local p = V.resolve(ctx.cwd, rest[i])
            local ok, e = V.mkdir(p)
            if not ok then
                err(ctx, "mkdir: cannot create directory '" .. rest[i] .. "': " .. (e or "error"))
            end
        end
    end

    cmds.rmdir = function(args, ctx)
        if #args == 0 then
            err(ctx, "rmdir: missing operand")
            return
        end
        for i = 1, #args do
            local p = V.resolve(ctx.cwd, args[i])
            if not V.isDir(p) then
                err(ctx, "rmdir: " .. args[i] .. ": Not a directory")
            else
                local list = V.list(p) or {}
                if #list > 0 then
                    err(ctx, "rmdir: " .. args[i] .. ": Directory not empty")
                else
                    V.remove(p)
                end
            end
        end
    end

    cmds.rm = function(args, ctx)
        local flags, rest = parse_flags(args)
        if #rest == 0 then
            err(ctx, "rm: missing operand")
            return
        end
        for i = 1, #rest do
            if rest[i] == "/" and flags.r and flags.f then
                err(ctx, "rm: it is dangerous to operate recursively on '/'")
                return
            end
            local p = V.resolve(ctx.cwd, rest[i])
            if not V.exists(p) then
                if not flags.f then
                    err(ctx, "rm: cannot remove '" .. rest[i] .. "': No such file or directory")
                end
            elseif V.isDir(p) and not flags.r then
                err(ctx, "rm: cannot remove '" .. rest[i] .. "': Is a directory")
            else
                local ok, e = V.remove(p)
                if not ok and not flags.f then
                    err(ctx, "rm: cannot remove '" .. rest[i] .. "': " .. (e or "error"))
                end
            end
        end
    end

    cmds.touch = function(args, ctx)
        if #args == 0 then
            err(ctx, "touch: missing file operand")
            return
        end
        for i = 1, #args do
            local p = V.resolve(ctx.cwd, args[i])
            if not V.exists(p) then
                V.write(p, "", "w")
            end
        end
    end

    cmds.cp = function(args, ctx)
        if #args < 2 then
            err(ctx, "cp: missing operand")
            return
        end
        local dst = V.resolve(ctx.cwd, args[#args])
        local src = V.resolve(ctx.cwd, args[1])
        if V.isDir(dst) then
            local name = args[1]:match("([^/]+)$") or args[1]
            dst = V.norm(dst .. "/" .. name)
        end
        local ok, e = V.copy(src, dst)
        if not ok then
            err(ctx, "cp: " .. (e or "error"))
        end
    end

    cmds.mv = function(args, ctx)
        if #args < 2 then
            err(ctx, "mv: missing operand")
            return
        end
        local src = V.resolve(ctx.cwd, args[1])
        local dst = V.resolve(ctx.cwd, args[2])
        local data, e = V.read(src)
        if not data then
            err(ctx, "mv: " .. (e or "error"))
            return
        end
        V.write(dst, data, "w")
        V.remove(src)
    end

    cmds.head = function(args, ctx)
        local n = 10
        local file
        local i = 1
        while i <= #args do
            if args[i] == "-n" and args[i + 1] then
                n = tonumber(args[i + 1]) or 10
                i = i + 2
            elseif args[i]:match("^%-n%d") then
                n = tonumber(args[i]:sub(3)) or 10
                i = i + 1
            else
                file = args[i]
                i = i + 1
            end
        end
        local data
        if file then
            data = V.read(V.resolve(ctx.cwd, file))
            if not data then
                err(ctx, "head: cannot open '" .. file .. "'")
                return
            end
        else
            data = ctx.stdin or ""
        end
        local c = 0
        for line in (data .. "\n"):gmatch("(.-)\n") do
            c = c + 1
            if c > n then
                break
            end
            print(line)
        end
    end

    cmds.tail = function(args, ctx)
        local n = 10
        local file
        local i = 1
        while i <= #args do
            if args[i] == "-n" and args[i + 1] then
                n = tonumber(args[i + 1]) or 10
                i = i + 2
            else
                file = args[i]
                i = i + 1
            end
        end
        local data
        if file then
            data = V.read(V.resolve(ctx.cwd, file))
            if not data then
                err(ctx, "tail: cannot open '" .. file .. "'")
                return
            end
        else
            data = ctx.stdin or ""
        end
        local lines = {}
        for line in (data .. "\n"):gmatch("(.-)\n") do
            lines[#lines + 1] = line
        end
        local from = math.max(1, #lines - n + 1)
        for j = from, #lines do
            print(lines[j])
        end
    end

    cmds.wc = function(args, ctx)
        local data, name
        if args[1] then
            name = args[1]
            data = V.read(V.resolve(ctx.cwd, args[1]))
            if not data then
                err(ctx, "wc: " .. args[1] .. ": No such file")
                return
            end
        else
            data = ctx.stdin or ""
            name = ""
        end
        local lines, words = 0, 0
        for line in (data .. "\n"):gmatch("(.-)\n") do
            lines = lines + 1
            for _ in line:gmatch("%S+") do
                words = words + 1
            end
        end
        if data:sub(-1) == "\n" or data == "" then
            -- keep
        end
        print(string.format("%7d %7d %7d %s", lines, words, #data, name))
    end

    cmds.grep = function(args, ctx)
        if #args == 0 then
            err(ctx, "grep: missing pattern")
            return
        end
        local flags, rest = parse_flags(args)
        local pat = rest[1]
        if not pat then
            err(ctx, "grep: missing pattern")
            return
        end
        local data
        if rest[2] then
            data = V.read(V.resolve(ctx.cwd, rest[2]))
            if not data then
                err(ctx, "grep: " .. rest[2] .. ": No such file")
                return
            end
        else
            data = ctx.stdin or ""
        end
        if flags.i then
            pat = pat:lower()
        end
        local ok_pat, _ = pcall(string.find, "", pat)
        for line in (data .. "\n"):gmatch("(.-)\n") do
            local hay = flags.i and line:lower() or line
            local found = false
            if ok_pat then
                found = hay:find(pat) ~= nil
            else
                found = hay:find(pat, 1, true) ~= nil
            end
            if found then
                print(line)
            end
        end
    end

    cmds.tree = function(args, ctx)
        local start = V.resolve(ctx.cwd, args[1] or ".")
        local function rec(p, prefix)
            local list = V.list(p) or {}
            table.sort(list)
            for i = 1, #list do
                local last = i == #list
                local n = list[i]
                print(prefix .. (last and "`-- " or "|-- ") .. n)
                local ch = V.norm(p .. "/" .. n)
                if V.isDir(ch) then
                    rec(ch, prefix .. (last and "    " or "|   "))
                end
            end
        end
        print(start)
        rec(start, "")
    end

    cmds.uname = function(args)
        local flags, _ = parse_flags(args)
        if flags.a or args[1] == "-a" then
            print(string.format("Linux %s %s %s lua-cc %s GNU/Linux",
                K.hostname, K.release, K.version, K.machine))
        elseif flags.r then
            print(K.release)
        elseif flags.n then
            print(K.hostname)
        elseif flags.s or #args == 0 then
            print("Linux")
        elseif flags.m then
            print(K.machine)
        elseif flags.v then
            print(K.version)
        else
            print("Linux")
        end
    end

    cmds.hostname = function(args, ctx)
        if args[1] then
            K.hostname = args[1]:sub(1, 32)
            V.write("/etc/hostname", K.hostname .. "\n", "w")
        else
            print(K.hostname)
        end
    end

    cmds.whoami = function()
        print("root")
    end
    cmds.id = function()
        print("uid=0(root) gid=0(root) groups=0(root)")
    end

    cmds.date = function()
        if os.date then
            print(os.date("%a %b %d %H:%M:%S UTC %Y"))
        else
            print(tostring(os.time()))
        end
    end

    cmds.uptime = function()
        local u = K.uptime()
        local m = math.floor(u / 60)
        local s = math.floor(u % 60)
        local load = string.format("%.2f, %.2f, %.2f", 0.00, 0.00, 0.00)
        print(string.format("up %d min, %d users, load average: %s", m, 1, load))
        if s >= 0 then
            -- keep
        end
    end

    cmds.dmesg = function(args)
        local flags, _ = parse_flags(args)
        for i = 1, #K.dmesg do
            print(K.dmesg[i])
        end
    end
    cmds.journalctl = function(args, ctx)
        cmds.dmesg(args, ctx)
    end

    cmds.free = function(args)
        local flags, _ = parse_flags(args)
        local total = K.mem_kb
        local used = math.floor(total * 0.18)
        local free = total - used
        if flags.h then
            local function h(n)
                if n >= 1024 then
                    return string.format("%.0fM", n / 1024)
                end
                return tostring(n) .. "K"
            end
            print("               total        used        free      shared  buff/cache   available")
            print(string.format("Mem:     %10s %11s %11s          0         %s        %s",
                h(total), h(used), h(free), h(math.floor(total * 0.07)), h(free)))
            print("Swap:             0B          0B          0B")
        else
            print("               total        used        free      shared  buff/cache   available")
            print(string.format("Mem:     %10d %11d %11d          0 %11d %11d",
                total, used, free, math.floor(total * 0.07), free))
            print("Swap:            0          0          0")
        end
    end

    cmds.df = function(args)
        local flags, _ = parse_flags(args)
        local free = fs.getFreeSpace and fs.getFreeSpace("/") or 0
        local used = 0
        if fs.getCapacity then
            local cap = fs.getCapacity("/")
            if cap then
                used = cap - free
            end
        end
        if used < 0 then
            used = 0
        end
        local total = used + free
        local pct = total > 0 and math.floor(used * 100 / total) or 0
        local function h(n)
            if flags.h then
                if n > 1024 * 1024 then
                    return string.format("%.1fM", n / 1024 / 1024)
                end
                if n > 1024 then
                    return string.format("%.1fK", n / 1024)
                end
            end
            return tostring(n)
        end
        print("Filesystem     1K-blocks    Used Available Use% Mounted on")
        print(string.format("/dev/hda1      %10s %7s %9s %3d%% /", h(total), h(used), h(free), pct))
        print("tmpfs                  0       0         0   0% /tmp")
        print("craftos                -       -         -   -  /mnt/craftos")
    end

    cmds.mount = function()
        print("/dev/hda1 on / type ext2 (rw,relatime)")
        print("proc on /proc type proc (rw,nosuid,nodev,noexec)")
        print("sysfs on /sys type sysfs (rw)")
        print("devtmpfs on /dev type devtmpfs (rw)")
        print("craftos on /mnt/craftos type ext2 (rw)")
    end

    cmds.lsmod = function()
        print("Module                  Size  Used by")
        for i = 1, #K.modules do
            local m = K.modules[i]
            print(string.format("%-16s %8d  %d %s", m.name, m.size, m.used, m.flags))
        end
    end

    cmds.insmod = function(args, ctx)
        if not args[1] then
            err(ctx, "insmod: missing module name")
            return
        end
        if args[1] == "panic" or args[1] == "oops" then
            K.panic("fatal error in module " .. args[1])
            return
        end
        K.printk("insmod: loading dummy module " .. args[1])
        K.modules[#K.modules + 1] = { name = args[1], size = 4096, used = 0, flags = "Live 0x00000000 (O)" }
        K.taint(1)
    end
    cmds.modprobe = cmds.insmod
    cmds.rmmod = function(args, ctx)
        print("rmmod: module in use")
        ctx.ok = false
    end

    cmds.ps = function(args)
        local flags, _ = parse_flags(args)
        print("  PID TTY          TIME CMD")
        for _, p in ipairs(K.ps_list()) do
            local time = string.format("00:00:%02d", math.floor((K.now() - p.start) % 60))
            print(string.format("%5d tty0     %s %s", p.pid, time, p.comm))
        end
    end

    cmds.kill = function(args, ctx)
        if #args == 0 then
            err(ctx, "kill: usage: kill [-s sig] pid")
            return
        end
        local sig, i = 15, 1
        if args[1]:sub(1, 1) == "-" then
            local s = args[1]:sub(2)
            if s == "9" or s == "KILL" then
                sig = 9
            elseif s == "15" or s == "TERM" then
                sig = 15
            elseif tonumber(s) then
                sig = tonumber(s)
            end
            i = 2
        end
        if not args[i] then
            err(ctx, "kill: missing pid")
            return
        end
        local ok, e = K.kill(args[i], sig)
        if not ok then
            err(ctx, "kill: (" .. tostring(args[i]) .. ") " .. (e or "error"))
        end
    end

    cmds.pidof = function(args, ctx)
        if not args[1] then
            ctx.ok = false
            return
        end
        local found = {}
        for _, p in ipairs(K.ps_list()) do
            if p.comm == args[1] then
                found[#found + 1] = tostring(p.pid)
            end
        end
        if #found == 0 then
            ctx.ok = false
            return
        end
        print(table.concat(found, " "))
    end

    cmds.sleep = function(args)
        sleep(tonumber(args[1]) or 1)
    end

    cmds.sync = function()
        K.printk("sys_sync()")
    end

    cmds.env = function(args, ctx)
        local keys = {}
        for k in pairs(ctx.env) do
            keys[#keys + 1] = k
        end
        table.sort(keys)
        for i = 1, #keys do
            print(keys[i] .. "=" .. tostring(ctx.env[keys[i]]))
        end
    end
    cmds.export = function(args, ctx)
        if not args[1] then
            cmds.env(args, ctx)
            return
        end
        local k, v = args[1]:match("^([A-Za-z_][A-Za-z0-9_]*)=(.*)$")
        if k then
            ctx.env[k] = v
        elseif args[2] then
            ctx.env[args[1]] = args[2]
        end
    end
    cmds.set = cmds.env

    cmds.which = function(args, ctx)
        if not args[1] then
            ctx.ok = false
            return
        end
        if cmds[args[1]] then
            print("/usr/bin/" .. args[1])
        else
            ctx.ok = false
            print(args[1] .. " not found")
        end
    end
    cmds.type = cmds.which

    cmds.lscpu = function()
        print("Architecture:            cc-" .. K.machine)
        print("CPU op-mode(s):          lua32")
        print("Byte Order:              Little Endian")
        print("CPU(s):                  1")
        print("Model name:              " .. K.host())
        print("BIOS:                    " .. K.bios())
        print("Flags:                   fpu lua cc tty")
    end

    cmds.lsblk = function()
        print("NAME   MAJ:MIN RM  SIZE RO TYPE MOUNTPOINTS")
        print("hda      3:0    0    -  0 disk")
        print("└─hda1   3:1    0    -  0 part /")
    end

    cmds.neofetch = function(args, ctx)
        local penguin = {
            "      .--.      ",
            "     |o_o |     ",
            "     |:_/ |     ",
            "    //   \\ \\    ",
            "   (|     | )   ",
            "  /'\\_   _/`\\   ",
            "  \\___)=(___/   ",
        }
        local info = {
            K.hostname .. "@" .. K.hostname,
            "--------------",
            "OS: ccLinux 6.12 GNU/Linux",
            "Host: " .. K.host(),
            "Kernel: " .. K.release,
            "Uptime: " .. math.floor(K.uptime()) .. " s",
            "Shell: bash 5.2.0-cc",
            "Terminal: tty0",
            "CPU: " .. K.machine,
            "Memory: " .. math.floor(K.mem_kb * 0.18) .. "KiB / " .. K.mem_kb .. "KiB",
        }
        local n = math.max(#penguin, #info)
        local color = term.isColor and term.isColor()
        for i = 1, n do
            if color then
                term.setTextColor(colors.cyan)
            end
            write((penguin[i] or string.rep(" ", 16)))
            if color then
                term.setTextColor(colors.white)
            end
            print("  " .. (info[i] or ""))
        end
        if color then
            term.setTextColor(colors.lightGray)
        end
    end
    cmds.fastfetch = cmds.neofetch
    cmds.screenfetch = cmds.neofetch

    cmds.panic = function(args)
        local reason = join(args)
        if reason == "" then
            reason = "Fatal exception"
        end
        K.panic(reason)
    end
    cmds.oops = function(args)
        K.oops(join(args) ~= "" and join(args) or nil)
        print("Oops logged. System continues. See dmesg.")
    end
    cmds.sysrq = function(args, ctx)
        if not args[1] then
            write(K.sysrq_help())
            return
        end
        K.sysrq(args[1])
    end
    cmds.sysctl = function(args, ctx)
        if args[1] == "-a" then
            print("kernel.hostname = " .. K.hostname)
            print("kernel.ostype = Linux")
            print("kernel.osrelease = " .. K.release)
            print("kernel.panic = " .. tostring(K.panic_timeout))
            print("kernel.sysrq = " .. (K.sysrq and "1" or "0"))
            return
        end
        if args[1] and args[1]:find("=") then
            local k, v = args[1]:match("^([^=]+)=(.*)$")
            if k == "kernel.panic" or k == "kernel.panic " then
                K.panic_timeout = tonumber(v) or K.panic_timeout
            elseif k == "kernel.hostname" then
                K.hostname = v
            end
            return
        end
        print("usage: sysctl -a | sysctl kernel.panic=N")
    end

    local function power(kind)
        print("Broadcast message from root@" .. K.hostname .. " (tty0):")
        print("")
        if kind == "halt" or kind == "poweroff" then
            print("The system is going down for power off NOW!")
            K.printk("systemd-shutdown: powering off")
            sleep(1)
            os.shutdown()
        else
            print("The system is going down for reboot NOW!")
            K.printk("systemd-shutdown: rebooting")
            sleep(1)
            os.reboot()
        end
    end

    cmds.shutdown = function(args)
        local a = args[1]
        if a == "-h" or a == "-P" or a == "--poweroff" or a == "now" or a == "-n" or not a then
            if a == "-r" then
                power("reboot")
            else
                power("poweroff")
            end
        elseif a == "-r" then
            power("reboot")
        else
            power("poweroff")
        end
    end
    cmds.reboot = function()
        power("reboot")
    end
    cmds.halt = function()
        power("halt")
    end
    cmds.poweroff = function()
        power("poweroff")
    end

    cmds.systemctl = function(args, ctx)
        local sub = args[1] or "status"
        if sub == "poweroff" or sub == "halt" then
            power("poweroff")
        elseif sub == "reboot" then
            power("reboot")
        elseif sub == "status" then
            print("* ccLinux 6.12.0-cclinux running")
            print("    State: running")
            print("     Jobs: 0 queued")
            print("   Failed: 0 units")
        elseif sub == "kexec" then
            K.panic("kexec: no crash kernel loaded")
        else
            print("Unknown command '" .. sub .. "'")
            ctx.ok = false
        end
    end

    cmds.less = function(args, ctx)
        cmds.cat(args, ctx)
    end
    cmds.more = cmds.less

    cmds.edit = function(args, ctx)
        if not args[1] then
            err(ctx, "edit: missing file")
            return
        end
        local p = V.resolve(ctx.cwd, args[1])
        local kind = p:sub(1, 5)
        if p:sub(1, 5) == "/proc" or p:sub(1, 4) == "/sys" or p:sub(1, 4) == "/dev" then
            err(ctx, "edit: cannot edit virtual file")
            return
        end
        local real
        if p:sub(1, 12) == "/mnt/craftos" then
            real = p == "/mnt/craftos" and "/" or p:sub(13)
        else
            real = V.real(p)
        end
        if shell and shell.run then
            shell.run("/rom/programs/edit.lua", real)
        else
            os.run({}, "/rom/programs/edit.lua", real)
        end
        -- restore tty colors after CraftOS editor
        if term.isColor and term.isColor() then
            term.setBackgroundColor(colors.black)
            term.setTextColor(colors.lightGray)
        else
            term.setBackgroundColor(colors.black)
            term.setTextColor(colors.white)
        end
    end
    cmds.nano = cmds.edit
    cmds.vi = cmds.edit
    cmds.vim = function()
        print("vim: command not found (try: edit)")
    end
    cmds.emacs = function()
        print("emacs: not now, this is a tty")
    end

    cmds.ping = function(args, ctx)
        local host = args[1] or "127.0.0.1"
        print("PING " .. host .. " (" .. host .. "): 56 data bytes")
        for i = 1, 4 do
            local ms = 4 + math.random(1, 20) + (host ~= "127.0.0.1" and 10 or 0)
            print(string.format("64 bytes from %s: icmp_seq=%d ttl=64 time=%d.%d ms", host, i, ms, math.random(0, 9)))
            sleep(0.4)
        end
        print("--- " .. host .. " ping statistics ---")
        print("4 packets transmitted, 4 received, 0% packet loss")
    end

    cmds.ip = function(args)
        local id = K.id()
        if args[1] == "a" or args[1] == "addr" or args[1] == "address" or not args[1] then
            print("1: lo: <LOOPBACK,UP> mtu 65536")
            print("    inet 127.0.0.1/8 scope host lo")
            print("2: cc0: <BROADCAST,UP> mtu 1500")
            print("    inet 10.0." .. (id % 256) .. "." .. ((id * 7) % 256) .. "/16 scope global cc0")
            print("    computer-id " .. tostring(id))
        else
            print("Usage: ip [ addr ]")
        end
    end
    cmds.ifconfig = cmds.ip

    cmds.lua = function(args, ctx)
        print("Lua interpreter disabled in kernel mode. Use CraftOS from GRUB.")
        ctx.ok = false
    end

    cmds.su = function()
        print("You are already root")
    end
    cmds.sudo = function(args, ctx)
        if #args == 0 then
            print("usage: sudo <cmd>")
            return
        end
        local name = args[1]
        table.remove(args, 1)
        if cmds[name] then
            cmds[name](args, ctx)
        else
            err(ctx, "sudo: " .. name .. ": command not found")
        end
    end

    cmds.login = function()
        print("Already logged in on tty0 as root")
    end

    cmds.history = function(args, ctx)
        for i = 1, #(ctx.history or {}) do
            print(string.format("%5d  %s", i, ctx.history[i]))
        end
    end

    cmds.exit = function(args, ctx)
        ctx.exit = true
    end
    cmds.logout = cmds.exit
    cmds.logout_ = cmds.exit

    cmds.yes = function(args)
        local s = args[1] or "y"
        for i = 1, 16 do
            print(s)
        end
        print("yes: broken pipe")
    end

    cmds.apt = function()
        print("E: Package manager not configured (busybox build)")
    end
    cmds.apt_get = cmds.apt
    cmds["apt-get"] = cmds.apt
    cmds.pacman = cmds.apt
    cmds.yum = cmds.apt
    cmds.dnf = cmds.apt
    cmds.apk = cmds.apt

    cmds.uname_ = cmds.uname
end

return C
