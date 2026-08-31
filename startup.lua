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
