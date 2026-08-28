AzerothAdminEasy = AzerothAdminEasy or {}
local addon = AzerothAdminEasy
if not addon.RegisterLocale then return end

addon:RegisterLocale("koKR", {
    INTEGRATIONS_CRAFT_UI_MISSING = "전문기술 정보 UI를 찾지 못했습니다.",
    INTEGRATIONS_ITEM_MODULE_MISSING = "통합 아이템 정보 모듈을 찾지 못했습니다.",
    INTEGRATIONS_ITEM_OPEN_FAILED = "아이템 정보 창을 열지 못했습니다: %s",
})
