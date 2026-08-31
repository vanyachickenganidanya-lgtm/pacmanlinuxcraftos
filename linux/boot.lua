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
