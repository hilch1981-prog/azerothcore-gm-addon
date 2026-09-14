-- Follows the native quest window. No bindings, Blizzard scripts or selection are replaced.
local A = AzerothAdminAC335
local D, N = A.WorkbenchAdapter, A.NativeUI
local B = { dirty = true, elapsed = 0 }
A.QuestLogBridge = B
local function L(key) return A:WL(key) end
function B:Anchor()
    if not self.frame or not self.native then return end
    local parentScale = UIParent:GetEffectiveScale()
    local nativeScale = self.native:GetEffectiveScale() / parentScale
    local scale = math.min(1, (UIParent:GetHeight() - 32) / 426)
    self.frame:SetScale(scale)
    local right = (self.native:GetRight() or 0) * nativeScale
    local left = (self.native:GetLeft() or 0) * nativeScale
    local top = (self.native:GetTop() or UIParent:GetHeight()) * nativeScale
    local screenWidth = UIParent:GetWidth()
    local x = right + 8
    if x + 310 * scale > screenWidth - 8 then
        x = left - 310 * scale - 8
        if x < 8 then x = screenWidth - 310 * scale - 8 end
    end
    self.frame:ClearAllPoints()
    self.frame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", x / scale, math.min(UIParent:GetHeight() - 8, top) / scale)
end
function B:Action(action)
    local current = D:SelectedQuest()
    if not current then self:Refresh(); return end
    self.quest=current
    if D:CanQuestAction(action, current) then D:QuestAction(action, current) end
    self.dirty = true
end
function B:RefreshBody()
    if self.refreshing or not self.frame then return end
    self.refreshing = true
    local quest = D:SelectedQuest()
    self.quest = quest
    self.title:SetText(quest and quest.title or L("QUEST_SELECT"))
    self.info:SetText(quest and ("ID " .. quest.id .. "  |  " .. L("LEVEL") .. " " .. (quest.level or 0)) or "")
    local count = quest and quest.logIndex and GetNumQuestLeaderBoards and (GetNumQuestLeaderBoards(quest.logIndex) or 0) or 0
    local lines = {}
    for i = 1, count do
        local text, _, done = GetQuestLogLeaderBoard(i, quest.logIndex)
        if text then lines[#lines + 1] = (done and "|cff80c050" or "|cffe9d8a0") .. text .. "|r" end
    end
    if quest and #lines == 0 then
        lines[1] = L((quest.complete == 1 or quest.complete == true) and "QUEST_READY" or "QUEST_DIALOGUE")
    end
    self.objectives:SetText(table.concat(lines, "\n\n"))
    local contentHeight = math.max(230, self.objectives:GetStringHeight() + 8)
    self.scrollChild:SetHeight(contentHeight)
    for action, button in pairs(self.buttons) do
        if D:CanQuestAction(action, quest) then button:Enable() else button:Disable() end
    end
    self.refreshing, self.dirty = false, false
end
function B:Refresh()
 if self.refreshing then return end
 local ok,err=pcall(self.RefreshBody,self);self.refreshing=false
 if not ok then self.dirty=true;if self.lastError~=err then self.lastError=err;A:Print(A:T("퀘스트 도우미 오류: ")..tostring(err),true) end end
end
function B:Create()
    if self.frame then return end
    local frame = CreateFrame("Frame", D.namespace .. "QuestCompanion", UIParent)
    self.frame = frame
    frame:SetWidth(310); frame:SetHeight(426); frame:SetFrameStrata("DIALOG")
    frame:SetClampedToScreen(true); frame:EnableMouse(true); N:Panel(frame); frame:Hide()
    local heading = N:Text(frame, L("QUEST_COMPANION"), 180)
    heading:SetPoint("TOPLEFT", frame, "TOPLEFT", 16, -17)
    local close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -3, -3)
    close:SetScript("OnClick", function() B.dismissed = false; if B.native then B.native:Hide() end; frame:Hide() end)
    self.title = N:Text(frame, "", 276); self.title:SetHeight(42); self.title:SetJustifyV("TOP")
    self.title:SetPoint("TOPLEFT", frame, "TOPLEFT", 17, -48)
    self.info = N:Text(frame, "", 276, true); self.info:SetPoint("TOPLEFT", frame, "TOPLEFT", 17, -94)
    local scroll = CreateFrame("ScrollFrame", D.namespace .. "QuestCompanionScroll", frame, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", frame, "TOPLEFT", 17, -119); scroll:SetWidth(252); scroll:SetHeight(215)
    local child = CreateFrame("Frame", nil, scroll); child:SetWidth(250); child:SetHeight(230)
    scroll:SetScrollChild(child); self.scrollChild = child
    self.objectives = N:Text(child, "", 246, true); self.objectives:SetJustifyV("TOP")
    self.objectives:SetPoint("TOPLEFT", child, "TOPLEFT", 0, -2)
    self.buttons = {}
    for i, action in ipairs({ "start", "finish", "complete", "full" }) do
        local chosenAction = action
        local button = N:Button(frame, L("QUEST_" .. string.upper(action)), 134, 25, function() B:Action(chosenAction) end)
        button:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 17 + ((i - 1) % 2) * 140, 45 - math.floor((i - 1) / 2) * 29)
        N:Hint(button, L("QUEST_" .. string.upper(action)), L("QUEST_ACTION_HINT"))
        self.buttons[action] = button
    end
    frame:SetScript("OnUpdate", function(_, delta)
        B.elapsed = B.elapsed + delta
        if B.elapsed < 0.15 then return end
        B.elapsed = 0
        B:Refresh()
    end)
end
function B:UpdateVisibility()
    if not self.native then return end
    if self.native:IsShown() and A.Workbench:DB().questCompanion~=false and not self.dismissed then
        self:Create(); self:Anchor(); self.frame:Show(); self:Refresh()
    elseif self.frame then self.visibilityUpdate=true;self.frame:Hide();self.visibilityUpdate=false end
end
function B:Install()
    local native = QuestLogFrame
    if not native or self.native == native then return end
    self.native = native
    N:OnViewportChanged(function() B:Anchor() end)
    native:HookScript("OnShow", function() B.dismissed = false; B:UpdateVisibility() end)
    native:HookScript("OnHide", function() B.dismissed = false; if B.frame then B.frame:Hide() end end)
    local toggle = N:Button(native, "GM", 42, 20, function()
        B.dismissed = B.frame and B.frame:IsShown() or false
        if not B.dismissed then A.Workbench:DB().questCompanion = true end
        B:UpdateVisibility()
    end)
    toggle:SetPoint("TOPRIGHT", native, "TOPRIGHT", -48, -10)
    N:Hint(toggle, L("QUEST_COMPANION"), L("QUEST_AUTO"))
    self.toggle = toggle
    if hooksecurefunc then
        for _, name in ipairs({ "SelectQuestLogEntry", "QuestLog_SetSelection", "QuestLog_Update" }) do
            if type(_G[name]) == "function" then
                hooksecurefunc(name, function() if not B.refreshing then B.dirty = true end end)
            end
        end
    end
    self:UpdateVisibility()
end
local events = CreateFrame("Frame")
for _, event in ipairs({ "PLAYER_LOGIN", "PLAYER_ENTERING_WORLD", "ADDON_LOADED", "QUEST_LOG_UPDATE", "QUEST_WATCH_UPDATE", "PLAYER_TARGET_CHANGED" }) do events:RegisterEvent(event) end
events:SetScript("OnEvent", function()
    B:Install(); B.dirty = true; B:UpdateVisibility()
end)
