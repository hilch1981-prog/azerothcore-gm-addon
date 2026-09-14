-- Attach the companion only to the L-key quest log.
local A = AzerothAdminAC335
local B, D, W, N = A.QuestLogBridge, A.WorkbenchAdapter, A.Workbench, A.NativeUI
local selectedLogQuest, canQuestAction = D.SelectedQuest, D.CanQuestAction

-- NPC dialogue/accept/progress/reward frames never own the helper.
function B:VisibleNative()
 if (QuestFrame and QuestFrame:IsVisible()) or (GossipFrame and GossipFrame:IsVisible()) then return nil end
 if QuestLogFrame and QuestLogFrame:IsVisible() then return QuestLogFrame end
end
function D:SelectedQuest() return selectedLogQuest(self) end
function D:CanQuestAction(action, quest)
    if action=="complete" and quest and quest.dialogue and not quest.logIndex then return false end
    return canQuestAction(self,action,quest)
end
function B:UpdateVisibility()
    if self.visibilityUpdating then return end
    self.visibilityUpdating=true
    local native=self:VisibleNative()
    self.visibilityUpdate=true
    if native then
        self.native=native;self.dismissed=false;W:DB().questCompanion=true
        self:Create();self:Anchor();self.frame:Show();self:Refresh()
    else
        self.native=nil
        if self.frame then self.frame:Hide() end
    end
    self.visibilityUpdate=false;self.visibilityUpdating=false
end
function B:Install()
    self.attachedNatives=self.attachedNatives or {}
    for _,name in ipairs({"QuestLogFrame","QuestFrame","GossipFrame"}) do
        local frame=_G[name]
        if frame and not self.attachedNatives[frame] then
            self.attachedNatives[frame]=true
            frame:HookScript("OnShow",function() B:UpdateVisibility() end)
            frame:HookScript("OnHide",function() B:UpdateVisibility() end)
            if name=="QuestLogFrame" then
            local toggle=N:Button(frame,"GM",42,20,function() B:UpdateVisibility() end)
            toggle:SetPoint("TOPRIGHT",frame,"TOPRIGHT",-48,-10)
            N:Hint(toggle,A:T("퀘스트 도우미"),A:L('UX_QUEST_LOG_ONLY'))
            self.toggle=toggle
            end
        end
    end
    if not self.rc93Viewport then
        self.rc93Viewport=true;N:OnViewportChanged(function() B:UpdateVisibility() end)
    end
    self:UpdateVisibility()
end
local anchor=B.Anchor
function B:Anchor()
    anchor(self)
    if not self.frame or not self.native then return end
    -- Keep the compact controls beside the actual native window, including
    -- dialogs without a QuestNPCModel. Clamp prevents off-screen attachment.
    self.frame:SetClampedToScreen(true)
    self.frame:SetFrameStrata(self.native:GetFrameStrata())
    self.frame:SetFrameLevel(self.native:GetFrameLevel()+10)
end
local events=CreateFrame("Frame")
for _,event in ipairs({"QUEST_DETAIL","QUEST_PROGRESS","QUEST_COMPLETE","QUEST_GREETING","QUEST_FINISHED","PLAYER_REGEN_ENABLED","PLAYER_REGEN_DISABLED"}) do events:RegisterEvent(event) end
events:SetScript("OnEvent",function() B.dirty=true;B:Install() end)
-- Native OnShow may precede QuestFrame's detail event on some clients.
events:SetScript("OnUpdate",function(_,elapsed)
    B.contextElapsed=(B.contextElapsed or 0)+elapsed
    if B.contextElapsed<.2 then return end
    B.contextElapsed=0
    local native=B:VisibleNative()
    if native~=B.native or (native and (not B.frame or not B.frame:IsVisible())) then B:Install() end
end)
