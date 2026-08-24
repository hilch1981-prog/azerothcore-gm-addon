AzerothAdminEasy = AzerothAdminEasy or {}
local addon = AzerothAdminEasy

if addon.RegisterModule and not addon:GetModule("language") then
    addon:RegisterModule("language", {
        status = "foundation-active",
        dependencies = {},
        runtimeFiles = {
            "Framework/Localization.lua",
            "Locale.lua",
            "Modules/Language/Module.lua",
        },
        dataFiles = {
            "Locales/enUS.lua",
            "Locales/koKR.lua",
            "Locales/zhCN.lua",
            "Locales/zhTW.lua",
        },
        tests = { "tools/test_module_architecture.py" },
        futurePath = "AzerothAdmin/Modules/Language",
    })
end

local function printLine(text, isError)
    if addon.Print then
        addon:Print(text, isError)
    elseif DEFAULT_CHAT_FRAME and DEFAULT_CHAT_FRAME.AddMessage then
        DEFAULT_CHAT_FRAME:AddMessage("|cffffd24aAzerothAdmin:|r " .. tostring(text or ""))
    end
end

local function trim(value)
    value = tostring(value or "")
    return string.gsub(value, "^%s*(.-)%s*$", "%1")
end

SlashCmdList = SlashCmdList or {}
SLASH_AZEROTHADMINLANG1 = "/aalang"
SlashCmdList.AZEROTHADMINLANG = function(message)
    local requested = trim(message)
    if requested == "" then
        printLine(addon:T("LANGUAGE_USAGE", addon.ActiveLocale or "enUS"))
        return
    end

    if not addon:SetLocaleOverride(requested) then
        printLine(addon:T("LANGUAGE_UNSUPPORTED"), true)
        return
    end

    printLine(addon:T("LANGUAGE_SAVED", requested))
    if ReloadUI then ReloadUI() end
end
