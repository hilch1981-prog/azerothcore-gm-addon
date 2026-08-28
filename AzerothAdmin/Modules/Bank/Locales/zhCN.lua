AzerothAdminEasy = AzerothAdminEasy or {}
local addon = AzerothAdminEasy
if not addon.RegisterLocale then return end

addon:RegisterLocale("zhCN", {
    BANK_FRAME_LOAD_FAILED = "无法加载原生银行界面。",
    BANK_COMMAND_SEND_FAILED = "无法发送远程银行命令。",
})
