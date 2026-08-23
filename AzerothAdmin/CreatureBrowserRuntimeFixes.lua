AzerothAdminEasy = AzerothAdminEasy or {}
local addon = AzerothAdminEasy

-- WoW WotLK 3.3.5a Build 12340 + AzerothCore runtime diagnostics/fixes.
-- This file is loaded last.  R4 deliberately hooks the actual button scripts
-- after BlueItemInfo3/CreatureBrowser have finished building their UI.
addon.CreatureBrowserRuntimeRevision = "IME/MODEL R4"

-- Selected AzerothCore creature_template_model rows verified against the public
-- AzerothCore WotLK world DB.  A Build 12340 row is preferred when one exists.
-- The second argument to SetCreature is attempted only through pcall because
-- support differs between old client builds; SetUnit(target) remains the exact
-- path when the creature is physically loaded in the 3.3.5a client.
local ACORE_MODEL_INFO = {
    [3057]  = { { 4307, 51831 } },
    [4949]  = { { 4527, 12340 } },
    [4968]  = { { 30863, 51831 } },
    [7937]  = { { 7006, 12340 }, { 31658, 51831 } },
    [7999]  = { { 7274, 51831 } },
    [10181] = { { 28213, 12340 } },
    [10184] = { { 8570, 51831 } },
    [12397] = { { 12449, 12340 } },
    [14887] = { { 15364, 12340 } },
    [14888] = { { 15365, 12340 } },
    [14889] = { { 15366, 12340 } },
    [14890] = { { 15363, 12340 } },
    [36597] = { { 30721, 11159 } },
}
addon.AzerothCoreCreatureModelInfo = ACORE_MODEL_INFO

local function safeCall(method, object, ...)
    if not method or not object then return false end
    return pcall(method, object, ...)
end

local function runAfter(delay, callback)
    if addon.RunAfter then
        addon:RunAfter(delay, callback)
    else
        callback()
    end
end

-- ---------------------------------------------------------------------------
-- Keyboard / koKR IME
-- ---------------------------------------------------------------------------

local imeSink = CreateFrame("EditBox", "AzerothAdminImeReleaseSink", UIParent)
imeSink:SetWidth(1)
imeSink:SetHeight(1)
imeSink:SetPoint("TOPLEFT", UIParent, "TOPLEFT", -20, 20)
imeSink:SetAutoFocus(false)
imeSink:SetAlpha(0)
imeSink:EnableMouse(false)
imeSink:Hide()

local function getCurrentFocus()
    if not GetCurrentKeyBoardFocus then return nil end
    local ok, focus = pcall(GetCurrentKeyBoardFocus)
    if ok then return focus end
    return nil
end

local function clearCurrentFocus()
    local pass
    for pass = 1, 4 do
        local focus = getCurrentFocus()
        if not focus then return true end
        if focus.ClearFocus then safeCall(focus.ClearFocus, focus) end
    end
    return getCurrentFocus() == nil
end

local function focusStateText()
    local focus = getCurrentFocus()
    if not focus then return "KEY:FREE" end
    local name = nil
    if focus.GetName then
        local ok, value = pcall(focus.GetName, focus)
        if ok then name = value end
    end
    if not name or name == "" then name = "EditBox" end
    return "KEY:FOCUS " .. tostring(name)
end

local function updateImeBadges()
    local state = focusStateText()
    if addon._aaeR4CreatureBadge then
        addon._aaeR4CreatureBadge:SetText("IME/MODEL R4 · " .. state)
    end
    local BII3 = _G.BlueItemInfo3
    if BII3 and BII3._aaeR4ImeBadge then
        BII3._aaeR4ImeBadge:SetText("IME R4 · " .. state)
    end
end

local function forceFocusToSinkAndRelease()
    imeSink:Show()
    if imeSink.EnableKeyboard then safeCall(imeSink.EnableKeyboard, imeSink, true) end
    if imeSink.SetText then imeSink:SetText("") end
    if imeSink.SetFocus then safeCall(imeSink.SetFocus, imeSink) end
    if imeSink.ClearFocus then safeCall(imeSink.ClearFocus, imeSink) end
    if imeSink.EnableKeyboard then safeCall(imeSink.EnableKeyboard, imeSink, false) end
    imeSink:Hide()
end

local function hardReleaseEdit(edit)
    -- The key difference from the previous attempts is that R4 does not assume
    -- that 'edit' is the object still owning the keyboard.  It clears the real
    -- keyboard focus reported by the 3.3.5 API after the search handler ran.
    if edit and edit.ClearFocus then safeCall(edit.ClearFocus, edit) end
    clearCurrentFocus()
    forceFocusToSinkAndRelease()
    clearCurrentFocus()

    -- Keep the submitted EditBox unable to recapture keyboard input until the
    -- user explicitly clicks it again.  This is intentional for koKR IME.
    if edit and edit.EnableKeyboard then safeCall(edit.EnableKeyboard, edit, false) end

    updateImeBadges()
    runAfter(0.05, function()
        clearCurrentFocus()
        updateImeBadges()
    end)
    runAfter(0.20, function()
        clearCurrentFocus()
        updateImeBadges()
    end)
end

local function makeEditReactivatable(edit)
    if not edit or edit._aaeR4Reactivatable then return end
    edit._aaeR4Reactivatable = true

    local oldMouseDown = edit:GetScript("OnMouseDown")
    edit:SetScript("OnMouseDown", function(self, ...)
        if self.EnableKeyboard then safeCall(self.EnableKeyboard, self, true) end
        if oldMouseDown then oldMouseDown(self, ...) end
        if self.SetFocus then safeCall(self.SetFocus, self) end
        updateImeBadges()
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
    if not button or button._aaeR4ImeHooked then return end
    local text = getButtonText(button)
    if not text or not accepted[text] then return end
    local oldClick = button:GetScript("OnClick")
    if not oldClick then return end

    button._aaeR4ImeHooked = true
    button:SetScript("OnClick", function(self, ...)
        -- IMPORTANT: run original FIRST.  BlueItemInfo3's visible search button
        -- calls its local runSearch() directly; it does not call BII3:Search().
        oldClick(self, ...)
        hardReleaseEdit(edit)
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
    if not edit or edit._aaeR4EnterHooked then return end
    local oldEnter = edit:GetScript("OnEnterPressed")
    if not oldEnter then return end

    edit._aaeR4EnterHooked = true
    edit:SetScript("OnEnterPressed", function(self, ...)
        oldEnter(self, ...)
        hardReleaseEdit(self)
    end)
end

local function createBadge(parent, text, point, x, y)
    if not parent then return nil end
    local badge = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    badge:SetPoint(point or "TOPRIGHT", parent, point or "TOPRIGHT", x or -12, y or -10)
    badge:SetText(text)
    badge:SetTextColor(1, 0.82, 0.1)
    return badge
end

local function installBlueItemImeR4()
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

    if not BII3._aaeR4ImeBadge then
        BII3._aaeR4ImeBadge = createBadge(BII3, "IME R4 · " .. focusStateText(), "TOPRIGHT", -12, -11)
    end

    if BII3.Search and not BII3._aaeR4SearchWrapped then
        BII3._aaeR4SearchWrapped = true
        local oldSearch = BII3.Search
        BII3.Search = function(self, ...)
            local result = oldSearch(self, ...)
            hardReleaseEdit(self.searchEdit)
            return result
        end
    end
end

local function installCreatureSearchImeR4()
    local frame = addon.creatureBrowserFrame
    local edit = addon.creatureBrowserSearch
    if not frame or not edit then return end

    makeEditReactivatable(edit)
    hookEnter(edit)
    hookButtonsRecursive(frame, edit, {
        ["검색"] = true,
        ["전체 DB 검색"] = true,
    })

    if not addon._aaeR4CreatureBadge then
        addon._aaeR4CreatureBadge = createBadge(frame, "IME/MODEL R4 · " .. focusStateText(), "TOPRIGHT", -12, -11)
    end
end

if addon.RunLocaleSearch and not addon._aaeR4LocaleSearchWrapped then
    addon._aaeR4LocaleSearchWrapped = true
    local oldRunLocaleSearch = addon.RunLocaleSearch
    addon.RunLocaleSearch = function(self, ...)
        local result = oldRunLocaleSearch(self, ...)
        hardReleaseEdit(self.localeSearchEdit)
        return result
    end
end

-- ---------------------------------------------------------------------------
-- Creature model preview
-- ---------------------------------------------------------------------------

local function preferredModelInfo(entry)
    local rows = ACORE_MODEL_INFO[tonumber(entry)]
    if not rows then return nil end
    local i
    for i = 1, table.getn(rows) do
        if tonumber(rows[i][2]) == 12340 then return rows[i] end
    end
    return rows[1]
end

local function getLoadedModelPath(model)
    if not model or not model.GetModel then return nil end
    local ok, path = pcall(model.GetModel, model)
    if not ok or type(path) ~= "string" or path == "" then return nil end
    return path
end

local function getTargetCreatureEntry()
    if not UnitGUID then return nil end
    local guid = UnitGUID("target")
    if type(guid) ~= "string" or string.len(guid) < 12 then return nil end

    -- WotLK 3.3.5 GUID: 0xF130 + 6 hex creature entry + low GUID.
    if string.sub(guid, 3, 6) ~= "F130" then return nil end
    return tonumber(string.sub(guid, 7, 12), 16)
end

local function targetMatches(record)
    local entry = tonumber(record and record[1])
    return entry and getTargetCreatureEntry() == entry
end

local function modelSourceText(record)
    local entry = tonumber(record and record[1])
    local info = preferredModelInfo(entry)
    if info then
        return "Entry " .. tostring(entry) .. " · DisplayID " .. tostring(info[1]) .. " · Build " .. tostring(info[2])
    end
    return "Entry " .. tostring(entry or "?") .. " · AzerothCore creature_template_model"
end

local function setModelStatus(text)
    local status = addon.creatureBrowserModelStatus
    if not status then return end
    status:SetText(text or "")
    if text and text ~= "" then status:Show() else status:Hide() end
end

local function prepareModel(model)
    if not model then return end
    if model.SetAlpha then safeCall(model.SetAlpha, model, 0) end
    if model.ClearModel then safeCall(model.ClearModel, model) end
    if model.SetModelScale then safeCall(model.SetModelScale, model, 1) end
    if model.SetPosition then safeCall(model.SetPosition, model, 0, 0, 0) end
    if model.SetFacing then safeCall(model.SetFacing, model, 0) end
end

local function presentModel(model)
    if not model then return end
    if model.SetCamDistanceScale then safeCall(model.SetCamDistanceScale, model, 1.05) end
    if model.SetRotation then safeCall(model.SetRotation, model, addon.creatureBrowserModelRotation or 0) end
    if model.SetAlpha then safeCall(model.SetAlpha, model, 1) end
    model:Show()
end

local function loadModelR4(record)
    local model = addon.creatureBrowserModel
    local entry = tonumber(record and record[1])
    if not model or not entry then return false end

    prepareModel(model)
    if addon.creatureBrowserModelFallback then addon.creatureBrowserModelFallback:Hide() end

    -- Exact live unit is the reliable 3.3.5 path, including humanoid equipment.
    if targetMatches(record) and model.SetUnit then
        local ok = safeCall(model.SetUnit, model, "target")
        if ok then
            setModelStatus(modelSourceText(record) .. "\nR4: 실제 target 외형 로드")
            return true
        end
    end

    local info = preferredModelInfo(entry)
    local ok = false

    -- Some old PlayerModel implementations accept an optional displayID on
    -- SetCreature.  Try it only through pcall; if Build 12340 ignores/rejects
    -- it we immediately fall back to the canonical SetCreature(entry).
    if info and model.SetCreature then
        ok = safeCall(model.SetCreature, model, entry, tonumber(info[1]))
    end
    if not ok and model.SetCreature then
        ok = safeCall(model.SetCreature, model, entry)
    end

    if ok then
        setModelStatus(modelSourceText(record) .. "\nR4: 모델 응답 확인 중...")
    else
        setModelStatus(modelSourceText(record) .. "\nR4: PlayerModel 호출 실패")
    end
    return ok
end

local function inspectModelR4(record, finalCheck)
    if addon.creatureBrowserSelected ~= record then return false end
    local model = addon.creatureBrowserModel
    if not model then return false end

    local path = getLoadedModelPath(model)
    if path then
        presentModel(model)
        if targetMatches(record) then
            setModelStatus(modelSourceText(record) .. "\nR4: 실제 target 외형")
        else
            setModelStatus("")
        end
        return true
    end

    -- Never leave the previously selected Thrall/Jaina model visible.  A blank
    -- result is a real 3.3.5 creature-cache miss, not a successful model swap.
    prepareModel(model)
    model:Hide()
    if addon.creatureBrowserModelFallback then addon.creatureBrowserModelFallback:Hide() end

    if finalCheck then
        setModelStatus(modelSourceText(record)
            .. "\nR4: 3.3.5a creature cache 미등록"
            .. "\n해당 NPC를 실제 대상 지정하면 SetUnit(target)으로 갱신됩니다.")
    end
    return false
end

if addon.SelectFeaturedCreature and not addon._aaeR4SelectWrapped then
    addon._aaeR4SelectWrapped = true
    local oldSelectFeaturedCreature = addon.SelectFeaturedCreature
    addon.SelectFeaturedCreature = function(self, record)
        local result = oldSelectFeaturedCreature(self, record)
        self._aaeR4ModelSerial = (self._aaeR4ModelSerial or 0) + 1
        local serial = self._aaeR4ModelSerial

        if not record then
            setModelStatus("")
            return result
        end

        -- Remove whatever the previous compatibility layer displayed before R4.
        prepareModel(self.creatureBrowserModel)
        if self.creatureBrowserModel then self.creatureBrowserModel:Hide() end
        setModelStatus(modelSourceText(record) .. "\nR4: 모델 로드 시작")

        runAfter(0.08, function()
            if serial ~= addon._aaeR4ModelSerial or addon.creatureBrowserSelected ~= record then return end
            loadModelR4(record)
            runAfter(0.18, function()
                if serial == addon._aaeR4ModelSerial then inspectModelR4(record, false) end
            end)
            runAfter(0.55, function()
                if serial == addon._aaeR4ModelSerial then inspectModelR4(record, true) end
            end)
        end)
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
    if not targetMatches(record) then return end

    addon._aaeR4ModelSerial = (addon._aaeR4ModelSerial or 0) + 1
    local serial = addon._aaeR4ModelSerial
    loadModelR4(record)
    runAfter(0.18, function()
        if serial == addon._aaeR4ModelSerial then inspectModelR4(record, true) end
    end)
end)

-- ---------------------------------------------------------------------------
-- Installation after all original UI constructors are available
-- ---------------------------------------------------------------------------

local function ensureModelStatus()
    if not addon.creatureBrowserModel or addon.creatureBrowserModelStatus then return end
    local panel = addon.creatureBrowserModel:GetParent()
    if not panel then return end
    local status = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    status:SetPoint("CENTER", panel, "CENTER", 0, -4)
    status:SetWidth(180)
    status:SetJustifyH("CENTER")
    status:SetTextColor(0.9, 0.85, 0.7)
    status:SetText("")
    status:Hide()
    addon.creatureBrowserModelStatus = status
end

local function installCreatureR4()
    installCreatureSearchImeR4()
    ensureModelStatus()
    updateImeBadges()
end

if addon.CreateCreatureBrowser and not addon._aaeR4CreateWrapped then
    addon._aaeR4CreateWrapped = true
    local oldCreateCreatureBrowser = addon.CreateCreatureBrowser
    addon.CreateCreatureBrowser = function(self, ...)
        local result = oldCreateCreatureBrowser(self, ...)
        installCreatureR4()
        return result
    end
end

-- The frames normally already exist because their files are loaded before this
-- runtime layer.  These immediate calls are therefore the primary R4 install.
installBlueItemImeR4()
installCreatureR4()

-- Correct the Gundrak encounter entry used by AzerothCore.
local function correctFeaturedEntry()
    local list = addon.FeaturedCreatures or {}
    local foundCorrect = false
    local i
    for i = table.getn(list), 1, -1 do
        local record = list[i]
        local entry = tonumber(record and record[1])
        if entry == 29573 then
            foundCorrect = true
        elseif entry == 29307 and record and tostring(record[5] or "") == "군드락" then
            table.remove(list, i)
        end
    end
    if not foundCorrect then
        table.insert(list, { 29573, "드라카리 거대골렘", "dungeon", "wotlk", "군드락", true })
    end
end
correctFeaturedEntry()
