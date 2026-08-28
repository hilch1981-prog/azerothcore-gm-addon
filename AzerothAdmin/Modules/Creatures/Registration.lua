AzerothAdminEasy = AzerothAdminEasy or {}
local addon = AzerothAdminEasy
if not addon.RegisterModule then return end

addon:RegisterModule("creatures", {
    status = "module-active-game-test-pending",
    dependencies = { "shell", "search", "teleports" },
    runtimeFiles = {
        "AzerothAdmin/Modules/Creatures/Browser.lua",
        "AzerothAdmin/Modules/Creatures/Fixes.lua",
        "AzerothAdmin/Modules/Creatures/RuntimeFixes.lua",
        "AzerothAdmin/Modules/Creatures/Registration.lua",
    },
    dataFiles = {
        "AzerothAdmin/Modules/Creatures/Data.lua",
        "AzerothAdmin/Modules/Creatures/ExpandedData.lua",
    },
    tests = { "tools/test_featured_creature_browser.py" },
    futurePath = "AzerothAdmin/Modules/Creatures",
})
