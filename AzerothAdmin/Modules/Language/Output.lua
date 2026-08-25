AzerothAdminEasy = AzerothAdminEasy or {}
local addon = AzerothAdminEasy

if addon.Print and addon.TranslateUI and not addon.aaeOriginalPrint then
    addon.aaeOriginalPrint = addon.Print
    addon.Print = function(self, text, isError)
        local translated = text
        if self.ActiveLocale ~= "koKR" then translated = self:TranslateUI(text) end
        return self.aaeOriginalPrint(self, translated, isError)
    end
end
