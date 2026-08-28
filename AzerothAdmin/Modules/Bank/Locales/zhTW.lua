AzerothAdminEasy = AzerothAdminEasy or {}
local addon = AzerothAdminEasy
if not addon.RegisterLocale then return end

addon:RegisterLocale("zhTW", {
    BANK_FRAME_LOAD_FAILED = "無法載入原生銀行介面。",
    BANK_COMMAND_SEND_FAILED = "無法傳送遠端銀行命令。",
})
