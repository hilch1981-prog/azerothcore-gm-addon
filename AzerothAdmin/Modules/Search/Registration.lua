AzerothAdminEasy = AzerothAdminEasy or {}
local addon = AzerothAdminEasy
if not addon.RegisterModule then return end

addon:RegisterModule("search", {
    status = "module-active-translation-pending",
    dependencies = { "shell" },
    runtimeFiles = { "AzerothAdmin/Modules/Search/Module.lua", "AzerothAdmin/Modules/Search/Registration.lua" },
    dataFiles = { "AzerothAdmin/KoKRSearchData.lua" },
    tests = { "tools/test_popup_layer_lifecycle.py" },
    futurePath = "AzerothAdmin/Modules/Search",
})
