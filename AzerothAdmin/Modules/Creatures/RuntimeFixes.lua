AzerothAdminEasy = AzerothAdminEasy or {}
local addon = AzerothAdminEasy

-- R8.1 precheck runtime corrections for WoW WotLK 3.3.5a Build 12340 + AzerothCore.
--
-- Keyboard:
--   Preserve the R6 koKR input-release sequence that was confirmed in game.
--   It completes the input-language transition, clears any keyboard focus,
--   disables keyboard capture on the finished search EditBox, and restores it
--   when the player clicks the field again. It never submits chat text.
--
-- PlayerModel:
--   Follow the real 3.3.5 _NPCScan sequence: keep PlayerModel visible,
--   ClearModel -> reset scale/position/facing -> install OnUpdateModel ->
--   SetCreature(entry). Do not Hide/alpha-zero the model before loading.

addon.CreatureBrowserRuntimeRevision = "IME R6 / MODEL R8.1 PRECHECK"

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

chatMessage("|cffffd24aAzerothAdmin R8.1 PRECHECK · IME R6 로드됨|r")

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
-- Creature PlayerModel: 3.3.5 _NPCScan-compatible load lifecycle
-- ---------------------------------------------------------------------------

local MODEL_DEFAULT_SCALE = 0.75
local MODEL_CAMERAS = {
    ["creature\\dragon\\northrenddragon.m2"] = { 0.50, 0, 20, -14 },
    ["creature\\protodragon\\protodragon.m2"] = { 1.30, 0, -3, 0 },
    ["creature\\mammoth\\mammoth.m2"] = { 0.35, 0.9, 2.7, 0 },
    ["creature\\northrendfleshgiant\\northrendfleshgiant.m2"] = { 1.0, 0, 2, 0 },
}

local function modelPath(model)
    if not model or not model.GetModel then return nil end
    local ok, path = pcall(model.GetModel, model)
    if ok and type(path) == "string" and path ~= "" then return path end
    return nil
end

local function ensureStatus()
    if addon.creatureBrowserModelStatus or not addon.creatureBrowserModel then return end
    local parent = addon.creatureBrowserModel:GetParent()
    if not parent then return end
    local status = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    status:SetPoint("CENTER", parent, "CENTER", 0, -4)
    status:SetWidth(190)
    status:SetJustifyH("CENTER")
    status:SetTextColor(1, 0.78, 0.28)
    status:SetText("")
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

local function applyModelCamera(model)
    local path = modelPath(model)
    if not path then return false end
    local camera = MODEL_CAMERAS[string.lower(path)]
    local scale = camera and camera[1] or 1
    local x = camera and camera[2] or 0
    local y = camera and camera[3] or 0
    local z = camera and camera[4] or 0
    if model.SetModelScale then safeCall(model.SetModelScale, model, MODEL_DEFAULT_SCALE * scale) end
    if model.SetPosition then safeCall(model.SetPosition, model, z, x, y) end
    if model.SetCamDistanceScale then safeCall(model.SetCamDistanceScale, model, 1.05) end
    if model.SetRotation then safeCall(model.SetRotation, model, addon.creatureBrowserModelRotation or 0) end
    if model.SetAlpha then safeCall(model.SetAlpha, model, 1) end
    model:Show()
    if addon.creatureBrowserModelFallback then addon.creatureBrowserModelFallback:Hide() end
    setStatus("")
    return true
end

local function resetModelVisible(model, keepFacing)
    if not model then return end
    -- _NPCScan keeps the PlayerModel active while SetCreature loads its mesh.
    -- R7 hid/zeroed alpha before loading and regressed even known cached models.
    model:Show()
    if model.SetAlpha then safeCall(model.SetAlpha, model, 1) end
    if model.ClearModel then safeCall(model.ClearModel, model) end
    if model.SetModelScale then safeCall(model.SetModelScale, model, 1) end
    if model.SetPosition then safeCall(model.SetPosition, model, 0, 0, 0) end
    if not keepFacing and model.SetFacing then safeCall(model.SetFacing, model, 0) end
end

-- _NPCScan 3.3.5 extracts the 20-bit NPC entry from GUID characters 8..12.
local function targetCreatureEntry()
    if not UnitExists or not UnitExists("target") then return nil end
    if UnitIsPlayer and UnitIsPlayer("target") then return nil end
    if not UnitGUID then return nil end
    local guid = UnitGUID("target")
    if type(guid) ~= "string" or string.len(guid) < 12 then return nil end
    return tonumber(string.sub(guid, 8, 12), 16)
end

local modelSerial = 0

local function finishModelLoad(model, record, serial)
    if serial ~= modelSerial or addon.creatureBrowserSelected ~= record then return end
    if applyModelCamera(model) then return end
    if addon.creatureBrowserModelFallback then addon.creatureBrowserModelFallback:Show() end
    setStatus("R8.1: Entry " .. tostring(record and record[1] or "?")
        .. " 가 클라이언트 creaturecache에 없습니다.\n검증된 R8.1 캐시 병합 후 WoW를 완전히 재시작하세요.")
end

local function loadModelNative(record, useTarget)
    local model = addon.creatureBrowserModel
    local entry = tonumber(record and record[1])
    if not model or not entry then return end

    modelSerial = modelSerial + 1
    local serial = modelSerial
    setStatus("R8.1: Entry " .. tostring(entry) .. " 3D 외형 로드 중...")
    if addon.creatureBrowserModelFallback then addon.creatureBrowserModelFallback:Hide() end
    resetModelVisible(model, false)

    local oldOnUpdate = model:GetScript("OnUpdate")
    local oldOnUpdateModel = model:GetScript("OnUpdateModel")
    local modelReady = false

    local function restoreScripts()
        if serial ~= modelSerial then return end
        model:SetScript("OnUpdateModel", oldOnUpdateModel)
        model:SetScript("OnUpdate", oldOnUpdate)
    end

    local function afterOneFrame(self)
        if serial ~= modelSerial then return end
        self:SetScript("OnUpdate", oldOnUpdate)
        modelReady = applyModelCamera(self)
        if modelReady then self:SetScript("OnUpdateModel", oldOnUpdateModel) end
    end

    model:SetScript("OnUpdateModel", function(self)
        if serial ~= modelSerial then return end
        self:SetScript("OnUpdateModel", nil)
        self:SetScript("OnUpdate", afterOneFrame)
    end)

    local ok = false
    if useTarget and targetCreatureEntry() == entry and model.SetUnit then
        ok = safeCall(model.SetUnit, model, "target")
    elseif model.SetCreature then
        ok = safeCall(model.SetCreature, model, entry)
    end

    if not ok then
        restoreScripts()
        if addon.creatureBrowserModelFallback then addon.creatureBrowserModelFallback:Show() end
        setStatus("R8.1: PlayerModel 호출 실패 · Entry " .. tostring(entry))
        return
    end

    runAfter(0.08, function()
        if serial ~= modelSerial or modelReady then return end
        if modelPath(model) then
            modelReady = applyModelCamera(model)
            if modelReady then restoreScripts() end
        end
    end)

    runAfter(1.00, function()
        if serial ~= modelSerial or modelReady then return end
        restoreScripts()
        finishModelLoad(model, record, serial)
    end)
end

if addon.SelectFeaturedCreature and not addon._aaeR81SelectWrapped then
    addon._aaeR81SelectWrapped = true
    local oldSelectFeaturedCreature = addon.SelectFeaturedCreature
    addon.SelectFeaturedCreature = function(self, record)
        local result = oldSelectFeaturedCreature(self, record)
        if record then
            loadModelNative(record, targetCreatureEntry() == tonumber(record[1]))
        else
            modelSerial = modelSerial + 1
            if self.creatureBrowserModel then
                self.creatureBrowserModel:Hide()
                if self.creatureBrowserModel.ClearModel then safeCall(self.creatureBrowserModel.ClearModel, self.creatureBrowserModel) end
            end
            setStatus("")
        end
        return result
    end
end

local modelEvents = CreateFrame("Frame")
modelEvents:RegisterEvent("PLAYER_TARGET_CHANGED")
modelEvents:RegisterEvent("UNIT_MODEL_CHANGED")
modelEvents:SetScript("OnEvent", function(self, event, unit)
    if event == "UNIT_MODEL_CHANGED" and unit and unit ~= "target" then return end
    local record = addon.creatureBrowserSelected
    if not record or not addon.creatureBrowserFrame or not addon.creatureBrowserFrame:IsShown() then return end
    if targetCreatureEntry() == tonumber(record[1]) then loadModelNative(record, true) end
end)

if addon.CreateCreatureBrowser and not addon._aaeR81CreateWrapped then
    addon._aaeR81CreateWrapped = true
    local oldCreateCreatureBrowser = addon.CreateCreatureBrowser
    addon.CreateCreatureBrowser = function(self, ...)
        local result = oldCreateCreatureBrowser(self, ...)
        installCreatureSearchImeR6()
        ensureStatus()
        return result
    end
end
