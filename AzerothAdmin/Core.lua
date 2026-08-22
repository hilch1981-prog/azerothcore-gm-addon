AzerothAdminEasy = AzerothAdminEasy or {}
local addon = AzerothAdminEasy
local L = addon.L

local function trim(value)
    if not value then return "" end
    return string.gsub(value, "^%s*(.-)%s*$", "%1")
end

addon.Trim = trim

function addon:Print(message, isError)
    local color = isError and "|cffff6666" or "|cff66ff99"
    DEFAULT_CHAT_FRAME:AddMessage(color .. "AzerothAdmin Easy:|r " .. tostring(message))
end

function addon:SetStatus(message, isError)
    if self.statusText then
        self.statusText:SetText(message or L.STATUS_IDLE)
        if isError then
            self.statusText:SetTextColor(1, 0.35, 0.35)
        else
            self.statusText:SetTextColor(0.72, 0.82, 0.88)
        end
    end
end


-- Command metadata comes from the user-provided acore_world.command dump.
function addon:GetCommandName(command)
    if not command then return nil end
    local value = trim(command)
    value = string.gsub(value, "^[%.!]", "")
    value = string.gsub(value, "%s+{args}.*$", "")
    value = string.gsub(value, "%s+{target}.*$", "")
    value = trim(value)
    if value == "" then return nil end
    local tokens = {}
    local token
    for token in string.gmatch(value, "%S+") do table.insert(tokens, token) end
    local count = table.getn(tokens)
    local i
    for i = count, 1, -1 do
        local candidate = table.concat(tokens, " ", 1, i)
        if self.CommandSecurity and self.CommandSecurity[candidate] ~= nil then
            return candidate
        end
    end
    return nil
end

local actionPermissionCommands = {
    godToggle = ".cheat god on",
    visibilityToggle = ".gm visible off",
    flightToggle = ".gm fly on",
    speedToggle = ".modify speed all 3",
    waterwalkToggle = ".cheat waterwalk on",
}

function addon:AttachCommandMetadata()
    if not self.Categories then return end
    local ci, di
    for ci = 1, table.getn(self.Categories) do
        local category = self.Categories[ci]
        if category and category.commands then
            for di = 1, table.getn(category.commands) do
                local def = category.commands[di]
                if def then
                    local permissionCommand = def.command or actionPermissionCommands[def.action]
                    def.permissionCommand = permissionCommand
                    if permissionCommand then
                        local name = self:GetCommandName(permissionCommand)
                        def.commandName = name
                        if name and self.CommandSecurity then
                            def.requiredSecurity = self.CommandSecurity[name]
                        end
                        if def.command and name and self.CommandSyntax then
                            def.officialSyntax = self.CommandSyntax[name]
                        end
                    end
                end
            end
        end
    end
end

function addon:GetDetectedSecurity()
    AzerothAdminEasyDB = AzerothAdminEasyDB or {}
    return tonumber(AzerothAdminEasyDB.detectedSecurity)
end

function addon:IsDefinitionAllowed(definition)
    if not definition then return true, nil end
    local permissionCommand = definition.permissionCommand or definition.command
    if not permissionCommand then return true, nil end
    local name = definition.commandName or self:GetCommandName(permissionCommand)
    if name and self.sessionDeniedCommands and self.sessionDeniedCommands[name] then
        return false, "서버가 이 명령의 권한을 거부했습니다."
    end
    local required = definition.requiredSecurity
    if required == nil and name and self.CommandSecurity then required = self.CommandSecurity[name] end
    if required == 4 then
        return false, "Console 보안 레벨(4) 전용 명령입니다."
    end
    local current = self:GetDetectedSecurity()
    if current and required and required > current then
        return false, "필요 GM 레벨 " .. tostring(required) .. " / 현재 " .. tostring(current)
    end
    return true, nil
end

function addon:GetDefinitionKey(definition)
    if not definition or not definition.command then return nil end
    return definition.command
end

function addon:GetCommandFavorites()
    AzerothAdminEasyDB = AzerothAdminEasyDB or {}
    AzerothAdminEasyDB.commandFavorites = AzerothAdminEasyDB.commandFavorites or {}
    return AzerothAdminEasyDB.commandFavorites
end

function addon:FindDefinitionByKey(key)
    if not key or not self.Categories then return nil end
    local ci, di
    for ci = 1, table.getn(self.Categories) do
        local commands = self.Categories[ci].commands or {}
        for di = 1, table.getn(commands) do
            local def = commands[di]
            if self:GetDefinitionKey(def) == key then return def end
        end
    end
    return nil
end

function addon:IsCommandFavorite(definition)
    local key = self:GetDefinitionKey(definition)
    if not key then return nil end
    local favs = self:GetCommandFavorites()
    local i
    for i = 1, table.getn(favs) do
        if favs[i] == key then return i end
    end
    return nil
end

function addon:ToggleCommandFavorite(definition)
    local key = self:GetDefinitionKey(definition)
    if not key then
        self:Print("GM 명령 버튼만 퀵슬롯에 등록할 수 있습니다.", true)
        return
    end
    local favs = self:GetCommandFavorites()
    local found = self:IsCommandFavorite(definition)
    if found then
        table.remove(favs, found)
        self:Print("명령 퀵슬롯 해제: " .. tostring(definition.label or key))
    else
        table.insert(favs, 1, key)
        while table.getn(favs) > 2 do table.remove(favs) end
        self:Print("명령 퀵슬롯 등록: " .. tostring(definition.label or key))
    end
    if self.RefreshCommandQuickSlots then self:RefreshCommandQuickSlots() end
    if self.RefreshCommands then self:RefreshCommands() end
end

local failurePatterns = {
    "syntax", "unknown command", "no such command", "no such subcommand", "invalid command", "permission", "not have permission", "no permission",
    "not found", "must select", "select a", "error", "failed", "invalid", "does not exist", "can't", "cannot",
    "구문", "명령을 찾", "권한이 없", "권한 부족", "대상을 선택", "선택하세요", "오류", "실패", "잘못", "존재하지", "찾을 수 없",
}
local permissionPatterns = {
    "permission", "not have permission", "no permission", "access denied", "do not have access", "not allowed to use",
    "권한이 없", "권한 부족", "접근 권한", "사용할 권한",
}
local unavailablePatterns = {
    "unknown command", "no such command", "no such subcommand", "command not found",
    "명령을 찾", "없는 명령", "알 수 없는 명령",
}

local function containsAny(message, patterns)
    local lower = string.lower(message or "")
    local i
    for i = 1, table.getn(patterns) do
        if string.find(lower, string.lower(patterns[i]), 1, true) then return true end
    end
    return false
end

function addon:IsFailureSystemMessage(message)
    return containsAny(message, failurePatterns)
end

function addon:IsPermissionSystemMessage(message)
    return containsAny(message, permissionPatterns)
end

function addon:SetDefinitionResult(definition, state, message)
    if not definition then return end
    definition._resultState = state
    definition._resultMessage = message or ""
    definition._resultTime = GetTime and GetTime() or 0
    if self.RefreshCommands then self:RefreshCommands() end
end

function addon:StartExecutionTracking(command, definition)
    if not definition then return end
    self.executionSerial = (self.executionSerial or 0) + 1
    local serial = self.executionSerial
    self.pendingExecution = {
        serial = serial,
        command = command,
        definition = definition,
        gotResponse = false,
        failed = false,
    }
    self:SetDefinitionResult(definition, "pending", "서버 응답 대기")
    self:RunAfter(1.4, function()
        local pending = addon.pendingExecution
        if not pending or pending.serial ~= serial then return end
        if pending.failed then return end
        local msg = pending.gotResponse and (pending.lastMessage or "서버 응답 확인") or "명령 전송 완료"
        addon:SetDefinitionResult(pending.definition, "success", msg)
        addon.pendingExecution = nil
    end)
end

function addon:HandleCommandSystemMessage(message)
    message = tostring(message or "")

    -- Remote bank fallback consumes the same server system lines produced by
    -- .character check bank.  Keep this before command-result tracking so the
    -- bank window receives every row even when the command tracker is active.
    if self.HandleBankSystemMessage then self:HandleBankSystemMessage(message) end

    if self.securityProbeActive then
        local lower = string.lower(message)
        if string.find(lower, "security", 1, true) or string.find(lower, "access level", 1, true)
            or string.find(lower, "account level", 1, true) or string.find(lower, "gm level", 1, true)
            or string.find(message, "보안", 1, true) or string.find(message, "권한", 1, true) or string.find(message, "레벨", 1, true) then
            local level = tonumber(string.match(message, "([0-4])"))
            if level then
                AzerothAdminEasyDB.detectedSecurity = level
                self.securityProbeActive = false
                self:Print("GM 권한 자동 감지: 레벨 " .. tostring(level))
                if self.RefreshCommands then self:RefreshCommands() end
                if self.RefreshCommandQuickSlots then self:RefreshCommandQuickSlots() end
                if self.RefreshToolbarPermissions then self:RefreshToolbarPermissions() end
            end
        end
    end

    local pending = self.pendingExecution
    if not pending then return end
    pending.gotResponse = true
    pending.lastMessage = message
    if self:IsFailureSystemMessage(message) then
        pending.failed = true
        local def = pending.definition
        local name = def and (def.commandName or self:GetCommandName(def.command))
        if name and (self:IsPermissionSystemMessage(message) or containsAny(message, unavailablePatterns)) then
            self.sessionDeniedCommands = self.sessionDeniedCommands or {}
            self.sessionDeniedCommands[name] = true
        end
        self:SetDefinitionResult(def, "failure", message)
        self.pendingExecution = nil
        if self.RefreshCommandQuickSlots then self:RefreshCommandQuickSlots() end
        if self.RefreshToolbarPermissions then self:RefreshToolbarPermissions() end
    end
end

function addon:ProbeSecurity(silent)
    if self.securityProbeActive then return end
    self.securityProbeActive = true
    self.securityProbeStarted = GetTime and GetTime() or 0
    if not silent then self:Print("GM 권한을 .account 응답에서 자동 확인합니다.") end
    SendChatMessage(".account", "SAY")
    self:RunAfter(2.5, function()
        if addon.securityProbeActive then
            addon.securityProbeActive = false
            if not silent then
                addon:Print("GM 레벨 자동 감지 응답을 확인하지 못했습니다. 권한 거부가 확인된 명령은 실행 후 자동 잠금됩니다.", true)
            end
        end
    end)
end

-- Addon UI windows are mutually exclusive. The persistent quick toolbar and minimap icon are not hidden.
-- Managed-window navigation for 3.3.5a.
-- Only one AzerothAdmin layer is visible at a time, but closing a child restores its parent.
function addon:EnsureEscapeProxy()
    if self.escapeProxy then return self.escapeProxy end
    local proxy = CreateFrame("Frame", "AzerothAdminEscapeProxy", UIParent)
    proxy:SetWidth(1); proxy:SetHeight(1)
    proxy:SetPoint("TOPLEFT", UIParent, "TOPLEFT", -100, 100)
    proxy:SetAlpha(0)
    proxy:EnableMouse(false)
    proxy:Hide()
    self.escapeProxy = proxy
    UISpecialFrames = UISpecialFrames or {}
    local found = false
    local i
    for i = 1, table.getn(UISpecialFrames) do
        if UISpecialFrames[i] == "AzerothAdminEscapeProxy" then found = true; break end
    end
    if not found then table.insert(UISpecialFrames, "AzerothAdminEscapeProxy") end
    proxy:SetScript("OnHide", function()
        if addon._escapeProxyInternal then return end
        addon:HandleManagedEscape()
        addon:RunAfter(0.01, function() addon:UpdateEscapeProxy() end)
    end)
    return proxy
end

function addon:GetManagedFrames()
    local frames = {}
    local function add(f)
        if f and f.IsShown then table.insert(frames, f) end
    end
    add(self.argumentFrame)
    add(self.localeSearchFrame)
    add(self.questHelperFrame)
    add(self.teleportFrame)
    add(self.favoriteFrame)
    add(BlueItemInfo3)
    add(AzerothAdminCraftInfoFrame)
    add(self.remoteBankFrame)
    add(BankFrame)
    add(self.frame)
    return frames
end

function addon:GetVisibleManagedFrame(exceptFrame)
    if self.currentManagedFrame and self.currentManagedFrame ~= exceptFrame and self.currentManagedFrame.IsShown and self.currentManagedFrame:IsShown() then
        return self.currentManagedFrame
    end
    local frames = self:GetManagedFrames()
    local i
    for i = 1, table.getn(frames) do
        local f = frames[i]
        if f ~= exceptFrame and f:IsShown() then return f end
    end
    return nil
end

function addon:UpdateEscapeProxy()
    local proxy = self:EnsureEscapeProxy()
    local visible = self:GetVisibleManagedFrame(nil)
    self._escapeProxyInternal = true
    -- StaticPopup dialogs already participate in UISpecialFrames.  While one of
    -- our child dialogs is visible, suspend the proxy so one ESC key closes only
    -- that child instead of also closing/restoring its parent in the same pass.
    if (self.popupEscapeDepth or 0) > 0 then
        proxy:Hide()
    elseif visible then
        proxy:Show()
    else
        proxy:Hide()
    end
    self._escapeProxyInternal = nil
end

function addon:RaisePopup(frame)
    if not frame then return end
    -- StaticPopup frames are shared by every addon. Preserve their original
    -- layer before temporarily raising one above our FULLSCREEN_DIALOG windows.
    if not frame._aaePopupLayerRaised then
        frame._aaePopupLayerRaised = true
        if frame.GetFrameStrata then frame._aaePopupOriginalStrata = frame:GetFrameStrata() end
        if frame.GetFrameLevel then frame._aaePopupOriginalLevel = frame:GetFrameLevel() end
        if frame.IsToplevel then frame._aaePopupOriginalToplevel = frame:IsToplevel() and true or false end
    end
    -- Managed windows (quest/item/craft) use FULLSCREEN_DIALOG. StaticPopup's
    -- default strata can therefore end up behind them on the 3.3.5a client.
    -- TOOLTIP is the top UI strata and is safe for short modal dialogs.
    if frame.SetFrameStrata then frame:SetFrameStrata("TOOLTIP") end
    if frame.SetFrameLevel then frame:SetFrameLevel(1000) end
    if frame.SetToplevel then frame:SetToplevel(true) end
end

function addon:RestorePopupLayer(frame)
    if not frame or not frame._aaePopupLayerRaised then return end
    if frame.SetFrameStrata and frame._aaePopupOriginalStrata then
        frame:SetFrameStrata(frame._aaePopupOriginalStrata)
    end
    if frame.SetFrameLevel and frame._aaePopupOriginalLevel ~= nil then
        frame:SetFrameLevel(frame._aaePopupOriginalLevel)
    end
    if frame.SetToplevel and frame._aaePopupOriginalToplevel ~= nil then
        frame:SetToplevel(frame._aaePopupOriginalToplevel)
    end
    frame._aaePopupLayerRaised = nil
    frame._aaePopupOriginalStrata = nil
    frame._aaePopupOriginalLevel = nil
    frame._aaePopupOriginalToplevel = nil
end

function addon:SuspendManagedEscapeForPopup(frame)
    if frame and frame._aaeEscapeSuspended then return end
    if frame then frame._aaeEscapeSuspended = true end
    self.popupEscapeDepth = (self.popupEscapeDepth or 0) + 1
    self:UpdateEscapeProxy()
end

function addon:ResumeManagedEscapeForPopup(frame)
    if frame and not frame._aaeEscapeSuspended then return end
    if frame then frame._aaeEscapeSuspended = nil end
    self:RestorePopupLayer(frame)
    self.popupEscapeDepth = math.max(0, (self.popupEscapeDepth or 1) - 1)
    self:RunAfter(0.02, function() addon:UpdateEscapeProxy() end)
end

function addon:RegisterEscapeFrame(frame)
    if not frame then return end
    frame.aaeEscapable = true
    self:EnsureEscapeProxy()
    if frame._aaeManagedHook then return end
    frame._aaeManagedHook = true
    if frame.HookScript then
        frame:HookScript("OnShow", function(f)
            addon.currentManagedFrame = f
            addon:UpdateEscapeProxy()
        end)
        frame:HookScript("OnHide", function(f)
            if f.aaeSuppressRestore then
                f.aaeSuppressRestore = nil
                addon:UpdateEscapeProxy()
                return
            end
            if addon.currentManagedFrame == f then addon.currentManagedFrame = nil end
            local parent = f.aaeReturnFrame
            f.aaeReturnFrame = nil
            if parent and not addon._closingManagedWindows and parent.Show and not parent:IsShown() then
                parent:Show()
                addon.currentManagedFrame = parent
            end
            addon:UpdateEscapeProxy()
        end)
    end
end

function addon:OpenManagedFrame(frame, showFunc)
    if not frame then return false end
    self:RegisterEscapeFrame(frame)
    if frame:IsShown() then
        frame:Hide()
        return false
    end
    local parent = self:GetVisibleManagedFrame(frame)
    if parent then
        self:RegisterEscapeFrame(parent)
        frame.aaeReturnFrame = parent
        parent.aaeSuppressRestore = true
        parent:Hide()
    else
        frame.aaeReturnFrame = nil
    end
    local ok = true
    if showFunc then
        ok = pcall(showFunc, frame)
    else
        frame:Show()
    end
    if not ok or not frame:IsShown() then
        local restore = frame.aaeReturnFrame
        frame.aaeReturnFrame = nil
        if restore and not restore:IsShown() then restore:Show(); self.currentManagedFrame = restore end
        self:UpdateEscapeProxy()
        return false
    end
    self.currentManagedFrame = frame
    self:UpdateEscapeProxy()
    return true
end

function addon:HandleManagedEscape()
    -- Embedded child lists are closed before their owning window.
    if self.questHelperSearchResultFrame and self.questHelperSearchResultFrame:IsShown() then
        self.questHelperSearchResultFrame:Hide()
        return true
    end
    local frame = self:GetVisibleManagedFrame(nil)
    if frame and frame.aaeEscapable and frame:IsShown() then
        frame:Hide()
        return true
    end
    return false
end

function addon:CloseAllManagedWindows()
    self._closingManagedWindows = true
    local frames = self:GetManagedFrames()
    local i
    for i = 1, table.getn(frames) do
        local f = frames[i]
        f.aaeReturnFrame = nil
        if f:IsShown() then f:Hide() end
    end
    self.currentManagedFrame = nil
    self._closingManagedWindows = nil
    self:UpdateEscapeProxy()
end

function addon:HideAddonPopups(exceptKey)
    if not StaticPopup_Hide then return end
    local keys = {
        "AZEROTHADMIN_EASY_CONFIRM",
        "AZEROTHADMIN_QUEST_COMPLETE_AND_GO",
        "AZEROTHADMIN_ITEM_ADD_QUANTITY",
        "AZEROTHADMIN_QUEST_ADD_SEARCH",
        "AZEROTHADMIN_CRAFT_LEARN",
    }
    local i
    for i = 1, table.getn(keys) do
        if keys[i] ~= exceptKey then pcall(StaticPopup_Hide, keys[i]) end
    end
end

function addon:HideAddonWindows(exceptFrame)
    self._closingManagedWindows = true
    local frames = self:GetManagedFrames()
    local i
    for i = 1, table.getn(frames) do
        local frame = frames[i]
        if frame ~= exceptFrame and frame.IsShown and frame:IsShown() then
            frame.aaeReturnFrame = nil
            frame:Hide()
        end
    end
    self._closingManagedWindows = nil
    if exceptFrame and exceptFrame.IsShown and exceptFrame:IsShown() then self.currentManagedFrame = exceptFrame end
    self:UpdateEscapeProxy()
end

function addon:ShowExclusiveFrame(frame)
    if not frame then return end
    self:HideAddonPopups(nil)
    self:OpenManagedFrame(frame)
end

function addon:ValidateCommand(command)
    command = trim(command)
    if command == "" then return nil end
    if string.find(command, "[\r\n]") then
        self:Print("여러 줄 명령은 실행할 수 없습니다.", true)
        return nil
    end
    if string.len(command) > 255 then
        self:Print(L.COMMAND_TOO_LONG, true)
        return nil
    end
    local first = string.sub(command, 1, 1)
    if first ~= "." and first ~= "!" then
        self:Print(L.INVALID_COMMAND, true)
        return nil
    end
    return command
end

function addon:AddHistory(command)
    AzerothAdminEasyDB = AzerothAdminEasyDB or {}
    AzerothAdminEasyDB.history = AzerothAdminEasyDB.history or {}
    table.insert(AzerothAdminEasyDB.history, 1, command)
    while table.getn(AzerothAdminEasyDB.history) > 20 do
        table.remove(AzerothAdminEasyDB.history)
    end
    if self.RefreshHistory then self:RefreshHistory() end
end

function addon:SendNow(command, definition, chatType, chatTarget)
    command = self:ValidateCommand(command)
    if not command then return end
    local trackDefinition = definition
    if not trackDefinition then
        local name = self:GetCommandName(command)
        if name then
            trackDefinition = { command = command, permissionCommand = command, commandName = name, requiredSecurity = self.CommandSecurity and self.CommandSecurity[name], _transient = true }
        end
    end
    if trackDefinition then self:StartExecutionTracking(command, trackDefinition) end

    -- Normal GM commands use SAY.  Some 3.3.5a clients/cores do not reliably
    -- transmit SAY while the player is a corpse/ghost, even though AzerothCore
    -- parses commands before its dead-player say restriction.  Callers such as
    -- ReviveSmart can therefore use a self-whisper packet without changing the
    -- command text or the normal execution/history path.
    chatType = chatType or "SAY"
    if chatType == "WHISPER" then
        SendChatMessage(command, "WHISPER", nil, chatTarget or UnitName("player"))
    else
        SendChatMessage(command, chatType)
    end
    self:AddHistory(command)
    self:Print(L.SENT .. ": " .. command)
    self:SetStatus(L.SENT .. ": " .. command, false)
end

function addon:GetSelfLowGUID()
    if not UnitGUID then return nil end
    local guid = UnitGUID("player")
    if type(guid) ~= "string" or guid == "" then return nil end

    -- WoW 3.3.5a returns a hexadecimal GUID such as 0x0000000000012345.
    -- AzerothCore PlayerIdentifier accepts the decimal low GUID directly.
    local hex = string.match(guid, "0x(%x+)")
    if not hex then return nil end
    if string.len(hex) > 8 then hex = string.sub(hex, -8) end
    local low = tonumber(hex, 16)
    if not low or low <= 0 then return nil end
    return math.floor(low)
end

function addon:GetTargetName()
    if UnitExists("target") and UnitIsPlayer("target") then
        local name = UnitName("target")
        if name then return name end
    end
    return ""
end

function addon:BuildCommand(definition)
    local command = definition.command
    if not command then return nil end

    if string.find(command, "{target}", 1, true) then
        local target = trim(self.pendingTargetName or "")
        if target == "" then target = self:GetTargetName() end
        if target == "" then
            self:Print(L.NO_TARGET, true)
            self:SetStatus(L.NO_TARGET, true)
            return nil
        end
        command = string.gsub(command, "{target}", target)
    end

    if string.find(command, "{args}", 1, true) then
        local arguments = trim(self.pendingArgumentValue or "")
        if arguments == "" then
            self:Print(L.NO_ARGUMENTS, true)
            self:SetStatus((definition.hint or "") .. "  |  " .. L.NO_ARGUMENTS, true)
            return nil
        end
        command = string.gsub(command, "{args}", arguments)
    end

    self.pendingTargetName = nil
    self.pendingArgumentValue = nil
    return command
end

function addon:ConfirmCommand(command, definition)
    self.pendingCommand = command
    self.pendingDefinition = definition
    self:HideAddonPopups("AZEROTHADMIN_EASY_CONFIRM")
    StaticPopup_Show("AZEROTHADMIN_EASY_CONFIRM", definition.label or command, command)
end


function addon:RunAfter(delay, func)
    local f = CreateFrame("Frame")
    local elapsed = 0
    f:SetScript("OnUpdate", function(self, dt)
        elapsed = elapsed + (dt or 0)
        if elapsed >= (delay or 0) then
            self:SetScript("OnUpdate", nil)
            func()
        end
    end)
end

function addon:ValidateDefinitionTarget(definition)
    if not definition or not definition.requires then return true end
    local req = definition.requires
    if req == "unit" then
        if not UnitExists("target") then
            self:Print("대상을 먼저 선택하세요.", true)
            return false
        end
    elseif req == "player" then
        if not UnitExists("target") or not UnitIsPlayer("target") then
            self:Print("플레이어 대상을 먼저 선택하세요.", true)
            return false
        end
    elseif req == "creature" then
        if not UnitExists("target") or UnitIsPlayer("target") then
            self:Print("크리쳐/NPC 대상을 먼저 선택하세요.", true)
            return false
        end
    end
    return true
end

function addon:ReviveSmart(definition)
    local selfDead = false
    if UnitIsDeadOrGhost then selfDead = UnitIsDeadOrGhost("player") and true or false end
    if not selfDead and UnitIsDead then selfDead = UnitIsDead("player") and true or false end
    if not selfDead and UnitIsGhost then selfDead = UnitIsGhost("player") and true or false end

    if selfDead then
        local playerName = UnitName("player")

        -- AzerothCore .revive resolves the current selected player or self when
        -- no character argument is supplied.  Clear the selection so the command
        -- cannot accidentally resolve to a stale target after dying/releasing.
        if ClearTarget then pcall(ClearTarget) end

        -- Do not depend on SAY while dead.  WHISPER-to-self is still a normal
        -- CMSG_MESSAGECHAT packet and AzerothCore parses the GM command before
        -- regular chat delivery checks.  This also keeps the command syntax at
        -- the core-native '.revive' form.
        self:RunAfter(0.05, function()
            if ClearTarget then pcall(ClearTarget) end
            addon:SendNow(".revive", definition, "WHISPER", playerName)
        end)

        -- Retry only while the client still reports corpse/ghost.  The second
        -- whisper covers selection-update latency; the final SAY is a compatibility
        -- fallback for custom cores that only accept commands from SAY.
        self:RunAfter(0.35, function()
            local stillDead = (UnitIsDeadOrGhost and UnitIsDeadOrGhost("player"))
                or (UnitIsDead and UnitIsDead("player"))
                or (UnitIsGhost and UnitIsGhost("player"))
            if stillDead then
                if ClearTarget then pcall(ClearTarget) end
                addon:SendNow(".revive", nil, "WHISPER", playerName)
            end
        end)
        self:RunAfter(0.90, function()
            local stillDead = (UnitIsDeadOrGhost and UnitIsDeadOrGhost("player"))
                or (UnitIsDead and UnitIsDead("player"))
                or (UnitIsGhost and UnitIsGhost("player"))
            if stillDead then
                if ClearTarget then pcall(ClearTarget) end
                addon:SendNow(".revive")
            end
        end)
        return
    end

    -- Alive GM: preserve normal target-or-self behavior for reviving another
    -- selected player.
    self:SendNow(".revive", definition)
end

function addon:ExecuteDefinition(definition)
    if not definition then return end

    -- Apply command.security / runtime RBAC denial before both direct commands and
    -- command-backed toggle actions. Pure client-side windows have no permission command.
    local allowed, reason = self:IsDefinitionAllowed(definition)
    if not allowed then
        self:Print("실행 불가: " .. tostring(reason or "권한 부족"), true)
        self:SetDefinitionResult(definition, "locked", reason or "권한 부족")
        return
    end

    if definition.action == "teleports" then
        self:ToggleTeleportWindow()
        return
    elseif definition.action == "favorites" then
        self:ToggleFavoriteWindow()
        return
    elseif definition.action == "questhelper" then
        self:ToggleQuestHelper()
        return
    elseif definition.action == "locale_lookup" then
        self:OpenLocaleSearch(definition.lookupKind)
        return
    elseif definition.action == "kr_item_search" then
        self:OpenLocaleSearch("item")
        return
    elseif definition.action == "kr_quest_search" then
        self:OpenLocaleSearch("quest")
        return
    elseif definition.action == "kr_creature_search" then
        self:OpenLocaleSearch("creature")
        return
    elseif definition.action == "bankToggle" then
        self:ToggleBankWindow()
        return
    elseif definition.action == "craftInfo" then
        self:ToggleCraftInfo()
        return
    elseif definition.action == "itemInfo" then
        self:ToggleItemInfo()
        return
    elseif definition.action == "revive" then
        self:ReviveSmart(definition)
        return
    elseif definition.action == "probeSecurity" then
        self:ProbeSecurity(false)
        return
    elseif definition.action == "godToggle" then
        self:ToggleGod(definition)
        return
    elseif definition.action == "visibilityToggle" then
        self:ToggleVisibility(definition)
        return
    elseif definition.action == "flightToggle" then
        self:ToggleFlight(definition)
        return
    elseif definition.action == "speedToggle" then
        self:ToggleSpeed(definition)
        return
    elseif definition.action == "waterwalkToggle" then
        self:ToggleWaterwalk(definition)
        return
    elseif definition.action == "screenshot" then
        local wasShown = self.frame and self.frame:IsShown()
        if wasShown then self.frame:Hide() end
        Screenshot()
        if wasShown then self.frame:Show() end
        return
    end

    if not self:ValidateDefinitionTarget(definition) then return end

    if definition.command and string.find(definition.command, "{target}", 1, true)
        and trim(self.pendingTargetName or "") == "" and self:GetTargetName() == "" then
        if self.PromptTarget then self:PromptTarget(definition) end
        return
    end
    if definition.command and string.find(definition.command, "{args}", 1, true)
        and trim(self.pendingArgumentValue or "") == "" then
        if self.PromptArguments then self:PromptArguments(definition) end
        return
    end

    local command = self:BuildCommand(definition)
    if not command then return end
    command = self:ValidateCommand(command)
    if not command then return end

    if definition.confirm then
        self:ConfirmCommand(command, definition)
    else
        self:SendNow(command, definition)
    end
end

StaticPopupDialogs["AZEROTHADMIN_EASY_CONFIRM"] = {
    text = "%s\n\n|cffffff00%s|r",
    button1 = YES,
    button2 = NO,
    OnShow = function(self)
        AzerothAdminEasy:RaisePopup(self)
        AzerothAdminEasy:SuspendManagedEscapeForPopup(self)
    end,
    OnHide = function(self)
        AzerothAdminEasy:ResumeManagedEscapeForPopup(self)
    end,
    OnAccept = function()
        local afterCommand = AzerothAdminEasy.pendingDefinition and AzerothAdminEasy.pendingDefinition.afterCommand
        if AzerothAdminEasy.pendingCommand then
            AzerothAdminEasy:SendNow(AzerothAdminEasy.pendingCommand, AzerothAdminEasy.pendingDefinition)
        end
        if afterCommand then AzerothAdminEasy:SendAfter(afterCommand, 0.9) end
        AzerothAdminEasy.pendingCommand = nil
        AzerothAdminEasy.pendingDefinition = nil
    end,
    OnCancel = function()
        AzerothAdminEasy.pendingCommand = nil
        AzerothAdminEasy.pendingDefinition = nil
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}

function addon:RunRawCommand()
    if not self.rawEdit then return end
    local command = trim(self.rawEdit:GetText())
    if command == "" then return end
    self:SendNow(command)
end

function addon:SendAfter(command, delay)
    if not command then return end
    local timer = CreateFrame("Frame")
    local elapsed = 0
    timer:SetScript("OnUpdate", function(self, dt)
        elapsed = elapsed + (dt or 0)
        if elapsed >= (delay or 0.6) then
            self:SetScript("OnUpdate", nil)
            addon:SendNow(command)
        end
    end)
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
eventFrame:RegisterEvent("CHAT_MSG_SYSTEM")
eventFrame:SetScript("OnEvent", function(self, event, ...)
    local arg1 = ...
    if event == "ADDON_LOADED" and arg1 == "AzerothAdmin" then
        AzerothAdminEasyDB = AzerothAdminEasyDB or {}
        AzerothAdminEasyDB.history = AzerothAdminEasyDB.history or {}
        AzerothAdminEasyDB.commandFavorites = AzerothAdminEasyDB.commandFavorites or {}
        addon.sessionDeniedCommands = {}
        addon:AttachCommandMetadata()
        -- UI v4: reset only layout coordinates so older broken builds cannot hide the toolbar/minimap.
        if AzerothAdminEasyDB.layoutVersion ~= 11 then
            AzerothAdminEasyDB.point = nil
            AzerothAdminEasyDB.relativePoint = nil
            AzerothAdminEasyDB.x = nil
            AzerothAdminEasyDB.y = nil
            AzerothAdminEasyDB.toolbarPoint = nil
            AzerothAdminEasyDB.toolbarRelativePoint = nil
            AzerothAdminEasyDB.toolbarX = nil
            AzerothAdminEasyDB.toolbarY = nil
            AzerothAdminEasyDB.minimapX = nil
            AzerothAdminEasyDB.minimapY = nil
            AzerothAdminEasyDB.bankPoint = nil
            AzerothAdminEasyDB.bankRelativePoint = nil
            AzerothAdminEasyDB.bankX = nil
            AzerothAdminEasyDB.bankY = nil
            AzerothAdminEasyDB.remoteBankPoint = nil
            AzerothAdminEasyDB.remoteBankRelativePoint = nil
            AzerothAdminEasyDB.remoteBankX = nil
            AzerothAdminEasyDB.remoteBankY = nil
            AzerothAdminEasyDB.lastCategory = 1
            AzerothAdminEasyDB.lastPage = 1
            AzerothAdminEasyDB.layoutVersion = 11
        end
        AzerothAdminEasyDB.lastCategory = AzerothAdminEasyDB.lastCategory or 1
        AzerothAdminEasyDB.lastPage = AzerothAdminEasyDB.lastPage or 1
        AzerothAdminEasyDB.teleportGroup = AzerothAdminEasyDB.teleportGroup or "ALL"
        if AzerothAdminEasyDB.godMode == nil then AzerothAdminEasyDB.godMode = false end
        if AzerothAdminEasyDB.gmFlight == nil then AzerothAdminEasyDB.gmFlight = false end
        if AzerothAdminEasyDB.gmInvisible == nil then AzerothAdminEasyDB.gmInvisible = false end
        if AzerothAdminEasyDB.speedBoosted == nil then AzerothAdminEasyDB.speedBoosted = false end
        if AzerothAdminEasyDB.waterwalk == nil then AzerothAdminEasyDB.waterwalk = false end
    elseif event == "PLAYER_LOGIN" then
        addon:CreateUI()
        addon:Print(L.READY)
        addon:RunAfter(1.5, function() addon:ProbeSecurity(true) end)
    elseif event == "CHAT_MSG_SYSTEM" then
        addon:HandleCommandSystemMessage(arg1)
    elseif event == "PLAYER_TARGET_CHANGED" then
        -- Main window no longer carries a target input field. Selected target is read on demand.
    end
end)

SLASH_AZEROTHADMINEASY1 = "/aa"
SLASH_AZEROTHADMINEASY2 = "/azerothadmin"
SlashCmdList["AZEROTHADMINEASY"] = function(message)
    message = trim(message)
    if message == "" then
        addon:Toggle()
    elseif string.lower(message) == "tele" or string.lower(message) == "tp" then
        addon:ToggleTeleportWindow()
    elseif string.lower(message) == "fav" or string.lower(message) == "favorite" or string.lower(message) == "favorites" then
        addon:ToggleFavoriteWindow()
    elseif string.lower(message) == "quest" or string.lower(message) == "qh" then
        addon:ToggleQuestHelper()
    elseif string.lower(message) == "bank" then
        addon:ToggleBankWindow()
    elseif string.lower(message) == "craft" or string.lower(message) == "ici" then
        addon:ToggleCraftInfo()
    elseif string.lower(message) == "iteminfo" or string.lower(message) == "bii" then
        addon:ToggleItemInfo()
    elseif string.lower(message) == "auth" or string.lower(message) == "rbac" then
        addon:ProbeSecurity(false)
    elseif string.sub(string.lower(message), 1, 4) == "run " then
        addon:SendNow(trim(string.sub(message, 5)))
    elseif string.lower(message) == "clear" then
        AzerothAdminEasyDB.history = {}
        if addon.RefreshHistory then addon:RefreshHistory() end
        addon:Print("최근 명령을 지웠습니다.")
    elseif string.lower(message) == "bar" then
        if addon.toolbar then
            if addon.toolbar:IsShown() then addon.toolbar:Hide() else addon.toolbar:Show() end
        end
    elseif string.lower(message) == "icon" then
        if addon.minimapButton then
            if addon.minimapButton:IsShown() then addon.minimapButton:Hide() else addon.minimapButton:Show() end
        end
    elseif string.lower(message) == "resetui" then
        AzerothAdminEasyDB.point = nil
        AzerothAdminEasyDB.relativePoint = nil
        AzerothAdminEasyDB.x = nil
        AzerothAdminEasyDB.y = nil
        AzerothAdminEasyDB.toolbarPoint = nil
        AzerothAdminEasyDB.toolbarRelativePoint = nil
        AzerothAdminEasyDB.toolbarX = nil
        AzerothAdminEasyDB.toolbarY = nil
        AzerothAdminEasyDB.minimapX = nil
        AzerothAdminEasyDB.minimapY = nil
        AzerothAdminEasyDB.bankPoint = nil
        AzerothAdminEasyDB.bankRelativePoint = nil
        AzerothAdminEasyDB.bankX = nil
        AzerothAdminEasyDB.bankY = nil
        AzerothAdminEasyDB.remoteBankPoint = nil
        AzerothAdminEasyDB.remoteBankRelativePoint = nil
        AzerothAdminEasyDB.remoteBankX = nil
        AzerothAdminEasyDB.remoteBankY = nil
        if addon.frame then
            addon.frame:ClearAllPoints(); addon.frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
        end
        if addon.toolbar then
            addon.toolbar:ClearAllPoints(); addon.toolbar:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, 92); addon.toolbar:Show()
        end
        if addon.minimapButton then
            addon.minimapButton:ClearAllPoints(); addon.minimapButton:SetPoint("TOPRIGHT", Minimap, "TOPRIGHT", 7, -38); addon.minimapButton:Show()
        end
        if BankFrame then
            BankFrame:ClearAllPoints(); BankFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
        end
        if addon.remoteBankFrame then
            addon.remoteBankFrame:ClearAllPoints(); addon.remoteBankFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
        end
        addon:Print("UI 위치를 기본값으로 복구했습니다.")
    else
        addon:Print("/aa, /aa tele, /aa fav, /aa quest, /aa bank, /aa craft, /aa iteminfo, /aa auth, /aa bar, /aa icon, /aa resetui, /aa run .명령, /aa clear")
    end
end
