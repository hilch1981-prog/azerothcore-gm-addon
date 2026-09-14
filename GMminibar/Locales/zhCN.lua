local A = AzerothAdminAC335
A:RegisterLocale("zhCN", {
    LOCALE_CHANGED = "Locale changed",
    SUBTITLE = "AzerothCore · AzerothAdmin 3.5.0",
    TITLE = "AzerothAdmin - 熊猫人之谜 3.3.5a",
})

A:RegisterLocale("zhCN", {
    TELEPORTS = "传送", SERVER_ALL = "全部地点", QUICK_ALL = "熊猫人快速 31",
    ITEM_BROWSER = "物品信息", ITEM_CATEGORY_LEGACY = "原版 AzerothAdmin 分类", ITEM_PLACEHOLDER_FILTERED = "已隐藏 %d 个临时/未使用物品",
    PROFESSIONS = "专业信息", PROFESSION_LIVE_DATA = "客户端实时数据", PROFESSION_OFFLINE_DATA = "内置材料数据", TOOL_LABEL = "需要工具",
    REAGENT_DATA_UNAVAILABLE = "没有此配方的材料数据。", QUEST_ACTIVE_COUNT = "%d 个进行中任务", NO_ACTIVE_QUESTS = "任务日志尚未载入或没有任务。",
    LANGUAGE_BUTTON_TITLE = "语言切换", LANGUAGE_BUTTON_HINT = "当前：%s · 点击切换 AUTO → 韩文 → EN → 中文 → RU",
    LANGUAGE_CURRENT_MODE = "模式：%s · 当前语言：%s", LANGUAGE_UNSUPPORTED = "不支持的语言：%s",
    DEAD_COMMAND_NOTE = "死亡时命令通过对自己密语发送；复活会清除目标并自动重试。", COMMAND_SEND_FAILED = "命令发送失败：%s",
})

A:RegisterLocale("zhCN", {
    REAGENT_COUNT_READY = "拥有 %s / 需要 %s · 已备齐",
    REAGENT_COUNT_SHORT = "拥有 %s / 需要 %s · 缺少 %s",
    REAGENT_READY_TOOLTIP = "所需材料已全部备齐（%s/%s）。",
    REAGENT_SHORT_TOOLTIP = "还缺少 %s 个。",
    QUEST_ENTRY_FALLBACK = "NPC 条目后备定位",
    QUEST_RELATION_NO_ACTIVE_SPAWN = "任务关系存在，但数据库中没有可用的生成坐标/GUID。",
    QUEST_ITEM_SCRIPT_START_HINT = "这可能是物品触发、自动触发或脚本专用任务。",
    QUEST_OBJECTIVE_RELATION_NO_SPAWN = "目标关系（ID %s）存在，但没有安全的生成坐标。",
})

-- R7 in-game feedback strings.
A:RegisterLocale("zhCN", {
    QUALITY_ARTIFACT = "神器",
    OBJECTIVE_DIALOGUE = "对话",
    QUEST_DIALOGUE_OBJECTIVE = "与%s对话/汇报",
    QUEST_LOOKUP_NAME_UNAVAILABLE = "没有可用于服务器查询的本地化 NPC、物件或物品名称。",
    TELEPORT_CANONICAL_SUBTITLE_R7 = "大陆 → 区域 → 目的地 → 等级 · 右键：收藏",
    TELEPORT_PROGRESS_ONLY = "本阵营/当前等级",
    TELEPORT_PROGRESS_ACTIVE = "已应用进度筛选",
    TELEPORT_TABLE_HEADER = "大陆 / 区域  →  目的地  ·  推荐等级  ·  阵营    （右键：收藏）",
    TELEPORT_TABLE_PATH = "%s / %s · %s",
    TELEPORT_FACTION_LABEL = "阵营",
    TELEPORT_FACTION_ALLIANCE = "联盟",
    TELEPORT_FACTION_HORDE = "部落",
    TELEPORT_FACTION_NEUTRAL = "中立",
    ALL_TIERS = "全部技能阶段",
    SORT_SKILL = "技能排序",
    PROF_TIER_APPRENTICE = "初级",
    PROF_TIER_JOURNEYMAN = "中级",
    PROF_TIER_EXPERT = "高级",
    PROF_TIER_ARTISAN = "专家",
    PROF_TIER_MASTER = "大师",
    PROF_TIER_GRAND_MASTER = "宗师",
    PROF_TIER_ILLUSTRIOUS = "巨匠",
    PROF_TIER_ZEN_MASTER = "禅师",
    PROF_SKILL_SHORT = "%d/%d",
    PROF_NOT_LEARNED_SHORT = "未学习",
    PROF_REQUIRED_SKILL = "需要技能 %d",
    PROF_CURRENT_SKILL = "当前技能 %d/%d",
    PROF_LEARN_NO_RECIPE = "请先选择配方。",
    PROF_LEARN_ALREADY_KNOWN = "已经学会此配方。",
    PROF_LEARN_NO_PERMISSION = "账号无权执行学习命令。",
    PROF_LEARN_PROFESSION_MISSING = "请先学习所需专业。",
    PROF_LEARN_SKILL_LOW = "当前技能 %d，低于需要的 %d。",
    PROF_LEARN_READY = "可以学习 · 当前 %d / 需要 %d",
})
A:RegisterLocale("zhCN", {
    MAIN_INFO_LINE = "AC335 3.3.5a · AzerothCore · 权限 %d · 发布 %s",
    BACK = "返回",
    ITEM_ADVANCED_FILTERS = "高级筛选 ▼",
    ITEM_ADVANCED_FILTERS_HIDE = "高级筛选 ▲",
    ITEM_ADVANCED_ACTIVE = "高级筛选已启用",
    ITEM_CURRENT_FILTER_SIMPLE = "分类：%s",
    ITEM_BROWSER_HINT = "默认使用分类与名称/ID搜索；需要时展开高级筛选。",
    ITEM_BROWSER_CANONICAL_HINT = "左侧分类 + 名称/ID搜索 · 可选类型/品质高级筛选",
    QUEST_SELECTION_REFRESHED = "任务选择已变化，目标信息已刷新，请再次执行。",
    TELEPORT_COUNTS = "快捷: %d · 可用: %d · 结果: %d",
    TELEPORT_FILTER_CATEGORY = "分类",
    TELEPORT_COL_AREA = "大陆/区域",
    TELEPORT_COL_DESTINATION = "目的地",
})
