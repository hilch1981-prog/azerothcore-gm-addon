AzerothAdminEasy = AzerothAdminEasy or {}
local addon = AzerothAdminEasy

if addon.RegisterModule and not addon:GetModule("quest-helper") then
    addon:RegisterModule("quest-helper", {
        status = "module-active-translation-pending",
        dependencies = { "shell", "teleports" },
        runtimeFiles = {
            "Modules/QuestHelper/Module.lua",
            "Modules/QuestHelper/Registration.lua",
        },
        dataFiles = {},
        tests = {
            "tools/test_quest_drop_source_cycle.py",
            "tools/test_party_bot_quest_sync.py",
        },
        futurePath = "AzerothAdmin/Modules/QuestHelper",
    })
end
