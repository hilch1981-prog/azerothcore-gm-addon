local A = AzerothAdminAC335
local QUICK_ORDER = { "auto", "koKR", "enUS", "zhCN", "zhTW", "ruRU" }
local QUICK_LABELS = { auto = "AUTO", koKR = "KO", enUS = "EN", zhCN = "CN", zhTW = "TW", ruRU = "RU" }

local function localeDisplay(locale)
    return QUICK_LABELS[locale] or tostring(locale or "AUTO")
end

function A:RefreshLanguageMinibarButton()
    local button = self.languageMinibarButton
    if not button then return end
    local current = self:GetConfiguredLocaleOverride()
    button:SetText(localeDisplay(current))
    button.aaeTitle = self:L("LANGUAGE_BUTTON_TITLE")
    button.aaeHint = self:L("LANGUAGE_BUTTON_HINT", localeDisplay(current))
end

function A:CreateLanguageMinibarButton()
    if self.languageMinibarButton then self:RefreshLanguageMinibarButton(); return self.languageMinibarButton end
    if not self.toolbar or not self.UI then return nil end
    local button = self.UI:Button(self.toolbar, 48, 24, "AUTO", "utility")
    button:SetPoint("LEFT", self.toolbar, "RIGHT", 6, 0)
    button:SetFrameStrata("HIGH")
    button:SetScript("OnEnter", function(self)
        A.UI:ShowHint(self, self.aaeTitle or A:L("LANGUAGE_BUTTON_TITLE"), self.aaeHint or A:L("LANGUAGE_BUTTON_HINT", self:GetText()), "ANCHOR_RIGHT")
    end)
    button:SetScript("OnLeave", function() GameTooltip:Hide() end)
    button:SetScript("OnClick", function()
        local nextLocale = A:CycleLocale()
        if nextLocale then
            A:RefreshLanguageMinibarButton()
            if ReloadUI then ReloadUI() elseif A.RefreshLocalizedUI then A:RefreshLocalizedUI() end
        end
    end)
    self.languageMinibarButton = button
    self:RefreshLanguageMinibarButton()
    return button
end

function A:OpenLanguageWindow()
    local frame = self.windows.language
    if not frame then
        frame = self.UI:CreateWindow("language", self:L("LANGUAGE"), 440, 290)
        frame.localeButtons = {}
        for index, locale in ipairs(QUICK_ORDER) do
            local selectedLocale = locale
            local button = self.UI:Button(frame, 62, 26, localeDisplay(locale), "utility")
            button:SetPoint("TOPLEFT", frame, "TOPLEFT", 18 + (index - 1) * 67, -60)
            button:SetScript("OnClick", function()
                if A:SetLocale(selectedLocale) then
                    A:RefreshLanguageMinibarButton()
                    if ReloadUI then ReloadUI() elseif A.RefreshLocalizedUI then A:RefreshLocalizedUI() end
                end
            end)
            frame.localeButtons[index] = button
        end
        local current = self.UI:Text(frame, "", "small")
        current:SetPoint("TOPLEFT", frame, "TOPLEFT", 18, -101); current:SetWidth(400); current:SetJustifyH("LEFT")
        current:SetTextColor(0.55, 0.88, 0.92); frame.currentLocale = current
        local label = self.UI:Text(frame, self:L("SECURITY_TARGET", self:GetAccountSecurity()), "normal")
        label:SetPoint("TOPLEFT", frame, "TOPLEFT", 18, -137); frame.securityLabel = label
        local box = self.UI:EditBox(frame, 80, 24)
        box:SetPoint("TOPLEFT", frame, "TOPLEFT", 18, -166); box:SetText(tostring(self:GetAccountSecurity())); frame.securityBox = box
        local apply = self.UI:Button(frame, 90, 24, self:L("RUN"), "reward")
        apply:SetPoint("LEFT", box, "RIGHT", 8, 0)
        apply:SetScript("OnClick", function()
            A:SetAccountSecurity(box:GetText())
            label:SetText(A:L("SECURITY_TARGET", A:GetAccountSecurity()))
        end)
        local note = self.UI:Text(frame, self:L("ACCOUNT_9_NOTE"), "small")
        note:SetPoint("TOPLEFT", frame, "TOPLEFT", 18, -207); note:SetWidth(400); note:SetJustifyH("LEFT")
    end
    frame.aaeTitle:SetText(self:L("LANGUAGE"))
    frame.securityLabel:SetText(self:L("SECURITY_TARGET", self:GetAccountSecurity()))
    frame.currentLocale:SetText(self:L("LANGUAGE_CURRENT_MODE", localeDisplay(self:GetConfiguredLocaleOverride()), self:GetConfiguredLocale()))
    self.UI:ShowWindow(frame)
end

SLASH_AZEROTHADMINLANG1 = "/aalang"
SlashCmdList["AZEROTHADMINLANG"] = function()
    local nextLocale = A:CycleLocale()
    if nextLocale and ReloadUI then ReloadUI() end
end
