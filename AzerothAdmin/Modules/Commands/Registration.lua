AzerothAdminEasy = AzerothAdminEasy or {}
local addon = AzerothAdminEasy
if not addon.RegisterModule then return end

addon:RegisterModule("commands", {
    status = "module-active-translation-pending",
    dependencies = { "shell" },
    runtimeFiles = {
        "AzerothAdmin/Modules/Commands/CommandMeta.lua",
        "AzerothAdmin/Modules/Commands/Module.lua",
        "AzerothAdmin/Modules/Commands/Registration.lua",
    },
    dataFiles = {},
    tests = { "tools/test_audit_command_meta.py", "tools/test_quickslot_actions.py" },
    futurePath = "AzerothAdmin/Modules/Commands",
})
