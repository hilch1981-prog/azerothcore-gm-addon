AzerothAdminEasy = AzerothAdminEasy or {}
local addon = AzerothAdminEasy

addon.UILiteralPacks = addon.UILiteralPacks or {}
addon.UIPatternPacks = addon.UIPatternPacks or {}

function addon:RegisterUILiterals(locale, values, patterns)
    if not locale or type(values) ~= "table" then return false end
    self.UILiteralPacks[locale] = self.UILiteralPacks[locale] or {}
    local key, value
    for key, value in pairs(values) do
        self.UILiteralPacks[locale][key] = value
    end
    if type(patterns) == "table" then
        self.UIPatternPacks[locale] = self.UIPatternPacks[locale] or {}
        local i
        for i = 1, table.getn(patterns) do
            table.insert(self.UIPatternPacks[locale], patterns[i])
        end
    end
    return true
end

function addon:TranslateUI(text)
    text = tostring(text or "")
    if text == "" or self.ActiveLocale == "koKR" then return text end
    local locale = self.ActiveLocale or "enUS"
    local pack = self.UILiteralPacks[locale] or self.UILiteralPacks.enUS or {}
    local exact = pack[text]
    if exact then return exact end
    local patterns = self.UIPatternPacks[locale] or self.UIPatternPacks.enUS or {}
    local translated = text
    local i
    for i = 1, table.getn(patterns) do
        local rule = patterns[i]
        if type(rule) == "table" and rule[1] and rule[2] and string.find(translated, rule[1]) then
            translated = string.gsub(translated, rule[1], rule[2])
        end
    end
    return translated
end

local function localizeField(frame, key)
    local current = frame and frame[key]
    if type(current) ~= "string" or current == "" then return end
    local translated = addon:TranslateUI(current)
    if translated ~= current then frame[key] = translated end
end

local function localizeRegions(frame)
    if not frame then return end
    localizeField(frame, "aaeHint")
    localizeField(frame, "aaeTitle")
    localizeField(frame, "tooltipText")
    localizeField(frame, "tooltipTitle")
    if not frame.GetRegions then return end
    local regions = { frame:GetRegions() }
    local i
    for i = 1, table.getn(regions) do
        local region = regions[i]
        if region and region.GetObjectType and region:GetObjectType() == "FontString"
            and region.GetText and region.SetText then
            local current = region:GetText()
            if current and current ~= "" then
                local translated = addon:TranslateUI(current)
                if translated ~= current then region:SetText(translated) end
            end
        end
    end
end

function addon:LocalizeFrame(root)
    if not root or self.ActiveLocale == "koKR" then return end
    local seen = {}
    local function scan(frame, depth)
        if not frame or seen[frame] or depth > 12 then return end
        seen[frame] = true
        localizeRegions(frame)
        if frame.GetChildren then
            local children = { frame:GetChildren() }
            local i
            for i = 1, table.getn(children) do scan(children[i], depth + 1) end
        end
    end
    scan(root, 0)
end

function addon:LocalizeVisibleFrames()
    if self.ActiveLocale == "koKR" then return end
    local frames = {
        self.frame,
        self.toolbar,
        self.localeSearchFrame,
        self.questHelperFrame,
        self.creatureBrowserFrame,
        _G.AzerothAdminCraftInfoFrame,
        _G.BlueItemInfo3,
    }
    local i
    for i = 1, table.getn(frames) do
        local frame = frames[i]
        if frame and frame.IsShown and frame:IsShown() then self:LocalizeFrame(frame) end
    end
end
