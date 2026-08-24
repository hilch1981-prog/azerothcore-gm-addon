AzerothAdminEasy = AzerothAdminEasy or {}
local addon = AzerothAdminEasy
if not addon.RegisterLocale then return end

addon:RegisterLocale("koKR", {
    BANK_FRAME_LOAD_FAILED = "기본 은행 프레임을 불러오지 못했습니다.",
    BANK_COMMAND_SEND_FAILED = "원격 은행 명령을 전송하지 못했습니다.",
})
