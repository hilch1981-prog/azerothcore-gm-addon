AzerothAdminEasy = AzerothAdminEasy or {}
local addon = AzerothAdminEasy

-- Runtime corrections confirmed from WotLK 3.3.5a client testing.
-- Loaded last so the original UI and previous compatibility layer remain intact.

local function clearFocus(edit)
    if edit and edit.ClearFocus then
        pcall(edit.ClearFocus, edit)
    end
end

local function hasNonAscii(text)
    text = tostring(text or "")
    local i
    for i = 1, string.len(text) do
        if (string.byte(text, i) or 0) > 127 then return true end
    end
    return false
end

local function resetKeyboardContext(edit)
    clearFocus(edit)
    if edit and edit.EnableKeyboard then
        pcall(edit.EnableKeyboard, edit, false)
        pcall(edit.EnableKeyboard, edit, true)
    end
end

-- In the 3.3.5a client the Korean IME can remain active after ClearFocus().
-- The physical Hangul/English key fixes movement because it changes the input
-- mode before focus is discarded. Do the same while the search EditBox owns
-- focus, then clear/reset its keyboard context. This is done only for text that
-- actually contains non-ASCII characters so normal English searches are not
-- toggled unnecessarily.
local function finishKoreanInput(edit)
    if not edit then return end
    local text = edit.GetText and edit:GetText() or ""
    if hasNonAscii(text) and edit.SetFocus and edit.ToggleInputLanguage then
        pcall(edit.SetFocus, edit)
        pcall(edit.ToggleInputLanguage, edit)
    end
    resetKeyboardContext(edit)
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
            resetKeyboardContext(edit)
            if edit.Hide then pcall(edit.Hide, edit) end
        end
    end
end

local function releaseSearchKeyboard()
    resetKeyboardContext(addon.creatureBrowserSearch)
    resetKeyboardContext(addon.localeSearchEdit)
    if _G.BlueItemInfo3 then
        resetKeyboardContext(_G.BlueItemInfo3.searchEdit)
    end
    releaseChatFocus()
end

local function releaseSearchKeyboardDelayed()
    releaseSearchKeyboard()
    if addon.RunAfter then
        addon:RunAfter(0.05, releaseSearchKeyboard)
        addon:RunAfter(0.20, releaseSearchKeyboard)
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

local function hookSearchButton(button, edit)
    if not button or button._aaeImeReleaseHooked then return end
    local text = getButtonText(button)
    if text ~= "검색" and text ~= "전체 DB 검색" then return end
    local original = button:GetScript("OnClick")
    if not original then return end
    button._aaeImeReleaseHooked = true
    button:SetScript("OnClick", function(self, ...)
        finishKoreanInput(edit)
        return original(self, ...)
    end)
end

local function hookSearchButtonsRecursive(frame, edit)
    if not frame or not frame.GetChildren then return end
    local children = { frame:GetChildren() }
    local i
    for i = 1, table.getn(children) do
        local child = children[i]
        hookSearchButton(child, edit)
        hookSearchButtonsRecursive(child, edit)
    end
end

local function hookSearchEnter(edit)
    if not edit or edit._aaeImeEnterHooked then return end
    local original = edit:GetScript("OnEnterPressed")
    if not original then return end
    edit._aaeImeEnterHooked = true
    edit:SetScript("OnEnterPressed", function(self, ...)
        finishKoreanInput(self)
        return original(self, ...)
    end)
end

local previousRefreshCreatureBrowser = addon.RefreshCreatureBrowser
if previousRefreshCreatureBrowser then
    addon.RefreshCreatureBrowser = function(self, ...)
        local result = previousRefreshCreatureBrowser(self, ...)
        releaseSearchKeyboardDelayed()
        return result
    end
end

local previousRunLocaleSearch = addon.RunLocaleSearch
if previousRunLocaleSearch then
    addon.RunLocaleSearch = function(self, ...)
        local result = previousRunLocaleSearch(self, ...)
        releaseSearchKeyboardDelayed()
        return result
    end
end

local BII3 = _G.BlueItemInfo3
if BII3 and BII3.Search then
    local previousBII3Search = BII3.Search
    BII3.Search = function(self, ...)
        finishKoreanInput(self.searchEdit)
        local result = previousBII3Search(self, ...)
        releaseSearchKeyboardDelayed()
        return result
    end
end

local function getLoadedModelPath(model)
    if not model or not model.GetModel then return nil end
    local ok, path = pcall(model.GetModel, model)
    if not ok or type(path) ~= "string" or path == "" then return nil end
    return path
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

-- On the original WotLK client SetCreature() only renders creatures already in
-- CreatureCache. It does not provide the later SetDisplayInfo path that can
-- render arbitrary uncached display IDs. Therefore selection performs exactly
-- one normal SetCreature load and then reports the real cache state instead of
-- repeatedly clearing/restarting the model load.
local function inspectSelectedModel(record, finalCheck)
    if addon.creatureBrowserSelected ~= record then return false end
    local model = addon.creatureBrowserModel
    if not model then return false end
    local path = getLoadedModelPath(model)
    if path then
        applyModelPresentation(model, path)
        model:Show()
        if addon.creatureBrowserModelFallback then addon.creatureBrowserModelFallback:Hide() end
        setModelStatus("")
        return true
    end

    if finalCheck then
        model:Hide()
        if addon.creatureBrowserModelFallback then addon.creatureBrowserModelFallback:Hide() end
        setModelStatus("3.3.5a 클라이언트 캐시에 없는 외형입니다.\n위치 이동 또는 임시 소환으로 NPC를 실제 로드한 뒤\n같은 항목을 다시 선택하면 3D 외형이 표시됩니다.")
    else
        setModelStatus("3D 외형 불러오는 중...")
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
        setModelStatus("3D 외형 불러오는 중...")

        -- CreatureBrowserFixes performs one compatibility SetCreature refresh at
        -- 0.05 sec. Inspect only after that pass; do not ClearModel repeatedly.
        if self.RunAfter then
            self:RunAfter(0.15, function()
                if serial == addon._runtimeModelSerial then inspectSelectedModel(record, false) end
            end)
            self:RunAfter(0.40, function()
                if serial == addon._runtimeModelSerial then inspectSelectedModel(record, true) end
            end)
        else
            inspectSelectedModel(record, true)
        end
        return result
    end
end

local function installCreatureBrowserRuntimeUI()
    if not addon.creatureBrowserFrame then return end

    local edit = addon.creatureBrowserSearch
    hookSearchEnter(edit)
    hookSearchButtonsRecursive(addon.creatureBrowserFrame, edit)

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
