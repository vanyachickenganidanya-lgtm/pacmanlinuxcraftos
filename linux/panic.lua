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
