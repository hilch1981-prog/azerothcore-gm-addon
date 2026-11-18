local _, addon = ...

local questIdsByTitle = {}
for id, quest in pairs(addon.quests) do
    local title = quest.enTitle
    if questIdsByTitle[title] == nil then
        questIdsByTitle[title] = id
    else
        questIdsByTitle[title] = false
    end
end

local function FindQuest(id, title)
    if type(id) ~= "number" or id <= 0 then
        id = questIdsByTitle[title]
    end
    local quest = id and addon.quests[id]
    if quest and quest.enTitle == title then
        return quest, id
    end
end

local function IsVisible(frame)
    return frame and frame:IsVisible()
end

local function ReadQuest()
    if IsVisible(QuestFrame) then
        local stage
        if IsVisible(QuestFrameDetailPanel) then
            stage = "detail"
        elseif IsVisible(QuestFrameProgressPanel) then
            stage = "progress"
        elseif IsVisible(QuestFrameRewardPanel) then
            stage = "completion"
        end
        if stage then
            return stage, type(GetQuestID) == "function" and GetQuestID(), GetTitleText()
        end
        return
    end

    if IsVisible(QuestLogFrame) and IsVisible(QuestLogDetailScrollFrame) then
        local index = GetQuestLogSelection()
        if index and index > 0 then
            local title, _, _, _, isHeader, _, _, _, id = GetQuestLogTitle(index)
            if not isHeader then
                return "detail", id, title
            end
        end
    end
end

local function GetBody(quest, stage)
    if stage == "progress" then
        return quest.progress or quest.objectives
    end
    if stage == "completion" then
        return quest.completion
    end
    if quest.objectives and quest.description then
        return "목표\n" .. quest.objectives .. "\n\n설명\n" .. quest.description
    end
    return quest.objectives or quest.description
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
local displayedId, displayedStage

local function Refresh()
    local stage, id, title = ReadQuest()
    local quest, resolvedId = FindQuest(id, title)
    local body = quest and GetBody(quest, stage)
    if not enabled or not body then
        panel:Hide()
        displayedId, displayedStage = nil, nil
        return
    end
    if resolvedId == displayedId and stage == displayedStage then
        return
    end
    displayedId, displayedStage = resolvedId, stage
    titleText:SetText(quest.title)
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
SlashCmdList.WRATHQUESTKOREAN = function()
    enabled = not enabled
    Refresh()
    DEFAULT_CHAT_FRAME:AddMessage(enabled and "한글 퀘스트 표시 켬" or "한글 퀘스트 표시 끔")
end
