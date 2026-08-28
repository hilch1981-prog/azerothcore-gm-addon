AzerothAdminEasy = AzerothAdminEasy or {}
local addon = AzerothAdminEasy

local LOCALE_ALIASES = {
    enGB = "enUS",
}

local SUPPORTED_LOCALES = {
    enUS = true,
    koKR = true,
    zhCN = true,
    zhTW = true,
    ruRU = true,
}

local function merge(target, source)
    local key, value
    for key, value in pairs(source or {}) do
        target[key] = value
    end
end

local function normalizedLocale(locale)
    locale = LOCALE_ALIASES[locale] or locale
    if SUPPORTED_LOCALES[locale] then return locale end
    return nil
end

-- Multiple feature locale files may contribute to one locale pack. This keeps
-- each module's strings next to that module instead of creating one huge file.
function addon:RegisterLocale(locale, values)
    locale = normalizedLocale(locale)
    if not locale or type(values) ~= "table" then return false end
    self.LocalePacks = self.LocalePacks or {}
    self.LocalePacks[locale] = self.LocalePacks[locale] or {}
    merge(self.LocalePacks[locale], values)
    return true
end

function addon:GetSupportedLocales()
    return { "enUS", "koKR", "zhCN", "zhTW", "ruRU" }
end

function addon:SetLocaleOverride(locale)
    locale = tostring(locale or "")
    if locale == "" or locale == "auto" then
        AzerothAdminEasyDB = AzerothAdminEasyDB or {}
        AzerothAdminEasyDB.localeOverride = nil
        return true
    end

    locale = normalizedLocale(locale)
    if not locale then return false end
    AzerothAdminEasyDB = AzerothAdminEasyDB or {}
    AzerothAdminEasyDB.localeOverride = locale
    return true
end

function addon:GetConfiguredLocale()
    local override = AzerothAdminEasyDB and normalizedLocale(AzerothAdminEasyDB.localeOverride)
    if override then return override end
    local clientLocale = GetLocale and GetLocale() or "enUS"
    return normalizedLocale(clientLocale) or "enUS"
end

function addon:ActivateLocale(locale)
    locale = normalizedLocale(locale) or "enUS"
    local fallback = self.LocalePacks and self.LocalePacks.enUS or {}
    local selected = self.LocalePacks and self.LocalePacks[locale] or nil

    -- Mutate the existing table instead of replacing it. Legacy files keep a
    -- local reference to addon.L, so this also makes ADDON_LOADED reactivation
    -- safe after SavedVariables become available.
    self.L = self.L or {}
    local key
    for key in pairs(self.L) do self.L[key] = nil end
    merge(self.L, fallback)
    if selected and selected ~= fallback then merge(self.L, selected) end

    self.ActiveLocale = selected and locale or "enUS"
    return self.L
end

function addon:T(key, ...)
    local value = self.L and self.L[key] or nil
    if value == nil then value = tostring(key or "") end
    if select("#", ...) == 0 then return value end
    local ok, formatted = pcall(string.format, value, ...)
    if ok then return formatted end
    return value
end
