AzerothAdminEasy = AzerothAdminEasy or {}
local addon = AzerothAdminEasy
if not addon.RegisterLocale then return end

addon:RegisterLocale("ruRU", {
    BANK_FRAME_LOAD_FAILED = "Не удалось загрузить стандартное окно банка.",
    BANK_COMMAND_SEND_FAILED = "Не удалось отправить команду удалённого банка.",
})
