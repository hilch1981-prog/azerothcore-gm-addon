local A = AzerothAdminAC335
A:RegisterLocale("zhTW", {
    LOCALE_CHANGED = "Locale changed",
    SUBTITLE = "AzerothCore · AzerothAdmin 3.5.0",
    TITLE = "AzerothAdmin - 潘達利亞之謎 3.3.5a",
})

A:RegisterLocale("zhTW", {
    TELEPORTS = "傳送", SERVER_ALL = "全部地點", QUICK_ALL = "潘達利亞快速 31",
    ITEM_BROWSER = "物品資訊", ITEM_CATEGORY_LEGACY = "原版 AzerothAdmin 分類", ITEM_PLACEHOLDER_FILTERED = "已隱藏 %d 個臨時/未使用物品",
    PROFESSIONS = "專業資訊", PROFESSION_LIVE_DATA = "用戶端即時資料", PROFESSION_OFFLINE_DATA = "內建材料資料", TOOL_LABEL = "需要工具",
    REAGENT_DATA_UNAVAILABLE = "沒有此配方的材料資料。", QUEST_ACTIVE_COUNT = "%d 個進行中任務", NO_ACTIVE_QUESTS = "任務日誌尚未載入或沒有任務。",
    LANGUAGE_BUTTON_TITLE = "語言切換", LANGUAGE_BUTTON_HINT = "目前：%s · 點擊切換 AUTO → 韓文 → EN → 中文 → RU",
    LANGUAGE_CURRENT_MODE = "模式：%s · 目前語言：%s", LANGUAGE_UNSUPPORTED = "不支援的語言：%s",
    DEAD_COMMAND_NOTE = "死亡時命令透過對自己密語傳送；復活會清除目標並自動重試。", COMMAND_SEND_FAILED = "命令傳送失敗：%s",
})

A:RegisterLocale("zhTW", {
    REAGENT_COUNT_READY = "擁有 %s / 需要 %s · 已備齊",
    REAGENT_COUNT_SHORT = "擁有 %s / 需要 %s · 缺少 %s",
    REAGENT_READY_TOOLTIP = "所需材料已全部備齊（%s/%s）。",
    REAGENT_SHORT_TOOLTIP = "還缺少 %s 個。",
    QUEST_ENTRY_FALLBACK = "NPC 條目備援定位",
    QUEST_RELATION_NO_ACTIVE_SPAWN = "任務關係存在，但資料庫中沒有可用的生成座標/GUID。",
    QUEST_ITEM_SCRIPT_START_HINT = "這可能是物品觸發、自動觸發或腳本專用任務。",
    QUEST_OBJECTIVE_RELATION_NO_SPAWN = "目標關係（ID %s）存在，但沒有安全的生成座標。",
})

-- R7 in-game feedback strings.
A:RegisterLocale("zhTW", {
    QUALITY_ARTIFACT = "神器",
    OBJECTIVE_DIALOGUE = "對話",
    QUEST_DIALOGUE_OBJECTIVE = "與%s對話/回報",
    QUEST_LOOKUP_NAME_UNAVAILABLE = "沒有可用於伺服器查詢的本地化 NPC、物件或物品名稱。",
    TELEPORT_CANONICAL_SUBTITLE_R7 = "大陸 → 區域 → 目的地 → 等級 · 右鍵：收藏",
    TELEPORT_PROGRESS_ONLY = "本陣營/目前等級",
    TELEPORT_PROGRESS_ACTIVE = "已套用進度篩選",
    TELEPORT_TABLE_HEADER = "大陸 / 區域  →  目的地  ·  建議等級  ·  陣營    （右鍵：收藏）",
    TELEPORT_TABLE_PATH = "%s / %s · %s",
    TELEPORT_FACTION_LABEL = "陣營",
    TELEPORT_FACTION_ALLIANCE = "聯盟",
    TELEPORT_FACTION_HORDE = "部落",
    TELEPORT_FACTION_NEUTRAL = "中立",
    ALL_TIERS = "全部技能階段",
    SORT_SKILL = "技能排序",
    PROF_TIER_APPRENTICE = "初級",
    PROF_TIER_JOURNEYMAN = "中級",
    PROF_TIER_EXPERT = "高級",
    PROF_TIER_ARTISAN = "專家",
    PROF_TIER_MASTER = "大師",
    PROF_TIER_GRAND_MASTER = "宗師",
    PROF_TIER_ILLUSTRIOUS = "巨匠",
    PROF_TIER_ZEN_MASTER = "禪師",
    PROF_SKILL_SHORT = "%d/%d",
    PROF_NOT_LEARNED_SHORT = "未學習",
    PROF_REQUIRED_SKILL = "需要技能 %d",
    PROF_CURRENT_SKILL = "目前技能 %d/%d",
    PROF_LEARN_NO_RECIPE = "請先選擇配方。",
    PROF_LEARN_ALREADY_KNOWN = "已經學會此配方。",
    PROF_LEARN_NO_PERMISSION = "帳號無權執行學習命令。",
    PROF_LEARN_PROFESSION_MISSING = "請先學習所需專業。",
    PROF_LEARN_SKILL_LOW = "目前技能 %d，低於需要的 %d。",
    PROF_LEARN_READY = "可以學習 · 目前 %d / 需要 %d",
})
A:RegisterLocale("zhTW", {
    MAIN_INFO_LINE = "AC335 3.3.5a · AzerothCore · 權限 %d · 發布 %s",
    BACK = "返回",
    ITEM_ADVANCED_FILTERS = "進階篩選 ▼",
    ITEM_ADVANCED_FILTERS_HIDE = "進階篩選 ▲",
    ITEM_ADVANCED_ACTIVE = "進階篩選已啟用",
    ITEM_CURRENT_FILTER_SIMPLE = "分類：%s",
    ITEM_BROWSER_HINT = "預設使用分類與名稱/ID搜尋；需要時展開進階篩選。",
    ITEM_BROWSER_CANONICAL_HINT = "左側分類 + 名稱/ID搜尋 · 可選類型/品質進階篩選",
    QUEST_SELECTION_REFRESHED = "任務選擇已變更，目標資訊已重新整理，請再次執行。",
    TELEPORT_COUNTS = "快捷: %d · 可用: %d · 結果: %d",
    TELEPORT_FILTER_CATEGORY = "分類",
    TELEPORT_COL_AREA = "大陸/區域",
    TELEPORT_COL_DESTINATION = "目的地",
})
