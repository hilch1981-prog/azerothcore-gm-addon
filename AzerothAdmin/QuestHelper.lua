AzerothAdminEasy = AzerothAdminEasy or {}
local addon = AzerothAdminEasy

local QUESTS_PER_PAGE = 8
local MAX_OBJECTIVE_ROWS = 5

local function qText(parent, text, size)
    local fs = parent:CreateFontString(nil, "OVERLAY")
    if size == "large" then
        fs:SetFontObject(GameFontNormalLarge)
    elseif size == "small" then
        fs:SetFontObject(GameFontHighlightSmall)
    else
        fs:SetFontObject(GameFontNormal)
    end
    fs:SetText(text or "")
    return fs
end

local function qButton(parent, width, height, text)
    local b = CreateFrame("Button", nil, parent)
    b:SetWidth(width)
    b:SetHeight(height)
    b:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 12, edgeSize = 8,
        insets = { left = 2, right = 2, top = 2, bottom = 2 },
    })
    b:SetBackdropColor(0.025, 0.04, 0.055, 1)
    b:SetBackdropBorderColor(0.48, 0.43, 0.31, 1)
    local label = b:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    label:SetPoint("LEFT", b, "LEFT", 4, 0)
    label:SetPoint("RIGHT", b, "RIGHT", -4, 0)
    label:SetJustifyH("CENTER")
    label:SetText(text or "")
    b.aaeLabel = label
    b.SetText = function(self, value) self.aaeLabel:SetText(value or "") end
    b:SetScript("OnEnter", function(self)
        if self:IsEnabled() then
            self:SetBackdropColor(0.07, 0.22, 0.28, 1)
            self:SetBackdropBorderColor(0.22, 0.88, 0.95, 1)
        end
        if self.aaeHint then
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText(self.aaeTitle or self.aaeLabel:GetText() or "", 1, 0.82, 0.18)
            GameTooltip:AddLine(self.aaeHint, 1, 1, 1, true)
            GameTooltip:Show()
        end
    end)
    b:SetScript("OnLeave", function(self)
        if self:IsEnabled() then
            self:SetBackdropColor(0.025, 0.04, 0.055, 1)
            self:SetBackdropBorderColor(0.48, 0.43, 0.31, 1)
        end
        GameTooltip:Hide()
    end)
    return b
end

local function qEdit(parent, width, height)
    local e = CreateFrame("EditBox", nil, parent)
    e:SetWidth(width); e:SetHeight(height); e:SetAutoFocus(false)
    e:SetFontObject(ChatFontNormal); e:SetTextInsets(6, 6, 0, 0)
    e:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 12, edgeSize = 8,
        insets = { left = 2, right = 2, top = 2, bottom = 2 },
    })
    e:SetBackdropColor(0.01, 0.02, 0.025, 1)
    e:SetBackdropBorderColor(0.48, 0.43, 0.31, 1)
    return e
end

local function questLevelColor(level)
    level = tonumber(level) or 0
    if level <= 0 then return 0.7, 0.7, 0.7 end
    if GetQuestDifficultyColor then
        local ok, c = pcall(GetQuestDifficultyColor, level)
        if ok and c then return c.r or 1, c.g or 1, c.b or 1 end
    end
    local playerLevel = UnitLevel("player") or 1
    local diff = level - playerLevel
    if diff >= 5 then return 1, 0.1, 0.1 end
    if diff >= 3 then return 1, 0.5, 0 end
    if diff >= -2 then return 1, 1, 0 end
    if diff >= -5 then return 0.25, 0.75, 0.25 end
    return 0.55, 0.55, 0.55
end

local function qSetEnabled(button, enabled)
    if enabled then
        button:Enable()
        button:SetBackdropColor(0.025, 0.04, 0.055, 1)
        button:SetBackdropBorderColor(0.48, 0.43, 0.31, 1)
        button.aaeLabel:SetTextColor(1, 0.82, 0.18)
    else
        button:Disable()
        button:SetBackdropColor(0.025, 0.03, 0.035, 0.85)
        button:SetBackdropBorderColor(0.14, 0.16, 0.18, 0.8)
        button.aaeLabel:SetTextColor(0.38, 0.40, 0.42)
    end
end

local function trim(text)
    if not text then return "" end
    return string.gsub(text, "^%s*(.-)%s*$", "%1")
end

local function questLogInfo(index)
    -- WoW 3.3.5a:
    -- title, level, questTag, suggestedGroup, isHeader, isCollapsed, isComplete, isDaily, questID
    return GetQuestLogTitle(index)
end

local function questIDFromIndex(index)
    local _, _, _, _, isHeader, _, _, _, questID = questLogInfo(index)
    if isHeader then return nil end
    if questID and questID > 0 then return questID end
    if GetQuestLink then
        local ok, link = pcall(GetQuestLink, index)
        if ok and link then
            local found = string.match(link, "quest:(%d+)")
            if found then return tonumber(found) end
        end
    end
    return nil
end

local function expandAllQuestHeaders()
    if not ExpandQuestHeader or not GetNumQuestLogEntries then return end
    local safety = 0
    while safety < 50 do
        safety = safety + 1
        local total = GetNumQuestLogEntries() or 0
        local expanded = false
        local i
        for i = 1, total do
            local _, _, _, _, isHeader, isCollapsed = questLogInfo(i)
            if isHeader and isCollapsed then
                pcall(ExpandQuestHeader, i)
                expanded = true
                break
            end
        end
        if not expanded then break end
    end
end

local function parseProgress(text)
    if not text then return nil, nil end
    local current, needed = string.match(text, "(%d+)%s*/%s*(%d+)")
    if current and needed then return tonumber(current), tonumber(needed) end
    return nil, nil
end

local function objectiveName(text)
    local value = trim(text or "")
    value = string.gsub(value, "%s*:?%s*%d+%s*/%s*%d+.*$", "")
    value = string.gsub(value, "%s+[Ss]lain$", "")
    value = string.gsub(value, "%s+[Kk]illed$", "")
    value = string.gsub(value, "%s+[Ff]ound$", "")
    value = string.gsub(value, "%s+[Cc]ollected$", "")
    value = string.gsub(value, "%s*처치함$", "")
    value = string.gsub(value, "%s*처치$", "")
    value = string.gsub(value, "%s*처치하기$", "")
    value = string.gsub(value, "%s*획득$", "")
    value = string.gsub(value, "%s*수집$", "")
    value = string.gsub(value, "%s*찾기$", "")
    value = string.gsub(value, "%s*파괴$", "")
    return trim(value)
end

local function getObjectiveItemLink(objectiveIndex, questIndex)
    if not GetQuestLogItemLink then return nil end
    local ok, link = pcall(GetQuestLogItemLink, objectiveIndex, questIndex)
    if ok and link then return link end
    if GetQuestLogSelection and SelectQuestLogEntry then
        local selected = GetQuestLogSelection()
        pcall(SelectQuestLogEntry, questIndex)
        ok, link = pcall(GetQuestLogItemLink, objectiveIndex)
        if selected and selected > 0 then pcall(SelectQuestLogEntry, selected) end
        if ok and link then return link end
    end
    return nil
end

local function appendUnique(rows, row)
    local key = string.lower((row.type or "") .. "|" .. (row.text or ""))
    local i
    for i = 1, table.getn(rows) do
        local other = string.lower((rows[i].type or "") .. "|" .. (rows[i].text or ""))
        if key == other then return end
    end
    table.insert(rows, row)
end

function addon:BuildQuestHelperData()
    expandAllQuestHeaders()
    if QuestMapUpdateAllQuests then pcall(QuestMapUpdateAllQuests) end
    local quests = {}
    local totalEntries = GetNumQuestLogEntries and (GetNumQuestLogEntries() or 0) or 0
    local currentRegion = "기타"
    local index
    for index = 1, totalEntries do
        local title, level, questTag, suggestedGroup, isHeader, isCollapsed, isComplete, isDaily, questID = questLogInfo(index)
        if title and isHeader then
            currentRegion = title
        elseif title and not isHeader then
            questID = questID or questIDFromIndex(index)
            if questID and questID > 0 then
                table.insert(quests, {
                    logIndex = index,
                    id = questID,
                    title = title,
                    level = level or 0,
                    region = currentRegion or "기타",
                    tag = questTag,
                    suggestedGroup = suggestedGroup,
                    complete = isComplete,
                    daily = isDaily,
                })
            end
        end
    end
    self.questHelperData = quests
    self:SortQuestHelperData()
    return quests
end

function addon:SortQuestHelperData()
    local data = self.questHelperData or {}
    local key = self.questHelperSortKey or "id"
    local asc = self.questHelperSortAsc ~= false
    table.sort(data, function(a, b)
        local av, bv
        if key == "title" then
            av, bv = string.lower(a.title or ""), string.lower(b.title or "")
        elseif key == "level" then
            av, bv = tonumber(a.level) or 0, tonumber(b.level) or 0
        elseif key == "region" then
            av, bv = string.lower(a.region or ""), string.lower(b.region or "")
        else
            av, bv = tonumber(a.id) or 0, tonumber(b.id) or 0
        end
        if av == bv then return (tonumber(a.id) or 0) < (tonumber(b.id) or 0) end
        if asc then return av < bv else return av > bv end
    end)
end

function addon:SetQuestHelperSort(key)
    if self.questHelperSortKey == key then
        self.questHelperSortAsc = not self.questHelperSortAsc
    else
        self.questHelperSortKey = key
        self.questHelperSortAsc = true
    end
    self:SortQuestHelperData()
    self.questHelperPage = 1
    self:RefreshQuestHelper(false)
    if self.RefreshQuestSortHeaders then self:RefreshQuestSortHeaders() end
end

function addon:GetQuestObjectives(quest)
    local result = {}
    if not quest then return result end

    if GetNumQuestLeaderBoards and GetQuestLogLeaderBoard then
        local count = GetNumQuestLeaderBoards(quest.logIndex) or 0
        local i
        for i = 1, count do
            local text, objectiveType, finished = GetQuestLogLeaderBoard(i, quest.logIndex)
            if text then
                local current, needed = parseProgress(text)
                local targetName = objectiveName(text)
                local link = nil
                local itemID = nil
                local creatureID = nil

                if objectiveType == "item" then
                    link = getObjectiveItemLink(i, quest.logIndex)
                    if link then
                        local found = string.match(link, "item:(%d+)")
                        if found then itemID = tonumber(found) end
                    end
                    if not itemID and self.FindLocaleID then
                        itemID = self:FindLocaleID("item", targetName)
                    end
                elseif objectiveType == "monster" and self.FindLocaleID then
                    creatureID = self:FindLocaleID("creature", targetName)
                end

                appendUnique(result, {
                    index = i,
                    text = text,
                    type = objectiveType or "other",
                    finished = finished,
                    current = current,
                    needed = needed,
                    itemID = itemID,
                    itemLink = link,
                    creatureID = creatureID,
                    targetName = targetName,
                    questID = quest.id,
                    logIndex = quest.logIndex,
                })
            end
        end
    end

    -- WotLK 3.3.5a exposes extra item-drop tooltip rows for the selected quest.
    -- They are merged into the same table and resolved through the koKR item index.
    if GetNumQuestItemDrops and GetQuestLogItemDrop then
        local ok, count = pcall(GetNumQuestItemDrops, quest.logIndex)
        if ok and count and count > 0 then
            local i
            for i = 1, count do
                local success, text, texture, finished = pcall(GetQuestLogItemDrop, i, quest.logIndex)
                if success and text then
                    local current, needed = parseProgress(text)
                    local targetName = objectiveName(text)
                    local itemID = self.FindLocaleID and self:FindLocaleID("item", targetName) or nil
                    appendUnique(result, {
                        index = i,
                        text = text,
                        type = "drop",
                        finished = finished,
                        current = current,
                        needed = needed,
                        itemID = itemID,
                        targetName = targetName,
                        questID = quest.id,
                        logIndex = quest.logIndex,
                        isDropRow = true,
                    })
                end
            end
        end
    end

    return result
end

function addon:QuestGoStart(questID)
    if not questID or questID == 0 then return end
    self:SendNow(".go quest starter " .. questID)
end

function addon:QuestGoEnd(questID)
    if not questID or questID == 0 then return end
    self:SendNow(".go quest ender " .. questID)
end

-- Compatibility aliases for older saved/UI code.
function addon:QuestGoStarterNPC(questID) self:QuestGoStart(questID) end
function addon:QuestGoEnderNPC(questID) self:QuestGoEnd(questID) end
function addon:QuestGoStarterObject(questID) self:QuestGoStart(questID) end
function addon:QuestGoEnderObject(questID) self:QuestGoEnd(questID) end

StaticPopupDialogs["AZEROTHADMIN_QUEST_COMPLETE_AND_GO"] = {
    text = "퀘스트 조건을 GM 완료 처리한 뒤 종료 위치로 이동하시겠습니까?\n\n|cffffff00[%s] %s|r\n\n보상은 자동 지급하지 않습니다. 종료 NPC/오브젝트에서 직접 선택하세요.",
    button1 = YES,
    button2 = NO,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
    OnShow = function(self)
        AzerothAdminEasy:RaisePopup(self)
        AzerothAdminEasy:SuspendManagedEscapeForPopup(self)
    end,
    OnHide = function(self)
        AzerothAdminEasy:ResumeManagedEscapeForPopup(self)
    end,
    OnAccept = function(self, data)
        if not data or not data.id or data.id == 0 then return end
        AzerothAdminEasy:SendNow(".quest complete " .. data.id)
        AzerothAdminEasy:RunAfter(0.75, function()
            AzerothAdminEasy:QuestGoEnd(data.id)
        end)
    end,
}

function addon:QuestCompleteAndGo(quest)
    if not quest or not quest.id or quest.id == 0 then return end
    if quest.complete == 1 or (self.GetQuestProgressStatus and self:GetQuestProgressStatus(quest) == "조건완료") then
        self:QuestGoEnd(quest.id)
        return
    end
    self:HideAddonPopups("AZEROTHADMIN_QUEST_COMPLETE_AND_GO")
    StaticPopup_Show("AZEROTHADMIN_QUEST_COMPLETE_AND_GO", quest.id, quest.title, quest)
end

function addon:GetQuestPOILocation(obj)
    if not obj or not obj.questID then return nil end
    if not GetQuestWorldMapAreaID or not QuestPOIGetIconInfo then return nil end

    local okArea, areaID = pcall(GetQuestWorldMapAreaID, obj.questID)
    local okPOI, _, x, y, objective = pcall(QuestPOIGetIconInfo, obj.questID)
    if not okArea or not okPOI or not areaID or not x or not y then return nil end
    if areaID <= 0 or x < 0 or y < 0 then return nil end

    -- When Blizzard provides an objective number, prefer a matching row.
    if obj.index and objective and objective > 0 and obj.type ~= "drop" and objective ~= obj.index then
        return nil
    end

    return areaID, x * 100, y * 100
end

local function getQuestieDBForDrops()
    if _G.QuestieDB and (type(_G.QuestieDB.QueryItem) == "function" or type(_G.QuestieDB.GetItem) == "function") then
        return _G.QuestieDB
    end
    local loader = _G.QuestieLoader
    if loader and type(loader.ImportModule) == "function" then
        local ok, module = pcall(loader.ImportModule, loader, "QuestieDB")
        if ok and module then return module end
        ok, module = pcall(loader.ImportModule, "QuestieDB")
        if ok and module then return module end
    end
    return nil
end

function addon:GetQuestItemDropSources(obj)
    if not obj then return {} end
    local itemID = tonumber(obj.itemID)
    if not itemID and self.FindLocaleID and obj.targetName then
        itemID = self:FindLocaleID("item", obj.targetName)
        obj.itemID = itemID
    end
    if not itemID then return {} end

    local qdb = getQuestieDBForDrops()
    if not qdb then return {} end
    local sources, seen = {}, {}
    local function addSource(kind, id)
        id = math.abs(tonumber(id) or 0)
        if id <= 0 then return end
        local key = kind .. ":" .. id
        if seen[key] then return end
        seen[key] = true
        table.insert(sources, { type = kind, id = id })
    end

    -- Query only Questie's public drop fields. QueryItem returns values in the
    -- requested order, so vendors can never be mistaken for loot sources and no
    -- private adapter table is required.
    if type(qdb.QueryItem) == "function" then
        local ok, raw = pcall(qdb.QueryItem, itemID, {"npcDrops", "objectDrops"})
        if ok and type(raw) == "table" then
            local npcs = raw[1]
            local objects = raw[2]
            if type(npcs) == "table" then
                for _, id in pairs(npcs) do addSource("monster", id) end
            end
            if type(objects) == "table" then
                for _, id in pairs(objects) do addSource("object", id) end
            end
        end
    end

    -- Older Questie builds may not expose QueryItem.  Their GetItem() source
    -- list is still useful as a fallback; keep it behind the precise path above.
    if table.getn(sources) == 0 and type(qdb.GetItem) == "function" then
        local ok, item = pcall(qdb.GetItem, qdb, itemID)
        if ok and type(item) == "table" and type(item.Sources) == "table" then
            for _, source in pairs(item.Sources) do
                if type(source) == "table" then
                    if source.Type == "object" then
                        addSource("object", source.Id)
                    elseif source.Type == "monster" then
                        addSource("monster", source.Id)
                    end
                end
            end
        end
    end
    -- pairs() iteration order is undefined in Lua 5.1. Keep repeated clicks
    -- predictable: NPC entries first, then game objects, each by ascending ID.
    local sourceOrder = { monster = 1, object = 2 }
    table.sort(sources, function(a, b)
        local aOrder = sourceOrder[a.type] or 99
        local bOrder = sourceOrder[b.type] or 99
        if aOrder ~= bOrder then return aOrder < bOrder end
        return a.id < b.id
    end)
    return sources
end

function addon:QuestObjectiveLookup(obj)
    if not obj then return end
    local name = obj.targetName or ""

    if obj.type == "monster" then
        if self.OpenLocaleSearch then
            self:OpenLocaleSearch("creature", obj.creatureID and tostring(obj.creatureID) or name)
        end
    elseif obj.type == "item" or obj.type == "drop" then
        if BlueItemInfo3 and BlueItemInfo3.Search then
            BlueItemInfo3:Search(obj.itemID and tostring(obj.itemID) or name)
        elseif self.OpenLocaleSearch then
            self:OpenLocaleSearch("item", obj.itemID and tostring(obj.itemID) or name)
        end
    elseif obj.type == "object" then
        if name ~= "" then
            self:SendNow(".lookup object " .. name)
        else
            self:Print("오브젝트 이름을 확인할 수 없습니다.", true)
        end
    else
        if self.OpenLocaleSearch then self:OpenLocaleSearch("quest", tostring(obj.questID or "")) end
    end
end

function addon:QuestObjectiveTeleport(obj)
    if not obj then return end
    if obj.type == "monster" and obj.creatureID then
        self:SendNow(".go creature id " .. obj.creatureID)
        return
    end

    if obj.type == "item" or obj.type == "drop" then
        local sources = self:GetQuestItemDropSources(obj)
        if table.getn(sources) > 0 then
            obj._aaeDropSourceIndex = ((tonumber(obj._aaeDropSourceIndex) or 0) % table.getn(sources)) + 1
            local source = sources[obj._aaeDropSourceIndex]
            if source.type == "object" then
                self:SendNow(".go gameobject id " .. source.id)
                self:Print("드랍 오브젝트 " .. source.id .. " 위치로 이동합니다. (" .. obj._aaeDropSourceIndex .. "/" .. table.getn(sources) .. ")")
            else
                self:SendNow(".go creature id " .. source.id)
                self:Print("드랍 몬스터 " .. source.id .. " 위치로 이동합니다. (" .. obj._aaeDropSourceIndex .. "/" .. table.getn(sources) .. ")")
            end
            return
        end
    end

    local areaID, x, y = self:GetQuestPOILocation(obj)
    if areaID and x and y then
        self:SendNow(string.format(".go zonexy %.2f %.2f %d", x, y, areaID))
        return
    end

    if obj.type == "monster" then
        self:Print("크리쳐 ID 또는 해당 목표의 퀘스트 POI를 확인할 수 없어 한글 검색을 엽니다.")
        self:QuestObjectiveLookup(obj)
    elseif obj.type == "item" or obj.type == "drop" then
        self:Print("드랍 원천 데이터와 퀘스트 POI를 확인하지 못했습니다. 아이템 검색을 엽니다.")
        self:QuestObjectiveLookup(obj)
    elseif obj.type == "object" then
        self:Print("오브젝트 entry 좌표가 클라이언트 로그에 없어 오브젝트 이름 조회를 실행합니다.")
        self:QuestObjectiveLookup(obj)
    else
        self:Print("이 목표의 자동 위치를 확인할 수 없습니다.", true)
    end
end

function addon:QuestObjectiveAddItem(obj)
    if not obj then return end
    if not obj.itemID and self.FindLocaleID and obj.targetName then
        obj.itemID = self:FindLocaleID("item", obj.targetName)
    end
    if not obj.itemID then
        self:Print("아이템 ID를 한글 Locale에서 자동 확인하지 못했습니다. 아이템 검색을 엽니다.", true)
        self:QuestObjectiveLookup(obj)
        return
    end

    local amount = 1
    if obj.current and obj.needed and obj.needed > obj.current then
        amount = obj.needed - obj.current
    elseif obj.finished then
        self:Print("이미 완료된 아이템 목표입니다.")
        return
    end
    local playerName = UnitName("player")
    if playerName and playerName ~= "" then
        self:SendNow(".additem " .. playerName .. " " .. obj.itemID .. " " .. amount)
    else
        self:SendNow(".additem " .. obj.itemID .. " " .. amount)
    end
end

local function objectiveTypeLabel(obj)
    if obj.type == "monster" then return "몹" end
    if obj.type == "item" then return "아이템" end
    if obj.type == "drop" then return "드롭" end
    if obj.type == "object" then return "오브젝트" end
    if obj.type == "log" then return "진행" end
    if obj.type == "event" then return "이벤트" end
    if obj.type == "player" then return "대상" end
    return obj.type or "기타"
end

function addon:RefreshQuestHelperSearchRows()
    if not self.questHelperSearchRows then return end
    local results = self.questHelperSearchResults or {}
    local i
    for i = 1, table.getn(self.questHelperSearchRows) do
        local row = self.questHelperSearchRows[i]
        local result = results[i]
        row.aaeResult = result
        if result then
            row:SetText("[" .. result[1] .. "]  " .. result[2])
            row:Show()
        else
            row:Hide()
        end
    end
    if self.questHelperSearchCount then
        self.questHelperSearchCount:SetText("검색 " .. (self.questHelperSearchTotal or 0) .. "개")
    end
    if self.questHelperSearchResultFrame then
        if table.getn(results) > 0 then self.questHelperSearchResultFrame:Show() else self.questHelperSearchResultFrame:Hide() end
    end
end

function addon:RunQuestHelperSearch()
    if not self.questHelperSearchEdit then return end
    local query = trim(self.questHelperSearchEdit:GetText())
    local data = self.KoKRSearchData and self.KoKRSearchData.quest or {}
    local results = {}
    local total = 0
    if query ~= "" then
        local needle = string.lower(query)
        local numeric = tonumber(query)
        local i
        for i = 1, table.getn(data) do
            local id, name = data[i][1], data[i][2]
            if (numeric and id == numeric) or string.find(string.lower(name or ""), needle, 1, true) then
                total = total + 1
                if table.getn(results) < 6 then table.insert(results, data[i]) end
            end
        end
    end
    self.questHelperSearchResults = results
    self.questHelperSearchTotal = total
    self:RefreshQuestHelperSearchRows()
end

function addon:AddQuestFromHelperSearch(result)
    if not result or not result[1] then return end
    self:SendNow(".quest add " .. result[1])
    if self.questHelperSearchResultFrame then self.questHelperSearchResultFrame:Hide() end
    if self.questHelperSearchEdit then self.questHelperSearchEdit:SetText(""); self.questHelperSearchEdit:ClearFocus() end
    self.questHelperSearchResults = {}
    self.questHelperSearchTotal = 0
    self:RunAfter(0.8, function()
        if addon.questHelperFrame and addon.questHelperFrame:IsShown() then addon:RefreshQuestHelper(true) end
    end)
end

function addon:CreateQuestHelperWindow()
    if self.questHelperFrame then return end

    local frame = CreateFrame("Frame", "AzerothAdminQuestHelperFrame", UIParent)
    frame:SetWidth(880)
    frame:SetHeight(600)
    frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    frame:SetFrameStrata("FULLSCREEN_DIALOG")
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:SetClampedToScreen(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", function(self) self:StartMoving() end)
    frame:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
    frame:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 14,
        insets = { left = 4, right = 4, top = 4, bottom = 4 },
    })
    frame:SetBackdropColor(0.018, 0.025, 0.035, 0.985)
    frame:SetBackdropBorderColor(0.95, 0.58, 0.10, 1)
    frame:Hide()
    self.questHelperFrame = frame
    if self.RegisterEscapeFrame then self:RegisterEscapeFrame(frame) end

    local titleIcon = frame:CreateTexture(nil, "ARTWORK")
    titleIcon:SetTexture("Interface\\Icons\\INV_Misc_Book_07")
    titleIcon:SetWidth(32); titleIcon:SetHeight(32)
    titleIcon:SetPoint("TOPLEFT", frame, "TOPLEFT", 14, -9)
    local title = qText(frame, "퀘스트 도우미 · 진행 중 퀘스트", "large")
    title:SetPoint("TOPLEFT", frame, "TOPLEFT", 54, -17)
    title:SetTextColor(1, 0.78, 0.25)

    local close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -5, -5)

    local refresh = CreateFrame("Button", nil, frame)
    refresh:SetWidth(28); refresh:SetHeight(28)
    refresh:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -42, -10)
    local refreshTex = refresh:CreateTexture(nil, "ARTWORK")
    refreshTex:SetTexture("Interface\\Buttons\\UI-RotationRight-Button-Up")
    refreshTex:SetAllPoints(refresh)
    refresh:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square")
    refresh:SetScript("OnClick", function() addon:RefreshQuestHelper(true) end)
    refresh:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:SetText("새로고침", 1, 0.82, 0.18)
        GameTooltip:AddLine("현재 진행 중 퀘스트 목록/ID/목표를 다시 읽습니다.", 1, 1, 1, true)
        GameTooltip:Show()
    end)
    refresh:SetScript("OnLeave", function() GameTooltip:Hide() end)
    self.questRefreshButton = refresh

    local help = qText(frame, "완료 = 조건 완료 후 종료 위치 이동 · 보상 선택은 종료 NPC/오브젝트에서 직접 진행", "small")
    help:SetPoint("TOPLEFT", frame, "TOPLEFT", 18, -48)
    help:SetTextColor(0.55, 0.88, 0.92)

    local searchLabel = qText(frame, "퀘스트 추가", "small")
    searchLabel:SetPoint("TOPLEFT", frame, "TOPLEFT", 18, -72)
    searchLabel:SetTextColor(1, 0.78, 0.25)
    local searchEdit = qEdit(frame, 380, 23)
    searchEdit:SetPoint("TOPLEFT", frame, "TOPLEFT", 92, -66)
    self.questHelperSearchEdit = searchEdit
    local searchButton = qButton(frame, 72, 23, "검색")
    searchButton:SetPoint("LEFT", searchEdit, "RIGHT", 8, 0)
    searchButton.aaeHint = "koKR 퀘스트 제목 또는 퀘스트 ID로 검색합니다. 결과 클릭 시 .quest add로 등록합니다."
    searchButton:SetScript("OnClick", function() addon:RunQuestHelperSearch() end)
    local searchCount = qText(frame, "", "small")
    searchCount:SetWidth(120); searchCount:SetJustifyH("LEFT")
    searchCount:SetPoint("LEFT", searchButton, "RIGHT", 10, 0)
    searchCount:SetTextColor(0.55, 0.88, 0.92)
    self.questHelperSearchCount = searchCount
    searchEdit:SetScript("OnEnterPressed", function(self) addon:RunQuestHelperSearch(); self:ClearFocus() end)
    searchEdit:SetScript("OnEscapePressed", function(self)
        if addon.questHelperSearchResultFrame and addon.questHelperSearchResultFrame:IsShown() then
            addon.questHelperSearchResultFrame:Hide()
            self:ClearFocus()
        else
            self:ClearFocus()
            frame:Hide()
        end
    end)

    local resultFrame = CreateFrame("Frame", nil, frame)
    resultFrame:SetWidth(540); resultFrame:SetHeight(162)
    resultFrame:SetPoint("TOPLEFT", frame, "TOPLEFT", 90, -94)
    resultFrame:SetFrameLevel(frame:GetFrameLevel() + 30)
    resultFrame:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 12, edgeSize = 10,
        insets = { left = 3, right = 3, top = 3, bottom = 3 },
    })
    resultFrame:SetBackdropColor(0.01, 0.018, 0.024, 0.99)
    resultFrame:SetBackdropBorderColor(0.2, 0.8, 0.9, 1)
    resultFrame:Hide()
    self.questHelperSearchResultFrame = resultFrame
    self.questHelperSearchRows = {}
    local sr
    for sr = 1, 6 do
        local b = qButton(resultFrame, 520, 22, "")
        b:SetPoint("TOPLEFT", resultFrame, "TOPLEFT", 10, -9 - (sr - 1) * 24)
        b.aaeLabel:SetJustifyH("LEFT")
        b:RegisterForClicks("LeftButtonUp", "RightButtonUp")
        b:SetScript("OnClick", function(self, mouseButton)
            if not self.aaeResult then return end
            if mouseButton == "RightButton" and addon.ShowSearchContextMenu then
                addon:ShowSearchContextMenu("quest", self.aaeResult)
            else
                addon:AddQuestFromHelperSearch(self.aaeResult)
            end
        end)
        b:SetScript("OnEnter", function(self)
            if self.aaeResult then
                self:SetBackdropColor(0.07, 0.22, 0.28, 1)
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:SetText("[" .. self.aaeResult[1] .. "] " .. self.aaeResult[2], 1, 0.82, 0.18)
                GameTooltip:AddLine("좌클릭: 이 퀘스트를 캐릭터에게 등록", 0.55, 0.95, 0.75, true)
                GameTooltip:AddLine("우클릭: 추가/시작/종료 위치 메뉴", 1, 0.82, 0.25, true)
                GameTooltip:Show()
            end
        end)
        b:SetScript("OnLeave", function(self) self:SetBackdropColor(0.025, 0.04, 0.055, 1); GameTooltip:Hide() end)
        self.questHelperSearchRows[sr] = b
    end

    self.questSortButtons = {}
    local sortHeaders = {
        { key = "id", x = 18, text = "ID", width = 58 },
        { key = "title", x = 80, text = "퀘스트명", width = 260 },
        { key = "level", x = 345, text = "레벨", width = 58 },
        { key = "region", x = 408, text = "지역", width = 170 },
    }
    local h
    for h = 1, table.getn(sortHeaders) do
        local meta = sortHeaders[h]
        local button = qButton(frame, meta.width, 20, meta.text)
        button:SetPoint("TOPLEFT", frame, "TOPLEFT", meta.x, -99)
        button.aaeSortKey = meta.key
        button.aaeHint = "클릭: " .. meta.text .. " 기준 오름차순/내림차순 정렬"
        button:SetScript("OnClick", function(self) addon:SetQuestHelperSort(self.aaeSortKey) end)
        self.questSortButtons[meta.key] = button
    end
    local actionHeaders = {
        { x = 585, text = "상태", width = 70 },
        { x = 660, text = "시작위치", width = 90 },
        { x = 755, text = "종료위치", width = 90 },
    }
    for h = 1, table.getn(actionHeaders) do
        local meta = actionHeaders[h]
        local label = qText(frame, meta.text, "small")
        label:SetWidth(meta.width); label:SetJustifyH("CENTER")
        label:SetPoint("TOPLEFT", frame, "TOPLEFT", meta.x, -101)
        label:SetTextColor(1, 0.75, 0.20)
    end

    function addon:RefreshQuestSortHeaders()
        if not self.questSortButtons then return end
        local labels = { id = "ID", title = "퀘스트명", level = "레벨", region = "지역" }
        local key, button
        for key, button in pairs(self.questSortButtons) do
            local text = labels[key] or key
            if self.questHelperSortKey == key then text = text .. (self.questHelperSortAsc == false and " ▼" or " ▲") end
            button:SetText(text)
        end
    end
    self.questHelperSortKey = self.questHelperSortKey or "id"
    if self.questHelperSortAsc == nil then self.questHelperSortAsc = true end
    self:RefreshQuestSortHeaders()

    self.questHelperRows = {}
    local i
    for i = 1, QUESTS_PER_PAGE do
        local row = CreateFrame("Frame", nil, frame)
        row:SetWidth(860); row:SetHeight(26)
        row:SetPoint("TOPLEFT", frame, "TOPLEFT", 18, -124 - ((i - 1) * 29))
        row:SetBackdrop({ bgFile = "Interface\\Tooltips\\UI-Tooltip-Background" })
        row:SetBackdropColor(0.02, 0.035, 0.045, (i % 2 == 0) and 0.72 or 0.48)

        local id = qText(row, "", "small")
        id:SetWidth(58); id:SetJustifyH("CENTER"); id:SetPoint("LEFT", row, "LEFT", 0, 0)
        id:SetTextColor(0.45, 0.9, 1.0); row.id = id
        local name = qText(row, "", "small")
        name:SetWidth(260); name:SetJustifyH("LEFT"); name:SetPoint("LEFT", row, "LEFT", 62, 0)
        row.name = name
        local nameClick = CreateFrame("Button", nil, row)
        nameClick:SetWidth(260); nameClick:SetHeight(24); nameClick:SetPoint("LEFT", row, "LEFT", 62, 0)
        nameClick:RegisterForClicks("LeftButtonUp")
        nameClick:SetScript("OnClick", function(self)
            if self.aaeQuest then addon:SelectQuestHelperQuest(self.aaeQuest) end
        end)
        nameClick:SetScript("OnEnter", function(self)
            if self.aaeQuest then
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:SetText("[" .. tostring(self.aaeQuest.id or "") .. "] " .. tostring(self.aaeQuest.title or ""), 1, 0.82, 0.18)
                GameTooltip:AddLine("클릭: 아래 목표 상세 표시", 0.55, 0.95, 0.80, true)
                GameTooltip:Show()
            end
        end)
        nameClick:SetScript("OnLeave", GameTooltip_Hide)
        row.nameClick = nameClick
        local level = qText(row, "", "small")
        level:SetWidth(58); level:SetJustifyH("CENTER"); level:SetPoint("LEFT", row, "LEFT", 327, 0)
        row.level = level
        local region = qText(row, "", "small")
        region:SetWidth(170); region:SetJustifyH("LEFT"); region:SetPoint("LEFT", row, "LEFT", 390, 0)
        region:SetTextColor(0.82, 0.86, 0.90); row.region = region

        local complete = qButton(row, 68, 22, "완료")
        complete:SetPoint("LEFT", row, "LEFT", 567, 0)
        complete:SetScript("OnClick", function(self)
            if self.aaeQuest then addon:QuestCompleteAndGo(self.aaeQuest) end
        end)
        complete.aaeHint = "퀘스트 조건을 완료 처리하고 종료 위치로 이동합니다. 보상은 직접 선택합니다."
        row.complete = complete

        local startPos = qButton(row, 88, 22, "시작위치")
        startPos:SetPoint("LEFT", row, "LEFT", 642, 0)
        startPos:SetScript("OnClick", function(self)
            if self.aaeQuest then addon:QuestGoStart(self.aaeQuest.id) end
        end)
        startPos.aaeHint = "AzerothCore 퀘스트 시작 relation(NPC/오브젝트) 위치로 이동합니다."
        row.startPos = startPos

        local endPos = qButton(row, 88, 22, "종료위치")
        endPos:SetPoint("LEFT", row, "LEFT", 737, 0)
        endPos:SetScript("OnClick", function(self)
            if self.aaeQuest then addon:QuestGoEnd(self.aaeQuest.id) end
        end)
        endPos.aaeHint = "AzerothCore 퀘스트 종료 relation(NPC/오브젝트) 위치로 이동합니다."
        row.endPos = endPos


        self.questHelperRows[i] = row
    end

    local prev = qButton(frame, 76, 22, "◀ 이전")
    prev:SetPoint("TOPLEFT", frame, "TOPLEFT", 20, -365)
    prev:SetScript("OnClick", function()
        if addon.questHelperPage > 1 then addon.questHelperPage = addon.questHelperPage - 1; addon:RefreshQuestHelper(false) end
    end)
    self.questHelperPrev = prev
    local page = qText(frame, "", "small")
    page:SetWidth(210); page:SetJustifyH("CENTER"); page:SetPoint("LEFT", prev, "RIGHT", 14, 0)
    self.questHelperPageText = page
    local nextb = qButton(frame, 76, 22, "다음 ▶")
    nextb:SetPoint("LEFT", page, "RIGHT", 14, 0)
    nextb:SetScript("OnClick", function()
        if addon.questHelperPage < addon.questHelperPageCount then addon.questHelperPage = addon.questHelperPage + 1; addon:RefreshQuestHelper(false) end
    end)
    self.questHelperNext = nextb

    local selectedTitle = qText(frame, "목표 상세: 퀘스트를 선택하세요.", "small")
    selectedTitle:SetPoint("TOPLEFT", frame, "TOPLEFT", 20, -397)
    selectedTitle:SetTextColor(1, 0.78, 0.25)
    self.questHelperSelectedTitle = selectedTitle

    local objectiveHeader = qText(frame, "유형        목표/드롭 내용                                                     위치/드롭          찾기          아이템 생성", "small")
    objectiveHeader:SetPoint("TOPLEFT", frame, "TOPLEFT", 20, -420)
    objectiveHeader:SetTextColor(0.55, 0.88, 0.92)

    self.questObjectiveRows = {}
    for i = 1, MAX_OBJECTIVE_ROWS do
        local row = CreateFrame("Frame", nil, frame)
        row:SetWidth(860); row:SetHeight(27)
        row:SetPoint("TOPLEFT", frame, "TOPLEFT", 18, -443 - ((i - 1) * 31))
        row:SetBackdrop({ bgFile = "Interface\\Tooltips\\UI-Tooltip-Background" })
        row:SetBackdropColor(0.02, 0.035, 0.045, (i % 2 == 0) and 0.72 or 0.48)

        local typ = qText(row, "", "small")
        typ:SetWidth(64); typ:SetJustifyH("CENTER"); typ:SetPoint("LEFT", row, "LEFT", 2, 0)
        row.typeText = typ
        local desc = qText(row, "", "small")
        desc:SetWidth(524); desc:SetJustifyH("LEFT"); desc:SetPoint("LEFT", row, "LEFT", 70, 0)
        desc:SetTextColor(0.95, 0.95, 0.92); row.desc = desc

        local go = qButton(row, 88, 22, "이동")
        go:SetPoint("LEFT", row, "LEFT", 600, 0)
        go:SetScript("OnClick", function(self)
            if self.aaeObjective then addon:QuestObjectiveTeleport(self.aaeObjective) end
        end)
        row.go = go
        local lookup = qButton(row, 72, 22, "찾기")
        lookup:SetPoint("LEFT", row, "LEFT", 694, 0)
        lookup:SetScript("OnClick", function(self)
            if self.aaeObjective then addon:QuestObjectiveLookup(self.aaeObjective) end
        end)
        row.lookup = lookup
        local item = qButton(row, 88, 22, "아이템 생성")
        item:SetPoint("LEFT", row, "LEFT", 772, 0)
        item:SetScript("OnClick", function(self)
            if self.aaeObjective then addon:QuestObjectiveAddItem(self.aaeObjective) end
        end)
        row.item = item
        self.questObjectiveRows[i] = row
    end

    local note = qText(frame, "※ 드랍 아이템은 Questie/QuestieDB의 NPC·오브젝트 드랍 원천을 우선 사용하며, 없으면 3.3.5a 퀘스트 POI로 이동합니다.", "small")
    note:SetWidth(850)
    note:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 20, 12)
    note:SetTextColor(0.72, 0.72, 0.72)

    self.questHelperPage = 1
    self:RefreshQuestHelper(true)
end

function addon:GetQuestProgressStatus(quest)
    if not quest then return "미진행" end
    if quest.complete == 1 then return "조건완료" end
    local objectives = self:GetQuestObjectives(quest)
    local anyProgress, anyObjective, allFinished = false, false, true
    local i
    for i = 1, table.getn(objectives) do
        local obj = objectives[i]
        if not obj.isDropRow then
            anyObjective = true
            local done = obj.finished or (obj.needed and obj.current and obj.needed > 0 and obj.current >= obj.needed)
            if not done then allFinished = false end
            if done or (obj.current and obj.current > 0) then anyProgress = true end
        end
    end
    if anyObjective and allFinished then return "조건완료" end
    return anyProgress and "진행중" or "미진행"
end

function addon:RefreshQuestHelperSelectionHighlight()
    if not self.questHelperRows then return end
    local selectedID = self.questHelperSelectedQuest and self.questHelperSelectedQuest.id or nil
    local i
    for i = 1, table.getn(self.questHelperRows) do
        local row = self.questHelperRows[i]
        local selected = row.aaeQuest and selectedID and row.aaeQuest.id == selectedID
        if selected then
            row:SetBackdropColor(0.07, 0.24, 0.30, 0.98)
        else
            row:SetBackdropColor(0.02, 0.035, 0.045, (i % 2 == 0) and 0.72 or 0.48)
        end
    end
end

function addon:SelectQuestHelperQuest(quest)
    self.questHelperSelectedQuest = quest
    self:RefreshQuestHelperSelectionHighlight()
    if self.questHelperSelectedTitle then
        self.questHelperSelectedTitle:SetText("목표 상세: [" .. quest.id .. "] " .. quest.title .. "  [Lv." .. tostring(quest.level or 0) .. "]")
    end
    local objectives = self:GetQuestObjectives(quest)
    self.questHelperObjectives = objectives

    local i
    for i = 1, MAX_OBJECTIVE_ROWS do
        local row = self.questObjectiveRows[i]
        local obj = objectives[i]
        if obj then
            row.aaeObjective = obj
            row.typeText:SetText(objectiveTypeLabel(obj))
            local extra = ""
            if obj.itemID then extra = "  |cff66ccff[Item:" .. obj.itemID .. "]|r"
            elseif obj.creatureID then extra = "  |cff66ccff[NPC:" .. obj.creatureID .. "]|r" end
            row.desc:SetText((obj.text or "") .. extra)
            row.go.aaeObjective = obj
            row.lookup.aaeObjective = obj
            row.item.aaeObjective = obj

            if obj.type == "monster" then
                row.go:SetText("몹 이동")
                row.go.aaeHint = "NPC entry가 확인되면 해당 몬스터로 이동하고, 없으면 퀘스트 POI를 사용합니다."
                qSetEnabled(row.go, obj.creatureID ~= nil or self:GetQuestPOILocation(obj) ~= nil)
            elseif obj.type == "item" or obj.type == "drop" then
                row.go:SetText("드랍처 이동")
                row.go.aaeHint = "Questie 드랍 데이터가 있으면 몬스터/오브젝트 entry로 이동합니다. 여러 원천은 반복 클릭으로 순환하며, 없으면 퀘스트 POI를 사용합니다."
                qSetEnabled(row.go, true)
            elseif obj.type == "object" then
                row.go:SetText("위치 찾기")
                row.go.aaeHint = "오브젝트 목표의 퀘스트 POI를 우선 사용하고, 좌표가 없으면 이름 조회를 실행합니다."
                qSetEnabled(row.go, true)
            else
                row.go:SetText("POI 이동")
                row.go.aaeHint = "클라이언트가 제공하는 해당 퀘스트 목표 POI 위치로 이동합니다."
                qSetEnabled(row.go, self:GetQuestPOILocation(obj) ~= nil)
            end

            qSetEnabled(row.lookup, true)
            local canAdd = (obj.type == "item" or obj.type == "drop") and obj.itemID and not obj.finished
            qSetEnabled(row.item, canAdd and true or false)
            if obj.itemID then
                row.item.aaeHint = "아이템 ID " .. obj.itemID .. "를 현재 부족 수량만큼 가방에 생성합니다."
            else
                row.item.aaeHint = "한글 Locale에서 아이템 ID가 자동 확인되면 활성화됩니다."
            end
            row:Show()
        else
            row.aaeObjective = nil
            row:Hide()
        end
    end
end

function addon:RefreshQuestHelper(rebuild)
    if not self.questHelperRows then return end
    local data = self.questHelperData
    if rebuild or not data then data = self:BuildQuestHelperData() end

    local count = table.getn(data or {})
    self.questHelperPageCount = math.max(1, math.ceil(count / QUESTS_PER_PAGE))
    if not self.questHelperPage or self.questHelperPage < 1 then self.questHelperPage = 1 end
    if self.questHelperPage > self.questHelperPageCount then self.questHelperPage = self.questHelperPageCount end

    local first = ((self.questHelperPage - 1) * QUESTS_PER_PAGE) + 1
    local i
    for i = 1, QUESTS_PER_PAGE do
        local quest = data[first + i - 1]
        local row = self.questHelperRows[i]
        if quest then
            row.aaeQuest = quest
            row.id:SetText(quest.id or "")
            row.name:SetText(quest.title or "")
            row.level:SetText(tostring(quest.level or 0))
            row.region:SetText(quest.region or "기타")
            local qr, qg, qb = questLevelColor(quest.level)
            row.name:SetTextColor(qr, qg, qb)
            row.level:SetTextColor(qr, qg, qb)
            row.complete.aaeQuest = quest
            row.startPos.aaeQuest = quest
            row.endPos.aaeQuest = quest
            row.nameClick.aaeQuest = quest

            local progressStatus = self:GetQuestProgressStatus(quest)
            row.complete:SetText(progressStatus)
            if progressStatus == "조건완료" then
                row.complete.aaeHint = "조건이 완료되었습니다. 클릭하면 종료 위치로 이동합니다."
            else
                row.complete.aaeHint = progressStatus .. " · 클릭하면 GM 완료 처리 후 종료 위치로 이동합니다."
            end
            row:Show()
        else
            row.aaeQuest = nil
            if row.nameClick then row.nameClick.aaeQuest = nil end
            row:Hide()
        end
    end

    if self.RefreshQuestSortHeaders then self:RefreshQuestSortHeaders() end
    self.questHelperPageText:SetText("진행 중 " .. count .. "개   ·   " .. self.questHelperPage .. " / " .. self.questHelperPageCount)
    qSetEnabled(self.questHelperPrev, self.questHelperPage > 1)
    qSetEnabled(self.questHelperNext, self.questHelperPage < self.questHelperPageCount)

    if self.questHelperSelectedQuest and rebuild then
        local selectedID = self.questHelperSelectedQuest.id
        local found = nil
        for i = 1, count do
            if data[i].id == selectedID then found = data[i]; break end
        end
        if found then
            self:SelectQuestHelperQuest(found)
        else
            self.questHelperSelectedQuest = nil
            self.questHelperSelectedTitle:SetText("목표 상세: 퀘스트를 선택하세요.")
            for i = 1, MAX_OBJECTIVE_ROWS do self.questObjectiveRows[i]:Hide() end
        end
    end
    self:RefreshQuestHelperSelectionHighlight()
end

function addon:ToggleQuestHelper()
    if not self.questHelperFrame then self:CreateQuestHelperWindow() end
    if self.questHelperFrame:IsShown() then
        self.questHelperFrame.aaeReturnFrame=nil
        self.questHelperFrame:Hide()
    else
        self:HideAddonPopups(nil)
        self.questHelperPage = 1
        if self.questHelperSearchEdit then self.questHelperSearchEdit:SetText("") end
        self.questHelperSearchResults = {}
        self.questHelperSearchTotal = 0
        if self.questHelperSearchResultFrame then self.questHelperSearchResultFrame:Hide() end
        if self.questHelperSearchCount then self.questHelperSearchCount:SetText("") end
        self:RefreshQuestHelper(true)
        self:OpenManagedFrame(self.questHelperFrame)
    end
end

local questEvent = CreateFrame("Frame")
questEvent:RegisterEvent("QUEST_LOG_UPDATE")
questEvent:SetScript("OnEvent", function()
    if addon.questHelperFrame and addon.questHelperFrame:IsShown() then
        addon:RefreshQuestHelper(true)
    end
end)
