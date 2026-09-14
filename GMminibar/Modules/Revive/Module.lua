local A = AzerothAdminAC335

function A:ReviveSmart()
    if self:IsPlayerDeadOrGhost() then
        local playerName = UnitName and UnitName("player") or nil
        if ClearTarget then pcall(ClearTarget) end
        self:SendCommand(".revive", "WHISPER", playerName)
        self:RunAfter(0.35, function()
            if A:IsPlayerDeadOrGhost() then
                if ClearTarget then pcall(ClearTarget) end
                A:SendCommand(".revive", "WHISPER", playerName)
            end
        end)
        self:RunAfter(0.90, function()
            if A:IsPlayerDeadOrGhost() then
                if ClearTarget then pcall(ClearTarget) end
                A:SendCommand(".revive", "WHISPER", playerName)
            end
        end)
        return true
    end
    return self:SendCommand(".revive")
end

function A:OpenRecoveryWindow()
    local frame = self.windows.recovery
    if not frame then
        frame = self.UI:CreateWindow("recovery", self:L("RECOVERY"), 460, 330)
        local actions = {
            { "recovery_revive", "CMD_REVIVE" }, { "recovery_respawn", "CMD_RESPAWN" },
            { "recovery_repair", "CMD_REPAIR" }, { "recovery_unstuck", "CMD_UNSTUCK" },
            { "recovery_recall", "CMD_RECALL" }, { "recovery_combatstop", "CMD_COMBATSTOP" },
            { "recovery_dismount", "CMD_DISMOUNT" }, { "recovery_unaura", "CMD_UNAURA" },
        }
        for index, row in ipairs(actions) do
            local commandID, labelKey = row[1], row[2]
            local definition = A:GetCommand(commandID)
            local button = A.UI:Button(frame, 190, 28, A:L(labelKey), definition and definition.style or "reward")
            button:SetPoint("TOPLEFT", frame, "TOPLEFT", 28 + ((index - 1) % 2) * 205, -62 - math.floor((index - 1) / 2) * 38)
            button:SetScript("OnClick", function() A:RunRegisteredCommand(commandID) end)
        end
        local note = self.UI:Text(frame, self:L("DEAD_COMMAND_NOTE"), "small")
        note:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 20, 20); note:SetWidth(420); note:SetJustifyH("LEFT")
    end
    self.UI:ShowWindow(frame)
end
