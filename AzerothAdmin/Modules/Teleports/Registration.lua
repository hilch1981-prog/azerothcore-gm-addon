AzerothAdminEasy = AzerothAdminEasy or {}
local addon = AzerothAdminEasy
if not addon.RegisterModule then return end

addon:RegisterModule("teleports", {
    status = "module-active-translation-pending",
    dependencies = { "shell", "commands" },
    runtimeFiles = { "AzerothAdmin/Modules/Teleports/Module.lua", "AzerothAdmin/Modules/Teleports/Registration.lua" },
    dataFiles = { "AzerothAdmin/Teleports.lua" },
    tests = {},
    futurePath = "AzerothAdmin/Modules/Teleports",
})
