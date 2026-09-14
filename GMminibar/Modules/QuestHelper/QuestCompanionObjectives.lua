local A = AzerothAdminAC335
local B, D, N = A.QuestLogBridge, A.WorkbenchAdapter, A.NativeUI
function B:RefreshObjectives()
    if not self.frame then return end
    self.objectives:Hide()
    self.refreshing = true
    self.objectiveRows = self.objectiveRows or {}
    local items = self.quest and A:GetQuestObjectives(self.quest) or {}
    for i, objective in ipairs(items) do
        local row = self.objectiveRows[i]
        if not row then
            row = CreateFrame("Frame", nil, self.scrollChild); row:SetWidth(250); row:SetHeight(105)
            row:SetPoint("TOPLEFT", self.scrollChild, "TOPLEFT", 0, -(i - 1) * 109)
            row.label = N:Text(row, "", 244, true); row.label:SetHeight(52); row.label:SetJustifyV("TOP"); row.label:SetPoint("TOPLEFT", row, "TOPLEFT", 0, -2)
            row.buttons = {}
            for j, action in ipairs({ "lookup", "move", "item" }) do
                local selectedAction = action
                local button = N:Button(row, A:XL("OBJECTIVE_" .. action), j == 3 and 94 or 72, 24, function()
                    B:ObjectiveAction(selectedAction, row.objective)
                end)
                button:SetPoint("TOPLEFT", row, "TOPLEFT", (j - 1) * 75, -68)
                N:Hint(button, A:XL("OBJECTIVE_" .. action), A:XL("OBJECTIVE_HINT"))
                row.buttons[action] = button
            end
            self.objectiveRows[i] = row
        end
        row.objective = objective
        row.label:SetText(objective.description or objective.text or "")
        for action, button in pairs(row.buttons) do
            local allowed = action ~= "item" or (objective.itemID and (not UnitExists("target") or UnitIsUnit("target", "player")))
            if action == "move" and A.QuestObjectiveCanMove then allowed = A:QuestObjectiveCanMove(objective) end
            if allowed then button:Enable() else button:Disable() end
        end
        row:Show()
    end
    for i = #items + 1, #self.objectiveRows do self.objectiveRows[i]:Hide() end
    if #items == 0 then self.objectives:Show() end
    self.scrollChild:SetHeight(math.max(230, #items * 109))
    self.refreshing = false
end
function B:ObjectiveAction(action, objective)
    local selected = D:SelectedQuest()
    local id = objective and (objective.questID or (objective.quest and objective.quest.id))
    if not selected or selected.id ~= id then self:Refresh(); return end
    if action == "item" and UnitExists("target") and not UnitIsUnit("target", "player") then return end
    -- AC335's existing dispatcher validates this ID against the full helper selection.
    if D.configuredSecurity then A.questHelperSelectedQuestID = selected.id end
    if action == "lookup" then A:QuestObjectiveLookup(objective)
    elseif action == "move" then A:QuestObjectiveTeleport(objective)
    elseif action == "item" and objective.itemID then A:QuestObjectiveAddItem(objective) end
end
hooksecurefunc(B, "Refresh", function() B:RefreshObjectives() end)
