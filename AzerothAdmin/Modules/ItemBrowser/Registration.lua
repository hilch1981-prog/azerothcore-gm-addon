AzerothAdminEasy = AzerothAdminEasy or {}
local addon = AzerothAdminEasy

if addon.RegisterModule and not addon:GetModule("item-browser") then
    addon:RegisterModule("item-browser", {
        status = "module-active-translation-pending",
        dependencies = { "shell", "language" },
        runtimeFiles = {
            "Modules/ItemBrowser/Module.lua",
            "Modules/ItemBrowser/Registration.lua",
        },
        dataFiles = {
            "Embedded/BlueItemInfo3/Data.lua",
            "Embedded/BlueItemInfo3/CategoryIndex.lua",
            "Embedded/BlueItemInfo3/QuestRewards335.lua",
        },
        tests = {
            "tools/test_generate_quest_reward_335.py",
            "tools/test_profession_enhancement_categories.py",
        },
        futurePath = "AzerothAdmin/Modules/ItemBrowser",
    })
end
