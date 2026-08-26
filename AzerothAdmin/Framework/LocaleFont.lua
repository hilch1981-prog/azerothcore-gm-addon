AzerothAdminEasy = AzerothAdminEasy or {}
local addon = AzerothAdminEasy

local UNICODE_FONT = "Interface\\AddOns\\AzerothAdmin\\Fonts\\AzerothAdminUnicode.ttf"
local FONT_LOCALES = {
    zhCN = true,
    zhTW = true,
    ruRU = true,
}

function addon:GetLocaleFontPath()
    if FONT_LOCALES[self.ActiveLocale] then return UNICODE_FONT end
    return nil
end

function addon:ApplyLocaleFont(region)
    local path = self:GetLocaleFontPath()
    if not path or not region or not region.GetFont or not region.SetFont then return false end
    local _, size, flags = region:GetFont()
    size = tonumber(size) or 12
    local ok, applied = pcall(region.SetFont, region, path, size, flags or "")
    return ok and applied ~= nil
end
