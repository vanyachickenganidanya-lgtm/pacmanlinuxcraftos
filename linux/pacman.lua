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
