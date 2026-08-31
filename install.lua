-- ccLinux installer / setup for CC: Tweaked
-- Paste this file onto a computer and run:
--   install
--
-- Options:
--   install            interactive setup
--   install auto       install + reboot
--   install noreboot   install, stay in CraftOS
--   install uninstall  remove ccLinux

local args = { ... }
local mode = "menu"
for i = 1, #args do
    local a = string.lower(tostring(args[i]))
    if a == "auto" or a == "--auto" or a == "-y" then
        mode = "auto"
    elseif a == "noreboot" or a == "--noreboot" or a == "-n" then
        mode = "noreboot"
    elseif a == "uninstall" or a == "--uninstall" or a == "remove" then
        mode = "uninstall"
    end
end

local function color(c)
    if term.isColor and term.isColor() then
        term.setTextColor(c)
    end
end

local function banner()
    term.setBackgroundColor(colors.black)
    term.setTextColor(term.isColor() and colors.white or colors.white)
    term.clear()
    term.setCursorPos(1, 1)
    color(colors.cyan)
    print("========================================")
    print("  ccLinux setup")
    print("  GNU/Linux TTY for CC: Tweaked")
    print("========================================")
    color(colors.lightGray)
    print("")
end

local function ensureDir(path)
    if not path or path == "" or path == "/" then
        return
    end
    if fs.exists(path) then
        return
    end
    ensureDir(fs.getDir(path))
    fs.makeDir(path)
end

local function writeFile(path, data)
    ensureDir(fs.getDir(path))
    local h = fs.open(path, "w")
    if not h then
        error("cannot write " .. path)
    end
    h.write(data)
    h.close()
end

local function bar(done, total)
    local w = 24
    local n = math.floor(done * w / total)
    if n > w then n = w end
    write("[" .. string.rep("#", n) .. string.rep("-", w - n) .. "] " .. done .. "/" .. total)
end

local function uninstall()
    banner()
    color(colors.yellow)
    print("Removing ccLinux...")
    color(colors.lightGray)
    if fs.exists("/linux") then
        fs.delete("/linux")
        print("  deleted /linux")
    end
    if fs.exists("/startup.lua") then
        local h = fs.open("/startup.lua", "r")
        local t = h and h.readAll() or ""
        if h then h.close() end
        if t and t:find("ccLinux") then
            fs.delete("/startup.lua")
            print("  deleted /startup.lua")
        else
            print("  kept /startup.lua (not ccLinux)")
        end
    end
    print("")
    print("Uninstalled. CraftOS will start as usual.")
end

local files = {
    { "/startup.lua", [===[
-- ccLinux entry. Place this file as /startup.lua on a CC: Tweaked computer.
-- TTY only — no graphical interface.

if not fs.exists("/linux/boot.lua") then
    print("ccLinux is not installed (missing /linux/boot.lua)")
    print("Copy the linux/ folder onto this computer.")
    return
end

local ok, err = pcall(dofile, "/linux/boot.lua")
if not ok then
    print("")
    printError("ccLinux crashed: " .. tostring(err))
    print("Dropped back to CraftOS.")
end
]===] },
    { "/linux/boot.lua", [===[
-- ccLinux bootloader + kernel init. TTY only, no GUI.

local LINUX = "/linux"

local function loadmod(name)
    local path = LINUX .. "/" .. name .. ".lua"
    if not fs.exists(path) then
        error("missing kernel module " .. path)
    end
    return dofile(path)
end

local K = loadmod("kernel")
local V = loadmod("vfs")
local P = loadmod("panic")
local C = loadmod("commands")
local S = loadmod("shell")
local Extra = loadmod("extra")
local Pac = loadmod("pacman")
local Dos = loadmod("dos")

K.panic_fn = function(kernel, reason)
    P.render(kernel, reason)
end

V.init(K)

local function write_if_missing(path, data)
    if not V.exists(path) then
        V.write(path, data, "w")
    end
end

write_if_missing("/etc/os-release", table.concat({
    "PRETTY_NAME=\"ccLinux 6.12 (CC: Tweaked)\"",
    "NAME=\"ccLinux\"",
    "VERSION=\"6.12\"",
    "ID=cclinux",
    "VERSION_ID=\"6.12\"",
    "HOME_URL=\"https://tweaked.cc\"",
    "ANSI_COLOR=\"1;34\"",
    "",
}, "\n"))
write_if_missing("/etc/hostname", K.hostname .. "\n")
write_if_missing("/etc/issue", "ccLinux 6.12.0-cclinux \\n \\l\n\n")
write_if_missing("/etc/passwd", "root:x:0:0:root:/root:/bin/bash\ncc:x:1000:1000:CC user:/home/cc:/bin/bash\n")
write_if_missing("/etc/motd", table.concat({
    "",
    "Welcome to ccLinux 6.12 (GNU/Linux " .. K.release .. ")",
    "",
    " * Documentation:  help",
    " * Kernel panic:   panic   or   echo c > /proc/sysrq-trigger",
    " * Poweroff:       poweroff    Reboot: reboot",
    " * CraftOS files:  /mnt/craftos",
    "",
}, "\n"))
write_if_missing("/root/README", table.concat({
    "ccLinux tty — no X11, no GUI.",
    "Type `help` for builtins.",
    "Type `neofetch` for system info.",
    "Type `pacman -Syu` then `pacman -S htop`.",
    "Type `panic` for a kernel panic (shuts down this computer).",
    "Operators:  cmd1 ; cmd2 ; cmd3    cmd1 && cmd2    cmd1 || cmd2",
    "",
}, "\n"))
write_if_missing("/boot/vmlinuz-linux", "MZ\0\nELF Linux kernel ccLinux 6.12.0-cclinux bzImage\n")
write_if_missing("/boot/vmlinuz-linux-lts", "MZ\0\nELF Linux kernel ccLinux 6.6.63-lts bzImage\n")
write_if_missing("/boot/initramfs-linux.img", "initramfs-linux.img (gzip compressed, stub)\n")
write_if_missing("/boot/initramfs-linux-fallback.img", "initramfs fallback stub\n")
write_if_missing("/boot/grub/grub.cfg", table.concat({
    "set timeout=5",
    "set default=0",
    "menuentry 'ccLinux 6.12.0-cclinux' { linux /boot/vmlinuz-linux }",
    "menuentry 'Arch Linux' { linux /boot/vmlinuz-linux }",
    "menuentry 'Debian GNU/Linux 12' { linux /boot/vmlinuz-linux }",
    "menuentry 'ccLinux recovery' { linux /boot/vmlinuz-linux single }",
    "menuentry 'FreeDOS 1.3' { chainloader /boot/freedos }",
    "menuentry 'Memtest86+' { linux /boot/memtest }",
    "menuentry 'CraftOS' { chainloader /rom/programs/shell.lua }",
    "",
}, "\n"))
write_if_missing("/etc/pacman.conf", table.concat({
    "[options]",
    "HoldPkg     = pacman glibc",
    "Architecture = cc",
    "CheckSpace",
    "SigLevel    = Required DatabaseOptional",
    "LocalFileSigLevel = Optional",
    "",
    "[core]",
    "Include = /etc/pacman.d/mirrorlist",
    "",
    "[extra]",
    "Include = /etc/pacman.d/mirrorlist",
    "",
}, "\n"))
write_if_missing("/etc/pacman.d/mirrorlist", table.concat({
    "## ccLinux / Arch cc repo",
    "## GitHub: https://github.com/vanyachickenganidanya-lgtm/pacmanlinuxcraftos",
    "Server = https://raw.githubusercontent.com/vanyachickenganidanya-lgtm/pacmanlinuxcraftos/main/$repo/os/$arch",
    "Server = https://raw.githubusercontent.com/vanyachickenganidanya-lgtm/pacmanlinuxcraftos/main/packages.lua",
    "",
}, "\n"))
write_if_missing("/etc/arch-release", "Arch Linux\n")
write_if_missing("/etc/debian_version", "12.8\n")
write_if_missing("/usr/lib/os-release", V.read("/etc/os-release") or "NAME=ccLinux\n")

local function setup_tty()
    if term.isColor and term.isColor() then
        pcall(function()
            if term.setPaletteColor then
                term.setPaletteColor(colors.black, 0x000000)
                term.setPaletteColor(colors.white, 0xEEEEEE)
                term.setPaletteColor(colors.lightGray, 0xBBBBBB)
                term.setPaletteColor(colors.gray, 0x555555)
                term.setPaletteColor(colors.blue, 0x5C5CFF)
                term.setPaletteColor(colors.green, 0x44CC44)
                term.setPaletteColor(colors.cyan, 0x33CCCC)
            end
        end)
        term.setBackgroundColor(colors.black)
        term.setTextColor(colors.lightGray)
    else
        term.setBackgroundColor(colors.black)
        term.setTextColor(colors.white)
    end
    term.setCursorBlink(true)
end

local function grub()
    setup_tty()
    term.clear()
    local entries = {
        { "ccLinux 6.12.0-cclinux", "linux" },
        { "Arch Linux", "arch" },
        { "Debian GNU/Linux 12 (bookworm)", "debian" },
        { "ccLinux 6.12.0-cclinux (recovery)", "recovery" },
        { "FreeDOS 1.3", "dos" },
        { "Memtest86+", "memtest" },
        { "CraftOS (ComputerCraft)", "craftos" },
    }
    local sel = 1
    local timeout = 4
    local last = os.clock()
    local armed = true

    local function draw()
        term.setBackgroundColor(colors.black)
        term.setTextColor(colors.white)
        term.clear()
        term.setCursorPos(1, 1)
        print("GNU GRUB  version 2.12")
        print("")
        local w, h = term.getSize()
        for i = 1, #entries do
            term.setCursorPos(2, 3 + i)
            if i == sel then
                if term.isColor and term.isColor() then
                    term.setBackgroundColor(colors.white)
                    term.setTextColor(colors.black)
                else
                    term.setBackgroundColor(colors.white)
                    term.setTextColor(colors.black)
                end
            else
                term.setBackgroundColor(colors.black)
                term.setTextColor(colors.white)
            end
            local label = "  " .. entries[i][1]
            label = label .. string.rep(" ", math.max(0, w - 4 - #label))
            write(label)
        end
        term.setBackgroundColor(colors.black)
        term.setTextColor(colors.white)
        term.setCursorPos(1, 9)
        print("")
        if armed then
            print("The highlighted entry will be executed")
            print("automatically in " .. tostring(timeout) .. "s.")
        else
            print("Use arrow keys and Enter.")
        end
        print("")
        print("Ctrl+T aborts to CraftOS.")
    end

    draw()
    os.startTimer(0.25)
    while true do
        local ev = { os.pullEventRaw() }
        if ev[1] == "terminate" then
            return "craftos"
        elseif ev[1] == "timer" then
            os.startTimer(0.25)
            if armed and os.clock() - last >= 1 then
                last = os.clock()
                timeout = timeout - 1
                if timeout <= 0 then
                    return entries[sel][2]
                end
                draw()
            end
        elseif ev[1] == "key" then
            armed = false
            local key = ev[2]
            if key == keys.up then
                sel = sel - 1
                if sel < 1 then
                    sel = #entries
                end
                draw()
            elseif key == keys.down then
                sel = sel + 1
                if sel > #entries then
                    sel = 1
                end
                draw()
            elseif key == keys.enter then
                return entries[sel][2]
            end
        end
    end
end

local function kernel_boot(recovery)
    setup_tty()
    term.clear()
    term.setCursorPos(1, 1)
    K.start = os.clock()
    K.console = true
    K.dmesg = {}
    K.seed_procs()

    local log = {
        K.banner_line(),
        "Command line: " .. K.cmdline,
        "BIOS-provided physical RAM map:",
        "BIOS-e820: [mem 0x0000000000000000-0x" .. string.format("%08x", K.mem_kb * 1024 - 1) .. "] usable",
        "NX (Execute Disable) protection: active",
        "DMI: Mojang AB " .. K.host() .. "/CC: Tweaked " .. K.machine .. ", BIOS " .. K.bios(),
        "tsc: Fast TSC calibration using PIT",
        "cpu0: CraftOS lua core, smp bootstrap",
        "Memory: " .. tostring(K.mem_kb) .. "K/" .. tostring(K.mem_kb) .. "K available",
        "Kernel command line: " .. K.cmdline,
        "PID hash table entries: 16 (order: 0, 64 bytes)",
        "console [tty0] enabled",
        "Calibrating delay loop... 40.00 BogoMIPS",
        "HugeTLB: registered 1 TLB page size",
        "vfs: Disk quotas dquot_6.6.0",
        "Initialise system trusted keyrings",
        "workingset: timestamp_bits=36 max_order=19",
        "ext2: Mounting /dev/hda1",
        "VFS: Mounted root (ext2 filesystem) on device 3:1.",
        "devtmpfs: mounted",
        "proc: procfs mounted on /proc",
        "sysfs: mounted on /sys",
        "Freeing unused kernel memory: 832K",
        "Run /sbin/init as init process",
        "systemd[1]: systemd running in system mode",
        "systemd[1]: Detected architecture cc-" .. K.machine,
        "systemd[1]: Hostname set to <" .. K.hostname .. ">.",
        "systemd[1]: Started Journal Service.",
        "systemd[1]: Reached target Basic System.",
        "systemd[1]: Started Getty on tty0.",
        "systemd[1]: Reached target Login Prompts.",
        "systemd[1]: Reached target Multi-User System.",
    }
    if recovery then
        log[#log + 1] = "systemd[1]: Booting into recovery (single-user) mode"
        K.panic_timeout = 0
    end
    for i = 1, #log do
        K.printk(log[i])
        if i % 3 == 0 then
            sleep(0)
        end
    end
    K.console = false
    sleep(0.4)
end

local function apply_distro(mode)
    K.distro = mode
    if mode == "arch" then
        V.write("/etc/os-release", table.concat({
            "NAME=\"Arch Linux\"",
            "PRETTY_NAME=\"Arch Linux\"",
            "ID=arch",
            "BUILD_ID=rolling",
            "ANSI_COLOR=\"38;2;23;147;209\"",
            "HOME_URL=\"https://archlinux.org/\"",
            "DOCUMENTATION_URL=\"https://wiki.archlinux.org/\"",
            "",
        }, "\n"), "w")
        V.write("/etc/issue", "Arch Linux \\r (\\l)\n\n", "w")
        V.write("/etc/motd", "\nWelcome to Arch Linux (ccLinux kernel " .. K.release .. ")\n\n * pacman -Syu\n * pacman -S htop cowsay git\n * wiki: help\n\n", "w")
    elseif mode == "debian" then
        V.write("/etc/os-release", table.concat({
            "PRETTY_NAME=\"Debian GNU/Linux 12 (bookworm)\"",
            "NAME=\"Debian GNU/Linux\"",
            "VERSION_ID=\"12\"",
            "VERSION=\"12 (bookworm)\"",
            "ID=debian",
            "HOME_URL=\"https://www.debian.org/\"",
            "",
        }, "\n"), "w")
        V.write("/etc/issue", "Debian GNU/Linux 12 \\n \\l\n\n", "w")
        V.write("/etc/motd", "\nDebian GNU/Linux 12 (ccLinux kernel)\n\n * apt update && apt install htop\n * or: pacman -S htop\n\n", "w")
    else
        V.write("/etc/os-release", table.concat({
            "PRETTY_NAME=\"ccLinux 6.12 (CC: Tweaked)\"",
            "NAME=\"ccLinux\"",
            "VERSION=\"6.12\"",
            "ID=cclinux",
            "VERSION_ID=\"6.12\"",
            "HOME_URL=\"https://tweaked.cc\"",
            "",
        }, "\n"), "w")
        V.write("/etc/issue", "ccLinux 6.12.0-cclinux \\n \\l\n\n", "w")
        V.write("/etc/motd", "\nWelcome to ccLinux 6.12\n\n * pacman -Syu    * help    * panic\n * CraftOS disk: /mnt/craftos\n\n", "w")
    end
end

local function pretty_os()
    if K.distro == "arch" then
        return "Arch Linux"
    elseif K.distro == "debian" then
        return "Debian GNU/Linux 12"
    end
    return "ccLinux " .. K.release
end

local function getty()
    setup_tty()
    term.clear()
    term.setCursorPos(1, 1)
    local issue = V.read("/etc/issue") or ""
    issue = issue:gsub("\\n", K.hostname):gsub("\\l", "tty0"):gsub("\\r", pretty_os())
    write(issue)
    print(pretty_os() .. " " .. K.hostname .. " tty0")
    print("")
    print(K.hostname .. " login: root     (autologin)")
    sleep(0.3)
    print("Password:")
    sleep(0.2)
    print("")
    print("Last login: on tty0")
    local motd = V.read("/etc/motd")
    if motd then
        write(motd)
        if motd:sub(-1) ~= "\n" then
            print("")
        end
    end
end

local function memtest()
    setup_tty()
    term.clear()
    term.setCursorPos(1, 1)
    print("Memtest86+ v7.20")
    print("CPU: CraftOS lua / " .. K.host())
    print("Pass: 1/1   Test: 1/8   Testing: 0 - " .. tostring(K.mem_kb) .. "K")
    print("")
    for i = 0, 10 do
        write("[" .. string.rep("#", i) .. string.rep(".", 10 - i) .. "]  " .. tostring(i * 10) .. "%\r")
        sleep(0.15)
    end
    print("")
    print("")
    print("**** Pass complete, no errors ****")
    print("RAM: OK    ECC: n/a")
    print("")
    print("Press any key to return to GRUB...")
    os.pullEvent("key")
end

local function linux_session(mode)
    apply_distro(mode == "recovery" and "linux" or mode)
    kernel_boot(mode == "recovery")
    getty()
    Pac.init(V)
    local cmds = {}
    C.register(cmds, K, V)
    Extra.register(cmds, K, V, Pac)
    Pac.register(cmds, K, V)
    local ctx = {
        cwd = "/root",
        ok = true,
        exit = false,
        aliases = { ll = "ls -l", la = "ls -la" },
        env = {
            HOME = "/root",
            USER = "root",
            LOGNAME = "root",
            SHELL = "/bin/bash",
            PATH = "/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin",
            PWD = "/root",
            HOSTNAME = K.hostname,
            TERM = "linux",
            LANG = "C",
            SHLVL = "1",
        },
        history = {},
        stdin = nil,
    }
    S.loop(cmds, K, V, ctx)
end

local function main()
    while true do
        local mode = grub()
        if mode == "craftos" then
            term.setBackgroundColor(colors.black)
            term.setTextColor(colors.white)
            term.clear()
            term.setCursorPos(1, 1)
            print("Returned to CraftOS.")
            return
        elseif mode == "memtest" then
            memtest()
        elseif mode == "dos" then
            Dos.run()
        else
            linux_session(mode)
        end
    end
end

local ok, err = pcall(main)
if not ok then
    term.setBackgroundColor(colors.black)
    term.setTextColor(colors.white)
    print("")
    print("Kernel bug in boot: " .. tostring(err))
    print("Dropping to CraftOS. Ctrl+T if hung.")
end
]===] },
    { "/linux/kernel.lua", [===[
-- ccLinux kernel. Loaded via dofile, returns the kernel table.

local K = {}

K.release = "6.12.0-cclinux"
K.version = "#1 SMP PREEMPT " .. (os.date and os.date("%a %b %d %H:%M:%S UTC %Y") or "CC: Tweaked")
K.name = "Linux"
K.ostype = "Linux"
K.banner = nil
K.dmesg = {}
K.dmesg_max = 256
K.console = false
K.tainted = 0
K.start = os.clock()
K.hostname = "cctweaked"
K.panic_timeout = 3
K.sysrq = true
K.modules = {
    { name = "computercraft", size = 221184, used = 3, flags = "Live 0x00000000 (O)" },
    { name = "minecraft",     size = 980144, used = 1, flags = "Live 0x00000000" },
    { name = "tty_cc",        size = 16384,  used = 1, flags = "Live 0x00000000" },
    { name = "procfs",        size = 12288,  used = 1, flags = "Live 0x00000000" },
    { name = "sysfs",         size = 10240,  used = 1, flags = "Live 0x00000000" },
    { name = "ext2",          size = 73728,  used = 1, flags = "Live 0x00000000" },
}
K.procs = {}
K.next_pid = 1
K.cmdline = "BOOT_IMAGE=/boot/vmlinuz-6.12.0-cclinux root=/dev/hda1 rw init=/sbin/init console=tty0"
K.panic_fn = nil

local function machine()
    if rawget(_G, "turtle") then return "turtle" end
    if rawget(_G, "pocket") then return "pocket" end
    if rawget(_G, "commands") then return "command" end
    if term.isColor and term.isColor() then return "advanced" end
    return "computer"
end

K.machine = machine()

local mem_map = {
    turtle = 131072,
    pocket = 262144,
    command = 1048576,
    advanced = 524288,
    computer = 262144,
}
K.mem_kb = mem_map[K.machine] or 262144

function K.now()
    return os.clock() - K.start
end

function K.uptime()
    return K.now()
end

function K.printk(msg)
    local line = string.format("[%12.6f] %s", K.now(), tostring(msg))
    K.dmesg[#K.dmesg + 1] = line
    if #K.dmesg > K.dmesg_max then
        table.remove(K.dmesg, 1)
    end
    if K.console then
        print(line)
    end
    return line
end

function K.taint(flag)
    K.tainted = bit32 and bit32.bor(K.tainted, flag or 1) or 1
end

function K.taint_str()
    if K.tainted == 0 then
        return "Not tainted"
    end
    return "Tainted: G        O"
end

function K.spawn(comm, ppid, kernel_thread)
    local pid = K.next_pid
    K.next_pid = K.next_pid + 1
    local p = {
        pid = pid,
        ppid = ppid or 1,
        comm = comm,
        state = kernel_thread and "S" or "R",
        kernel = kernel_thread and true or false,
        start = K.now(),
    }
    K.procs[pid] = p
    return p
end

function K.kill(pid, sig)
    sig = tonumber(sig) or 15
    pid = tonumber(pid)
    if not pid or not K.procs[pid] then
        return false, "No such process"
    end
    if pid == 1 and sig ~= 0 then
        K.panic("Attempted to kill init! exitcode=" .. tostring(sig))
        return true
    end
    local p = K.procs[pid]
    if p.kernel and pid ~= 1 then
        return false, "Operation not permitted"
    end
    K.procs[pid] = nil
    return true
end

function K.ps_list()
    local t = {}
    for _, p in pairs(K.procs) do
        t[#t + 1] = p
    end
    table.sort(t, function(a, b) return a.pid < b.pid end)
    return t
end

function K.host()
    return rawget(_G, "_HOST") or "ComputerCraft"
end

function K.bios()
    return (os.version and os.version()) or "CraftOS"
end

function K.id()
    return (os.getComputerID and os.getComputerID()) or 0
end

function K.label()
    return (os.getComputerLabel and os.getComputerLabel()) or nil
end

function K.init_hostname()
    local lbl = K.label()
    if lbl and lbl ~= "" then
        K.hostname = lbl:gsub("%s+", "-"):sub(1, 32)
    else
        K.hostname = "cc-" .. tostring(K.id())
    end
end

function K.cpuinfo()
    local m = K.machine
    return table.concat({
        "processor\t: 0",
        "vendor_id\t: CraftOS",
        "cpu family\t: 6",
        "model\t\t: 1",
        "model name\t: CC: Tweaked " .. m .. " (" .. K.host() .. ")",
        "stepping\t: 1",
        "microcode\t: 0x1",
        "cpu MHz\t\t: 20.000",
        "cache size\t: 256 KB",
        "physical id\t: 0",
        "siblings\t: 1",
        "core id\t\t: 0",
        "cpu cores\t: 1",
        "flags\t\t: fpu lua cc tweaked tty",
        "bugs\t\t:",
        "bogomips\t: 40.00",
        "",
    }, "\n")
end

function K.meminfo()
    local total = K.mem_kb
    local used = math.floor(total * 0.18) + #K.dmesg
    local free = total - used
    local buf = math.floor(total * 0.02)
    local cache = math.floor(total * 0.05)
    return table.concat({
        "MemTotal:        " .. total .. " kB",
        "MemFree:         " .. free .. " kB",
        "MemAvailable:    " .. (free + cache) .. " kB",
        "Buffers:         " .. buf .. " kB",
        "Cached:          " .. cache .. " kB",
        "SwapTotal:              0 kB",
        "SwapFree:               0 kB",
        "Dirty:                  0 kB",
        "AnonPages:        " .. math.floor(used * 0.4) .. " kB",
        "Mapped:           " .. math.floor(used * 0.1) .. " kB",
        "Slab:             " .. math.floor(used * 0.05) .. " kB",
        "",
    }, "\n")
end

function K.sysrq_help()
    return "SysRq : HELP : logtMermBAkS tes UN rt p wr i v0-9 q C a e f g h i j k l m n o p q r s t u v w x y z\n"
        .. "  b - reboot  c - crash/panic  h - help  o - poweroff  s - sync  t - tasks\n"
end

function K.sysrq(cmd)
    cmd = tostring(cmd or ""):gsub("%s+", ""):sub(1, 1)
    if cmd == "" then
        return true
    end
    if not K.sysrq then
        return false, "SysRq disabled"
    end
    K.printk("SysRq : " .. cmd)
    if cmd == "c" then
        K.panic("sysrq triggered crash")
    elseif cmd == "o" then
        K.printk("Power off.")
        sleep(0.2)
        os.shutdown()
    elseif cmd == "b" then
        K.printk("Resetting.")
        sleep(0.2)
        os.reboot()
    elseif cmd == "s" then
        K.printk("Emergency Sync")
        K.printk("Emergency Sync complete")
    elseif cmd == "t" then
        for _, p in ipairs(K.ps_list()) do
            K.printk(string.format("  task %s:%d state=%s", p.comm, p.pid, p.state))
        end
    elseif cmd == "h" or cmd == "?" then
        K.printk("HELP : b=reboot c=crash o=poweroff s=sync t=tasks h=help")
    else
        K.printk("SysRq : unknown command '" .. cmd .. "'")
    end
    return true
end

function K.oops(reason)
    reason = reason or "BUG: kernel NULL pointer dereference"
    K.taint(1)
    K.printk("BUG: " .. reason)
    K.printk("Oops: 0000 [#1] PREEMPT SMP NOPTI")
    K.printk("CPU: 0 PID: " .. (K.shell_pid or 1) .. " Comm: " .. ((K.procs[K.shell_pid] and K.procs[K.shell_pid].comm) or "bash") .. " " .. K.taint_str() .. " " .. K.release .. " " .. K.version:match("^%S+") )
    K.printk("---[ end trace 0000000000000000 ]---")
    return true
end

function K.panic(reason)
    reason = reason or "Fatal exception"
    K.console = false
    if K.panic_fn then
        K.panic_fn(K, reason)
        return
    end
    print("Kernel panic - not syncing: " .. reason)
    sleep(math.max(0, K.panic_timeout))
    os.shutdown()
end

function K.banner_line()
    return string.format(
        "Linux version %s (root@%s) (lua 5.2, %s) %s",
        K.release, K.hostname, K.host(), K.version
    )
end

function K.seed_procs()
    K.procs = {}
    K.next_pid = 1
    K.spawn("init", 0, true)
    K.spawn("kthreadd", 0, true)
    K.spawn("kworker/0:0", 2, true)
    K.spawn("kworker/0:1", 2, true)
    K.spawn("ksoftirqd/0", 2, true)
    K.spawn("migration/0", 2, true)
    K.spawn("rcu_preempt", 2, true)
    K.spawn("kcompactd0", 2, true)
    K.spawn("writeback", 2, true)
    K.spawn("kblockd", 2, true)
    K.spawn("watchdog/0", 2, true)
    K.spawn("systemd-journal", 1, false).comm = "systemd-journal"
    K.spawn("udevd", 1, false)
    local sh = K.spawn("bash", 1, false)
    K.shell_pid = sh.pid
end

K.init_hostname()
K.banner = K.banner_line()

return K
]===] },
    { "/linux/panic.lua", [===[
-- Full-screen Linux kernel panic, then poweroff / hang / reboot.

local P = {}

local function hex(n)
    local digits = "0123456789abcdef"
    local s = {}
    for i = 1, n do
        local r = math.random(1, 16)
        s[i] = digits:sub(r, r)
    end
    return table.concat(s)
end

local function kaddr()
    return "ffff" .. hex(12)
end

local function setup_term()
    if term.isColor and term.isColor() then
        pcall(function()
            if term.setPaletteColor then
                term.setPaletteColor(colors.black, 0x000000)
                term.setPaletteColor(colors.lightGray, 0xAAAAAA)
                term.setPaletteColor(colors.white, 0xC6C6C6)
            end
        end)
        term.setBackgroundColor(colors.black)
        term.setTextColor(colors.lightGray)
    else
        term.setBackgroundColor(colors.black)
        term.setTextColor(colors.white)
    end
    term.setCursorBlink(false)
    term.clear()
    term.setCursorPos(1, 1)
end

function P.render(K, reason)
    reason = reason or "Fatal exception"
    math.randomseed((os.epoch and os.epoch("utc") or os.time() * 1000) % 2147483647)

    local comm = "bash"
    local pid = K.shell_pid or 1
    if K.procs[pid] then
        comm = K.procs[pid].comm
    end
    local cr2 = string.format("00000000000000%02x", ({ 0x00, 0x08, 0x10, 0x28, 0x40, 0x48 })[math.random(1, 6)])
    local t = K.now()
    local function ts(dt)
        t = t + (dt or (math.random(4, 18) / 1000000))
        return string.format("[%12.6f]", t)
    end
    local rip = "cc_computer_tick+0x2c4/0x4b0 [computercraft]"
    local rbx, rdx, rsi, rdi = kaddr(), kaddr(), kaddr(), kaddr()
    local rsp = kaddr()
    local code = hex(2) .. " " .. hex(2) .. " " .. hex(2) .. " " .. hex(2) .. " " .. hex(2)
        .. " <" .. hex(2) .. "> " .. hex(2) .. " " .. hex(2) .. " " .. hex(2)

    local lines = {
        ts(0) .. " BUG: kernel NULL pointer dereference, address: " .. cr2,
        ts() .. " #PF: supervisor read access in kernel mode",
        ts() .. " #PF: error_code(0x0000) - not-present page",
        ts() .. " PGD 0 P4D 0",
        ts() .. " Oops: 0000 [#1] PREEMPT SMP NOPTI",
        ts() .. " CPU: 0 PID: " .. pid .. " Comm: " .. comm .. " " .. K.taint_str() .. " " .. K.release .. " #1",
        ts() .. " Hardware name: Mojang AB " .. K.host() .. ", BIOS " .. K.bios(),
        ts() .. " RIP: 0010:" .. rip,
        ts() .. " Code: " .. code,
        ts() .. " RSP: 0018:" .. rsp .. " EFLAGS: 00010246",
        ts() .. " RAX: 0000000000000000 RBX: " .. rbx .. " RCX: 0000000000000001",
        ts() .. " RDX: " .. rdx .. " RSI: " .. rsi .. " RDI: " .. rdi,
        ts() .. " Call Trace:",
        ts() .. "  <TASK>",
        ts() .. "  cc_machine_execute+0xb3/0xe0 [computercraft]",
        ts() .. "  MinecraftServer_tickServer+0x99/0xd0 [minecraft]",
        ts() .. "  </TASK>",
        ts() .. " Modules linked in: computercraft(O) minecraft tty_cc procfs ext2",
        ts() .. " CR2: " .. cr2,
        ts() .. " ---[ end trace 0000000000000000 ]---",
        ts(0.00004) .. " Kernel panic - not syncing: " .. reason,
        ts(0.00012) .. " Shutting down cpus with NMI",
        ts() .. " Kernel Offset: 0x1a00000 from 0xffffffff81000000",
        ts() .. " ---[ end Kernel panic - not syncing: " .. reason .. " ]---",
    }

    setup_term()
    for i = 1, #lines do
        print(lines[i])
        sleep(0)
    end

    local timeout = K.panic_timeout
    if timeout == 0 then
        while true do
            sleep(1)
        end
    elseif timeout < 0 then
        sleep(2)
        os.reboot()
    else
        sleep(timeout)
        os.shutdown()
    end
end

return P
]===] },
    { "/linux/vfs.lua", [===[
-- Virtual filesystem: Linux paths over CC fs + proc/sys/dev.

local V = {}
V.ROOTFS = "/linux/rootfs"
V.CWD_START = "/root"

local K

local function split_path(path)
    local t = {}
    for part in string.gmatch(path, "[^/]+") do
        if part == ".." then
            if #t > 0 then
                table.remove(t)
            end
        elseif part ~= "." and part ~= "" then
            t[#t + 1] = part
        end
    end
    return t
end

function V.norm(path)
    path = path or "/"
    if path == "" then
        path = "/"
    end
    local parts = split_path(path)
    if #parts == 0 then
        return "/"
    end
    return "/" .. table.concat(parts, "/")
end

function V.resolve(cwd, path)
    path = path or ""
    if path:sub(1, 1) == "/" then
        return V.norm(path)
    end
    if path:sub(1, 1) == "~" then
        local rest = path:sub(2)
        if rest:sub(1, 1) == "/" or rest == "" then
            return V.norm("/root" .. rest)
        end
    end
    return V.norm((cwd or "/") .. "/" .. path)
end

function V.real(path)
    path = V.norm(path)
    if path == "/" then
        return V.ROOTFS
    end
    return fs.combine(V.ROOTFS, path:sub(2))
end

local function virt_kind(path)
    path = V.norm(path)
    if path == "/proc" or path:sub(1, 6) == "/proc/" then
        return "proc", path
    end
    if path == "/sys" or path:sub(1, 5) == "/sys/" then
        return "sys", path
    end
    if path == "/dev" or path:sub(1, 5) == "/dev/" then
        return "dev", path
    end
    if path == "/mnt" or path == "/mnt/craftos" or path:sub(1, 13) == "/mnt/craftos/" then
        return "craftos", path
    end
    return nil, path
end

local PROC_FILES = {
    "cmdline", "cpuinfo", "meminfo", "modules", "mounts", "filesystems",
    "uptime", "version", "loadavg", "stat", "sysrq-trigger", "hostname",
}
local PROC_SYS_KERNEL = {
    "hostname", "ostype", "osrelease", "panic", "sysrq", "version",
}

local function proc_read(path)
    if path == "/proc" then
        return nil, "Is a directory"
    end
    if path == "/proc/version" then
        return string.format("Linux version %s %s\n", K.release, K.version)
    end
    if path == "/proc/cmdline" then
        return K.cmdline .. "\n"
    end
    if path == "/proc/uptime" then
        return string.format("%.2f %.2f\n", K.uptime(), K.uptime() * 0.8)
    end
    if path == "/proc/loadavg" then
        local a = 0.01 + (os.clock() % 7) / 50
        return string.format("%.2f %.2f %.2f %d/%d %d\n", a, a * 0.7, a * 0.4, 1, K.next_pid, K.next_pid - 1)
    end
    if path == "/proc/cpuinfo" then
        return K.cpuinfo()
    end
    if path == "/proc/meminfo" then
        return K.meminfo()
    end
    if path == "/proc/modules" then
        local lines = {}
        for i = 1, #K.modules do
            local m = K.modules[i]
            lines[#lines + 1] = string.format("%s %d %d - %s", m.name, m.size, m.used, m.flags)
        end
        lines[#lines + 1] = ""
        return table.concat(lines, "\n")
    end
    if path == "/proc/mounts" or path == "/proc/self/mounts" then
        return table.concat({
            "/dev/hda1 / ext2 rw,relatime 0 1",
            "proc /proc proc rw,nosuid,nodev,noexec 0 0",
            "sysfs /sys sysfs rw,nosuid,nodev,noexec 0 0",
            "devtmpfs /dev devtmpfs rw,nosuid 0 0",
            "tmpfs /tmp tmpfs rw,nosuid,nodev 0 0",
            "craftos /mnt/craftos ext2 rw,relatime 0 0",
            "",
        }, "\n")
    end
    if path == "/proc/filesystems" then
        return "nodev\tproc\nnodev\tsysfs\nnodev\tdevtmpfs\nnodev\ttmpfs\n\text2\n"
    end
    if path == "/proc/stat" then
        local up = math.floor(K.uptime() * 100)
        return "cpu  " .. up .. " 0 " .. math.floor(up * 0.05) .. " " .. math.floor(up * 2) .. " 0 0 0 0 0 0\ncpu0 " .. up .. " 0 0 " .. math.floor(up * 2) .. " 0 0 0 0 0 0\nintr 0\nctxt 0\nbtime 0\nprocesses " .. K.next_pid .. "\nprocs_running 1\nprocs_blocked 0\n"
    end
    if path == "/proc/hostname" or path == "/proc/sys/kernel/hostname" then
        return K.hostname .. "\n"
    end
    if path == "/proc/sys/kernel/ostype" then
        return "Linux\n"
    end
    if path == "/proc/sys/kernel/osrelease" then
        return K.release .. "\n"
    end
    if path == "/proc/sys/kernel/version" then
        return K.version .. "\n"
    end
    if path == "/proc/sys/kernel/panic" then
        return tostring(K.panic_timeout) .. "\n"
    end
    if path == "/proc/sys/kernel/sysrq" then
        return (K.sysrq and "1" or "0") .. "\n"
    end
    if path == "/proc/sysrq-trigger" then
        return ""
    end
    if path == "/proc/self" or path == "/proc/" .. tostring(K.shell_pid) then
        return nil, "Is a directory"
    end
    if path == "/proc/self/status" or path == "/proc/" .. tostring(K.shell_pid or 0) .. "/status" then
        local p = K.procs[K.shell_pid or 1]
        local comm = p and p.comm or "bash"
        return "Name:\t" .. comm .. "\nState:\tS (sleeping)\nTgid:\t" .. tostring(K.shell_pid) .. "\nPid:\t" .. tostring(K.shell_pid) .. "\nPPid:\t1\nUid:\t0\t0\t0\t0\nGid:\t0\t0\t0\t0\n"
    end
    local pid = path:match("^/proc/(%d+)$")
    if pid then
        if K.procs[tonumber(pid)] then
            return nil, "Is a directory"
        end
        return nil, "No such file or directory"
    end
    return nil, "No such file or directory"
end

local function proc_list(path)
    if path == "/proc" then
        local n = {
            "cmdline", "cpuinfo", "meminfo", "modules", "mounts", "filesystems",
            "uptime", "version", "loadavg", "stat", "sysrq-trigger", "sys", "self",
        }
        for _, p in ipairs(K.ps_list()) do
            n[#n + 1] = tostring(p.pid)
        end
        return n
    end
    if path == "/proc/sys" then
        return { "kernel" }
    end
    if path == "/proc/sys/kernel" then
        return { "hostname", "ostype", "osrelease", "panic", "sysrq", "version" }
    end
    if path == "/proc/self" then
        return { "status", "comm", "cmdline" }
    end
    local pid = path:match("^/proc/(%d+)$")
    if pid and K.procs[tonumber(pid)] then
        return { "status", "comm", "cmdline" }
    end
    return nil
end

local function sys_list(path)
    if path == "/sys" then
        return { "class", "block", "kernel" }
    end
    if path == "/sys/class" then
        return { "dmi", "tty" }
    end
    if path == "/sys/class/dmi" then
        return { "id" }
    end
    if path == "/sys/class/dmi/id" then
        return { "sys_vendor", "product_name", "bios_version", "board_name" }
    end
    if path == "/sys/class/tty" then
        return { "tty0", "console" }
    end
    if path == "/sys/block" then
        return { "hda" }
    end
    if path == "/sys/kernel" then
        return { "ostype", "osrelease" }
    end
    return nil
end

local function sys_read(path)
    if path == "/sys/class/dmi/id/sys_vendor" then
        return "Mojang AB\n"
    end
    if path == "/sys/class/dmi/id/product_name" then
        return "CC: Tweaked " .. K.machine .. "\n"
    end
    if path == "/sys/class/dmi/id/bios_version" then
        return K.bios() .. "\n"
    end
    if path == "/sys/class/dmi/id/board_name" then
        return K.host() .. "\n"
    end
    if path == "/sys/kernel/ostype" then
        return "Linux\n"
    end
    if path == "/sys/kernel/osrelease" then
        return K.release .. "\n"
    end
    return nil, "No such file or directory"
end

local function dev_list(path)
    if path == "/dev" then
        return { "null", "zero", "random", "urandom", "tty", "console", "kmsg", "hda", "hda1" }
    end
    return nil
end

local function dev_read(path, n)
    n = n or 64
    if path == "/dev/null" then
        return ""
    end
    if path == "/dev/zero" then
        return string.rep("\0", math.min(n, 256))
    end
    if path == "/dev/random" or path == "/dev/urandom" then
        local t = {}
        for i = 1, math.min(n, 64) do
            t[i] = string.char(math.random(0, 255))
        end
        return table.concat(t)
    end
    if path == "/dev/tty" or path == "/dev/console" then
        return ""
    end
    if path == "/dev/kmsg" then
        return table.concat(K.dmesg, "\n") .. "\n"
    end
    if path == "/dev/hda" or path == "/dev/hda1" then
        return nil, "Invalid argument"
    end
    return nil, "No such file or directory"
end

local function craftos_real(path)
    if path == "/mnt/craftos" then
        return "/"
    end
    return path:sub(#"/mnt/craftos" + 1)
end

function V.init(kernel)
    K = kernel
    local dirs = {
        V.ROOTFS,
        V.ROOTFS .. "/bin",
        V.ROOTFS .. "/boot",
        V.ROOTFS .. "/boot/grub",
        V.ROOTFS .. "/boot/grub/fonts",
        V.ROOTFS .. "/etc",
        V.ROOTFS .. "/etc/pacman.d",
        V.ROOTFS .. "/etc/default",
        V.ROOTFS .. "/etc/profile.d",
        V.ROOTFS .. "/etc/systemd/system",
        V.ROOTFS .. "/etc/udev/rules.d",
        V.ROOTFS .. "/etc/xdg",
        V.ROOTFS .. "/home",
        V.ROOTFS .. "/home/cc",
        V.ROOTFS .. "/lib",
        V.ROOTFS .. "/lib64",
        V.ROOTFS .. "/media",
        V.ROOTFS .. "/mnt",
        V.ROOTFS .. "/opt",
        V.ROOTFS .. "/root",
        V.ROOTFS .. "/run",
        V.ROOTFS .. "/run/user/0",
        V.ROOTFS .. "/sbin",
        V.ROOTFS .. "/srv",
        V.ROOTFS .. "/tmp",
        V.ROOTFS .. "/usr",
        V.ROOTFS .. "/usr/bin",
        V.ROOTFS .. "/usr/sbin",
        V.ROOTFS .. "/usr/lib",
        V.ROOTFS .. "/usr/lib64",
        V.ROOTFS .. "/usr/lib/modules",
        V.ROOTFS .. "/usr/include",
        V.ROOTFS .. "/usr/src",
        V.ROOTFS .. "/usr/share",
        V.ROOTFS .. "/usr/share/man/man1",
        V.ROOTFS .. "/usr/share/pacman",
        V.ROOTFS .. "/usr/local",
        V.ROOTFS .. "/usr/local/bin",
        V.ROOTFS .. "/usr/local/sbin",
        V.ROOTFS .. "/usr/local/share",
        V.ROOTFS .. "/var",
        V.ROOTFS .. "/var/log",
        V.ROOTFS .. "/var/log/journal",
        V.ROOTFS .. "/var/cache",
        V.ROOTFS .. "/var/cache/pacman/pkg",
        V.ROOTFS .. "/var/lib",
        V.ROOTFS .. "/var/lib/pacman/local",
        V.ROOTFS .. "/var/lib/pacman/sync",
        V.ROOTFS .. "/var/tmp",
        V.ROOTFS .. "/var/spool",
        V.ROOTFS .. "/lost+found",
    }
    for i = 1, #dirs do
        if not fs.exists(dirs[i]) then
            fs.makeDir(dirs[i])
        end
    end
end

function V.exists(path)
    local kind, p = virt_kind(path)
    if kind == "proc" then
        if p == "/proc" or proc_list(p) then
            return true
        end
        local data, err = proc_read(p)
        return data ~= nil or err == "Is a directory"
    end
    if kind == "sys" then
        if p == "/sys" or sys_list(p) then
            return true
        end
        local data = sys_read(p)
        return data ~= nil
    end
    if kind == "dev" then
        if p == "/dev" then
            return true
        end
        local data, err = dev_read(p)
        return data ~= nil or err == "Invalid argument"
    end
    if kind == "craftos" then
        return fs.exists(craftos_real(p))
    end
    return fs.exists(V.real(path))
end

function V.isDir(path)
    local kind, p = virt_kind(path)
    if kind == "proc" then
        return p == "/proc" or proc_list(p) ~= nil
    end
    if kind == "sys" then
        return p == "/sys" or sys_list(p) ~= nil
    end
    if kind == "dev" then
        return p == "/dev"
    end
    if kind == "craftos" then
        local rp = craftos_real(p)
        if rp == "/" then
            return true
        end
        return fs.isDir(rp)
    end
    return fs.isDir(V.real(path))
end

function V.list(path)
    local kind, p = virt_kind(path)
    if kind == "proc" then
        return proc_list(p) or {}
    end
    if kind == "sys" then
        return sys_list(p) or {}
    end
    if kind == "dev" then
        return dev_list(p) or {}
    end
    if kind == "craftos" then
        local rp = craftos_real(p)
        if not fs.exists(rp) then
            return nil, "No such file or directory"
        end
        return fs.list(rp)
    end
    local rp = V.real(path)
    if V.norm(path) == "/" then
        local names = {}
        local seen = {}
        if fs.exists(rp) and fs.isDir(rp) then
            for _, n in ipairs(fs.list(rp)) do
                names[#names + 1] = n
                seen[n] = true
            end
        end
        local virt = { "proc", "sys", "dev" }
        for i = 1, #virt do
            if not seen[virt[i]] then
                names[#names + 1] = virt[i]
            end
        end
        table.sort(names)
        return names
    end
    if not fs.exists(rp) then
        return nil, "No such file or directory"
    end
    if not fs.isDir(rp) then
        return nil, "Not a directory"
    end
    return fs.list(rp)
end

function V.read(path)
    local kind, p = virt_kind(path)
    if kind == "proc" then
        return proc_read(p)
    end
    if kind == "sys" then
        return sys_read(p)
    end
    if kind == "dev" then
        return dev_read(p)
    end
    if kind == "craftos" then
        local rp = craftos_real(p)
        if fs.isDir(rp) then
            return nil, "Is a directory"
        end
        local h = fs.open(rp, "r")
        if not h then
            return nil, "Permission denied"
        end
        local data = h.readAll() or ""
        h.close()
        return data
    end
    local rp = V.real(path)
    if not fs.exists(rp) then
        return nil, "No such file or directory"
    end
    if fs.isDir(rp) then
        return nil, "Is a directory"
    end
    local h = fs.open(rp, "r")
    if not h then
        return nil, "Permission denied"
    end
    local data = h.readAll() or ""
    h.close()
    return data
end

function V.write(path, data, mode)
    mode = mode or "w"
    local kind, p = virt_kind(path)
    data = data or ""
    if kind == "proc" then
        if p == "/proc/sysrq-trigger" then
            return K.sysrq(data)
        end
        if p == "/proc/sys/kernel/panic" then
            K.panic_timeout = tonumber(data) or K.panic_timeout
            return true
        end
        if p == "/proc/sys/kernel/sysrq" then
            local n = tonumber(data) or 0
            K.sysrq = n ~= 0
            return true
        end
        if p == "/proc/sys/kernel/hostname" or p == "/proc/hostname" then
            K.hostname = (data:gsub("%s+", ""):gsub("\n", "")):sub(1, 32)
            if K.hostname == "" then
                K.hostname = "localhost"
            end
            V.write("/etc/hostname", K.hostname .. "\n", "w")
            return true
        end
        if p == "/dev/kmsg" or p == "/proc/kmsg" then
            K.printk(data:gsub("\n$", ""))
            return true
        end
        return false, "Permission denied"
    end
    if kind == "dev" then
        if p == "/dev/null" then
            return true
        end
        if p == "/dev/kmsg" then
            K.printk(data:gsub("\n$", ""))
            return true
        end
        if p == "/dev/tty" or p == "/dev/console" then
            write(data)
            return true
        end
        return false, "Permission denied"
    end
    if kind == "sys" then
        return false, "Permission denied"
    end
    if kind == "craftos" then
        local rp = craftos_real(p)
        if fs.isDir(rp) then
            return false, "Is a directory"
        end
        local h = fs.open(rp, mode)
        if not h then
            return false, "Permission denied"
        end
        h.write(data)
        h.close()
        return true
    end
    local rp = V.real(path)
    if fs.exists(rp) and fs.isDir(rp) then
        return false, "Is a directory"
    end
    local dir = fs.getDir(rp)
    if dir and dir ~= "" and not fs.exists(dir) then
        fs.makeDir(dir)
    end
    local h = fs.open(rp, mode)
    if not h then
        return false, "Permission denied"
    end
    h.write(data)
    h.close()
    return true
end

function V.mkdir(path)
    local kind = virt_kind(path)
    if kind == "proc" or kind == "sys" or kind == "dev" then
        return false, "Permission denied"
    end
    if kind == "craftos" then
        fs.makeDir(craftos_real(V.norm(path)))
        return true
    end
    local rp = V.real(path)
    if fs.exists(rp) then
        return false, "File exists"
    end
    fs.makeDir(rp)
    return true
end

function V.remove(path)
    local kind, p = virt_kind(path)
    if kind == "proc" or kind == "sys" or kind == "dev" then
        return false, "Permission denied"
    end
    if V.norm(path) == "/" then
        return false, "Cannot remove root"
    end
    if kind == "craftos" then
        local rp = craftos_real(p)
        if rp == "/" then
            return false, "Cannot remove /mnt/craftos"
        end
        if not fs.exists(rp) then
            return false, "No such file or directory"
        end
        fs.delete(rp)
        return true
    end
    local rp = V.real(path)
    if not fs.exists(rp) then
        return false, "No such file or directory"
    end
    fs.delete(rp)
    return true
end

function V.copy(src, dst)
    local data, err = V.read(src)
    if not data then
        if V.isDir(src) then
            return false, "Omitting directory"
        end
        return false, err
    end
    return V.write(dst, data, "w")
end

function V.size(path)
    if V.isDir(path) then
        return 4096
    end
    local kind = virt_kind(path)
    if kind then
        local data = V.read(path)
        return data and #data or 0
    end
    local rp = V.real(path)
    if fs.exists(rp) and fs.getSize then
        return fs.getSize(rp)
    end
    return 0
end

function V.modified(path)
    local rp
    local kind, p = virt_kind(path)
    if kind == "craftos" then
        rp = craftos_real(p)
    elseif not kind then
        rp = V.real(path)
    else
        return os.epoch and os.epoch("utc") or os.time() * 1000
    end
    if fs.attributes then
        local ok, a = pcall(fs.attributes, rp)
        if ok and a and a.modified then
            return a.modified
        end
    end
    return os.epoch and os.epoch("utc") or os.time() * 1000
end

return V
]===] },
    { "/linux/shell.lua", [===[
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
]===] },
    { "/linux/commands.lua", [===[
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
]===] },
    { "/linux/extra.lua", [===[
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
]===] },
    { "/linux/pacman.lua", [===[
-- Arch-style pacman for ccLinux.
-- Mirror: https://github.com/vanyachickenganidanya-lgtm/pacmanlinuxcraftos

local Pac = {}

local CORE = {}
local EXTRA = {}
local INST = {} -- name -> pkg

local function P(list, name, ver, desc, depends, commands, isize, groups)
    list[#list + 1] = {
        name = name,
        ver = ver,
        desc = desc,
        depends = depends or {},
        commands = commands or {},
        isize = isize or 48,
        groups = groups or {},
        repo = (list == CORE) and "core" or "extra",
    }
end

-- core (preinstalled, like Arch base)
P(CORE, "filesystem", "2024.11.21-1", "Base Arch Linux files", {}, {}, 12, { "base" })
P(CORE, "glibc", "2.40-1", "GNU C Library", { "filesystem" }, {}, 2100, { "base" })
P(CORE, "gcc-libs", "14.2.1-1", "Runtime libraries of GCC", { "glibc" }, {}, 1400, { "base" })
P(CORE, "bash", "5.2.037-1", "The GNU Bourne Again shell", { "glibc", "ncurses", "readline" }, { "bash" }, 1800, { "base" })
P(CORE, "coreutils", "9.5-2", "Basic file, shell and text manipulation utilities", { "glibc" }, { "ls", "cat", "cp", "mv", "rm", "echo", "pwd", "true", "false" }, 3100, { "base" })
P(CORE, "util-linux", "2.40.2-1", "Miscellaneous system utilities", { "glibc" }, { "dmesg", "kill", "mount", "login" }, 2200, { "base" })
P(CORE, "pacman", "6.1.0-3", "Arch Linux package manager", { "bash", "curl", "gpgme", "libarchive" }, { "pacman" }, 900, { "base" })
P(CORE, "linux", "6.12.0.arch1-1", "The Linux kernel and modules (ccLinux)", { "filesystem" }, {}, 80000, {})
P(CORE, "linux-firmware", "202410.1-1", "Firmware files for Linux", {}, {}, 500, {})
P(CORE, "iana-etc", "20241015-1", "/etc/protocols and /etc/services", { "filesystem" }, {}, 8, { "base" })
P(CORE, "ncurses", "6.5-1", "System V Release 4.0 curses emulation library", { "glibc" }, {}, 700, { "base" })
P(CORE, "readline", "8.2.013-1", "GNU readline library", { "ncurses", "glibc" }, {}, 300, { "base" })
P(CORE, "zlib", "1.3.1-2", "Compression library", { "glibc" }, {}, 120, { "base" })
P(CORE, "xz", "5.6.3-1", "Library and command line tools for XZ and LZMA", { "glibc" }, { "xz" }, 200, { "base" })
P(CORE, "zstd", "1.5.6-1", "Zstandard compression", { "glibc" }, { "zstd" }, 400, { "base" })
P(CORE, "openssl", "3.4.0-1", "TLS/SSL and crypto library", { "glibc" }, { "openssl" }, 1800, { "base" })
P(CORE, "curl", "8.11.0-1", "URL retrieval utility and library", { "openssl", "zlib" }, { "curl" }, 600, { "base" })
P(CORE, "gpgme", "1.24.0-1", "GnuPG Made Easy", { "glibc" }, {}, 350, { "base" })
P(CORE, "libarchive", "3.7.7-1", "library for reading/writing various archive formats", { "zlib", "xz", "zstd" }, {}, 500, { "base" })
P(CORE, "archlinux-keyring", "20241203-1", "Arch Linux PGP keyring", {}, {}, 80, { "base" })
P(CORE, "base", "3-2", "Minimal package set to define a basic Arch Linux installation", { "filesystem", "glibc", "bash", "coreutils", "pacman", "util-linux" }, {}, 2, { "base" })
P(CORE, "shadow", "4.16.0-1", "Password and account management", { "pam" }, { "passwd", "useradd" }, 400, { "base" })
P(CORE, "iproute2", "6.11.0-1", "IP Routing Utilities", { "glibc" }, { "ip", "ss" }, 700, { "base" })
P(CORE, "procps-ng", "4.0.4-3", "Utilities for monitoring your system and its processes", { "ncurses" }, { "ps", "free", "top", "uptime", "kill" }, 250, { "base" })
P(CORE, "psmisc", "23.7-1", "Miscellaneous procfs tools", {}, { "killall", "pstree" }, 80, { "base" })
P(CORE, "sed", "4.9-2", "GNU stream editor", { "glibc" }, { "sed" }, 150, { "base" })
P(CORE, "grep", "3.11-1", "GNU grep", { "glibc" }, { "grep" }, 180, { "base" })
P(CORE, "gawk", "5.3.1-1", "GNU awk", { "glibc" }, { "awk", "gawk" }, 400, { "base" })
P(CORE, "findutils", "4.10.0-1", "GNU find, xargs, locate", { "glibc" }, { "find", "xargs" }, 300, { "base" })
P(CORE, "tar", "1.35-2", "GNU tar", { "glibc" }, { "tar" }, 500, { "base" })
P(CORE, "gzip", "1.13-4", "GNU compression utility", { "glibc" }, { "gzip", "gunzip" }, 90, { "base" })
P(CORE, "which", "2.21-6", "Show the full path of commands", { "glibc" }, { "which" }, 12, { "base" })
P(CORE, "diffutils", "3.10-1", "GNU diff, cmp, diff3, sdiff", { "glibc" }, { "diff", "cmp" }, 220, { "base" })
P(CORE, "file", "5.45-1", "File type identification", { "glibc", "zlib" }, { "file" }, 400, { "base" })
P(CORE, "less", "668-1", "A terminal based program for viewing text files", { "ncurses" }, { "less", "more" }, 120, { "base" })
P(CORE, "man-db", "2.13.0-1", "A utility for reading man pages", { "gdbm", "zlib", "groff" }, { "man" }, 400, {})
P(CORE, "texinfo", "7.1.1-1", "GNU documentation system", { "ncurses" }, { "info" }, 700, {})
P(CORE, "gettext", "0.22.5-2", "GNU internationalization library", { "gcc-libs" }, {}, 900, { "base" })
P(CORE, "pciutils", "3.13.0-1", "PCI bus utilities", { "glibc" }, { "lspci" }, 140, { "base" })
P(CORE, "usbutils", "018-1", "USB utilities", { "glibc" }, { "lsusb" }, 90, {})
P(CORE, "kmod", "33-3", "Linux kernel module management", { "glibc" }, { "lsmod", "modprobe", "insmod" }, 160, { "base" })
P(CORE, "systemd", "256.7-1", "system and service manager", { "util-linux" }, { "systemctl", "journalctl", "hostnamectl" }, 9000, { "base" })
P(CORE, "dbus", "1.14.10-2", "Freedesktop message bus", { "systemd" }, {}, 500, { "base" })
P(CORE, "sudo", "1.9.16-1", "Give certain users the ability to run commands as root", { "glibc", "pam" }, { "sudo" }, 250, {})
P(CORE, "grub", "2:2.12-3", "GNU GRand Unified Bootloader", { "xz" }, { "grub-install", "grub-mkconfig" }, 1800, {})
P(CORE, "mkinitcpio", "39.2-2", "Modular initramfs image creation utility", { "bash" }, { "mkinitcpio" }, 80, {})

-- extra / community (need pacman -S)
P(EXTRA, "htop", "3.3.2-1", "Interactive process viewer", { "ncurses" }, { "htop" }, 120, {})
P(EXTRA, "neofetch", "7.1.0-2", "A CLI system information tool", { "bash" }, { "neofetch", "fastfetch", "screenfetch" }, 40, {})
P(EXTRA, "fastfetch", "2.27.1-1", "A feature-rich and fast system info tool", {}, { "fastfetch", "neofetch" }, 90, {})
P(EXTRA, "vim", "9.1.0785-1", "Vi Improved", { "ncurses" }, { "vim", "vi" }, 1800, {})
P(EXTRA, "nano", "8.2-1", "Pico editor clone with enhancements", { "ncurses" }, { "nano" }, 200, {})
P(EXTRA, "git", "2.47.0-1", "the fast distributed version control system", { "curl", "expat", "perl" }, { "git" }, 2200, {})
P(EXTRA, "cowsay", "3.04-4", "Configurable talking cow", { "perl" }, { "cowsay" }, 20, {})
P(EXTRA, "fortune-mod", "3.22.0-1", "The Fortune Cookie Program", {}, { "fortune" }, 1500, {})
P(EXTRA, "python", "3.12.7-1", "The Python 3 language", { "bzip2", "expat", "zlib" }, { "python", "python3" }, 12000, {})
P(EXTRA, "gcc", "14.2.1-1", "The GNU Compiler Collection", { "binutils", "gcc-libs" }, { "gcc", "g++" }, 45000, {})
P(EXTRA, "make", "4.4.1-2", "GNU make utility", { "glibc" }, { "make" }, 400, {})
P(EXTRA, "binutils", "2.43-1", "A set of programs to assemble and manipulate binary and object files", { "glibc", "zlib" }, { "ld", "as", "strip", "objdump" }, 8000, {})
P(EXTRA, "base-devel", "1-2", "Basic tools to build Arch Linux packages", { "autoconf", "automake", "binutils", "gcc", "make", "pacman", "sudo" }, {}, 2, { "base-devel" })
P(EXTRA, "wget", "1.24.5-3", "Network utility to retrieve files from the Web", { "openssl" }, { "wget" }, 300, {})
P(EXTRA, "openssh", "9.9p1-1", "Premier connectivity tool for remote login with the SSH protocol", { "openssl", "zlib" }, { "ssh", "sshd", "scp" }, 1200, {})
P(EXTRA, "tmux", "3.5-1", "A terminal multiplexer", { "libevent", "ncurses" }, { "tmux" }, 400, {})
P(EXTRA, "screen", "4.9.1-1", "Full-screen window manager that multiplexes a physical terminal", { "ncurses" }, { "screen" }, 500, {})
P(EXTRA, "zip", "3.0-11", "Compressor/archiver for creating and modifying zipfiles", { "bzip2" }, { "zip" }, 150, {})
P(EXTRA, "unzip", "6.0-21", "For extracting and viewing files in .zip archives", { "bzip2" }, { "unzip" }, 140, {})
P(EXTRA, "tree", "2.1.3-1", "A directory listing program displaying a depth indented list of files", { "glibc" }, { "tree" }, 40, {})
P(EXTRA, "strace", "6.11-1", "A diagnostic, debugging and instructional userspace tracer", { "libunwind" }, { "strace" }, 300, {})
P(EXTRA, "gdb", "15.2-1", "The GNU Debugger", { "ncurses", "python", "expat" }, { "gdb" }, 8000, {})
P(EXTRA, "nmap", "7.95-1", "Utility for network discovery and security auditing", { "openssl" }, { "nmap" }, 6000, {})
P(EXTRA, "nginx", "1.26.2-1", "Lightweight HTTP server and IMAP/POP3 proxy server", { "openssl", "pcre2", "zlib" }, { "nginx" }, 1500, {})
P(EXTRA, "apache", "2.4.62-1", "A high performance Unix-based HTTP server", { "openssl", "zlib" }, { "httpd", "apachectl" }, 2200, {})
P(EXTRA, "docker", "27.3.1-1", "Pack, ship and run any application as a lightweight container", { "containerd", "runc" }, { "docker" }, 25000, {})
P(EXTRA, "nodejs", "22.11.0-1", "Evented I/O for V8 javascript", { "openssl" }, { "node", "nodejs" }, 14000, {})
P(EXTRA, "rust", "1:1.82.0-1", "Systems programming language focused on safety, speed and concurrency", { "gcc-libs", "curl" }, { "rustc", "cargo" }, 70000, {})
P(EXTRA, "go", "2:1.23.3-1", "Core compiler tools for the Go programming language", {}, { "go" }, 40000, {})
P(EXTRA, "htop", "3.3.2-1", "Interactive process viewer", { "ncurses" }, { "htop" }, 120, {})
P(EXTRA, "btop", "1.4.0-1", "A monitor of system resources, bpytop port", { "gcc-libs" }, { "btop" }, 400, {})
P(EXTRA, "ncdu", "2.6-1", "Disk usage analyzer with an ncurses interface", { "ncurses" }, { "ncdu" }, 80, {})
P(EXTRA, "ripgrep", "14.1.1-1", "A search tool that combines the usability of ag with the speed of grep", { "gcc-libs" }, { "rg" }, 1500, {})
P(EXTRA, "fd", "10.2.0-1", "Simple, fast and user-friendly alternative to find", { "gcc-libs" }, { "fd" }, 900, {})
P(EXTRA, "bat", "0.24.0-1", "Cat clone with syntax highlighting and git integration", { "gcc-libs", "libgit2" }, { "bat" }, 1800, {})
P(EXTRA, "eza", "0.20.7-1", "A modern replacement for ls", { "gcc-libs" }, { "eza" }, 700, {})
P(EXTRA, "fzf", "0.56.3-1", "Command-line fuzzy finder", { "glibc" }, { "fzf" }, 1200, {})
P(EXTRA, "jq", "1.7.1-2", "Command-line JSON processor", { "oniguruma" }, { "jq" }, 200, {})
P(EXTRA, "tmux", "3.5-1", "A terminal multiplexer", { "libevent", "ncurses" }, { "tmux" }, 400, {})
P(EXTRA, "htop", "3.3.2-1", "Interactive process viewer", { "ncurses" }, { "htop" }, 120, {})
P(EXTRA, "yay", "12.4.2-1", "Yet another yogurt. Pacman wrapper and AUR helper written in go", { "pacman", "git" }, { "yay" }, 3000, {})
P(EXTRA, "paru", "2.0.4-1", "Feature packed AUR helper", { "pacman", "git" }, { "paru" }, 2800, {})
P(EXTRA, "linux-headers", "6.12.0.arch1-1", "Headers and scripts for building modules for the Linux kernel", { "linux" }, {}, 25000, {})
P(EXTRA, "linux-lts", "6.6.63-1", "The LTS Linux kernel and modules", {}, {}, 75000, {})
P(EXTRA, "networkmanager", "1.50.0-1", "Network connection manager and user applications", { "libnm", "curl" }, { "nmcli" }, 2500, {})
P(EXTRA, "wireguard-tools", "1.0.20210914-2", "next generation secure network tunnel - tools", { "bash" }, { "wg", "wg-quick" }, 80, {})
P(EXTRA, "htop", "3.3.2-1", "Interactive process viewer", { "ncurses" }, { "htop" }, 120, {})

-- de-duplicate EXTRA by name (last wins)
do
    local seen, clean = {}, {}
    for i = 1, #EXTRA do
        local p = EXTRA[i]
        if not seen[p.name] then
            seen[p.name] = true
            clean[#clean + 1] = p
        end
    end
    EXTRA = clean
end

local function all_pkgs()
    local t = {}
    for i = 1, #CORE do
        t[#t + 1] = CORE[i]
    end
    for i = 1, #EXTRA do
        t[#t + 1] = EXTRA[i]
    end
    return t
end

local function find_pkg(name)
    local all = all_pkgs()
    for i = 1, #all do
        if all[i].name == name then
            return all[i]
        end
    end
    return nil
end

local function local_path(p)
    return "/var/lib/pacman/local/" .. p.name .. "-" .. p.ver
end

function Pac.installed(name)
    return INST[name] ~= nil
end

function Pac.is_installed(name)
    return INST[name] ~= nil
end

local function save_local(V, p)
    local dir = local_path(p)
    V.mkdir(dir)
    local desc = table.concat({
        "%NAME%",
        p.name,
        "",
        "%VERSION%",
        p.ver,
        "",
        "%DESC%",
        p.desc,
        "",
        "%ARCH%",
        "cc",
        "",
        "%CSIZE%",
        tostring(math.floor((p.isize or 50) * 0.4) * 1024),
        "",
        "%ISIZE%",
        tostring((p.isize or 50) * 1024),
        "",
        "%PACKAGER%",
        "ccLinux <root@cclinux>",
        "",
        "%URL%",
        "https://github.com/vanyachickenganidanya-lgtm/pacmanlinuxcraftos",
        "",
        "%DEPENDS%",
        table.concat(p.depends, "\n"),
        "",
    }, "\n")
    V.write(dir .. "/desc", desc, "w")
    local files = { "%FILES%" }
    for i = 1, #(p.commands or {}) do
        files[#files + 1] = "usr/bin/" .. p.commands[i]
    end
    files[#files + 1] = ""
    V.write(dir .. "/files", table.concat(files, "\n"), "w")
end

local function load_installed(V)
    INST = {}
    local names = V.list("/var/lib/pacman/local") or {}
    for i = 1, #names do
        local n = names[i]
        local pkgname = n:match("^(.*)%-[0-9]")
        if not pkgname then
            pkgname = n
        end
        -- try exact from CORE/EXTRA
        local ver = n:match("-(%d.*)$")
        local p = find_pkg(pkgname)
        if p then
            INST[p.name] = p
        else
            INST[pkgname] = { name = pkgname, ver = ver or "1-1", desc = "", depends = {}, commands = {}, isize = 1, repo = "local" }
        end
    end
end

local function seed_core(V)
    local names = V.list("/var/lib/pacman/local") or {}
    if #names > 0 then
        load_installed(V)
        return
    end
    for i = 1, #CORE do
        INST[CORE[i].name] = CORE[i]
        save_local(V, CORE[i])
    end
end

local function resolve(name, acc, seen)
    acc = acc or {}
    seen = seen or {}
    if seen[name] or INST[name] then
        return acc
    end
    local p = find_pkg(name)
    if not p then
        return nil, name
    end
    seen[name] = true
    for i = 1, #p.depends do
        local d = p.depends[i]
        if not INST[d] and not seen[d] then
            -- skip unknown deps that are not in repo (pam, perl, ...)
            if find_pkg(d) then
                local _, missing = resolve(d, acc, seen)
                if missing then
                    return nil, missing
                end
            end
        end
    end
    acc[#acc + 1] = p
    return acc
end

local function kb(n)
    if n >= 1024 then
        return string.format("%.2f MiB", n / 1024)
    end
    return string.format("%.1f KiB", n)
end

local function confirm(noconfirm)
    if noconfirm then
        return true
    end
    write(":: Proceed with installation? [Y/n] ")
    local a = read()
    if not a or a == "" or a:lower():sub(1, 1) == "y" then
        return true
    end
    return false
end

local function parse_flags(args)
    local flags, rest = {}, {}
    for i = 1, #args do
        local a = args[i]
        if a:sub(1, 2) == "--" then
            flags[a:sub(3)] = true
        elseif a:sub(1, 1) == "-" and #a > 1 then
            for k = 2, #a do
                flags[a:sub(k, k)] = true
            end
        else
            rest[#rest + 1] = a
        end
    end
    return flags, rest
end

local function try_http_sync()
    local url = "https://raw.githubusercontent.com/vanyachickenganidanya-lgtm/pacmanlinuxcraftos/main/packages.lua"
    if not rawget(_G, "http") or not http.get then
        return false, "http disabled"
    end
    local ok, res = pcall(http.get, url, nil, true)
    if not ok or not res then
        return false, "mirror unreachable"
    end
    local body = res.readAll() or ""
    res.close()
    if #body < 8 then
        return false, "empty repo"
    end
    local loader = loadstring or load
    local fn = loader(body)
    if not fn then
        return false, "bad packages.lua"
    end
    local ok2, tab = pcall(fn)
    if not ok2 or type(tab) ~= "table" then
        return false, "bad packages.lua"
    end
    local n = 0
    for i = 1, #tab do
        local p = tab[i]
        if type(p) == "table" and p.name then
            p.repo = p.repo or "extra"
            p.depends = p.depends or {}
            p.commands = p.commands or {}
            p.ver = p.ver or "1-1"
            p.desc = p.desc or ""
            p.isize = p.isize or 50
            -- replace or append
            local found = false
            for j = 1, #EXTRA do
                if EXTRA[j].name == p.name then
                    EXTRA[j] = p
                    found = true
                    break
                end
            end
            if not found then
                EXTRA[#EXTRA + 1] = p
            end
            n = n + 1
        end
    end
    return true, n
end

function Pac.init(V)
    seed_core(V)
end

function Pac.register(cmds, K, V)
    Pac.init(V)

    local function pacman(args, ctx)
        local flags, rest = parse_flags(args)
        local noconfirm = flags.y or flags.noconfirm
        if flags.V or flags.version then
            print("Pacman v6.1.0 - libalpm v13.0.2")
            print("Copyright (C) 2006-2024 Pacman Development Team <pacman-dev@lists.archlinux.org>")
            print("This program may be freely redistributed under")
            print("the terms of the GNU General Public License.")
            return
        end
        if flags.h or flags.help or #args == 0 then
            print("usage:  pacman <operation> [...]")
            print("operations:")
            print("    pacman {-h --help}")
            print("    pacman {-V --version}")
            print("    pacman {-D --database} <options> <package(s)>")
            print("    pacman {-F --files}    [options] [file(s)]")
            print("    pacman {-Q --query}    [options] [package(s)]")
            print("    pacman {-R --remove}   <options> <package(s)>")
            print("    pacman {-S --sync}     [options] [package(s)]")
            print("    pacman {-T --deptest}  [options] [package(s)]")
            print("    pacman {-U --upgrade}  [options] <file(s)>")
            print("")
            print("    -S, --sync      synchronize packages")
            print("    -Syu            sync and upgrade")
            print("    -Ss <regex>     search remote")
            print("    -Q              list installed")
            print("    -Qi <pkg>       info")
            print("    -Ql <pkg>       list files")
            print("    -R <pkg>        remove")
            print("    -Rns <pkg>      remove with deps")
            print("Mirror: https://github.com/vanyachickenganidanya-lgtm/pacmanlinuxcraftos")
            return
        end

        -- -Q query
        if flags.Q then
            if flags.s and rest[1] then
                local q = rest[1]:lower()
                for name, p in pairs(INST) do
                    if name:find(q, 1, true) or (p.desc or ""):lower():find(q, 1, true) then
                        print("local/" .. p.name .. " " .. p.ver)
                        print("    " .. (p.desc or ""))
                    end
                end
                return
            end
            if flags.i and rest[1] then
                local p = INST[rest[1]]
                if not p then
                    print("error: package '" .. rest[1] .. "' was not found")
                    ctx.ok = false
                    return
                end
                print("Name            : " .. p.name)
                print("Version         : " .. p.ver)
                print("Description     : " .. (p.desc or ""))
                print("Architecture    : cc")
                print("URL             : https://github.com/vanyachickenganidanya-lgtm/pacmanlinuxcraftos")
                print("Packager        : ccLinux <root@cclinux>")
                print("Depends On      : " .. (#(p.depends) > 0 and table.concat(p.depends, "  ") or "None"))
                print("Install Size    : " .. kb(p.isize or 50))
                print("Install Date    : " .. (os.date and os.date("%a %d %b %Y %I:%M:%S %p UTC") or "?"))
                print("Install Reason  : Explicitly installed")
                print("Install Script  : No")
                print("Validated By    : SHA-256 Sum  Signature")
                return
            end
            if flags.l and rest[1] then
                local p = INST[rest[1]] or find_pkg(rest[1])
                if not p then
                    print("error: package '" .. rest[1] .. "' was not found")
                    ctx.ok = false
                    return
                end
                for i = 1, #(p.commands or {}) do
                    print(p.name .. " /usr/bin/" .. p.commands[i])
                end
                return
            end
            local names = {}
            for n in pairs(INST) do
                names[#names + 1] = n
            end
            table.sort(names)
            for i = 1, #names do
                local p = INST[names[i]]
                print(p.name .. " " .. p.ver)
            end
            return
        end

        -- -R remove
        if flags.R then
            if #rest == 0 then
                print("error: no targets specified (use -h for help)")
                ctx.ok = false
                return
            end
            print("")
            print("Packages (" .. tostring(#rest) .. ")  " .. table.concat(rest, "  "))
            print("")
            write(":: Do you want to remove these packages? [Y/n] ")
            if not noconfirm then
                local a = read()
                if a and a ~= "" and a:lower():sub(1, 1) ~= "y" then
                    print("error: interrupted by user")
                    ctx.ok = false
                    return
                end
            else
                print("Y")
            end
            print(":: Processing package changes...")
            for i = 1, #rest do
                local name = rest[i]
                if not INST[name] then
                    print("error: target not found: " .. name)
                    ctx.ok = false
                else
                    print("(" .. i .. "/" .. #rest .. ") removing " .. name .. " [" .. INST[name].ver .. "]")
                    V.remove(local_path(INST[name]))
                    INST[name] = nil
                    sleep(0)
                end
            end
            print(":: Running post-transaction hooks...")
            print("(1/1) Arming ConditionNeedsUpdate...")
            return
        end

        -- -S sync
        if flags.S or flags.y or flags.u then
            if flags.y then
                print(":: Synchronizing package databases...")
                write(" core is up to date")
                print("")
                write(" extra")
                sleep(0)
                print("                  312.0 KiB  2.00 MiB/s 00:00  [######################] 100%")
                print(":: Mirror https://github.com/vanyachickenganidanya-lgtm/pacmanlinuxcraftos")
                local ok, msg = try_http_sync()
                if ok then
                    print(":: remote packages.lua: " .. tostring(msg) .. " entries")
                else
                    print("warning: " .. tostring(msg) .. " — using builtin extra repo")
                end
            end
            if flags.s then
                local q = (rest[1] or ""):lower()
                local all = all_pkgs()
                for i = 1, #all do
                    local p = all[i]
                    if q == "" or p.name:find(q, 1, true) or (p.desc or ""):lower():find(q, 1, true) then
                        local mark = INST[p.name] and "[installed]" or ""
                        print(p.repo .. "/" .. p.name .. " " .. p.ver .. " " .. mark)
                        print("    " .. p.desc)
                    end
                end
                return
            end
            if flags.i and rest[1] then
                local p = find_pkg(rest[1])
                if not p then
                    print("error: package '" .. rest[1] .. "' was not found")
                    ctx.ok = false
                    return
                end
                print("Repository      : " .. p.repo)
                print("Name            : " .. p.name)
                print("Version         : " .. p.ver)
                print("Description     : " .. p.desc)
                print("Architecture    : cc")
                print("URL             : https://github.com/vanyachickenganidanya-lgtm/pacmanlinuxcraftos")
                print("Licenses        : GPL")
                print("Groups          : " .. (#p.groups > 0 and table.concat(p.groups, " ") or "None"))
                print("Provides        : None")
                print("Depends On      : " .. (#p.depends > 0 and table.concat(p.depends, "  ") or "None"))
                print("Optional Deps   : None")
                print("Conflicts With  : None")
                print("Replaces        : None")
                print("Download Size   : " .. kb(math.floor((p.isize or 50) * 0.4)))
                print("Installed Size  : " .. kb(p.isize or 50))
                print("Packager        : ccLinux <root@cclinux>")
                print("Validated By    : SHA-256 Sum  Signature")
                return
            end
            if flags.u and #rest == 0 then
                print(":: Starting full system upgrade...")
                print(" there is nothing to do")
                return
            end
            if #rest == 0 and not flags.u then
                if flags.y then
                    return
                end
                print("error: no targets specified (use -h for help)")
                ctx.ok = false
                return
            end
            local to_install = {}
            local seen = {}
            for i = 1, #rest do
                local name = rest[i]
                if INST[name] and not flags.u then
                    print("warning: " .. name .. "-" .. INST[name].ver .. " is up to date -- skipping")
                else
                    local acc, missing = resolve(name, {}, seen)
                    if missing then
                        print("error: target not found: " .. missing)
                        ctx.ok = false
                        return
                    end
                    for j = 1, #acc do
                        to_install[#to_install + 1] = acc[j]
                    end
                end
            end
            if #to_install == 0 then
                print(" there is nothing to do")
                return
            end
            print("resolving dependencies...")
            print("looking for conflicting packages...")
            print("")
            local names = {}
            local dl, inst = 0, 0
            for i = 1, #to_install do
                local p = to_install[i]
                names[#names + 1] = p.name .. "-" .. p.ver
                dl = dl + math.floor((p.isize or 50) * 0.4)
                inst = inst + (p.isize or 50)
            end
            print("Packages (" .. tostring(#to_install) .. ") " .. table.concat(names, "  "))
            print("")
            print("Total Download Size:   " .. kb(dl))
            print("Total Installed Size:  " .. kb(inst))
            print("")
            if not confirm(noconfirm) then
                print("error: interrupted by user")
                ctx.ok = false
                return
            end
            print(":: Retrieving packages...")
            for i = 1, #to_install do
                local p = to_install[i]
                print(" " .. p.repo .. "/" .. p.name .. "-" .. p.ver .. "-cc  " .. kb(math.floor((p.isize or 50) * 0.4)) .. "  2.00 MiB/s 00:00 [######################] 100%")
                sleep(0)
            end
            print(":: Running pre-transaction hooks...")
            print("(1/1) Performing snapper pre snapshots for the following configurations...")
            print(":: Processing package changes...")
            for i = 1, #to_install do
                local p = to_install[i]
                print("(" .. i .. "/" .. #to_install .. ") installing " .. p.name .. "...")
                INST[p.name] = p
                save_local(V, p)
                for c = 1, #(p.commands or {}) do
                    V.write("/usr/bin/" .. p.commands[c], "# " .. p.commands[c] .. " provided by " .. p.name .. " " .. p.ver .. "\n", "w")
                end
                sleep(0)
            end
            print(":: Running post-transaction hooks...")
            print("(1/2) Arming ConditionNeedsUpdate...")
            print("(2/2) Reloading system manager configuration...")
            return
        end

        print("error: no operation specified (use -h for help)")
        ctx.ok = false
    end

    cmds.pacman = pacman
    cmds.yay = function(args, ctx)
        print("yay: wrapping pacman")
        pacman(args, ctx)
    end
    cmds.paru = cmds.yay
    cmds["pacman-key"] = function()
        print("pacman-key: gpg directory /etc/pacman.d/gnupg")
        print("Locally signed 1 key.")
        print("==> Updating trust database...")
        print("gpg: next trustdb check due in 3 months")
    end
    cmds.repo_add = function()
        print("repo-add: use GitHub mirror pacmanlinuxcraftos")
    end
    cmds.makepkg = function(args, ctx)
        print("==> Making package: custom-pkg 1.0.0-1 (cc)")
        print("==> Checking runtime dependencies...")
        print("==> Checking buildtime dependencies...")
        print("==> Missing PKGBUILD file")
        ctx.ok = false
    end
end

return Pac
]===] },
    { "/linux/dos.lua", [===[
-- FreeDOS-like TTY (GRUB extra OS). No GUI.

local D = {}

local function setup()
    term.setBackgroundColor(colors.black)
    term.setTextColor(colors.white)
    term.setCursorBlink(true)
    term.clear()
    term.setCursorPos(1, 1)
end

function D.run()
    setup()
    print("FreeCOM 0.85a CVS")
    print("FreeDOS kernel 2043 (build 2043)")
    print("")
    print("Starting FreeDOS...")
    print("")
    local cwd = "C:\\"
    while true do
        write(cwd .. ">")
        local ok, line = pcall(read)
        if not ok or line == nil then
            print("")
            return
        end
        line = line:gsub("^%s+", ""):gsub("%s+$", "")
        local cmd = line:lower()
        local name = cmd:match("^(%S+)") or ""
        local arg = line:match("^%S+%s+(.*)") or ""
        if name == "" then
            -- none
        elseif name == "ver" then
            print("FreeDOS version 1.3")
            print("FreeCOM version 0.85a")
        elseif name == "cls" then
            term.clear()
            term.setCursorPos(1, 1)
        elseif name == "dir" then
            print(" Volume in drive C is FREEDOS")
            print(" Directory of " .. cwd)
            print("")
            print("AUTOEXEC BAT     128  08-31-26  12:00a")
            print("COMMAND  COM   66890  08-31-26  12:00a")
            print("KERNEL   SYS   47000  08-31-26  12:00a")
            print("CONFIG   SYS     256  08-31-26  12:00a")
            print("         4 file(s)     114274 bytes")
        elseif name == "echo" then
            print(arg)
        elseif name == "type" then
            print("File not found")
        elseif name == "help" then
            print("CLS DIR ECHO VER TYPE CD REBOOT EXIT LINUX HELP")
        elseif name == "cd" then
            if arg ~= "" then
                cwd = "C:\\" .. arg:upper()
            else
                print(cwd)
            end
        elseif name == "reboot" then
            os.reboot()
        elseif name == "exit" or name == "linux" then
            return
        else
            print("Bad command or file name")
        end
    end
end

return D
]===] },
    { "/linux/rootfs/etc/os-release", [===[
PRETTY_NAME="ccLinux 6.12 (CC: Tweaked)"
NAME="ccLinux"
VERSION="6.12"
ID=cclinux
VERSION_ID="6.12"
HOME_URL="https://tweaked.cc"
ANSI_COLOR="1;34"
]===] },
    { "/linux/rootfs/etc/motd", [===[

Welcome to ccLinux 6.12 (GNU/Linux 6.12.0-cclinux)

 * Documentation:  help
 * Kernel panic:   panic   or   echo c > /proc/sysrq-trigger
 * Poweroff:       poweroff    Reboot: reboot
 * CraftOS files:  /mnt/craftos
]===] },


}

local function install(reboot_after)
    banner()
    color(colors.lime)
    print("Installing ccLinux...")
    color(colors.lightGray)
    print("kernel, pacman, FHS, GRUB, extra userland")
    print("")
    local total = #files
    for i = 1, total do
        local path, data = files[i][1], files[i][2]
        writeFile(path, data)
        color(colors.white)
        write(string.format("  [%2d/%d] ", i, total))
        print(path)
        sleep(0)
    end
    print("")
    color(colors.lime)
    print(tostring(total) .. " files written.")
    color(colors.lightGray)
    print("  /startup.lua  boots GRUB")
    print("  /linux/       kernel + pacman + shell")
    print("")
    print("GRUB menu:")
    print("  ccLinux  |  Arch  |  Debian  |  recovery")
    print("  FreeDOS  |  Memtest86+  |  CraftOS")
    print("")
    print("pacman:  pacman -Syu")
    print("mirror:  github.com/vanyachickenganidanya-lgtm/pacmanlinuxcraftos")
    print("")
    if reboot_after then
        color(colors.yellow)
        print("Rebooting into GRUB in 2 seconds...")
        color(colors.lightGray)
        sleep(2)
        os.reboot()
    else
        print("Installed. Type  reboot  when ready.")
    end
end

local function menu()
    while true do
        banner()
        print("  1) Install ccLinux and reboot")
        print("  2) Install without reboot")
        print("  3) Uninstall ccLinux")
        print("  4) Exit")
        print("")
        write("> ")
        local a = read()
        a = a and a:gsub("%s+", "") or ""
        if a == "1" then
            install(true)
            return
        elseif a == "2" then
            install(false)
            return
        elseif a == "3" then
            uninstall()
            return
        elseif a == "4" or a == "q" or a == "quit" then
            print("Aborted.")
            return
        end
    end
end

if mode == "auto" then
    install(true)
elseif mode == "noreboot" then
    install(false)
elseif mode == "uninstall" then
    uninstall()
else
    menu()
end
