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
