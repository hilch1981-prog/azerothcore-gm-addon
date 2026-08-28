AzerothAdminEasy = AzerothAdminEasy or {}
local addon = AzerothAdminEasy
if not addon.RegisterLocale then return end

addon:RegisterLocale("enUS", {
    INTEGRATIONS_CRAFT_UI_MISSING = "Profession information UI was not found.",
    INTEGRATIONS_ITEM_MODULE_MISSING = "Integrated item information module was not found.",
    INTEGRATIONS_ITEM_OPEN_FAILED = "Failed to open the item information window: %s",
})
