AzerothAdminEasy = AzerothAdminEasy or {}
local addon = AzerothAdminEasy

-- R7 runtime corrections for WoW WotLK 3.3.5a Build 12340 + AzerothCore.
-- Keyboard behavior from R6 is preserved; PlayerModel handling is replaced with
-- a cache-independent AzerothCore GM morph snapshot fallback.
addon.CreatureBrowserRuntimeRevision = "IME R6 / MODEL R7"

local function safeCall(method, object, ...)
    if not method or not object then return false end
    return pcall(method, object, ...)
end

local function runAfter(delay, callback)
    if addon.RunAfter then addon:RunAfter(delay, callback) else callback() end
end

local function chatMessage(text)
    if DEFAULT_CHAT_FRAME and DEFAULT_CHAT_FRAME.AddMessage then
        DEFAULT_CHAT_FRAME:AddMessage(text)
    end
end

chatMessage("|cffffd24aAzerothAdmin R7 MODEL TEST 로드됨|r")

-- ---------------------------------------------------------------------------
-- koKR IME release (R6: user game-tested and confirmed working)
-- ---------------------------------------------------------------------------

local imeFrame = CreateFrame("Frame")
imeFrame:Hide()
imeFrame.elapsed = 0
imeFrame.edit = nil
imeFrame.oldLanguageScript = nil
imeFrame.serial = 0

local function currentKeyboardFocus()
    if not GetCurrentKeyBoardFocus then return nil end
    local ok, focus = pcall(GetCurrentKeyBoardFocus)
    if ok then return focus end
    return nil
end

local function deactivateActiveChat()
    if not ChatEdit_GetActiveWindow then return end
    local ok, active = pcall(ChatEdit_GetActiveWindow)
    if ok and active and ChatEdit_DeactivateChat then
        pcall(ChatEdit_DeactivateChat, active)
    end
end

local function finalRelease(edit, serial)
    if serial and serial ~= imeFrame.serial then return end

    if edit then
        if edit.ClearFocus then safeCall(edit.ClearFocus, edit) end
        if edit.EnableKeyboard then safeCall(edit.EnableKeyboard, edit, false) end
    end

    local focus = currentKeyboardFocus()
    if focus and focus ~= edit and focus.ClearFocus then
        safeCall(focus.ClearFocus, focus)
    elseif focus == edit and edit and edit.ClearFocus then
        safeCall(edit.ClearFocus, edit)
    end

    deactivateActiveChat()
    imeFrame:Hide()
    imeFrame.edit = nil
    imeFrame.elapsed = 0
end

local function getInputLanguage(edit)
    if not edit or not edit.GetInputLanguage then return nil end
    local ok, language = pcall(edit.GetInputLanguage, edit)
    if ok then return language end
    return nil
end

imeFrame:SetScript("OnUpdate", function(self, elapsed)
    local edit = self.edit
    if not edit then self:Hide(); return end
    self.elapsed = self.elapsed + (elapsed or 0)

    local language = getInputLanguage(edit)
    if language == "ROMAN" then
        finalRelease(edit, self.serial)
        return
    end

    if self.elapsed >= 0.12 and not self.retried then
        self.retried = true
        if edit.SetFocus then safeCall(edit.SetFocus, edit) end
        if edit.ToggleInputLanguage then safeCall(edit.ToggleInputLanguage, edit) end
    end

    if self.elapsed >= 0.45 then
        finalRelease(edit, self.serial)
    end
end)

function addon:ReleaseKoreanSearchInput(edit)
    if not edit then return end

    imeFrame.serial = imeFrame.serial + 1
    local serial = imeFrame.serial
    imeFrame.edit = edit
    imeFrame.elapsed = 0
    imeFrame.retried = false

    if edit.EnableKeyboard then safeCall(edit.EnableKeyboard, edit, true) end
    if edit.Show then edit:Show() end
    if edit.SetFocus then safeCall(edit.SetFocus, edit) end

    local language = getInputLanguage(edit)
    if language == "ROMAN" then
        finalRelease(edit, serial)
        return
    end

    if edit.ToggleInputLanguage then
        safeCall(edit.ToggleInputLanguage, edit)
        imeFrame:Show()
    else
        finalRelease(edit, serial)
    end
end

local function makeEditReactivatable(edit)
    if not edit or edit._aaeR6Reactivatable then return end
    edit._aaeR6Reactivatable = true

    local oldMouseDown = edit:GetScript("OnMouseDown")
    edit:SetScript("OnMouseDown", function(self, ...)
        imeFrame.serial = imeFrame.serial + 1
        imeFrame:Hide()
        imeFrame.edit = nil
        if self.EnableKeyboard then safeCall(self.EnableKeyboard, self, true) end
        if oldMouseDown then oldMouseDown(self, ...) end
        if self.SetFocus then safeCall(self.SetFocus, self) end
    end)

    local oldFocusGained = edit:GetScript("OnEditFocusGained")
    edit:SetScript("OnEditFocusGained", function(self, ...)
        if self.EnableKeyboard then safeCall(self.EnableKeyboard, self, true) end
        if oldFocusGained then oldFocusGained(self, ...) end
    end)
end

local function getButtonText(button)
    if not button then return nil end
    if button.label and button.label.GetText then
        local ok, text = pcall(button.label.GetText, button.label)
        if ok and text then return text end
    end
    if button.GetText then
        local ok, text = pcall(button.GetText, button)
        if ok then return text end
    end
    return nil
end

local function hookSubmitButton(button, edit, accepted)
    if not button or button._aaeR6ImeHooked then return end
    local text = getButtonText(button)
    if not text or not accepted[text] then return end
    local oldClick = button:GetScript("OnClick")
    if not oldClick then return end

    button._aaeR6ImeHooked = true
    button:SetScript("OnClick", function(self, ...)
        oldClick(self, ...)
        addon:ReleaseKoreanSearchInput(edit)
    end)
end

local function hookButtonsRecursive(frame, edit, accepted)
    if not frame or not frame.GetChildren then return end
    local children = { frame:GetChildren() }
    local i
    for i = 1, table.getn(children) do
        local child = children[i]
        hookSubmitButton(child, edit, accepted)
        hookButtonsRecursive(child, edit, accepted)
    end
end

local function hookEnter(edit)
    if not edit or edit._aaeR6EnterHooked then return end
    local oldEnter = edit:GetScript("OnEnterPressed")
    if not oldEnter then return end
    edit._aaeR6EnterHooked = true
    edit:SetScript("OnEnterPressed", function(self, ...)
        oldEnter(self, ...)
        addon:ReleaseKoreanSearchInput(self)
    end)
end

local function installBlueItemImeR6()
    local BII3 = _G.BlueItemInfo3
    if not BII3 or not BII3.searchEdit then return end
    local edit = BII3.searchEdit
    makeEditReactivatable(edit)
    hookEnter(edit)
    hookButtonsRecursive(BII3, edit, {
        ["검색"] = true,
        ["분류"] = true,
        ["필터 적용"] = true,
    })

    if BII3.Search and not BII3._aaeR6PublicSearchWrapped then
        BII3._aaeR6PublicSearchWrapped = true
        local oldSearch = BII3.Search
        BII3.Search = function(self, ...)
            local result = oldSearch(self, ...)
            addon:ReleaseKoreanSearchInput(self.searchEdit)
            return result
        end
    end
end

local function installCreatureSearchImeR6()
    local frame = addon.creatureBrowserFrame
    local edit = addon.creatureBrowserSearch
    if not frame or not edit then return end
    makeEditReactivatable(edit)
    hookEnter(edit)
    hookButtonsRecursive(frame, edit, {
        ["검색"] = true,
        ["전체 DB 검색"] = true,
    })
end

if addon.RunLocaleSearch and not addon._aaeR6LocaleWrapped then
    addon._aaeR6LocaleWrapped = true
    local oldRunLocaleSearch = addon.RunLocaleSearch
    addon.RunLocaleSearch = function(self, ...)
        local result = oldRunLocaleSearch(self, ...)
        self:ReleaseKoreanSearchInput(self.localeSearchEdit)
        return result
    end
end

installBlueItemImeR6()
installCreatureSearchImeR6()

-- ---------------------------------------------------------------------------
-- Creature PlayerModel R7
-- ---------------------------------------------------------------------------
-- Stock 3.3.5a PlayerModel:SetCreature(entry) only renders entries already
-- known to the client.  R7 keeps that fast path, then falls back to AzerothCore
-- GM morph + PlayerModel:SetUnit("player") so first-ever-seen NPCs can render.

local function clearModel()
    local model = addon.creatureBrowserModel
    if not model then return end
    if model.Hide then model:Hide() end
    if model.ClearModel then safeCall(model.ClearModel, model) end
    if model.SetAlpha then safeCall(model.SetAlpha, model, 0) end
end

local function modelLoaded(model)
    if not model or not model.GetModel then return false end
    local ok, path = pcall(model.GetModel, model)
    return ok and type(path) == "string" and path ~= ""
end

local function ensureStatus()
    if addon.creatureBrowserModelStatus or not addon.creatureBrowserModel then return end
    local parent = addon.creatureBrowserModel:GetParent()
    if not parent then return end
    local status = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    status:SetPoint("CENTER", parent, "CENTER", 0, -4)
    status:SetWidth(184)
    status:SetJustifyH("CENTER")
    status:SetTextColor(1, 0.78, 0.28)
    status:Hide()
    addon.creatureBrowserModelStatus = status
end

local function setStatus(text)
    ensureStatus()
    local status = addon.creatureBrowserModelStatus
    if not status then return end
    status:SetText(text or "")
    if text and text ~= "" then status:Show() else status:Hide() end
end

local function applyPreviewPresentation()
    local model = addon.creatureBrowserModel
    if not model then return end
    if model.SetModelScale then safeCall(model.SetModelScale, model, 0.82) end
    if model.SetPosition then safeCall(model.SetPosition, model, 0, 0, 0) end
    if model.SetCamDistanceScale then safeCall(model.SetCamDistanceScale, model, 1.05) end
    if model.SetRotation then safeCall(model.SetRotation, model, addon.creatureBrowserModelRotation or 0) end
    if model.SetAlpha then safeCall(model.SetAlpha, model, 1) end
    model:Show()
    if addon.creatureBrowserModelFallback then addon.creatureBrowserModelFallback:Hide() end
end

-- _NPCScan 3.3.5 uses characters 8..12 of UnitGUID for the 20-bit NPC ID.
local function targetCreatureEntry()
    if not UnitExists or not UnitExists("target") or (UnitIsPlayer and UnitIsPlayer("target")) then return nil end
    if not UnitGUID then return nil end
    local guid = UnitGUID("target")
    if type(guid) ~= "string" or string.len(guid) < 12 then return nil end
    return tonumber(string.sub(guid, 8, 12), 16)
end

local function selectedModelInfo(record)
    local entry = tonumber(record and record[1])
    local map = addon.FeaturedCreatureModelInfo or {}
    local info = entry and map[entry] or nil
    if not info then return nil end
    return {
        entry = entry,
        displayID = tonumber(info[1]),
        displayScale = tonumber(info[2]) or 1,
        verifiedBuild = tonumber(info[3]) or 0,
    }
end

local function sendPreviewCommand(command)
    if not command or command == "" or not SendChatMessage then return false end
    -- Do not use addon:SendNow: preview morph/reset must not pollute GM history.
    SendChatMessage(command, "SAY")
    return true
end

local function tryDirectModel(record)
    local model = addon.creatureBrowserModel
    local entry = tonumber(record and record[1])
    if not model or not entry then return false end

    clearModel()
    if targetCreatureEntry() == entry and model.SetUnit then
        if safeCall(model.SetUnit, model, "target") then return true end
    end
    if model.SetCreature then return safeCall(model.SetCreature, model, entry) end
    return false
end

local morphState = {
    serial = 0,
    _state = nil,
}

local function restorePreviousTarget(state)
    if state and state.hadTarget and TargetLastTarget then pcall(TargetLastTarget) end
end

local function resetSelfMorph(state)
    if not state or state.phase == "done" then return end
    if ClearTarget then pcall(ClearTarget) end
    sendPreviewCommand(".morph reset")
    state.phase = "resetting"

    runAfter(0.18, function()
        if morphState.serial ~= state.serial then return end
        restorePreviousTarget(state)
        state.phase = "done"
        if morphState._state == state then morphState._state = nil end
        if modelLoaded(addon.creatureBrowserModel) then
            applyPreviewPresentation()
            setStatus("")
        else
            clearModel()
            if addon.creatureBrowserModelFallback then addon.creatureBrowserModelFallback:Show() end
            setStatus("R7: DisplayID " .. tostring(state.info and state.info.displayID or "?")
                .. " 스냅샷에 실패했습니다.")
        end
    end)
end

local function captureMorphedPlayer(state)
    if not state or morphState.serial ~= state.serial or state.captured then return end
    state.captured = true
    state.phase = "capturing"

    local model = addon.creatureBrowserModel
    if not model or not model.SetUnit then
        resetSelfMorph(state)
        return
    end

    clearModel()
    if model.SetModelScale then safeCall(model.SetModelScale, model, 1) end
    if model.SetPosition then safeCall(model.SetPosition, model, 0, 0, 0) end

    local finished = false
    local function finishSnapshot()
        if finished or morphState.serial ~= state.serial then return end
        finished = true
        if model.SetScript then model:SetScript("OnUpdateModel", state.oldOnUpdateModel) end
        if modelLoaded(model) then
            applyPreviewPresentation()
            setStatus("")
        end
        resetSelfMorph(state)
    end

    if model.GetScript then state.oldOnUpdateModel = model:GetScript("OnUpdateModel") end
    if model.SetScript then
        model:SetScript("OnUpdateModel", function(self)
            finishSnapshot()
        end)
    end

    safeCall(model.SetUnit, model, "player")
    model:Show()
    runAfter(0.16, finishSnapshot)
end

local function cancelActiveMorph()
    local state = morphState._state
    if not state or state.phase == "done" then return end
    if ClearTarget then pcall(ClearTarget) end
    sendPreviewCommand(".morph reset")
    restorePreviousTarget(state)
    state.phase = "done"
    morphState.serial = morphState.serial + 1
    morphState._state = nil
end

local function beginMorphFallback(record, serial)
    if serial ~= addon._aaeR7ModelSerial or addon.creatureBrowserSelected ~= record then return end

    local info = selectedModelInfo(record)
    if not info or not info.displayID or info.displayID <= 0 then
        clearModel()
        if addon.creatureBrowserModelFallback then addon.creatureBrowserModelFallback:Show() end
        setStatus("R7: Entry " .. tostring(record and record[1] or "?") .. " DisplayID 데이터가 없습니다.")
        return
    end

    if InCombatLockdown and InCombatLockdown() then
        clearModel()
        if addon.creatureBrowserModelFallback then addon.creatureBrowserModelFallback:Show() end
        setStatus("R7: 전투 중에는 서버 보조 3D 미리보기를 실행하지 않습니다.")
        return
    end

    local hadTarget = UnitExists and UnitExists("target") and true or false
    if hadTarget and not ClearTarget then
        setStatus("R7: 현재 대상을 안전하게 해제할 수 없어 서버 보조 미리보기를 중단했습니다.")
        return
    end
    if hadTarget then pcall(ClearTarget) end

    morphState.serial = morphState.serial + 1
    local state = {
        serial = morphState.serial,
        phase = "waitingMorph",
        record = record,
        info = info,
        hadTarget = hadTarget,
        captured = false,
        oldOnUpdateModel = nil,
    }
    morphState._state = state

    setStatus("R7: 캐시 미등록 · DisplayID " .. tostring(info.displayID) .. " 서버 보조 로드 중...")
    if not sendPreviewCommand(".morph target " .. tostring(info.displayID)) then
        restorePreviousTarget(state)
        morphState._state = nil
        setStatus("R7: morph 명령을 전송하지 못했습니다.")
        return
    end

    runAfter(0.30, function()
        if morphState._state ~= state or state.phase ~= "waitingMorph" then return end
        captureMorphedPlayer(state)
    end)

    runAfter(0.90, function()
        if morphState._state ~= state or state.phase == "done" then return end
        if not state.captured then captureMorphedPlayer(state) end
        if state.phase ~= "done" and state.phase ~= "resetting" then resetSelfMorph(state) end
    end)
end

local function startCreatureModel(record)
    cancelActiveMorph()
    addon._aaeR7ModelSerial = (addon._aaeR7ModelSerial or 0) + 1
    local serial = addon._aaeR7ModelSerial
    clearModel()

    if not record then
        setStatus("")
        return
    end

    setStatus("R7: Entry " .. tostring(record[1]) .. " 외형 로드 중...")
    tryDirectModel(record)

    runAfter(0.14, function()
        if serial ~= addon._aaeR7ModelSerial or addon.creatureBrowserSelected ~= record then return end
        if modelLoaded(addon.creatureBrowserModel) then
            applyPreviewPresentation()
            setStatus("")
            return
        end
        beginMorphFallback(record, serial)
    end)
end

if addon.SelectFeaturedCreature and not addon._aaeR7SelectWrapped then
    addon._aaeR7SelectWrapped = true
    local oldSelectFeaturedCreature = addon.SelectFeaturedCreature
    addon.SelectFeaturedCreature = function(self, record)
        local result = oldSelectFeaturedCreature(self, record)
        startCreatureModel(record)
        return result
    end
end

local modelEvents = CreateFrame("Frame")
modelEvents:RegisterEvent("UNIT_MODEL_CHANGED")
modelEvents:RegisterEvent("PLAYER_TARGET_CHANGED")
modelEvents:SetScript("OnEvent", function(self, event, unit)
    local state = morphState._state

    if event == "UNIT_MODEL_CHANGED" and unit == "player" and state and state.phase == "waitingMorph" then
        captureMorphedPlayer(state)
        return
    end

    if event == "PLAYER_TARGET_CHANGED" and (not state or state.phase == "done") then
        local record = addon.creatureBrowserSelected
        if not record or not addon.creatureBrowserFrame or not addon.creatureBrowserFrame:IsShown() then return end
        if targetCreatureEntry() == tonumber(record[1]) then
            addon._aaeR7ModelSerial = (addon._aaeR7ModelSerial or 0) + 1
            local model = addon.creatureBrowserModel
            clearModel()
            if model and model.SetUnit and safeCall(model.SetUnit, model, "target") then
                runAfter(0.12, function()
                    if modelLoaded(model) then applyPreviewPresentation(); setStatus("") end
                end)
            end
        end
    end
end)

if addon.CreateCreatureBrowser and not addon._aaeR7CreateWrapped then
    addon._aaeR7CreateWrapped = true
    local oldCreateCreatureBrowser = addon.CreateCreatureBrowser
    addon.CreateCreatureBrowser = function(self, ...)
        local result = oldCreateCreatureBrowser(self, ...)
        installCreatureSearchImeR6()
        ensureStatus()
        if self.creatureBrowserFrame and not self.creatureBrowserFrame._aaeR7MorphHideHooked then
            self.creatureBrowserFrame._aaeR7MorphHideHooked = true
            local oldHide = self.creatureBrowserFrame:GetScript("OnHide")
            self.creatureBrowserFrame:SetScript("OnHide", function(frame, ...)
                cancelActiveMorph()
                if oldHide then oldHide(frame, ...) end
            end)
        end
        return result
    end
end
