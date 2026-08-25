AzerothAdminEasy = AzerothAdminEasy or {}
local addon = AzerothAdminEasy
if not addon.RegisterLocale then return end

addon:RegisterLocale("zhTW", {
    INTEGRATIONS_CRAFT_UI_MISSING = "找不到專業技能資訊介面。",
    INTEGRATIONS_ITEM_MODULE_MISSING = "找不到整合物品資訊模組。",
    INTEGRATIONS_ITEM_OPEN_FAILED = "無法開啟物品資訊視窗：%s",
})
