local A = AzerothAdminAC335
local D = { client = "WotLK 3.3.5a", namespace = "GMminibarAC335Workbench", hasDatabase = true, configuredSecurity = true }
A.WorkbenchAdapter = D
function D:DB() return A:GetDB() end
function D:Locale() return A:GetConfiguredLocale() end
function D:Language(locale) A:SetLocale(locale); ReloadUI() end
function D:Label(d) return A:L(d.labelKey) end
function D:Definitions()
    local out = {}
    for _, id in ipairs(A.CommandOrder or {}) do
        local d = A.CommandCatalog[id]
        if not d.hidden and (not d.lifecycle or self:DB().showServerLifecycleCommands) then
            local category = A.Categories[d.category]
            out[#out + 1] = { definition = d, key = id, label = self:Label(d),
                category = category and A:L(category.labelKey) or d.category,
                group = A.WorkbenchCatalog:Group(d.command, d.action) }
        end
    end
    return out
end
function D:Allowed(entry) return A:CanRunCommand(entry.definition) end
function D:IsFavorite(entry)
    for _, definition in ipairs(entry.originals or { entry.definition }) do if A:IsCommandFavorite(definition.id) then return true end end
    return false
end
function D:InitialQuickKeys() return self:DB().quickSlots or {} end
function D:Favorite(entry) A:ToggleCommandFavorite(entry.definition.id) end
function D:Preview(entry, args) return A:BuildCommand(entry.definition, args) end
function D:Execute(entry, args, target)
    local d = entry.definition
    if not A:CanRunCommand(d) then return A:RunRegisteredCommand(d.id) end
    if d.action then return A:RunRegisteredCommand(d.id) end
    if args == "" and d.promptKey == "PROMPT_PLAYER" then args = target end
    if args == "" and d.promptKey then return A:ShowArgumentPrompt(d) end
    -- Reuse the existing confirmation path even when arguments are supplied inline.
    if d.dangerous then return A:ShowCommandConfirmation(d, args) end
    if d.rc8Literal or (A:GetCommand(d.id) and A:GetCommand(d.id).command~=d.command) then return A:SendCommand(A:BuildCommand(d,args)) end
    return A:RunRegisteredCommand(d.id, args, true)
end
function D:Raw(text)
    text = A:Trim(text)
    if text == "" then return end
    if text:sub(1, 1) ~= "." then text = "." .. text end
    A:ShowCommandConfirmation({ labelKey = "RAW_COMMAND", command = text }, "")
end
function D:History() return self:DB().commandHistory or {} end
function D:Security() return A:GetAccountSecurity() end
function D:Status() return "" end
function D:Open(key)
    if key == "search" then A:OpenSearchWindow()
    elseif key == "teleports" then A:OpenTeleportWindow()
    elseif key == "quests" then A:OpenQuestHelper()
    elseif key == "creatures" then A:OpenCreatureWindow()
    elseif key == "items" then A:OpenItemBrowser()
    elseif key == "spells" then A:OpenSpellBrowser()
    elseif key == "professions" then A:OpenProfessionWindow()
    elseif key == "bank" then A:OpenBank()
    elseif key == "telefavorites" then A:OpenTeleportFavoritesWindow()
    elseif key == "database" then A:OpenDatabaseWindow() end
end
function D:Frames()
    local keys = { search_tools = "search", teleports = "teleports", teleport_favorites = "telefavorites",
        quest_helper = "quests", item_browser = "items", profession_info = "professions", database = "database",
        creature_tools = "creatures", favorites = "favorites", recovery = "commands", integrations = "commands", playerbot = "commands", language = "commands" }
    local out = {}
    for key, frame in pairs(A.windows or {}) do
        if key ~= "main" and key ~= "argument" and key ~= "confirm" then
            out[#out + 1] = { frame, keys[key] or "search" }
        end
    end
    return out
end
function D:SelectedQuest()
    local index = GetQuestLogSelection and GetQuestLogSelection()
    if not index or index <= 0 then return nil end
    local title, level, _, header, _, complete, _, id = A.ReadQuestLogTitle(index)
    if header or not title then return nil end
    if not id or id == 0 then
        local link = GetQuestLink and GetQuestLink(index)
        id = link and tonumber(link:match("quest:(%d+)"))
    end
    if not id or id <= 0 then return nil end
    return { id = id, title = title, level = level, complete = complete, logIndex = index }
end
function D:QuestAction(action, quest)
    if action == "start" then return A:QuestGoLocation(quest, "s")
    elseif action == "finish" then return A:QuestGoLocation(quest, "e")
    elseif action == "complete" then return A:CompleteOwnQuest(quest)
    elseif action == "full" then A:OpenQuestHelper(); A:SelectQuestHelperQuest(quest) end
end
function D:CanQuestAction(action, quest)
    if not quest then return false end
    if action == "complete" then
        return A:CanRunCommand("quest_complete")
    end
    if action == "start" or action == "finish" then
        return #A:GetQuestLocationTargets(quest, action == "start" and "s" or "e") > 0
    end
    return true
end
