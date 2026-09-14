local A = AzerothAdminAC335
A.locales = A.locales or {}
A.LanguageCycleOrder = { "auto", "koKR", "enUS", "zhCN", "zhTW", "ruRU" }

function A:RegisterLocale(locale, values)
    if type(locale) ~= "string" or type(values) ~= "table" then return end
    self.locales[locale] = self.locales[locale] or {}
    for key, value in pairs(values) do self.locales[locale][key] = value end
end

function A:GetConfiguredLocaleOverride()
    local locale = self:GetDB().locale
    if locale and self.locales[locale] then return locale end
    return "auto"
end

function A:GetConfiguredLocale()
    local override = self:GetConfiguredLocaleOverride()
    if override ~= "auto" then return override end
    local client = GetLocale and GetLocale() or "enUS"
    if self.locales[client] then return client end
    return "enUS"
end

function A:SetLocale(locale)
    locale = self:Trim(locale)
    if locale == "" then locale = "auto" end
    if locale == "auto" then
        self:GetDB().locale = nil
        if self.ResetProfessionLocaleCache then self:ResetProfessionLocaleCache() end
        self:Print(self:L("LOCALE_CHANGED") .. ": AUTO")
        if self.RefreshLocalizedUI then self:RefreshLocalizedUI() end
        return true
    end
    if not self.locales[locale] then
        self:Print(self:L("LANGUAGE_UNSUPPORTED", locale), true)
        return false
    end
    self:GetDB().locale = locale
    if self.ResetProfessionLocaleCache then self:ResetProfessionLocaleCache() end
    local message = (self.locales[locale] and self.locales[locale].LOCALE_CHANGED) or "Locale changed"
    self:Print(message .. ": " .. locale)
    if self.RefreshLocalizedUI then self:RefreshLocalizedUI() end
    return true
end

function A:GetNextLocale(current)
    current = current or self:GetConfiguredLocaleOverride()
    for index, locale in ipairs(self.LanguageCycleOrder) do
        if locale == current then return self.LanguageCycleOrder[(index % table.getn(self.LanguageCycleOrder)) + 1] end
    end
    return self.LanguageCycleOrder[1]
end

function A:CycleLocale()
    local nextLocale = self:GetNextLocale(self:GetConfiguredLocaleOverride())
    if self:SetLocale(nextLocale) then return nextLocale end
    return nil
end

function A:L(key, ...)
    local locale = self:GetConfiguredLocale()
    local selected = self.locales[locale] or {}
    local fallback = self.locales.enUS or {}
    local value = selected[key] or fallback[key] or key
    if select('#', ...) > 0 then
        local ok, formatted = pcall(string.format, value, ...)
        if ok then return formatted end
    end
    return value
end

-- Translate addon-owned presentation only. Never translate a command payload,
-- server ID, saved key, native class name, or text entered by the player.
function A:T(text)
    if type(text)~="string" then return text end
    local key=self.textLocaleKeys and self.textLocaleKeys[text]
    if key then return self:L(key) end
    return text
end
-- Compose category labels (tiers, dungeon sizes, regions) without changing
-- their underlying IDs. Matches consume source text once, never translations.
function A:TranslateLabel(text)
    if type(text)~="string" or self:GetConfiguredLocale()=="koKR" then return text end
    local exact=self:T(text);if exact~=text then return exact end
    if not self.labelTrie then
        self.labelTrie={}
        for _,part in ipairs(self.labelLocaleParts or {}) do
            local node=self.labelTrie
            for i=1,#part[1] do local byte=part[1]:byte(i);node[byte]=node[byte] or {};node=node[byte] end
            node.key=part[2]
        end
    end
    local function hangulAt(i)
        local a,b,c=text:byte(i,i+2)
        if not a or not b or not c or a<224 or a>239 then return false end
        local cp=(a-224)*4096+(b-128)*64+c-128
        return cp>=44032 and cp<=55203
    end
    local out={};local pos=1
    while pos<=#text do
        local node=self.labelTrie;local cursor=pos;local key,finish
        while node and cursor<=#text do
            node=node[text:byte(cursor)]
            if node and node.key and not hangulAt(pos-3) and not hangulAt(cursor+1) then key,finish=node.key,cursor end
            cursor=cursor+1
        end
        if key then out[#out+1]=self:L(key);pos=finish+1 else out[#out+1]=text:sub(pos,pos);pos=pos+1 end
    end
    return table.concat(out)
end
function A:LocalizeWidget(widget)
    if not widget or widget.gmLocalizedText then return widget end
    widget.gmLocalizedText=true
    if self.ApplyLocaleFont then
        self:ApplyLocaleFont(widget)
        if widget.GetFontString then self:ApplyLocaleFont(widget:GetFontString()) end
    end
    local original=widget.SetText
    if original then widget.SetText=function(w,text,...)
        local result=original(w,A:T(text),...)
        if A.FitLocaleButton and (w.aaeLabel or (w.IsObjectType and w:IsObjectType("Button"))) then A:FitLocaleButton(w) end
        return result
    end end
    return widget
end
