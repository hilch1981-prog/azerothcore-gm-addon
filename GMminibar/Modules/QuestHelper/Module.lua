-- AzerothAdmin 3.5.0-335a quest-helper UI contract, adapted to AC335 3.3.5a APIs/data.
local A = AzerothAdminAC335
A.UI = type(A.UI) == "table" and A.UI or {}
local UI = A.UI
local QUESTS_PER_PAGE = 8
local MAX_OBJECTIVE_ROWS = 5
local SEARCH_ROWS = 6

local function questIdFromLink(link)
    if type(link) ~= "string" then return nil end
    return tonumber(string.match(link, "Hquest:(%d+)"))
end

local function stripProgress(text)
    text = tostring(text or "")
    text = text:gsub("^%s*%d+%s*/%s*%d+%s*", "")
    text = text:gsub("^%s*%-?%s*", "")
    return text
end

local function objectiveTypeLabel(kind)
    kind = string.lower(tostring(kind or ""))
    if kind == "monster" then return A:L("OBJECTIVE_MONSTER") end
    if kind == "item" then return A:L("OBJECTIVE_ITEM") end
    if kind == "object" then return A:L("OBJECTIVE_OBJECT") end
    if kind == "player" then return A:L("OBJECTIVE_PLAYER") end
    if kind == "log" or kind == "event" then return A:L("OBJECTIVE_EVENT") end
    if kind == "dialogue" or kind == "interact" then return A:L("OBJECTIVE_DIALOGUE") end
    return A:L("OBJECTIVE_OTHER")
end

local function regionName(zone)
    zone = tonumber(zone) or 0
    local names = {
        [5785] = A:L("ZONE_JADE_FOREST"), [5840] = A:L("ZONE_VALLEY_FOUR_WINDS"),
        [6134] = A:L("ZONE_KRASARANG"), [5841] = A:L("ZONE_KUNLAI"),
        [5842] = A:L("ZONE_TOWNLONG"), [5843] = A:L("ZONE_DREAD_WASTES"),
        [5844] = A:L("ZONE_VALE"), [6507] = A:L("ZONE_ISLE_THUNDER"), [6757] = A:L("ZONE_TIMELESS_ISLE"),
    }
    return names[zone] or (zone > 0 and (A:L("ZONE_ID") .. " " .. zone) or A:L("UNKNOWN"))
end

local function targetHasCoordinates(target)
    if not target then return false end
    local map = tonumber(target.m)
    local x, y, z = tonumber(target.x), tonumber(target.y), tonumber(target.z)
    if map == nil or x == nil or y == nil or z == nil then return false end
    -- Zero on one axis is a valid world coordinate.  Reject only the synthetic
    -- all-zero marker used when the pinned DB has no active spawn.
    return not (x == 0 and y == 0 and z == 0)
end

local function targetNavigationQuality(target)
    if not target then return 0 end
    if targetHasCoordinates(target) then return 40 end
    local guid = tonumber(target.g) or 0
    local entry = tonumber(target.e) or 0
    if target.k == "o" and guid > 0 then return 35 end
    if target.k == "c" and guid > 0 then return 35 end
    if target.k == "c" and entry > 0 then return 10 end
    return 0
end

local function targetCanNavigate(target)
    return targetNavigationQuality(target) > 0
end

local function targetIdentity(target)
    if not target then return "" end
    if targetHasCoordinates(target) then
        return table.concat({ "xyz", tostring(target.m), string.format("%.2f", tonumber(target.x) or 0), string.format("%.2f", tonumber(target.y) or 0), string.format("%.2f", tonumber(target.z) or 0) }, ":")
    end
    return table.concat({ tostring(target.k or ""), tostring(target.g or 0), tostring(target.e or 0) }, ":")
end

local function prioritizeTargets(values)
    local strong, weak, seen = {}, {}, {}
    for _, target in ipairs(values or {}) do
        local quality = targetNavigationQuality(target)
        local key = targetIdentity(target)
        if quality > 0 and not seen[key] then
            seen[key] = true
            if quality >= 30 then table.insert(strong, target) else table.insert(weak, target) end
        end
    end
    local function sortTargets(list)
        table.sort(list, function(left, right)
            local lq, rq = targetNavigationQuality(left), targetNavigationQuality(right)
            if lq ~= rq then return lq > rq end
            local ln = string.lower(tostring(left.n or ""))
            local rn = string.lower(tostring(right.n or ""))
            if ln ~= rn then return ln < rn end
            return (tonumber(left.g) or tonumber(left.e) or 0) < (tonumber(right.g) or tonumber(right.e) or 0)
        end)
    end
    sortTargets(strong); sortTargets(weak)
    -- Never cycle from a verified coordinate/GUID into a known spawnless entry.
    if table.getn(strong) > 0 then return strong end
    return weak
end

local function targetTypeLabel(target)
    if not target then return A:L("UNKNOWN") end
    if target.k == "c" then return A:L("OBJECTIVE_MONSTER") end
    if target.k == "o" then return A:L("OBJECTIVE_OBJECT") end
    return A:L("QUEST_LOCATION")
end

local function targetSummary(target)
    if not target then return A:L("QUEST_LOCATION_UNAVAILABLE") end
    local name = target.n and target.n ~= "" and target.n or (targetTypeLabel(target) .. " " .. tostring(target.e or target.g or ""))
    if targetHasCoordinates(target) then
        return name .. " · " .. A:L("MAP_COORDS", tonumber(target.m) or 0, tonumber(target.x) or 0, tonumber(target.y) or 0, tonumber(target.z) or 0)
    end
    if target.k == "c" and tonumber(target.g) and tonumber(target.g) > 0 then return name .. " · creature GUID " .. tostring(target.g) end
    if target.k == "c" and tonumber(target.e) then return name .. " · creature " .. tostring(target.e) .. " · " .. A:L("QUEST_ENTRY_FALLBACK") end
    if target.k == "o" and tonumber(target.g) then return name .. " · gameobject GUID " .. tostring(target.g) end
    return name
end

local function generatedItemName(itemID)
    itemID = tonumber(itemID)
    if not itemID then return nil end
    if GetItemInfo then
        local ok, name = pcall(GetItemInfo, itemID)
        if ok and name and name ~= "" then return name end
    end
    local row = A.Data and A.Data:GetGeneratedById("Items", itemID) or nil
    return row and row[2] or nil
end

local function namedTargetFromObjective(objective)
    local sources = { objective and objective.targets, objective and objective.dbObjective and objective.dbObjective.r }
    if objective and objective.lookupTarget then table.insert(sources, 1, { objective.lookupTarget }) end
    for _, values in ipairs(sources) do
        for _, target in ipairs(values or {}) do
            if target and target.n and target.n ~= "" then return target end
        end
    end
    return nil
end

function A:GetQuestLocationRecord(questID)
    if self.Data and self.Data.GetQuestLocation then return self.Data:GetQuestLocation(questID) end
    return self.AC335QuestLocations and self.AC335QuestLocations[tonumber(questID)] or nil
end

function A:GoToQuestTarget(target, context)
    if self.QuestLogBridge then self.QuestLogBridge.partyMove=nil end
    if self.IsUnsafeQuestTarget and self:IsUnsafeQuestTarget(target) then self:Print(self:L("QUEST_DESTINATION_QUARANTINED"),true);return false end
    if not targetCanNavigate(target) then
        self:Print(self:L("QUEST_LOCATION_UNAVAILABLE"), true)
        return false
    end
    local bridge=self.QuestLogBridge
    if bridge and bridge.BeginPartyMove then bridge:BeginPartyMove(target)end
    local ok = false
    if targetHasCoordinates(target) then
        local suffix = string.format("%.3f %.3f %.3f %d", tonumber(target.x) or 0, tonumber(target.y) or 0, tonumber(target.z) or 0, tonumber(target.m) or 0)
        ok = self:RunRegisteredCommand("go_xyz", suffix, true)
    elseif target.k == "c" then
        if tonumber(target.g) and tonumber(target.g) > 0 then
            ok = self:RunRegisteredCommand("go_creature", tostring(target.g), true)
        elseif tonumber(target.e) and tonumber(target.e) > 0 then
            ok = self:RunRegisteredCommand("go_creature", "id " .. tostring(target.e), true)
        end
    elseif target.k == "o" and tonumber(target.g) and tonumber(target.g) > 0 then
        ok = self:RunRegisteredCommand("go_object", tostring(target.g), true)
    end
    if ok then
        self:Debug("Quest navigation quality=" .. tostring(targetNavigationQuality(target)) .. " target=" .. targetSummary(target))
        self:Print(self:L("QUEST_NAVIGATING", context or targetSummary(target)))
    end
    if not ok and bridge then bridge.partyMove=nil end
    return ok and true or false
end

function A:GetQuestLocationTargets(quest, kind)
    local record = quest and self:GetQuestLocationRecord(quest.id) or nil
    local values = record and record[kind] or nil
    return prioritizeTargets(values)
end

function A:QuestGoLocation(quest, kind)
    local targets = self:GetQuestLocationTargets(quest, kind)
    if table.getn(targets) == 0 then
        self:Print(self:L("QUEST_LOCATION_UNAVAILABLE"), true)
        return false
    end
    self.questLocationCycle = self.questLocationCycle or {}
    local key = tostring(quest.id) .. ":" .. tostring(kind)
    local index = 1 -- Start/end buttons are stable; only condition navigation cycles.
    self.questLocationCycle[key] = index
    return self:GoToQuestTarget(targets[index], (kind == "s" and self:L("START_LOCATION") or self:L("END_LOCATION")) .. " · " .. targetSummary(targets[index]))
end

function A:GetQuestLocationHint(quest, kind)
    local targets = self:GetQuestLocationTargets(quest, kind)
    if table.getn(targets) == 0 then
        local record = quest and self:GetQuestLocationRecord(quest.id) or nil
        local raw = record and record[kind] or nil
        if type(raw) == "table" and table.getn(raw) > 0 then
            return { self:L("QUEST_LOCATION_UNAVAILABLE"), self:L("QUEST_RELATION_NO_ACTIVE_SPAWN") }
        end
        return { self:L("QUEST_LOCATION_UNAVAILABLE"), self:L("QUEST_ITEM_SCRIPT_START_HINT") }
    end
    local lines = { self:L("QUEST_LOCATION_COUNT", table.getn(targets)), self:L("QUEST_LOCATION_CYCLE_HINT") }
    for index = 1, math.min(table.getn(targets), 3) do table.insert(lines, targetSummary(targets[index])) end
    return lines
end

local function generatedObjectiveKind(clientType)
    clientType = string.lower(tostring(clientType or ""))
    if clientType == "monster" or clientType == "player" then return "c" end
    if clientType == "object" then return "o" end
    if clientType == "item" then return "i" end
    return nil
end

local function normalizedObjectiveText(value)
    value = stripProgress(value)
    value = value:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
    value = string.lower(value):gsub("[%p%c]", " "):gsub("%s+", " ")
    return value:match("^%s*(.-)%s*$") or ""
end

local function candidateObjectiveText(candidate)
    local parts = { tostring(candidate and candidate.d or "") }
    for _, target in ipairs((candidate and candidate.r) or {}) do
        if target.n and target.n ~= "" then table.insert(parts, target.n) end
    end
    return normalizedObjectiveText(table.concat(parts, " "))
end

local function objectiveCandidateScore(objective, candidate)
    local score = 0
    local wanted = generatedObjectiveKind(objective and objective.type)
    if tonumber(candidate.s) == tonumber(objective and objective.objectiveIndex) then score = score + 100 end
    if wanted and candidate.k == wanted then score = score + 45
    elseif wanted and candidate.k ~= "x" then score = score - 20 end
    if objective and objective.itemID and tonumber(candidate.i) == tonumber(objective.itemID) then score = score + 90 end
    if table.getn(prioritizeTargets(candidate.r or {})) > 0 then score = score + 12 end

    local left = normalizedObjectiveText(objective and objective.description or "")
    local right = candidateObjectiveText(candidate)
    if left ~= "" and right ~= "" then
        if string.find(left, right, 1, true) or string.find(right, left, 1, true) then score = score + 35 end
        local matched = 0
        for token in string.gmatch(left, "[^%s]+") do
            if string.len(token) >= 2 and string.find(right, token, 1, true) then matched = matched + 1 end
        end
        score = score + math.min(24, matched * 4)
    end
    return score
end

function A:AttachQuestObjectiveNavigation(quest, objectives)
    local record = quest and self:GetQuestLocationRecord(quest.id) or nil
    local generated = record and record.o or {}
    local used = {}
    for _, objective in ipairs(objectives or {}) do
        if not objective.special then
            local selected, selectedIndex, selectedScore = nil, nil, -100000
            for index, candidate in ipairs(generated) do
                if not used[index] then
                    local score = objectiveCandidateScore(objective, candidate)
                    if score > selectedScore then
                        selected, selectedIndex, selectedScore = candidate, index, score
                    end
                end
            end
            if selectedIndex then used[selectedIndex] = true end
            objective.dbObjective = selected
            if selected then
                objective.itemID = objective.itemID or tonumber(selected.i)
                objective.needed = objective.needed or tonumber(selected.c)
                objective.targets = prioritizeTargets(selected.r or {})
            else
                objective.targets = {}
            end
        end
    end
    return objectives
end

function A:FindQuestHelperQuestByID(id)
    id = tonumber(id)
    if not id then return nil end
    for _, quest in ipairs(self.questHelperData or {}) do
        if tonumber(quest.id) == id then return quest end
    end
    return nil
end

function A:ValidateQuestObjectiveSelection(objective)
    local objectiveQuestID = objective and objective.quest and tonumber(objective.quest.id) or nil
    local selectedID = tonumber(self.questHelperSelectedQuestID)
    if objectiveQuestID and selectedID and objectiveQuestID ~= selectedID then
        self:SelectQuestHelperQuest(self:FindQuestHelperQuestByID(selectedID))
        self:Print(self:L("QUEST_SELECTION_REFRESHED"), true)
        return false
    end
    return objectiveQuestID ~= nil and selectedID == objectiveQuestID
end

function A:QuestObjectiveCanMove(objective)
    return objective and type(objective.targets) == "table" and table.getn(objective.targets) > 0
end

function A:QuestObjectiveTeleport(objective)
    if not self:ValidateQuestObjectiveSelection(objective) then return false end
    if not self:QuestObjectiveCanMove(objective) then
        self:Print(self:L("QUEST_OBJECTIVE_MOVE_UNAVAILABLE"), true)
        return false
    end
    objective.targetIndex = ((tonumber(objective.targetIndex) or 0) % table.getn(objective.targets)) + 1
    return self:GoToQuestTarget(objective.targets[objective.targetIndex], stripProgress(objective.description))
end

function A:GetQuestObjectiveMoveHint(objective)
    if not self:QuestObjectiveCanMove(objective) then
        local dbObjective = objective and objective.dbObjective or nil
        if dbObjective then
            local id = dbObjective.i or dbObjective.e or dbObjective.id or 0
            return { self:L("QUEST_OBJECTIVE_MOVE_UNAVAILABLE"), self:L("QUEST_OBJECTIVE_RELATION_NO_SPAWN", tostring(id)) }
        end
        return { self:L("QUEST_OBJECTIVE_MOVE_UNAVAILABLE") }
    end
    local lines = { self:L("QUEST_LOCATION_COUNT", table.getn(objective.targets)), self:L("QUEST_LOCATION_CYCLE_HINT") }
    for index = 1, math.min(table.getn(objective.targets), 3) do table.insert(lines, targetSummary(objective.targets[index])) end
    return lines
end

local function questLogTitle(index)
    if not GetQuestLogTitle then return nil end
    -- Client 3.3.5a (12340), FrameXML/QuestLogFrame.lua:422, tag 3.3.5a.
    -- questTag is still slot 3; header/complete/questID are slots 5/7/9.
    local title, level, _, suggestedGroup, isHeader, isCollapsed, isComplete, frequency, questID = GetQuestLogTitle(index)
    return title, level, suggestedGroup, isHeader, isCollapsed, isComplete, frequency, questID
end

A.ReadQuestLogTitle = questLogTitle

local function expandQuestHeaders()
    if not ExpandQuestHeader or not GetNumQuestLogEntries or not GetQuestLogTitle then return false end
    local changed = false
    for _ = 1, 50 do
        local expandedThisPass = false
        local count = GetNumQuestLogEntries() or 0
        for index = 1, count do
            local _, _, _, isHeader, isCollapsed = questLogTitle(index)
            if isHeader and isCollapsed then
                pcall(ExpandQuestHeader, index)
                changed = true
                expandedThisPass = true
                break
            end
        end
        if not expandedThisPass then break end
    end
    return changed
end

function A:BuildQuestHelperData()
    local expanded = expandQuestHeaders()
    local rows = {}
    local count = GetNumQuestLogEntries and (GetNumQuestLogEntries() or 0) or 0
    local currentHeader = nil
    for index = 1, count do
        local title, level, _, isHeader, _, isComplete, _, questID = questLogTitle(index)
        if title and isHeader then
            currentHeader = title
        elseif title then
            local link = nil
            if GetQuestLink then
                local ok, value = pcall(GetQuestLink, index)
                if ok then link = value end
            end
            questID = tonumber(questID) or questIdFromLink(link)
            if questID and questID > 0 then
                local generated = self.Data:GetGeneratedById("Quests", questID)
                local zone = generated and generated[5] or 0
                local region = zone and tonumber(zone) ~= 0 and regionName(zone) or (currentHeader or self:L("UNKNOWN"))
                table.insert(rows, {
                    logIndex = index, id = questID, title = title,
                    level = tonumber(level) or (generated and tonumber(generated[3])) or 0,
                    complete = isComplete, zone = zone, region = region, header = currentHeader, generated = generated,
                })
            end
        end
    end
    self.questHelperData = rows
    self:SortQuestHelperData()
    if expanded and self.questHelperFrame then self:ScheduleQuestHelperRefresh(0.20) end
end

function A:ScheduleQuestHelperRefresh(delay)
    self.questHelperRefreshSerial = (self.questHelperRefreshSerial or 0) + 1
    local serial = self.questHelperRefreshSerial
    self:RunAfter(delay or 0.15, function()
        if serial ~= A.questHelperRefreshSerial then return end
        A:BuildQuestHelperData()
        if A.questHelperFrame then A:RefreshQuestHelper(false) end
    end)
end

function A:SortQuestHelperData()
    local rows = self.questHelperData or {}
    local key = self.questHelperSortKey or "id"
    local ascending = self.questHelperSortAsc ~= false
    table.sort(rows, function(left, right)
        local a, b
        if key == "title" then a, b = string.lower(left.title or ""), string.lower(right.title or "")
        elseif key == "level" then a, b = tonumber(left.level) or 0, tonumber(right.level) or 0
        elseif key == "region" then a, b = string.lower(left.region or ""), string.lower(right.region or "")
        else a, b = tonumber(left.id) or 0, tonumber(right.id) or 0 end
        if a == b then return (tonumber(left.id) or 0) < (tonumber(right.id) or 0) end
        if ascending then return a < b end
        return a > b
    end)
end

function A:SetQuestHelperSort(key)
    if self.questHelperSortKey == key then self.questHelperSortAsc = not self.questHelperSortAsc
    else self.questHelperSortKey = key; self.questHelperSortAsc = true end
    self:SortQuestHelperData()
    self.questHelperPage = 1
    self:RefreshQuestHelper(false)
end

function A:GetQuestProgressStatus(quest)
    if not quest then return self:L("QUEST_NOT_STARTED") end
    if quest.complete == 1 or quest.complete == true then return self:L("QUEST_CONDITION_COMPLETE") end
    local progress = false
    if GetNumQuestLeaderBoards and GetQuestLogLeaderBoard then
        local count = GetNumQuestLeaderBoards(quest.logIndex) or 0
        for i = 1, count do
            local description, _, finished = GetQuestLogLeaderBoard(i, quest.logIndex)
            if finished then progress = true
            elseif description and string.match(description, "(%d+)%s*/%s*(%d+)") then
                local current = tonumber(string.match(description, "(%d+)%s*/")) or 0
                if current > 0 then progress = true end
            end
        end
    end
    return progress and self:L("QUEST_IN_PROGRESS") or self:L("QUEST_NOT_STARTED")
end

function A:GetQuestObjectives(quest)
    local objectives = {}
    if not quest or not quest.logIndex then return objectives end
    if SelectQuestLogEntry then pcall(SelectQuestLogEntry, quest.logIndex) end
    local count = GetNumQuestLeaderBoards and (GetNumQuestLeaderBoards(quest.logIndex) or 0) or 0
    for index = 1, count do
        local description, objectiveType, finished = GetQuestLogLeaderBoard(index, quest.logIndex)
        local current, needed = tostring(description or ""):match("(%d+)%s*/%s*(%d+)")
        local itemID = tostring(description or ""):match("item:(%d+)")
        table.insert(objectives, {
            objectiveIndex = index,
            description = description or self:L("UNKNOWN"), type = objectiveType or "other", finished = finished and true or false,
            current = tonumber(current), needed = tonumber(needed), itemID = tonumber(itemID), quest = quest,
        })
    end
    if GetQuestLogSpecialItemInfo then
        local link, texture, charges, showWhenComplete = GetQuestLogSpecialItemInfo(quest.logIndex)
        local itemID = link and tonumber(string.match(link, "item:(%d+)")) or nil
        if itemID and table.getn(objectives) < MAX_OBJECTIVE_ROWS then
            table.insert(objectives, {
                description = self:L("QUEST_SPECIAL_ITEM") .. ": " .. tostring(link), type = "item", itemID = itemID,
                special = true, texture = texture, charges = charges, finished = showWhenComplete and quest.complete and true or false, quest = quest,
            })
        end
    end

    -- Dialogue/report/delivery quests often expose no leaderboard rows at all.
    -- The pinned AC335 DB still has a verified end relation, so surface that NPC
    -- as an explicit dialogue objective instead of leaving the lower pane empty.
    if table.getn(objectives) == 0 then
        local endTargets = self:GetQuestLocationTargets(quest, "e")
        local target = endTargets[1]
        if target then
            local targetName = target.n and target.n ~= "" and target.n or (self:L("OBJECTIVE_MONSTER") .. " " .. tostring(target.e or target.g or ""))
            table.insert(objectives, {
                objectiveIndex = 1, description = self:L("QUEST_DIALOGUE_OBJECTIVE", targetName),
                type = "dialogue", finished = quest.complete == 1 or quest.complete == true, quest = quest,
                special = true, syntheticDialogue = true, lookupTarget = target, targets = endTargets,
                dbObjective = { k = target.k, e = target.e, r = endTargets },
            })
        end
    end
    return self:AttachQuestObjectiveNavigation(quest, objectives)
end

function A:GetQuestObjectiveLookupQuery(objective)
    if not objective then return nil, nil end
    local dbObjective = objective.dbObjective
    local kind = dbObjective and dbObjective.k or generatedObjectiveKind(objective.type)
    local target = namedTargetFromObjective(objective)
    local fallback = stripProgress(objective.description)

    if kind == "i" or objective.type == "item" then
        local itemID = objective.itemID or (dbObjective and tonumber(dbObjective.i))
        return "lookup_item", generatedItemName(itemID) or fallback
    elseif kind == "c" or objective.type == "dialogue" or objective.type == "interact" then
        return "lookup_creature", (target and target.n) or fallback
    elseif kind == "o" then
        return "lookup_object", (target and target.n) or fallback
    end
    return "lookup_quest", tostring(objective.quest and objective.quest.id or "")
end

function A:QuestObjectiveLookup(objective)
    if not self:ValidateQuestObjectiveSelection(objective) then return false end
    local command, query = self:GetQuestObjectiveLookupQuery(objective)
    query = self:Trim(query or "")
    if not command or query == "" then
        self:Print(self:L("QUEST_LOOKUP_NAME_UNAVAILABLE"), true)
        return false
    end
    -- AzerothCore lookup handlers receive the full remaining argument string
    -- and do not strip quote characters. Send the localized name as plain text.
    return self:RunRegisteredCommand(command, query, true)
end

function A:QuestObjectiveAddItem(objective)
    if not self:ValidateQuestObjectiveSelection(objective) then return false end
    if objective and objective.itemID then
        local amount = objective.needed or 1
        self:ShowItemQuantityPopup(objective.itemID, stripProgress(objective.description), amount)
    end
end

function A:SelectQuestHelperQuest(quest)
    local questID = type(quest) == "table" and tonumber(quest.id) or tonumber(quest)
    local resolved = questID and self:FindQuestHelperQuestByID(questID) or nil
    if not resolved and type(quest) == "table" then resolved = quest end
    self.questHelperSelectedQuestID = resolved and tonumber(resolved.id) or nil
    self.questHelperSelectedQuest = resolved
    local frame = self.questHelperFrame
    if not frame then return end
    if not resolved then
        frame.selectedTitle:SetText(self:L("QUEST_SELECT_PROMPT"))
        for _, row in ipairs(frame.objectiveRows) do row.objective = nil; row.go.objective=nil; row.lookup.objective=nil; row.item.objective=nil; row:Hide() end
        return
    end
    frame.selectedTitle:SetText(self:L("QUEST_SELECTED", resolved.id, resolved.title))
    local objectives = self:GetQuestObjectives(resolved)
    for index = 1, MAX_OBJECTIVE_ROWS do
        local row = frame.objectiveRows[index]
        local objective = objectives[index]
        row.objective = objective
        row.go.objective = objective; row.lookup.objective = objective; row.item.objective = objective
        if objective then
            objective.quest = resolved
            row.typeText:SetText(objectiveTypeLabel(objective.type))
            local mark = objective.finished and "|cff55ff77✓|r " or ""
            row.desc:SetText(mark .. tostring(objective.description or ""))
            row:Show()
            UI:SetEnabled(row.go, self:QuestObjectiveCanMove(objective))
            UI:SetEnabled(row.lookup, true)
            UI:SetEnabled(row.item, objective.itemID ~= nil)
        else row:Hide() end
    end
    for _, row in ipairs(frame.questRows) do
        if row.quest and tonumber(row.quest.id) == tonumber(resolved.id) then row:SetBackdropColor(0.07, 0.24, 0.30, 0.98)
        else row:SetBackdropColor(0.02, 0.035, 0.045, (row.rowIndex % 2 == 0) and 0.72 or 0.48) end
    end
end

function A:RefreshQuestSortHeaders()
    local labels = { id = "QUEST_ID", title = "QUEST_NAME", level = "LEVEL", region = "REGION" }
    for key, button in pairs(self.questSortButtons or {}) do
        local text = self:L(labels[key] or key)
        if self.questHelperSortKey == key then text = text .. (self.questHelperSortAsc == false and " ▼" or " ▲") end
        button:SetText(text)
    end
end

function A:RefreshQuestHelper(rebuild)
    local frame = self.questHelperFrame
    if not frame then return end
    if rebuild or not self.questHelperData then self:BuildQuestHelperData() end
    local rows = self.questHelperData or {}
    local count = table.getn(rows)
    local maxPage = math.max(1, math.ceil(count / QUESTS_PER_PAGE))
    self.questHelperPage = math.max(1, math.min(self.questHelperPage or 1, maxPage))
    local first = (self.questHelperPage - 1) * QUESTS_PER_PAGE + 1
    for index = 1, QUESTS_PER_PAGE do
        local row = frame.questRows[index]
        local quest = rows[first + index - 1]
        row.quest = quest; row.nameClick.quest = quest; row.complete.quest = quest; row.startPos.quest = quest; row.endPos.quest = quest
        if quest then
            row.id:SetText(tostring(quest.id or 0)); row.name:SetText(quest.title or ""); row.level:SetText(tostring(quest.level or 0)); row.region:SetText(quest.region or "")
            local status = self:GetQuestProgressStatus(quest)
            row.complete:SetText(status)
            row.complete.aaeEnabledStyle = (quest.complete == 1 or quest.complete == true) and "reward" or "utility"
            UI:SetEnabled(row.complete, self:CanRunCommand("quest_complete"))
            UI:SetEnabled(row.startPos, table.getn(self:GetQuestLocationTargets(quest, "s")) > 0)
            UI:SetEnabled(row.endPos, table.getn(self:GetQuestLocationTargets(quest, "e")) > 0)
            row:Show()
        else row:Hide() end
    end
    frame.pageText:SetText(self:L("QUEST_PAGE_STATUS", count, self.questHelperPage, maxPage))
    if frame.activeCount then frame.activeCount:SetText(self:L("QUEST_ACTIVE_COUNT", count)) end
    if frame.emptyText then if count == 0 then frame.emptyText:Show() else frame.emptyText:Hide() end end
    UI:SetEnabled(frame.previous, self.questHelperPage > 1); UI:SetEnabled(frame.next, self.questHelperPage < maxPage)
    self:RefreshQuestSortHeaders()
    local pendingID = tonumber(self.questHelperPendingSelectID)
    local selectedID = pendingID or tonumber(self.questHelperSelectedQuestID)
    local selected = selectedID and self:FindQuestHelperQuestByID(selectedID) or nil
    if pendingID and selected then self.questHelperPendingSelectID = nil end
    self:SelectQuestHelperQuest(selected)
end

function A:RunQuestHelperSearch()
    local frame = self.questHelperFrame
    if not frame then return end
    local query = self:Trim(frame.searchEdit:GetText())
    if query == "" then frame.searchResultFrame:Hide(); frame.searchCount:SetText(""); return end
    local results, total = self.Data:SearchGenerated("Quests", query, SEARCH_ROWS, 0)
    frame.searchResults = results
    frame.searchCount:SetText(self:L("QUEST_SEARCH_COUNT", total))
    for index = 1, SEARCH_ROWS do
        local button = frame.searchRows[index]
        local result = results[index]
        button.result = result
        if result then
            button:SetText("[" .. tostring(result[1]) .. "] " .. tostring(result[2]) .. " · Lv " .. tostring(result[3] or 0) .. " · " .. regionName(result[5]))
            button:Show()
        else button:Hide() end
    end
    if table.getn(results) > 0 then frame.searchResultFrame:Show(); frame.searchResultFrame:Raise() else frame.searchResultFrame:Hide() end
end

function A:AddQuestFromHelperSearch(result)
    if not result then return end
    local id = tonumber(result[1])
    if not id then return end
    self.questHelperPendingSelectID = id
    self:RunRegisteredCommand("quest_add", tostring(id), true)
    if self.questHelperFrame then self.questHelperFrame.searchResultFrame:Hide() end
    self:RunAfter(0.45, function()
        A:BuildQuestHelperData()
        if A.questHelperFrame then A:RefreshQuestHelper(false) end
    end)
end

function A:CreateQuestHelperWindow()
    if self.questHelperFrame then return end
    local frame = UI:CreateWindow("quest_helper", self:L("QUEST_HELPER"), 880, 600, "strong")
    self.questHelperFrame = frame
    frame.aaeTitle:ClearAllPoints(); frame.aaeTitle:SetPoint("TOPLEFT", frame, "TOPLEFT", 54, -17)
    local titleIcon = frame:CreateTexture(nil, "ARTWORK"); titleIcon:SetTexture("Interface\\Icons\\INV_Misc_Book_07")
    titleIcon:SetWidth(32); titleIcon:SetHeight(32); titleIcon:SetPoint("TOPLEFT", frame, "TOPLEFT", 14, -9)
    frame.aaeTitleIcon = titleIcon
    local refresh = CreateFrame("Button", nil, frame); refresh:SetWidth(28); refresh:SetHeight(28); refresh:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -42, -10)
    local refreshTex = refresh:CreateTexture(nil, "ARTWORK"); refreshTex:SetTexture("Interface\\Buttons\\UI-RotationRight-Button-Up"); refreshTex:SetAllPoints(refresh)
    refresh:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square")
    refresh:SetScript("OnClick", function() A:RefreshQuestHelper(true) end)
    refresh:SetScript("OnEnter", function(self) UI:ShowHint(self, A:L("REFRESH"), A:L("QUEST_REFRESH_HINT"), "ANCHOR_LEFT") end)
    refresh:SetScript("OnLeave", function() GameTooltip:Hide() end)

    local help = UI:Text(frame, self:L("QUEST_HELPER_CANONICAL_HINT"), "small")
    help:SetWidth(440); help:SetJustifyH("LEFT"); help:SetPoint("TOPLEFT", frame, "TOPLEFT", 18, -48); help:SetTextColor(0.55, 0.88, 0.92)
    local activeCount = UI:Text(frame, self:L("QUEST_ACTIVE_COUNT", 0), "small")
    activeCount:SetWidth(150); activeCount:SetJustifyH("RIGHT"); activeCount:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -48, -72); activeCount:SetTextColor(0.45, 0.90, 1.00); frame.activeCount = activeCount
    local syncLabel = UI:Text(frame, self:L("PARTY_BOT_SYNC"), "small"); syncLabel:SetPoint("TOPLEFT", frame, "TOPLEFT", 462, -48); syncLabel:SetTextColor(1, 0.78, 0.25)
    local syncMissing = UI:Check(frame, 150, self:L("PARTY_BOT_ADD_MISSING"), false)
    syncMissing:SetPoint("TOPLEFT", frame, "TOPLEFT", 560, -43); syncMissing:Disable(); syncMissing.aaeLabel:SetTextColor(0.40, 0.42, 0.43)
    local syncComplete = UI:Check(frame, 160, self:L("PARTY_BOT_COMPLETE"), false)
    syncComplete:SetPoint("TOPLEFT", frame, "TOPLEFT", 712, -43); syncComplete:Disable(); syncComplete.aaeLabel:SetTextColor(0.40, 0.42, 0.43)
    syncMissing:SetScript("OnEnter", function(self) UI:ShowHint(self, A:L("PARTY_BOT_SYNC"), A:L("PLAYERBOT_BLOCKED")) end)
    syncMissing:SetScript("OnLeave", function() GameTooltip:Hide() end)
    syncComplete:SetScript("OnEnter", function(self) UI:ShowHint(self, A:L("PARTY_BOT_SYNC"), A:L("PLAYERBOT_BLOCKED")) end)
    syncComplete:SetScript("OnLeave", function() GameTooltip:Hide() end)

    local searchLabel = UI:Text(frame, self:L("QUEST_ADD"), "small"); searchLabel:SetPoint("TOPLEFT", frame, "TOPLEFT", 18, -72); searchLabel:SetTextColor(1, 0.78, 0.25)
    local searchEdit = UI:EditBox(frame, 380, 23, "AzerothAdminAC335QuestSearch"); searchEdit:SetPoint("TOPLEFT", frame, "TOPLEFT", 92, -66); frame.searchEdit = searchEdit
    local searchButton = UI:Button(frame, 72, 23, self:L("SEARCH"), "utility"); searchButton:SetPoint("LEFT", searchEdit, "RIGHT", 8, 0)
    searchButton:SetScript("OnClick", function() A:RunQuestHelperSearch() end)
    local searchCount = UI:Text(frame, "", "small"); searchCount:SetWidth(120); searchCount:SetJustifyH("LEFT"); searchCount:SetPoint("LEFT", searchButton, "RIGHT", 10, 0); searchCount:SetTextColor(0.55, 0.88, 0.92); frame.searchCount = searchCount
    searchEdit:SetScript("OnEnterPressed", function(self) A:RunQuestHelperSearch(); self:ClearFocus() end)
    searchEdit:SetScript("OnEscapePressed", function(self) if frame.searchResultFrame:IsShown() then frame.searchResultFrame:Hide() else self:ClearFocus(); frame:Hide() end end)

    local resultFrame = CreateFrame("Frame", nil, frame); resultFrame:SetWidth(540); resultFrame:SetHeight(162); resultFrame:SetPoint("TOPLEFT", frame, "TOPLEFT", 90, -94)
    resultFrame:SetFrameLevel(frame:GetFrameLevel() + 30); resultFrame:SetBackdrop(UI.windowBackdrop); resultFrame:SetBackdropColor(0.01, 0.018, 0.024, 0.99); resultFrame:SetBackdropBorderColor(0.2, 0.8, 0.9, 1); resultFrame:Hide()
    frame.searchResultFrame = resultFrame; frame.searchRows = {}
    for index = 1, SEARCH_ROWS do
        local button = UI:Button(resultFrame, 520, 22, "", "normal", "LEFT"); button:SetPoint("TOPLEFT", resultFrame, "TOPLEFT", 10, -9 - (index - 1) * 24)
        button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
        button:SetScript("OnClick", function(self, mouseButton)
            if not self.result then return end
            if mouseButton == "RightButton" then A:RunRegisteredCommand("lookup_quest", tostring(self.result[1]), true)
            else A:AddQuestFromHelperSearch(self.result) end
        end)
        button:SetScript("OnEnter", function(self)
            if self.result then self:SetBackdropColor(0.07, 0.22, 0.28, 1); UI:ShowHint(self, "[" .. self.result[1] .. "] " .. self.result[2], { A:L("QUEST_SEARCH_LEFT_HINT"), A:L("QUEST_SEARCH_RIGHT_HINT") }) end
        end)
        button:SetScript("OnLeave", function(self) UI:ApplyStyle(self, "normal"); GameTooltip:Hide() end)
        frame.searchRows[index] = button
    end

    self.questSortButtons = {}
    local sortHeaders = {
        { key = "id", x = 18, label = "QUEST_ID", width = 58 }, { key = "title", x = 80, label = "QUEST_NAME", width = 260 },
        { key = "level", x = 345, label = "LEVEL", width = 58 }, { key = "region", x = 408, label = "REGION", width = 170 },
    }
    for _, meta in ipairs(sortHeaders) do
        local button = UI:Button(frame, meta.width, 20, self:L(meta.label), "normal"); button:SetPoint("TOPLEFT", frame, "TOPLEFT", meta.x, -99); button.sortKey = meta.key
        button:SetScript("OnClick", function(self) A:SetQuestHelperSort(self.sortKey) end); self.questSortButtons[meta.key] = button
    end
    local actionHeaders = { { x = 585, label = "STATUS", width = 70 }, { x = 660, label = "START_LOCATION", width = 90 }, { x = 755, label = "END_LOCATION", width = 90 } }
    for _, meta in ipairs(actionHeaders) do
        local label = UI:Text(frame, self:L(meta.label), "small"); label:SetWidth(meta.width); label:SetJustifyH("CENTER"); label:SetPoint("TOPLEFT", frame, "TOPLEFT", meta.x, -101); label:SetTextColor(1, 0.75, 0.20)
    end
    self.questHelperSortKey = self.questHelperSortKey or "id"; if self.questHelperSortAsc == nil then self.questHelperSortAsc = true end

    local emptyText = UI:Text(frame, self:L("NO_ACTIVE_QUESTS"), "normal")
    emptyText:SetWidth(850); emptyText:SetJustifyH("CENTER"); emptyText:SetPoint("TOP", frame, "TOP", 0, -215); emptyText:SetTextColor(0.68, 0.74, 0.78); emptyText:Hide(); frame.emptyText = emptyText
    frame.questRows = {}
    for index = 1, QUESTS_PER_PAGE do
        local row = CreateFrame("Button", nil, frame); row:SetWidth(860); row:SetHeight(26); row:SetPoint("TOPLEFT", frame, "TOPLEFT", 18, -124 - (index - 1) * 29)
        row:RegisterForClicks("LeftButtonUp")
        row:SetScript("OnClick", function(self) if self.quest then A:SelectQuestHelperQuest(self.quest) end end)
        row:SetBackdrop({ bgFile = "Interface\\Tooltips\\UI-Tooltip-Background" }); row:SetBackdropColor(0.02, 0.035, 0.045, (index % 2 == 0) and 0.72 or 0.48); row.rowIndex = index
        local id = UI:Text(row, "", "small"); id:SetWidth(58); id:SetJustifyH("CENTER"); id:SetPoint("LEFT", row, "LEFT", 0, 0); id:SetTextColor(0.45, 0.90, 1.00); row.id = id
        local name = UI:Text(row, "", "small"); name:SetWidth(260); name:SetJustifyH("LEFT"); name:SetPoint("LEFT", row, "LEFT", 62, 0); row.name = name
        local nameClick = CreateFrame("Button", nil, row); nameClick:SetWidth(260); nameClick:SetHeight(24); nameClick:SetPoint("LEFT", row, "LEFT", 62, 0)
        nameClick:SetScript("OnClick", function(self) if self.quest then A:SelectQuestHelperQuest(self.quest) end end)
        nameClick:SetScript("OnEnter", function(self) if self.quest then UI:ShowHint(self, "[" .. self.quest.id .. "] " .. self.quest.title, A:L("QUEST_ROW_HINT")) end end)
        nameClick:SetScript("OnLeave", function() GameTooltip:Hide() end); row.nameClick = nameClick
        local level = UI:Text(row, "", "small"); level:SetWidth(58); level:SetJustifyH("CENTER"); level:SetPoint("LEFT", row, "LEFT", 327, 0); row.level = level
        local region = UI:Text(row, "", "small"); region:SetWidth(170); region:SetJustifyH("LEFT"); region:SetPoint("LEFT", row, "LEFT", 390, 0); region:SetTextColor(0.82, 0.86, 0.90); row.region = region
        local complete = UI:Button(row, 68, 22, self:L("COMPLETE"), "utility"); complete:SetPoint("LEFT", row, "LEFT", 567, 0)
        complete:SetScript("OnClick", function(self) if self.quest then A:RunRegisteredCommand("quest_complete", tostring(self.quest.id), true); A:SelectQuestHelperQuest(self.quest) end end); row.complete = complete
        local startPos = UI:Button(row, 88, 22, self:L("START_LOCATION"), "normal"); startPos:SetPoint("LEFT", row, "LEFT", 642, 0)
        startPos:SetScript("OnClick", function(self) if self.quest then A:SelectQuestHelperQuest(self.quest); A:QuestGoLocation(self.quest, "s") end end)
        startPos:SetScript("OnEnter", function(self) UI:ShowHint(self, A:L("START_LOCATION"), self.quest and A:GetQuestLocationHint(self.quest, "s") or A:L("QUEST_LOCATION_UNAVAILABLE")) end)
        startPos:SetScript("OnLeave", function() GameTooltip:Hide() end); row.startPos = startPos
        local endPos = UI:Button(row, 88, 22, self:L("END_LOCATION"), "normal"); endPos:SetPoint("LEFT", row, "LEFT", 737, 0)
        endPos:SetScript("OnClick", function(self) if self.quest then A:SelectQuestHelperQuest(self.quest); A:QuestGoLocation(self.quest, "e") end end)
        endPos:SetScript("OnEnter", function(self) UI:ShowHint(self, A:L("END_LOCATION"), self.quest and A:GetQuestLocationHint(self.quest, "e") or A:L("QUEST_LOCATION_UNAVAILABLE")) end)
        endPos:SetScript("OnLeave", function() GameTooltip:Hide() end); row.endPos = endPos
        frame.questRows[index] = row
    end

    local previous = UI:Button(frame, 76, 22, "◀ " .. self:L("PREVIOUS"), "utility"); previous:SetPoint("TOPLEFT", frame, "TOPLEFT", 20, -365)
    previous:SetScript("OnClick", function() if A.questHelperPage > 1 then A.questHelperPage = A.questHelperPage - 1; A:RefreshQuestHelper(false) end end); frame.previous = previous
    local pageText = UI:Text(frame, "", "small"); pageText:SetWidth(210); pageText:SetJustifyH("CENTER"); pageText:SetPoint("LEFT", previous, "RIGHT", 14, 0); frame.pageText = pageText
    local nextButton = UI:Button(frame, 76, 22, self:L("NEXT") .. " ▶", "utility"); nextButton:SetPoint("LEFT", pageText, "RIGHT", 14, 0)
    nextButton:SetScript("OnClick", function()
        local maxPage = math.max(1, math.ceil(table.getn(A.questHelperData or {}) / QUESTS_PER_PAGE))
        if A.questHelperPage < maxPage then A.questHelperPage = A.questHelperPage + 1; A:RefreshQuestHelper(false) end
    end); frame.next = nextButton

    local selectedTitle = UI:Text(frame, self:L("QUEST_SELECT_PROMPT"), "small"); selectedTitle:SetPoint("TOPLEFT", frame, "TOPLEFT", 20, -397); selectedTitle:SetTextColor(1, 0.78, 0.25); frame.selectedTitle = selectedTitle
    local objectiveHeader = UI:Text(frame, self:L("QUEST_OBJECTIVE_HEADER"), "small"); objectiveHeader:SetPoint("TOPLEFT", frame, "TOPLEFT", 20, -420); objectiveHeader:SetTextColor(0.55, 0.88, 0.92)
    frame.objectiveRows = {}
    for index = 1, MAX_OBJECTIVE_ROWS do
        local row = CreateFrame("Frame", nil, frame); row:SetWidth(860); row:SetHeight(27); row:SetPoint("TOPLEFT", frame, "TOPLEFT", 18, -443 - (index - 1) * 31)
        row:SetBackdrop({ bgFile = "Interface\\Tooltips\\UI-Tooltip-Background" }); row:SetBackdropColor(0.02, 0.035, 0.045, (index % 2 == 0) and 0.72 or 0.48)
        local typ = UI:Text(row, "", "small"); typ:SetWidth(64); typ:SetJustifyH("CENTER"); typ:SetPoint("LEFT", row, "LEFT", 2, 0); row.typeText = typ
        local desc = UI:Text(row, "", "small"); desc:SetWidth(524); desc:SetJustifyH("LEFT"); desc:SetPoint("LEFT", row, "LEFT", 70, 0); desc:SetTextColor(0.95, 0.95, 0.92); row.desc = desc
        local go = UI:Button(row, 88, 22, self:L("MOVE"), "normal"); go:SetPoint("LEFT", row, "LEFT", 600, 0)
        go:SetScript("OnClick", function(self) if self.objective then A:QuestObjectiveTeleport(self.objective) end end)
        go:SetScript("OnEnter", function(self) UI:ShowHint(self, A:L("MOVE"), self.objective and A:GetQuestObjectiveMoveHint(self.objective) or A:L("QUEST_OBJECTIVE_MOVE_UNAVAILABLE")) end)
        go:SetScript("OnLeave", function() GameTooltip:Hide() end); row.go = go
        local lookup = UI:Button(row, 72, 22, self:L("LOOKUP"), "utility"); lookup:SetPoint("LEFT", row, "LEFT", 694, 0)
        lookup:SetScript("OnClick", function(self) if self.objective then A:QuestObjectiveLookup(self.objective) end end); row.lookup = lookup
        local item = UI:Button(row, 88, 22, self:L("CREATE_ITEM"), "reward"); item:SetPoint("LEFT", row, "LEFT", 772, 0)
        item:SetScript("OnClick", function(self) if self.objective then A:QuestObjectiveAddItem(self.objective) end end); row.item = item
        frame.objectiveRows[index] = row; row:Hide()
    end
    local note = UI:Text(frame, self:L("QUEST_OBJECTIVE_NOTE"), "small"); note:SetWidth(850); note:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 20, 12); note:SetTextColor(0.72, 0.72, 0.72)

    self.questHelperPage = 1
    UI:BindMouseWheel(frame, previous, nextButton)
    for _, questRow in ipairs(frame.questRows or {}) do
        UI:BindMouseWheel(questRow, previous, nextButton)
        UI:BindMouseWheel(questRow.nameClick, previous, nextButton)
        UI:BindMouseWheel(questRow.complete, previous, nextButton)
        UI:BindMouseWheel(questRow.startPos, previous, nextButton)
        UI:BindMouseWheel(questRow.endPos, previous, nextButton)
    end
    for _, objectiveRow in ipairs(frame.objectiveRows or {}) do
        UI:BindMouseWheel(objectiveRow, previous, nextButton)
        UI:BindMouseWheel(objectiveRow.go, previous, nextButton)
        UI:BindMouseWheel(objectiveRow.lookup, previous, nextButton)
        UI:BindMouseWheel(objectiveRow.item, previous, nextButton)
    end
    local events = CreateFrame("Frame")
    events:RegisterEvent("QUEST_LOG_UPDATE")
    events:RegisterEvent("PLAYER_ENTERING_WORLD")
    events:RegisterEvent("QUEST_ACCEPTED")
    events:RegisterEvent("QUEST_REMOVED")
    events:RegisterEvent("QUEST_WATCH_UPDATE")
    events:RegisterEvent("QUEST_POI_UPDATE")
    events:RegisterEvent("PLAYER_ALIVE")
    events:SetScript("OnEvent", function(_, event)
        A:ScheduleQuestHelperRefresh(event == "PLAYER_ENTERING_WORLD" and 1.0 or 0.12)
    end)
    self.questHelperEventFrame = events
    self:RefreshQuestHelper(true)
end

function A:OpenQuestHelper()
    if not self.questHelperFrame then self:CreateQuestHelperWindow() end
    self:RefreshQuestHelper(true)
    UI:ShowWindow(self.questHelperFrame)
end

function A:ToggleQuestHelper()
    if not self.questHelperFrame then self:CreateQuestHelperWindow() end
    if self.questHelperFrame:IsShown() then self.questHelperFrame:Hide() else self:OpenQuestHelper() end
end
