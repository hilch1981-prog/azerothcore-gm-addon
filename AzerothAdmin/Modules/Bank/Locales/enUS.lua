AzerothAdminEasy = AzerothAdminEasy or {}
local addon = AzerothAdminEasy
if not addon.RegisterLocale then return end

addon:RegisterLocale("enUS", {
    BANK_FRAME_LOAD_FAILED = "Could not load the native bank frame.",
    BANK_COMMAND_SEND_FAILED = "Could not send the remote bank command.",
})
