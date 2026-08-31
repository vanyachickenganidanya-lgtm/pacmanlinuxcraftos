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
@@FILES@@

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
