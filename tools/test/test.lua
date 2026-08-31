-- ccLinux host-side smoke tests (run with: lua tools/test/test.lua)
--
-- 1. install.lua round-trip: the single-file installer must reproduce the
--    repo sources byte-for-byte on a fresh "computer disk", and `uninstall`
--    must remove them again.
-- 2. Module wiring: kernel/vfs/pacman/commands/extra/shell register and run.
-- 3. boot.lua: file provisioning + GRUB abort path.
-- 4. packages.lua: valid mirror database with required fields.
--
-- NOTE: all output assertions use PLAIN string search (find(s, 1, true))
-- because expected fragments contain Lua pattern magic chars ('.', '-').

local function repo_root()
    local s = arg and arg[0] or ""
    local m = s:match("^(.*/)?tools/test/")
    return m or "./"
end
local ROOT = repo_root()

local stub = dofile(ROOT .. "tools/test/ccstub.lua")

local FAILED = 0
local function check(name, cond, detail)
    if cond then
        print("PASS  " .. name)
    else
        FAILED = FAILED + 1
        print("FAIL  " .. name .. (detail and ("  [" .. tostring(detail) .. "]") or ""))
    end
end

local function has(s, sub)
    return s:find(sub, 1, true) ~= nil
end

local function read_file(path)
    local f = assert(io.open(path, "rb"))
    local data = f:read("*a")
    f:close()
    return data
end

local function disk_file(vpath)
    return stub.disk .. (vpath == "/" and "" or vpath)
end

-- ================================================================
-- 1. install.lua round-trip
-- ================================================================
local SOURCES = {
    { "startup.lua", "/startup.lua" },
    { "linux/boot.lua", "/linux/boot.lua" },
    { "linux/kernel.lua", "/linux/kernel.lua" },
    { "linux/panic.lua", "/linux/panic.lua" },
    { "linux/vfs.lua", "/linux/vfs.lua" },
    { "linux/shell.lua", "/linux/shell.lua" },
    { "linux/commands.lua", "/linux/commands.lua" },
    { "linux/extra.lua", "/linux/extra.lua" },
    { "linux/pacman.lua", "/linux/pacman.lua" },
    { "linux/dos.lua", "/linux/dos.lua" },
    { "linux/rootfs/etc/os-release", "/linux/rootfs/etc/os-release" },
    { "linux/rootfs/etc/motd", "/linux/rootfs/etc/motd" },
}

os.execute("rm -rf " .. stub.disk)
os.execute("mkdir -p " .. stub.disk)

local fn = assert(loadfile(ROOT .. "install.lua"))
local ok, err = pcall(fn, "noreboot")
check("install: noreboot completes", ok, err)

local all_same = true
local detail
for i = 1, #SOURCES do
    local repo, disk = SOURCES[i][1], SOURCES[i][2]
    local a = read_file(ROOT .. repo)
    local b = read_file(disk_file(disk))
    if a ~= b then
        all_same = false
        detail = repo .. " differs (" .. #a .. " vs " .. #b .. " bytes)"
        break
    end
end
check("install: all 12 files byte-identical to repo sources", all_same, detail)

-- uninstall
ok, err = pcall(fn, "uninstall")
check("install: uninstall completes", ok, err)
check("install: uninstall removed /linux", not stub.test_dir("/linux"))
check("install: uninstall removed /startup.lua", not stub.test_file("/startup.lua"))

-- ================================================================
-- 2. module wiring
-- ================================================================
local function copy_disk()
    stub.reset_disk()
    for i = 1, #SOURCES do
        local repo, disk = SOURCES[i][1], SOURCES[i][2]
        local dir = disk:match("^(.*)/[^/]*$") or "/"
        os.execute("mkdir -p " .. stub.disk .. dir)
        os.execute("cp " .. ROOT .. repo .. " " .. stub.disk .. disk)
    end
end

copy_disk()

local K = assert(dofile(disk_file("/linux/kernel.lua")))
local V = assert(dofile(disk_file("/linux/vfs.lua")))
local P = assert(dofile(disk_file("/linux/panic.lua")))
local C = assert(dofile(disk_file("/linux/commands.lua")))
local S = assert(dofile(disk_file("/linux/shell.lua")))
local E = assert(dofile(disk_file("/linux/extra.lua")))
local Pac = assert(dofile(disk_file("/linux/pacman.lua")))
local Dos = assert(dofile(disk_file("/linux/dos.lua")))

check("kernel: release", K.release == "6.12.0-cclinux", K.release)
check("kernel: hostname from label", K.hostname == "testbox", K.hostname)
K.seed_procs()
check("kernel: procs seeded", K.procs[1] and K.procs[1].comm == "init")
check("kernel: shell pid", K.shell_pid ~= nil and K.procs[K.shell_pid].comm == "bash")

V.init(K)
check("vfs: rootfs dirs created", V.isDir("/var/lib/pacman/local"))
V.write("/etc/os-release", 'PRETTY_NAME="ccLinux 6.12 (CC: Tweaked)"\nNAME="ccLinux"\n', "w")
check("vfs: write/read /etc", has(V.read("/etc/os-release") or "", "ccLinux 6.12"))
check("vfs: /proc/cpuinfo", has(V.read("/proc/cpuinfo") or "", "CraftOS"))
check("vfs: /dev/zero", (V.read("/dev/zero") or ""):len() == 64)
local rootlist = V.list("/")
local has_proc, has_dev = false, false
for i = 1, #rootlist do
    if rootlist[i] == "proc" then has_proc = true end
    if rootlist[i] == "dev" then has_dev = true end
end
check("vfs: / lists proc+dev", has_proc and has_dev)

Pac.init(V)
local cmds = {}
C.register(cmds, K, V)
E.register(cmds, K, V, Pac)
Pac.register(cmds, K, V)

local ctx = {
    cwd = "/root",
    ok = true,
    exit = false,
    aliases = { ll = "ls -l", la = "ls -la" },
    env = { HOME = "/root", USER = "root", LOGNAME = "root", SHELL = "/bin/bash",
        PATH = "/usr/bin:/bin", PWD = "/root", HOSTNAME = K.hostname,
        TERM = "linux", LANG = "C", SHLVL = "1" },
    history = {},
    stdin = nil,
}

local function run_capture(line)
    local buf = {}
    local op, ow = print, write
    print = function(...)
        local t = {}
        for i = 1, select("#", ...) do
            t[#t + 1] = tostring(select(i, ...))
        end
        buf[#buf + 1] = table.concat(t, "\t") .. "\n"
    end
    write = function(s)
        buf[#buf + 1] = tostring(s)
    end
    local r_ok, r_err = pcall(S.run_line, line, cmds, K, V, ctx)
    print, write = op, ow
    return r_ok, r_err, table.concat(buf)
end

local ok2, err2, out = run_capture("cat /etc/os-release")
check("shell: cat /etc/os-release", ok2 and has(out, "ccLinux 6.12"), err2)

ok2, err2, out = run_capture("ls /")
check("shell: ls /", ok2 and has(out, "bin") and has(out, "etc"), err2)

ok2, err2, out = run_capture("uname -a")
check("shell: uname -a", ok2 and has(out, "Linux testbox 6.12.0-cclinux"), err2)

ok2, err2, out = run_capture("neofetch")
check("shell: neofetch", ok2 and has(out, "ccLinux 6.12 GNU/Linux"), err2)

ok2, err2, out = run_capture("echo hello cc > /tmp/x && cat /tmp/x")
check("shell: echo && cat", ok2 and has(out, "hello cc"), err2)

ok2, err2, out = run_capture("echo alpha | grep alp")
check("shell: pipe grep", ok2 and has(out, "alpha"), err2)

ok2, err2, out = run_capture("ps")
check("shell: ps lists init", ok2 and has(out, "init"), err2)

ok2, err2, out = run_capture("free -h")
check("shell: free -h", ok2 and has(out, "Mem:"), err2)

K.printk("test printk line")
ok2, err2, out = run_capture("dmesg")
check("shell: dmesg", ok2 and has(out, "test printk line"), err2)

ok2, err2, out = run_capture("sysctl -a")
check("shell: sysctl -a", ok2 and has(out, "kernel.osrelease = 6.12.0-cclinux"), err2)

ok2, err2, out = run_capture("pacman -Ss htop")
check("shell: pacman -Ss htop", ok2 and has(out, "extra/htop 3.3.2-1"), err2)

ok2, err2, out = run_capture("pacman -Sy htop")
check("shell: pacman -Sy htop installs",
    ok2 and has(out, "installing htop") and has(out, "http disabled"), err2)
check("shell: htop file written",
    has(read_file(disk_file("/linux/rootfs/usr/bin/htop")) or "", "provided by htop 3.3.2-1"))

ok2, err2, out = run_capture("htop")
check("shell: htop runs after install", ok2 and has(out, "root"), err2)

ok2, err2, out = run_capture("kill 2")
check("shell: kill kernel thread denied", ok2 and has(out, "Operation not permitted"), err2)
check("shell: kill denied sets ok=false", ctx.ok == false)

ok2, err2, out = run_capture("kill 1")
check("shell: kill init -> panic -> shutdown",
    has(tostring(err2) or "", "__CC_SENTINEL_SHUTDOWN__"), err2)

ok2, err2, out = run_capture("cat /proc/cpuinfo")
check("shell: /proc/cpuinfo", ok2 and has(out, "model name"), err2)

ok2, err2, out = run_capture("cd /etc && ls")
check("shell: cd+ls", ok2 and has(out, "os-release"), err2)
ctx.cwd = "/root"

-- panic rendering
K.panic_timeout = 1
K.panic_fn = function(k, reason)
    P.render(k, reason)
end
ok2, err2, out = nil, nil, ""
do
    local buf = {}
    local op, ow = print, write
    print = function(...)
        local t = {}
        for i = 1, select("#", ...) do
            t[#t + 1] = tostring(select(i, ...))
        end
        buf[#buf + 1] = table.concat(t, "\t") .. "\n"
    end
    write = function(s)
        buf[#buf + 1] = tostring(s)
    end
    ok2, err2 = pcall(K.panic, "test panic reason")
    print, write = op, ow
    out = table.concat(buf)
end
check("panic: renders oops + shutdown",
    has(tostring(err2) or "", "__CC_SENTINEL_SHUTDOWN__")
    and has(out, "Kernel panic - not syncing: test panic reason"),
    err2)
K.panic_fn = nil

-- FreeDOS
for i = #stub.read_queue, 1, -1 do
    table.remove(stub.read_queue, i)
end
table.insert(stub.read_queue, "ver")
table.insert(stub.read_queue, "exit")
do
    local buf = {}
    local op, ow = print, write
    print = function(...)
        local t = {}
        for i = 1, select("#", ...) do
            t[#t + 1] = tostring(select(i, ...))
        end
        buf[#buf + 1] = table.concat(t, "\t") .. "\n"
    end
    write = function(s)
        buf[#buf + 1] = tostring(s)
    end
    ok2, err2 = pcall(Dos.run)
    print, write = op, ow
    out = table.concat(buf)
end
check("dos: ver + exit", ok2 and has(out, "FreeDOS version 1.3"), err2)

-- ================================================================
-- 3. boot.lua: provisioning + GRUB abort to CraftOS
-- ================================================================
copy_disk()
stub.use_disk_dofile = true
do
    local buf = {}
    local op, ow = print, write
    print = function(...)
        local t = {}
        for i = 1, select("#", ...) do
            t[#t + 1] = tostring(select(i, ...))
        end
        buf[#buf + 1] = table.concat(t, "\t") .. "\n"
    end
    write = function(s)
        buf[#buf + 1] = tostring(s)
    end
    local okb, errb = pcall(dofile, "/linux/boot.lua")
    print, write = op, ow
    out = table.concat(buf)
    check("boot: loads modules and aborts to CraftOS",
        okb and has(out, "Returned to CraftOS."), errb)
end
stub.use_disk_dofile = false
check("boot: mirrorlist provisioned",
    has(read_file(disk_file("/linux/rootfs/etc/pacman.d/mirrorlist")) or "", "pacmanlinuxcraftos"))
check("boot: grub.cfg provisioned",
    has(read_file(disk_file("/linux/rootfs/boot/grub/grub.cfg")) or "", "menuentry"))
check("boot: motd provisioned",
    has(read_file(disk_file("/linux/rootfs/etc/motd")) or "", "Welcome to ccLinux"))

-- ================================================================
-- 4. packages.lua mirror database
-- ================================================================
local pkgs = assert(dofile(ROOT .. "packages.lua"))
check("packages: is an array", type(pkgs) == "table" and #pkgs > 0, tostring(#pkgs))
local bad
local seen = {}
for i = 1, #pkgs do
    local p = pkgs[i]
    if not (p and type(p.name) == "string" and type(p.ver) == "string"
        and type(p.desc) == "string" and type(p.depends) == "table"
        and type(p.commands) == "table" and type(p.isize) == "number"
        and type(p.groups) == "table") then
        bad = i
        break
    end
    if seen[p.name] then
        bad = "duplicate: " .. p.name
        break
    end
    seen[p.name] = true
end
check("packages: all entries have required fields, no dupes", bad == nil, tostring(bad))

-- ================================================================
print("")
if FAILED == 0 then
    print("ALL TESTS PASSED")
else
    print(FAILED .. " TEST(S) FAILED")
    os.exit(1)
end
