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
