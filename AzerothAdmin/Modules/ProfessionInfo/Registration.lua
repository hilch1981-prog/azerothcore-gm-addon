AzerothAdminEasy = AzerothAdminEasy or {}
local addon = AzerothAdminEasy

if addon.RegisterModule and not addon:GetModule("profession-info") then
    addon:RegisterModule("profession-info", {
        status = "module-active-embedded-data-core",
        dependencies = { "shell", "language" },
        runtimeFiles = {
            "Modules/ProfessionInfo/UI.lua",
            "Modules/ProfessionInfo/Registration.lua",
        },
        dataFiles = {
            "Embedded/InvenCraftInfo/Core.lua",
            "Embedded/InvenCraftInfoData",
        },
        tests = { "tools/test_craft_frame_lifecycle.py" },
        futurePath = "AzerothAdmin/Modules/ProfessionInfo",
    })
end
