AzerothAdminEasy = AzerothAdminEasy or {}
local addon = AzerothAdminEasy
if not addon.RegisterModule then return end

addon:RegisterModule("integrations", {
    status = "module-active",
    dependencies = { "shell", "item-browser", "profession-info" },
    runtimeFiles = { "AzerothAdmin/Modules/Integrations/Module.lua", "AzerothAdmin/Modules/Integrations/Registration.lua" },
    dataFiles = {},
    tests = { "tools/test_craft_frame_lifecycle.py", "tools/test_remote_bank_flow.py" },
    futurePath = "AzerothAdmin/Modules/Integrations",
})
