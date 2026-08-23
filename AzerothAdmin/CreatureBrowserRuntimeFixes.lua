AzerothAdminEasy = AzerothAdminEasy or {}
local addon = AzerothAdminEasy

-- Runtime corrections for WoW WotLK 3.3.5a Build 12340 + AzerothCore.
-- Loaded last so the original browser/UI remains intact.
--
-- Important 3.3.5a limitation:
-- PlayerModel:SetCreature(entry) uses creature data already known by the client.
-- Unlike later clients, arbitrary CreatureDisplayID values cannot be used as a
-- reliable uncached model source.  When the selected NPC is the live target we
-- therefore switch to SetUnit("target"), which also supplies the exact humanoid
-- appearance/equipment that SetCreature alone can miss.

-- Verified directly against AzerothCore:
-- data/sql/base/db_world/creature_template_model.sql
-- { CreatureDisplayID, VerifiedBuild }.  Prefer a 12340 row when AzerothCore
-- keeps more than one model row for the same creature.
local ACORE_MODEL_INFO = {
    [3057]  = { { 4307, 51831 } },                         -- Cairne Bloodhoof
    [4949]  = { { 4527, 12340 } },                         -- Thrall
    [4968]  = { { 30863, 51831 } },                        -- Lady Jaina Proudmoore
    [7937]  = { { 7006, 12340 }, { 31658, 51831 } },       -- High Tinker Mekkatorque
    [7999]  = { { 7274, 51831 } },                         -- Tyrande Whisperwind
    [10181] = { { 28213, 12340 } },                        -- Lady Sylvanas Windrunner
    [10184] = { { 8570, 51831 } },                         -- Onyxia
    [12397] = { { 12449, 12340 } },                        -- Lord Kazzak
    [14887] = { { 15364, 12340 } },                        -- Ysondre
    [14888] = { { 15365, 12340 } },                        -- Lethon
    [14889] = { { 15366, 12340 } },                        -- Emeriss
    [14890] = { { 15363, 12340 } },                        -- Taerar
    [36597] = { { 30721, 11159 } },                        -- The Lich King
}
addon.AzerothCoreCreatureModelInfo = ACORE_MODEL_INFO

local function clearFocus(edit)
    if edit and edit.ClearFocus then pcall(edit.ClearFocus, edit) end
end

local function disableEditKeyboard(edit)
    if edit and edit.EnableKeyboard then pcall(edit.EnableKeyboard, edit, false) end
end

local function enableEditKeyboard(edit)
    if edit and edit.EnableKeyboard then pcall(edit.EnableKeyboard, edit, true) end
end

local function releaseChatFocus()
    local edit = nil
    if ChatEdit_GetActiveWindow then
        local ok, active = pcall(ChatEdit_GetActiveWindow)
        if ok then edit = active end
    end
    if edit then
        if ChatEdit_DeactivateChat then
            pcall(ChatEdit_DeactivateChat, edit)
        else
            clearFocus(edit)
        end
    end
end

-- A normal ClearFocus() was not enough on the koKR 3.3.5a client: after a
-- Hangul search, movement did not return until the physical Hangul/English key
-- was pressed.  Remove the EditBox from keyboard input entirely after submit.
-- A visual button keeps the same search field location/text; clicking it brings
-- the real EditBox back for the next edit.
local function updateCreatureSearchDisplay()
    local display = addon.creatureBrowserSearchDisplay
    local edit = addon.creatureBrowserSearch
    if not display or not display.aaeText or not edit then return end
    local text = edit:GetText() or ""
    if text == "" then text = "검색어 입력 / 수정" end
    display.aaeText:SetText(text)
end

local function commitCreatureSearchEdit(edit)
    if not edit then return end
    clearFocus(edit)
    disableEditKeyboard(edit)
    if edit.Hide then edit:Hide() end
    updateCreatureSearchDisplay()
    if addon.creatureBrowserSearchDisplay then addon.creatureBrowserSearchDisplay:Show() end
    releaseChatFocus()
end

local function activateCreatureSearchEdit()
    local edit = addon.creatureBrowserSearch
    local display = addon.creatureBrowserSearchDisplay
    if not edit then return end
    if display then display:Hide() end
    enableEditKeyboard(edit)
    edit:Show()
    if edit.SetFocus then pcall(edit.SetFocus, edit) end
    if edit.HighlightText then pcall(edit.HighlightText, edit) end
end

-- Other search windows do not have a dedicated display overlay.  For them,
-- force an OnHide/OnShow cycle after submitting so the 3.3.5a edit control
-- releases its IME composition instead of merely losing cursor focus.
local function hardResetSearchEdit(edit)
    if not edit then return end
    local wasShown = edit.IsShown and edit:IsShown()
    clearFocus(edit)
    disableEditKeyboard(edit)
    if edit.Hide then edit:Hide() end
    releaseChatFocus()

    local function restore()
        enableEditKeyboard(edit)
        if wasShown and edit.Show then edit:Show() end
        clearFocus(edit)
    end
    if addon.RunAfter then
        addon:RunAfter(0.05, restore)
    else
        restore()
    end
end

local function getButtonText(button)
    if not button then return nil end
    if button.label and button.label.GetText then
        local ok, text = pcall(button.label.GetText, button.label)
        if ok then return text end
    end
    if button.GetText then
        local ok, text = pcall(button.GetText, button)
        if ok then return text end
    end
    return nil
end

local function hookCreatureSearchButton(button, edit)
    if not button or button._aaeHardImeHooked then return end
    local text = getButtonText(button)
    if text ~= "검색" and text ~= "전체 DB 검색" then return end
    local original = button:GetScript("OnClick")
    if not original then return end
    button._aaeHardImeHooked = true
    button:SetScript("OnClick", function(self, ...)
        commitCreatureSearchEdit(edit)
        return original(self, ...)
    end)
end

local function hookCreatureSearchButtonsRecursive(frame, edit)
    if not frame or not frame.GetChildren then return end
    local children = { frame:GetChildren() }
    local i
    for i = 1, table.getn(children) do
        local child = children[i]
        hookCreatureSearchButton(child, edit)
        hookCreatureSearchButtonsRecursive(child, edit)
    end
end

local function hookCreatureSearchEnter(edit)
    if not edit or edit._aaeHardImeEnterHooked then return end
    local original = edit:GetScript("OnEnterPressed")
    if not original then return end
    edit._aaeHardImeEnterHooked = true
    edit:SetScript("OnEnterPressed", function(self, ...)
        commitCreatureSearchEdit(self)
        return original(self, ...)
    end)
end

local previousRunLocaleSearch = addon.RunLocaleSearch
if previousRunLocaleSearch then
    addon.RunLocaleSearch = function(self, ...)
        local result = previousRunLocaleSearch(self, ...)
        hardResetSearchEdit(self.localeSearchEdit)
        return result
    end
end

local BII3 = _G.BlueItemInfo3
if BII3 and BII3.Search then
    local previousBII3Search = BII3.Search
    BII3.Search = function(self, ...)
        local result = previousBII3Search(self, ...)
        hardResetSearchEdit(self.searchEdit)
        return result
    end
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

    -- Pre-4.0 GUID layout (2.4.0-3.3.5): creature entry occupies the six hex
    -- digits at characters 7..12 in the canonical 0xF130...... GUID.
    local prefix = string.sub(guid, 3, 6)
    if prefix ~= "F130" and prefix ~= "F150" then return nil end
    return tonumber(string.sub(guid, 7, 12), 16)
end

local function targetMatchesRecord(record)
    local entry = tonumber(record and record[1])
    return entry and getTargetCreatureEntry() == entry
end

local function preferredModelInfo(entry)
    local rows = ACORE_MODEL_INFO[tonumber(entry)]
    if not rows then return nil end
    local i
    for i = 1, table.getn(rows) do
        if tonumber(rows[i][2]) == 12340 then return rows[i] end
    end
    return rows[1]
end

local function modelSourceText(record)
    local entry = tonumber(record and record[1])
    local row = preferredModelInfo(entry)
    if not row then
        return "AzerothCore Entry " .. tostring(entry or "?")
    end
    return "AzerothCore DisplayID " .. tostring(row[1]) .. " · VerifiedBuild " .. tostring(row[2])
end

local function setModelStatus(text)
    local status = addon.creatureBrowserModelStatus
    if not status then return end
    status:SetText(text or "")
    if text and text ~= "" then status:Show() else status:Hide() end
end

local function applyModelPresentation(model, path)
    if not model then return end
    if model.SetModelScale then pcall(model.SetModelScale, model, 1) end
    if model.SetCamDistanceScale then pcall(model.SetCamDistanceScale, model, 1.05) end
    if model.SetFacing then pcall(model.SetFacing, model, 0) end
    if model.SetSequence then pcall(model.SetSequence, model, 4) end
    if model.SetRotation then pcall(model.SetRotation, model, addon.creatureBrowserModelRotation or 0) end
    if model.SetAlpha then pcall(model.SetAlpha, model, 1) end

    local lower = path and string.lower(path) or ""
    local largeFlying = string.find(lower, "dragon", 1, true)
        or string.find(lower, "wurm", 1, true)
        or string.find(lower, "drake", 1, true)
        or string.find(lower, "malygos", 1, true)
        or string.find(lower, "yoggsaron", 1, true)
    if largeFlying then
        if model.SetPosition then pcall(model.SetPosition, model, 0, 0, 0) end
        if model.SetCamera then pcall(model.SetCamera, model, 0) end
    else
        if model.SetPosition then pcall(model.SetPosition, model, 0.4, 0, 0) end
    end
end

local function loadSelectedCreatureModel(record)
    if addon.creatureBrowserSelected ~= record then return false end
    local model = addon.creatureBrowserModel
    local entry = tonumber(record and record[1])
    if not model or not entry then return false end

    if model.ClearModel then pcall(model.ClearModel, model) end
    if model.SetAlpha then pcall(model.SetAlpha, model, 0) end

    local usingTarget = targetMatchesRecord(record)
    local ok = false
    if usingTarget and model.SetUnit then
        ok = pcall(model.SetUnit, model, "target")
    elseif model.SetCreature then
        ok = pcall(model.SetCreature, model, entry)
    end

    if not ok then
        model:Hide()
        if addon.creatureBrowserModelFallback then addon.creatureBrowserModelFallback:Hide() end
        setModelStatus(modelSourceText(record) .. "\n3D 모델 호출에 실패했습니다.")
        return false
    end

    model:Show()
    return true
end

local function inspectSelectedModel(record, finalCheck)
    if addon.creatureBrowserSelected ~= record then return false end
    local model = addon.creatureBrowserModel
    if not model then return false end
    local path = getLoadedModelPath(model)
    if path then
        applyModelPresentation(model, path)
        model:Show()
        if addon.creatureBrowserModelFallback then addon.creatureBrowserModelFallback:Hide() end
        if targetMatchesRecord(record) then
            setModelStatus(modelSourceText(record) .. "\n실제 대상 외형으로 갱신됨")
        else
            setModelStatus("")
        end
        return true
    end

    if finalCheck then
        model:Hide()
        if addon.creatureBrowserModelFallback then addon.creatureBrowserModelFallback:Hide() end
        setModelStatus(modelSourceText(record)
            .. "\n3.3.5a 캐시에 없는 NPC입니다."
            .. "\nNPC를 실제로 대상으로 선택하면 정확한 외형으로 갱신됩니다.")
    else
        setModelStatus(modelSourceText(record) .. "\n3D 외형 불러오는 중...")
    end
    return false
end

local previousSelectFeaturedCreature = addon.SelectFeaturedCreature
if previousSelectFeaturedCreature then
    addon.SelectFeaturedCreature = function(self, record)
        local result = previousSelectFeaturedCreature(self, record)
        self._runtimeModelSerial = (self._runtimeModelSerial or 0) + 1
        local serial = self._runtimeModelSerial

        if not record then
            setModelStatus("")
            return result
        end

        if self.creatureBrowserModelFallback then self.creatureBrowserModelFallback:Hide() end
        setModelStatus(modelSourceText(record) .. "\n3D 외형 불러오는 중...")

        local function loadAndInspect(finalCheck)
            if serial ~= addon._runtimeModelSerial or addon.creatureBrowserSelected ~= record then return end
            loadSelectedCreatureModel(record)
            if addon.RunAfter then
                addon:RunAfter(0.18, function()
                    if serial == addon._runtimeModelSerial then inspectSelectedModel(record, finalCheck) end
                end)
            else
                inspectSelectedModel(record, finalCheck)
            end
        end

        -- CreatureBrowserFixes has an older 0.05-second SetCreature refresh.
        -- Run after it so this final compatibility layer owns the visible model.
        if self.RunAfter then
            self:RunAfter(0.08, function() loadAndInspect(false) end)
            self:RunAfter(0.55, function()
                if serial ~= addon._runtimeModelSerial then return end
                if not inspectSelectedModel(record, false) then
                    loadAndInspect(true)
                end
            end)
        else
            loadAndInspect(true)
        end
        return result
    end
end

-- _NPCScan 3.3.5 used the same pattern: SetCreature for a cached NPC, then
-- SetUnit("target") after the player actually targeted that NPC to refresh the
-- accurate visual (especially humanoid clothing).  Keep our preview in sync.
local modelEventFrame = CreateFrame("Frame")
modelEventFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
modelEventFrame:RegisterEvent("UNIT_MODEL_CHANGED")
modelEventFrame:SetScript("OnEvent", function(self, event, unit)
    local record = addon.creatureBrowserSelected
    if not record or not addon.creatureBrowserFrame or not addon.creatureBrowserFrame:IsShown() then return end
    if event == "UNIT_MODEL_CHANGED" and unit and unit ~= "target" then return end
    if not targetMatchesRecord(record) then return end

    addon._runtimeModelSerial = (addon._runtimeModelSerial or 0) + 1
    local serial = addon._runtimeModelSerial
    loadSelectedCreatureModel(record)
    if addon.RunAfter then
        addon:RunAfter(0.18, function()
            if serial == addon._runtimeModelSerial then inspectSelectedModel(record, true) end
        end)
    else
        inspectSelectedModel(record, true)
    end
end)

local function createCreatureSearchDisplay(edit)
    if addon.creatureBrowserSearchDisplay or not edit then return end
    local parent = edit:GetParent()
    if not parent then return end

    local button = CreateFrame("Button", nil, parent)
    button:SetPoint("TOPLEFT", edit, "TOPLEFT", 0, 0)
    button:SetPoint("BOTTOMRIGHT", edit, "BOTTOMRIGHT", 0, 0)
    button:SetFrameLevel((edit:GetFrameLevel() or 1) + 1)
    button:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 12, edgeSize = 8,
        insets = { left = 2, right = 2, top = 2, bottom = 2 },
    })
    button:SetBackdropColor(0.01, 0.02, 0.025, 1)
    button:SetBackdropBorderColor(0.48, 0.43, 0.31, 1)

    local text = button:CreateFontString(nil, "OVERLAY")
    text:SetFontObject(ChatFontNormal)
    text:SetPoint("LEFT", button, "LEFT", 6, 0)
    text:SetPoint("RIGHT", button, "RIGHT", -6, 0)
    text:SetJustifyH("LEFT")
    button.aaeText = text
    button:SetScript("OnClick", activateCreatureSearchEdit)
    button:Hide()
    addon.creatureBrowserSearchDisplay = button
end

local function installCreatureBrowserRuntimeUI()
    if not addon.creatureBrowserFrame then return end

    local edit = addon.creatureBrowserSearch
    createCreatureSearchDisplay(edit)
    hookCreatureSearchEnter(edit)
    hookCreatureSearchButtonsRecursive(addon.creatureBrowserFrame, edit)

    if addon.creatureBrowserModel and not addon.creatureBrowserModelStatus then
        local panel = addon.creatureBrowserModel:GetParent()
        if panel then
            local status = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            status:SetPoint("CENTER", panel, "CENTER", 0, -4)
            status:SetWidth(174)
            status:SetJustifyH("CENTER")
            status:SetTextColor(0.85, 0.85, 0.78)
            status:SetText("")
            status:Hide()
            addon.creatureBrowserModelStatus = status
        end
    end
end

local previousCreateCreatureBrowser = addon.CreateCreatureBrowser
if previousCreateCreatureBrowser then
    addon.CreateCreatureBrowser = function(self, ...)
        local result = previousCreateCreatureBrowser(self, ...)
        installCreatureBrowserRuntimeUI()
        return result
    end
end

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
