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
