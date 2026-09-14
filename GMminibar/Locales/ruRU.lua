local A = AzerothAdminAC335
A:RegisterLocale("ruRU", {
    LOCALE_CHANGED = "Locale changed",
    SUBTITLE = "AzerothCore · AzerothAdmin 3.5.0",
    TITLE = "AzerothAdmin - AC335 3.3.5a",
})

A:RegisterLocale("ruRU", {
    TELEPORTS = "Телепорты", SERVER_ALL = "Все точки", QUICK_ALL = "AC335 быстрые 31",
    ITEM_BROWSER = "Информация о предметах", ITEM_CATEGORY_LEGACY = "Категории AzerothAdmin", ITEM_PLACEHOLDER_FILTERED = "Скрыто временных/неиспользуемых: %d",
    PROFESSIONS = "Профессии", PROFESSION_LIVE_DATA = "данные клиента", PROFESSION_OFFLINE_DATA = "встроенные реагенты", TOOL_LABEL = "Инструмент",
    REAGENT_DATA_UNAVAILABLE = "Для этого рецепта нет данных о реагентах.", QUEST_ACTIVE_COUNT = "Активных заданий: %d", NO_ACTIVE_QUESTS = "Журнал заданий не загружен или пуст.",
    LANGUAGE_BUTTON_TITLE = "Переключение языка", LANGUAGE_BUTTON_HINT = "Сейчас: %s · AUTO → 한국어 → EN → 中文 → RU",
    LANGUAGE_CURRENT_MODE = "Режим: %s · язык: %s", LANGUAGE_UNSUPPORTED = "Неподдерживаемая локаль: %s",
    DEAD_COMMAND_NOTE = "После смерти команды отправляются шёпотом себе; воскрешение очищает цель и повторяется.", COMMAND_SEND_FAILED = "Ошибка отправки команды: %s",
})

A:RegisterLocale("ruRU", {
    REAGENT_COUNT_READY = "Есть %s / Нужно %s · ГОТОВО",
    REAGENT_COUNT_SHORT = "Есть %s / Нужно %s · Не хватает %s",
    REAGENT_READY_TOOLTIP = "Все необходимые материалы собраны (%s/%s).",
    REAGENT_SHORT_TOOLTIP = "Не хватает ещё: %s.",
    QUEST_ENTRY_FALLBACK = "переход по ID NPC",
    QUEST_RELATION_NO_ACTIVE_SPAWN = "Связь задания есть, но в БД нет активной точки/GUID.",
    QUEST_ITEM_SCRIPT_START_HINT = "Задание может запускаться предметом, автоматически или только скриптом.",
    QUEST_OBJECTIVE_RELATION_NO_SPAWN = "Связь цели (ID %s) есть, но безопасная точка не найдена.",
})

-- R7 in-game feedback strings.
A:RegisterLocale("ruRU", {
    QUALITY_ARTIFACT = "Артефакт",
    OBJECTIVE_DIALOGUE = "Диалог",
    QUEST_DIALOGUE_OBJECTIVE = "Поговорить/доложить: %s",
    QUEST_LOOKUP_NAME_UNAVAILABLE = "Нет локализованного имени NPC, объекта или предмета для поиска на сервере.",
    TELEPORT_CANONICAL_SUBTITLE_R7 = "Континент → зона → цель → уровень · ПКМ: избранное",
    TELEPORT_PROGRESS_ONLY = "Моя фракция/текущий уровень",
    TELEPORT_PROGRESS_ACTIVE = "фильтр прогресса",
    TELEPORT_TABLE_HEADER = "Континент / зона  →  цель  ·  уровень  ·  фракция    (ПКМ: избранное)",
    TELEPORT_TABLE_PATH = "%s / %s · %s",
    TELEPORT_FACTION_LABEL = "Фракция",
    TELEPORT_FACTION_ALLIANCE = "Альянс",
    TELEPORT_FACTION_HORDE = "Орда",
    TELEPORT_FACTION_NEUTRAL = "Нейтрально",
    ALL_TIERS = "Все ступени навыка",
    SORT_SKILL = "По навыку",
    PROF_TIER_APPRENTICE = "Ученик",
    PROF_TIER_JOURNEYMAN = "Подмастерье",
    PROF_TIER_EXPERT = "Умелец",
    PROF_TIER_ARTISAN = "Искусник",
    PROF_TIER_MASTER = "Мастер",
    PROF_TIER_GRAND_MASTER = "Великий мастер",
    PROF_TIER_ILLUSTRIOUS = "Прославленный мастер",
    PROF_TIER_ZEN_MASTER = "Дзен-мастер",
    PROF_SKILL_SHORT = "%d/%d",
    PROF_NOT_LEARNED_SHORT = "не изучено",
    PROF_REQUIRED_SKILL = "Требуется навык %d",
    PROF_CURRENT_SKILL = "Текущий навык %d/%d",
    PROF_LEARN_NO_RECIPE = "Сначала выберите рецепт.",
    PROF_LEARN_ALREADY_KNOWN = "Этот рецепт уже изучен.",
    PROF_LEARN_NO_PERMISSION = "У учётной записи нет права на команду learn.",
    PROF_LEARN_PROFESSION_MISSING = "Сначала изучите требуемую профессию.",
    PROF_LEARN_SKILL_LOW = "Текущий навык %d ниже требуемого %d.",
    PROF_LEARN_READY = "Можно изучить · текущий %d / требуется %d",
})
A:RegisterLocale("ruRU", {
    MAIN_INFO_LINE = "AC335 3.3.5a · AzerothCore · Доступ %d · Сборка %s",
    BACK = "Назад",
    ITEM_ADVANCED_FILTERS = "Расширенные фильтры ▼",
    ITEM_ADVANCED_FILTERS_HIDE = "Расширенные фильтры ▲",
    ITEM_ADVANCED_ACTIVE = "расширенный фильтр активен",
    ITEM_CURRENT_FILTER_SIMPLE = "Категория: %s",
    ITEM_BROWSER_HINT = "Сначала категория и поиск по имени/ID; расширенные фильтры — при необходимости.",
    ITEM_BROWSER_CANONICAL_HINT = "Категория слева + имя/ID · дополнительные фильтры типа/качества",
    QUEST_SELECTION_REFRESHED = "Выбор задания изменился. Цели обновлены; повторите действие.",
    TELEPORT_COUNTS = "Быстрые: %d · доступно: %d · найдено: %d",
    TELEPORT_FILTER_CATEGORY = "Тип",
    TELEPORT_COL_AREA = "Континент/зона",
    TELEPORT_COL_DESTINATION = "Назначение",
})
