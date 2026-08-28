AzerothAdminEasy = AzerothAdminEasy or {}
local addon = AzerothAdminEasy

if addon.RegisterModule and not addon:GetModule("language") then
    addon:RegisterModule("language", {
        status = "foundation-active-runtime-ui-localization",
        dependencies = {},
        runtimeFiles = {
            "Framework/Localization.lua",
            "Framework/UILocalization.lua",
            "Framework/FeatureLocalization.lua",
            "Locale.lua",
            "Modules/Language/Module.lua",
            "Modules/Language/Output.lua",
        },
        dataFiles = {
            "Locales/enUS.lua",
            "Locales/koKR.lua",
            "Locales/zhCN.lua",
            "Locales/zhTW.lua",
            "Locales/UI",
        },
        tests = {
            "tools/test_module_architecture.py",
            "tools/test_language_minibar.py",
            "tools/test_runtime_ui_localization.py",
        },
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

local LANGUAGE_ORDER = { "auto", "koKR", "enUS", "zhCN", "zhTW" }
local LANGUAGE_LABELS = {
    auto = "AUTO",
    koKR = "KO",
    enUS = "EN",
    zhCN = "简",
    zhTW = "繁",
}

local function configuredLanguage()
    if AzerothAdminEasyDB and AzerothAdminEasyDB.localeOverride then
        return AzerothAdminEasyDB.localeOverride
    end
    return "auto"
end

local function nextLanguage(current)
    local i
    for i = 1, table.getn(LANGUAGE_ORDER) do
        if LANGUAGE_ORDER[i] == current then
            return LANGUAGE_ORDER[(i % table.getn(LANGUAGE_ORDER)) + 1]
        end
    end
    return "auto"
end

local function refreshLanguageButton(button)
    if not button then return end
    local configured = configuredLanguage()
    local label = LANGUAGE_LABELS[configured] or string.upper(string.sub(configured, 1, 2))
    if button.aaeLabel then
        button.aaeLabel:SetText(label)
    end
    button.aaeConfiguredLocale = configured
end

function addon:CreateLanguageMinibarButton()
    if self.languageMinibarButton then
        refreshLanguageButton(self.languageMinibarButton)
        return true
    end

    local toolbar = self.toolbar or _G.AzerothAdminTurtleStyleToolbar
    if not toolbar then return false end

    local button = CreateFrame("Button", "AzerothAdminLanguageMinibarButton", toolbar)
    button:SetWidth(42)
    button:SetHeight(24)
    button:SetPoint("LEFT", toolbar, "RIGHT", 6, 0)
    button:SetFrameStrata("HIGH")
    button:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 8,
        edgeSize = 8,
        insets = { left = 2, right = 2, top = 2, bottom = 2 },
    })
    button:SetBackdropColor(0.035, 0.09, 0.11, 1)
    button:SetBackdropBorderColor(0.12, 0.63, 0.68, 1)

    local label = button:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    label:SetPoint("CENTER", button, "CENTER", 0, 0)
    button.aaeLabel = label
    refreshLanguageButton(button)

    button:SetScript("OnEnter", function(self)
        self:SetBackdropBorderColor(0.22, 0.88, 0.95, 1)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:SetText(addon:T("LANGUAGE_BUTTON_TITLE"), 1, 0.82, 0)
        GameTooltip:AddLine(addon:T("LANGUAGE_BUTTON_HINT", addon.ActiveLocale or "enUS"), 1, 1, 1, true)
        GameTooltip:Show()
    end)
    button:SetScript("OnLeave", function(self)
        self:SetBackdropBorderColor(0.12, 0.63, 0.68, 1)
        GameTooltip:Hide()
    end)
    button:SetScript("OnClick", function(self)
        local requested = nextLanguage(configuredLanguage())
        if not addon:SetLocaleOverride(requested) then
            printLine(addon:T("LANGUAGE_UNSUPPORTED"), true)
            return
        end
        refreshLanguageButton(self)
        printLine(addon:T("LANGUAGE_SAVED", requested))
        if ReloadUI then ReloadUI() end
    end)

    self.languageMinibarButton = button
    return true
end

local attachFrame = CreateFrame("Frame")
attachFrame:SetScript("OnUpdate", function(self)
    if addon:CreateLanguageMinibarButton() then
        self:SetScript("OnUpdate", nil)
    end
end)

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
