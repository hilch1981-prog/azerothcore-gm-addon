AzerothAdminEasy = AzerothAdminEasy or {}
local addon = AzerothAdminEasy
if not addon.RegisterModule then return end

addon:RegisterModule("shell", {
    status = "legacy-migration-pending",
    dependencies = {},
    runtimeFiles = { "Core.lua", "UI.lua", "Locale.lua" },
    dataFiles = {},
    tests = { "tools/test_quickslot_actions.py", "tools/test_popup_layer_lifecycle.py" },
    futurePath = "AzerothAdmin/Modules/Shell",
})
