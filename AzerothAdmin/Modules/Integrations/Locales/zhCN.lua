AzerothAdminEasy = AzerothAdminEasy or {}
local addon = AzerothAdminEasy
if not addon.RegisterLocale then return end

addon:RegisterLocale("zhCN", {
    INTEGRATIONS_CRAFT_UI_MISSING = "未找到专业技能信息界面。",
    INTEGRATIONS_ITEM_MODULE_MISSING = "未找到整合物品信息模块。",
    INTEGRATIONS_ITEM_OPEN_FAILED = "无法打开物品信息窗口：%s",
})
