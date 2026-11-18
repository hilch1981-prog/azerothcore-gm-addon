local _, addon = ...

local function Normalize(text)
    if type(text) ~= "string" then return "" end
    return (text:gsub("%$[bB]", " "):gsub("’", "'"):gsub("‘", "'")
        :gsub("“", '"'):gsub("”", '"'):gsub(" ", " ")
        :gsub("[ \t\r\n\v\f]+", " "):match("^%s*(.-)%s*$"):lower())
end

local questIdsByTitle = {}
for id, quest in pairs(addon.quests) do
    for _, title in ipairs({ quest.enTitle, quest.title }) do
        local key = Normalize(title)
        local matches = questIdsByTitle[key] or {}
        if matches[#matches] ~= id then
            matches[#matches + 1] = id
        end
        questIdsByTitle[key] = matches
    end
end

local function IsVisible(frame)
    return frame and frame:IsVisible()
end

local function ReadQuest()
    if IsVisible(QuestFrame) then
        local id = type(GetQuestID) == "function" and GetQuestID()
        if IsVisible(QuestFrameDetailPanel) then
            return id, GetTitleText(), GetQuestText(), GetObjectiveText()
        elseif IsVisible(QuestFrameProgressPanel) then
            return id, GetTitleText(), nil, nil, GetProgressText()
        elseif IsVisible(QuestFrameRewardPanel) then
            return id, GetTitleText(), nil, nil, nil, GetRewardText()
        end
        return
    end

    if IsVisible(QuestLogFrame) and IsVisible(QuestLogDetailScrollFrame) then
        local index = GetQuestLogSelection()
        if index and index > 0 then
            local title, _, _, _, isHeader, _, _, _, id = GetQuestLogTitle(index)
            if not isHeader then
                local description, objectives = GetQuestLogQuestText()
                return id, title, description, objectives
            end
        end
    end
end

local englishRaces = { Scourge = "Undead", NightElf = "Night Elf",
    BloodElf = "Blood Elf" }
local englishClasses = { DEATHKNIGHT = "Death Knight" }

local function Expand(text, korean)
    local sex = UnitSex("player")
    local race, raceToken = UnitRace("player")
    local class, classToken = UnitClass("player")
    local className = classToken and (englishClasses[classToken]
        or classToken:sub(1, 1) .. classToken:sub(2):lower())
    local values = {
        b = "\n",
        n = UnitName("player"),
        r = korean and race or englishRaces[raceToken] or raceToken,
        c = korean and class or className,
    }
    text = text:gsub("%$[gG]([^:;]*):([^;]*);", function(male, female)
        return sex == 3 and female or male
    end)
    return (text:gsub("%$([bBnNcCrR])", function(token)
        return values[token:lower()]
    end))
end

local function SelectText(entry, source)
    if not entry or not source or source == "" then return end
    local guard, translation = entry[1], entry[2]
    local normalized = Normalize(source)
    if type(guard) == "string" then
        if normalized ~= Normalize(Expand(guard, false)) then return end
    else
        if #normalized ~= guard[1] then return end
        local checksum = 0
        for i = 1, #normalized do
            checksum = (checksum * 131 + normalized:byte(i)) % 2147483647
        end
        if checksum ~= guard[2] then return end
    end
    return Expand(translation, true)
end

local function GetBody(quest, description, objectives, progress, completion)
    if description or objectives then
        local descriptionKo = SelectText(quest.description, description)
        local objectivesKo = SelectText(quest.objectives, objectives)
        if descriptionKo and objectivesKo then
            return "목표\n" .. objectivesKo .. "\n\n설명\n" .. descriptionKo
        end
        return objectivesKo or descriptionKo
    end
    return SelectText(quest.progress, progress) or SelectText(quest.completion, completion)
end

local function GetDisplay()
    local id, title, description, objectives, progress, completion = ReadQuest()
    if not title then return end
    local key = Normalize(title)
    if type(id) == "number" and id > 0 then
        local quest = addon.quests[id]
        if quest and (Normalize(quest.enTitle) == key or Normalize(quest.title) == key) then
            return quest.title or title, GetBody(quest, description, objectives, progress, completion)
        end
        return
    end

    local candidates = questIdsByTitle[key]
    if not candidates then return end
    local displayTitle, body
    for _, candidate in ipairs(candidates) do
        local quest = addon.quests[candidate]
        local matched = GetBody(quest, description, objectives, progress, completion)
        if matched then
            if body and matched ~= body then return end
            local candidateTitle = quest.title or title
            displayTitle = (displayTitle and displayTitle ~= candidateTitle) and title or candidateTitle
            body = matched
        end
    end
    return displayTitle, body
end

local panel = CreateFrame("Frame", nil, UIParent)
panel:SetSize(320, 250)
panel:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", -24, -135)
panel:SetFrameStrata("DIALOG")
panel:SetClampedToScreen(true)
panel:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true, tileSize = 32, edgeSize = 24,
    insets = { left = 6, right = 6, top = 6, bottom = 6 },
})
panel:Hide()

local titleText = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
titleText:SetPoint("TOPLEFT", 16, -16)
titleText:SetPoint("TOPRIGHT", -16, -16)
titleText:SetJustifyH("LEFT")

local scroll = CreateFrame("ScrollFrame", nil, panel)
scroll:SetPoint("TOPLEFT", titleText, "BOTTOMLEFT", 0, -12)
scroll:SetPoint("BOTTOMRIGHT", -16, 16)
scroll:EnableMouseWheel(true)
scroll:SetScript("OnMouseWheel", function(self, delta)
    local offset = self:GetVerticalScroll() - delta * 24
    self:SetVerticalScroll(math.max(0, math.min(self:GetVerticalScrollRange(), offset)))
end)

local content = CreateFrame("Frame", nil, scroll)
content:SetSize(288, 1)
scroll:SetScrollChild(content)

local bodyText = content:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
bodyText:SetPoint("TOPLEFT")
bodyText:SetPoint("TOPRIGHT")
bodyText:SetJustifyH("LEFT")
bodyText:SetJustifyV("TOP")

local enabled = true
local displayedTitle, displayedBody

local function Refresh()
    local title, body
    if enabled then
        title, body = GetDisplay()
    end
    if not body then
        panel:Hide()
        displayedTitle, displayedBody = nil, nil
        return
    end
    if title == displayedTitle and body == displayedBody then
        return
    end
    displayedTitle, displayedBody = title, body
    titleText:SetText(title)
    bodyText:SetText(body)
    panel:Show()
    content:SetHeight(math.max(1, math.ceil(bodyText:GetStringHeight())))
    scroll:UpdateScrollChildRect()
    scroll:SetVerticalScroll(0)
end

local watcher = CreateFrame("Frame")
local function QueueRefresh()
    -- Read after FrameXML has processed the event and finished switching panels.
    watcher:SetScript("OnUpdate", function(self)
        self:SetScript("OnUpdate", nil)
        Refresh()
    end)
end

local events = { "QUEST_GREETING", "QUEST_DETAIL", "QUEST_PROGRESS", "QUEST_COMPLETE",
    "QUEST_FINISHED", "QUEST_LOG_UPDATE", "PLAYER_ENTERING_WORLD" }
for _, event in ipairs(events) do
    watcher:RegisterEvent(event)
end
watcher:SetScript("OnEvent", QueueRefresh)

hooksecurefunc("QuestInfo_Display", QueueRefresh)
QuestFrame:HookScript("OnHide", QueueRefresh)
QuestLogFrame:HookScript("OnHide", QueueRefresh)
QuestLogFrame:HookScript("OnShow", QueueRefresh)

SLASH_WRATHQUESTKOREAN1 = "/wqk"
SlashCmdList.WRATHQUESTKOREAN = function(message)
    if message == "status" then
        local tooltip = type(IsAddOnLoaded) == "function" and IsAddOnLoaded("TooltipKOR-wotlk")
        DEFAULT_CHAT_FRAME:AddMessage(tooltip and "TooltipKOR-wotlk 사용 중" or "TooltipKOR-wotlk 미로드")
        return
    end
    enabled = not enabled
    Refresh()
    DEFAULT_CHAT_FRAME:AddMessage(enabled and "한글 퀘스트 표시 켬" or "한글 퀘스트 표시 끔")
end
