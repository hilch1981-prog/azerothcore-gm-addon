AzerothAdminEasy = AzerothAdminEasy or {}
local addon = AzerothAdminEasy
if not addon.RegisterModule then return end

addon:RegisterModule("shell", {
    status = "module-active-game-test-pending",
    dependencies = { "language" },
    runtimeFiles = {
        "AzerothAdmin/Modules/Shell/Core.lua",
        "AzerothAdmin/Modules/Shell/UI.lua",
        "AzerothAdmin/Modules/Shell/Registration.lua",
    },
    dataFiles = {},
    tests = {
        "tools/test_quickslot_actions.py",
        "tools/test_popup_layer_lifecycle.py",
        "tools/test_self_revive_flow.py",
    },
    futurePath = "AzerothAdmin/Modules/Shell",
})
