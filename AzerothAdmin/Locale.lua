AzerothAdminEasy = AzerothAdminEasy or {}
local addon = AzerothAdminEasy

local function activateConfiguredLocale()
    if not addon.ActivateLocale then
        addon.L = addon.L or {}
        return
    end
    local locale = addon.GetConfiguredLocale and addon:GetConfiguredLocale()
        or (GetLocale and GetLocale() or "enUS")
    addon:ActivateLocale(locale)
end

-- Provide strings to files loaded after this compatibility entrypoint.
activateConfiguredLocale()

-- SavedVariables are guaranteed by ADDON_LOADED. Reactivate the configured
-- override before PLAYER_LOGIN creates the visible UI.
local localeEvents = CreateFrame("Frame")
localeEvents:RegisterEvent("ADDON_LOADED")
localeEvents:SetScript("OnEvent", function(self, event, name)
    if name ~= "AzerothAdmin" then return end
    activateConfiguredLocale()
    self:UnregisterEvent("ADDON_LOADED")
end)
