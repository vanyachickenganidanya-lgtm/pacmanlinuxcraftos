-- Minimal CC: Tweaked API stub for host-side smoke tests.
--
-- Backs the virtual "computer disk" with a real directory (env CCLINUX_TEST_DISK
-- or /tmp/cctest/disk). Only implements the API surface used by the ccLinux
-- modules, with CC:T semantics (fs.open "w"/"a" creates the file, term is
-- monochrome, os.shutdown/os.reboot raise sentinels).
--
-- Load order: dofile this file FIRST; it installs the stubs as globals.

local stub = {}

stub.disk = os.getenv("CCLINUX_TEST_DISK") or "/tmp/cctest/disk"

local function q(p)
    return "'" .. tostring(p):gsub("'", [['"']]) .. "'"
end

local function real(path)
    path = tostring(path or "/")
    if path == "/" then
        return stub.disk
    end
    return stub.disk .. path
end

-- os.execute returns (true, "exit", code) on 5.3+ but just the code on 5.2
local function sh_ok(cmd)
    local a, b, c = os.execute(cmd)
    if type(a) == "number" then
        return a == 0
    end
    return a == true and c == 0
end

local function is_dir(path)
    return sh_ok("test -d " .. q(real(path)))
end

local function is_file(path)
    return sh_ok("test -f " .. q(real(path)))
end

local read_queue = {}
stub.read_queue = read_queue

function stub.reset_disk()
    os.execute("rm -rf " .. q(stub.disk))
    os.execute("mkdir -p " .. q(stub.disk))
end

function stub.test_dir(vpath)
    return is_dir(vpath)
end

function stub.test_file(vpath)
    return is_file(vpath)
end

-- ---------------------------------------------------------------- fs
local fs = {}

function fs.exists(path)
    return is_dir(path) or is_file(path)
end

function fs.isDir(path)
    return is_dir(path)
end

function fs.makeDir(path)
    os.execute("mkdir -p " .. q(real(path)))
end

function fs.delete(path)
    if not fs.exists(path) then
        error("No such file or directory", 2)
    end
    return os.execute("rm -rf " .. q(real(path))) == 0
end

function fs.combine(a, b)
    if b:sub(1, 1) == "/" then
        return b
    end
    if a == "/" then
        return "/" .. b
    end
    return a .. "/" .. b
end

function fs.getDir(path)
    local d = path:match("^(.*)/[^/]*$")
    if not d then
        return ""
    end
    if d == "" then
        return "/"
    end
    return d
end

function fs.getName(path)
    local n = path:match("/([^/]+)$")
    return n or ""
end

function fs.list(path)
    if not is_dir(path) then
        return nil, "Not a directory"
    end
    local tmp = stub.disk .. "/.__list_tmp"
    os.execute("ls -1A " .. q(real(path)) .. " > " .. q(tmp) .. " 2>/dev/null")
    local names = {}
    local f = io.open(tmp, "r")
    if f then
        for line in f:lines() do
            names[#names + 1] = line
        end
        f:close()
    end
    os.execute("rm -f " .. q(tmp))
    return names
end

local function make_handle(f, mode, path)
    local h = { mode = mode }
    function h.write(s)
        f:write(s)
    end
    function h.readAll()
        if mode == "r" then
            f:seek("set")
            return f:read("*a")
        end
        return nil
    end
    function h.close()
        f:close()
    end
    function h.getSize()
        local pos = f:seek()
        f:seek("end")
        local size = f:seek()
        f:seek("set", pos)
        return size
    end
    return h
end

function fs.open(path, mode)
    mode = mode or "r"
    local rp = real(path)
    if mode == "r" or mode == "rb" then
        local f = io.open(rp, "r")
        if not f then
            return nil, "No such file or directory"
        end
        return make_handle(f, "r", path)
    end
    -- CC:T write modes create the file if missing
    local f = io.open(rp, (mode == "a" or mode == "ab") and "a" or "w")
    if not f then
        return nil, "Permission denied"
    end
    return make_handle(f, "w", path)
end

function fs.getSize(path)
    local f = io.open(real(path), "r")
    if not f then
        return 0
    end
    f:seek("end")
    local size = f:seek()
    f:close()
    return size
end

function fs.attributes(path)
    if not fs.exists(path) then
        return nil, "No such file or directory"
    end
    return { modified = os.time() * 1000 }
end

function fs.getFreeSpace(path)
    return 100000
end

function fs.getCapacity(path)
    return 131072
end

-- ---------------------------------------------------------------- term
local term = {
    isColor = function() return false end,
    setTextColor = function() end,
    setBackgroundColor = function() end,
    clear = function() end,
    setCursorPos = function() end,
    setCursorBlink = function() end,
    setPaletteColor = function() end,
    getSize = function() return 50, 20 end,
}

local colors = {
    black = 1, red = 2, green = 3, white = 4, grey = 5, gray = 5, orange = 6,
    blue = 7, yellow = 8, violet = 9, purple = 9, brown = 10, lightRed = 11,
    lightGreen = 12, lime = 12, lightGrey = 13, lightGray = 13, lightBlue = 14,
    cyan = 15, lightViolet = 16, pink = 16, lightYellow = 17, magenta = 17,
}

local keys = {
    back = 14, tab = 28, enter = 13, shift = 42, ctrl = 29, alt = 56,
    pause = 19, capsLock = 20, esc = 1, space = 46, pageUp = 33, pageDown = 34,
    ["end"] = 35, home = 36, insert = 45, delete = 46, left = 37, up = 38,
    right = 39, down = 40, mouse1 = 141, mouse2 = 142,
}

-- ---------------------------------------------------------------- os extensions
os.startTimer = function() return 1 end
os.epoch = function() return os.time() * 1000 end
os.version = function() return "CraftOS 2 (stub)" end
os.getComputerID = function() return 1 end
os.getComputerLabel = function() return "testbox" end
os.reboot = function() error("__CC_SENTINEL_REBOOT__", 0) end
os.shutdown = function() error("__CC_SENTINEL_SHUTDOWN__", 0) end

local pull_event = nil
function stub.set_pull_event(ev)
    pull_event = ev
end
os.pullEventRaw = function()
    if pull_event then
        return pull_event[1], pull_event[2]
    end
    return "terminate"
end
os.pullEvent = os.pullEventRaw

-- ---------------------------------------------------------------- other globals
function read(...)
    return table.remove(read_queue, 1)
end

function write(s)
    io.stdout:write(tostring(s))
end

function printError(s)
    io.stdout:write(tostring(s) .. "\n")
end

function sleep()
    -- no-op in tests
end

-- install as globals
_G.fs = fs
_G.term = term
_G.colors = colors
_G.keys = keys

-- When enabled, dofile() resolves virtual computer paths (e.g. "/linux/kernel.lua")
-- against the fake disk — that is how boot.lua's loadmod() finds its modules.
local real_dofile = dofile
stub.use_disk_dofile = false
_G.dofile = function(path)
    if stub.use_disk_dofile and type(path) == "string" and path:sub(1, 1) == "/" then
        return real_dofile(stub.disk .. path)
    end
    return real_dofile(path)
end

return stub
