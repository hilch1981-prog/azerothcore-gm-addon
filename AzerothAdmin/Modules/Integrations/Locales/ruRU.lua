AzerothAdminEasy = AzerothAdminEasy or {}
local addon = AzerothAdminEasy
if not addon.RegisterLocale then return end

addon:RegisterLocale("ruRU", {
    INTEGRATIONS_CRAFT_UI_MISSING = "Интерфейс профессий не найден.",
    INTEGRATIONS_ITEM_MODULE_MISSING = "Модуль информации о предметах не найден.",
    INTEGRATIONS_ITEM_OPEN_FAILED = "Не удалось открыть окно информации о предметах: %s",
})
