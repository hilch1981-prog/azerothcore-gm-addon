AzerothAdminEasy = AzerothAdminEasy or {}
local addon = AzerothAdminEasy

-- R5 runtime corrections for WoW WotLK 3.3.5a Build 12340 + AzerothCore.
-- Loaded last from AzerothAdmin.toc.
--
-- R5 goals:
--   1) release the REAL BlueItemInfo3 search EditBox after mouse/Enter search;
--   2) never leave the previous creature model visible after a new selection;
--   3) ask the 3.3.5 client/server creature cache for the selected entry and
--      retry PlayerModel:SetCreature(entry) instead of hard-coding a few IDs.
--
-- Do not add Retail-only APIs here.  This file intentionally uses only legacy
-- Frame/EditBox/GameTooltip/PlayerModel methods available to the 3.3.5 UI.

addon.CreatureBrowserRuntimeRevision = "IME/MODEL R5"

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

local function chatMessage(text)
    if DEFAULT_CHAT_FRAME and DEFAULT_CHAT_FRAME.AddMessage then
        DEFAULT_CHAT_FRAME:AddMessage(text)
    end
end

-- This marker is deliberately global/chat-visible.  Unlike R4, the user does
-- not need to open a particular subwindow to prove that the file was loaded.
chatMessage("|cffffd24aAzerothAdmin R5 TEST 로드됨|r")

-- ---------------------------------------------------------------------------
-- BlueItemInfo3 / koKR IME focus release
-- ---------------------------------------------------------------------------

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

local function releaseSearchEdit(edit)
    if not edit then return end

    -- First release focus normally.
    if edit.ClearFocus then safeCall(edit.ClearFocus, edit) end

    -- If the legacy client still reports THIS edit box as keyboard focus, clear
    -- it explicitly.  Never clear an unrelated chat/edit box.
    if GetCurrentKeyBoardFocus then
        local ok, focus = pcall(GetCurrentKeyBoardFocus)
        if ok and focus == edit and focus.ClearFocus then
            safeCall(focus.ClearFocus, focus)
        end
    end

    -- koKR IME can keep an EditBox keyboard-active even after a simple
    -- ClearFocus() in some 3.3.5 clients.  Hide/show forces the widget out of
    -- the input path while preserving its text, then keyboard input is disabled
    -- until the user explicitly clicks the field again.
    local wasShown = edit.IsShown and edit:IsShown()
    if wasShown and edit.Hide and edit.Show then
        edit:Hide()
        edit:Show()
    end
    if edit.ClearFocus then safeCall(edit.ClearFocus, edit) end
    if edit.EnableKeyboard then safeCall(edit.EnableKeyboard, edit, false) end
end

local function makeEditClickableAgain(edit)
    if not edit or edit._aaeR5Clickable then return end
    edit._aaeR5Clickable = true

    local oldMouseDown = edit:GetScript("OnMouseDown")
    edit:SetScript("OnMouseDown", function(self, ...)
        if self.EnableKeyboard then safeCall(self.EnableKeyboard, self, true) end
        if oldMouseDown then oldMouseDown(self, ...) end
        if self.SetFocus then safeCall(self.SetFocus, self) end
    end)

    -- If another script focuses this edit directly, re-enable keyboard input.
    local oldFocusGained = edit:GetScript("OnEditFocusGained")
    edit:SetScript("OnEditFocusGained", function(self, ...)
        if self.EnableKeyboard then safeCall(self.EnableKeyboard, self, true) end
        if oldFocusGained then oldFocusGained(self, ...) end
    end)
end

local function hookSearchButton(button, edit, accepted)
    if not button or button._aaeR5SearchHooked then return end
    local text = getButtonText(button)
    if not text or not accepted[text] then return end

    local oldMouseDown = button:GetScript("OnMouseDown")
    local oldClick = button:GetScript("OnClick")
    if not oldClick then return end

    button._aaeR5SearchHooked = true

    -- Release BEFORE the click handler too.  The original runSearch() only
    -- reads edit:GetText(), so it does not require the EditBox to remain focused.
    button:SetScript("OnMouseDown", function(self, ...)
        releaseSearchEdit(edit)
        if oldMouseDown then oldMouseDown(self, ...) end
    end)

    -- Preserve the original button action, then release once more after it.
    button:SetScript("OnClick", function(self, ...)
        oldClick(self, ...)
        releaseSearchEdit(edit)
    end)
end

local function hookButtonsRecursive(frame, edit, accepted)
    if not frame or not frame.GetChildren then return end
    local children = { frame:GetChildren() }
    local i
    for i = 1, table.getn(children) do
        local child = children[i]
        hookSearchButton(child, edit, accepted)
        hookButtonsRecursive(child, edit, accepted)
    end
end

local function hookEditEnter(edit)
    if not edit or edit._aaeR5EnterHooked then return end
    local oldEnter = edit:GetScript("OnEnterPressed")
    if not oldEnter then return end

    edit._aaeR5EnterHooked = true
    edit:SetScript("OnEnterPressed", function(self, ...)
        oldEnter(self, ...)
        releaseSearchEdit(self)
    end)
end

local function installBlueItemImeR5()
    local BII3 = _G.BlueItemInfo3
    if not BII3 or not BII3.searchEdit then return end

    local edit = BII3.searchEdit
    makeEditClickableAgain(edit)
    hookEditEnter(edit)
    hookButtonsRecursive(BII3, edit, {
        ["검색"] = true,
        ["분류"] = true,
        ["필터 적용"] = true,
    })

    if not BII3._aaeR5HideHooked then
        BII3._aaeR5HideHooked = true
        local oldHide = BII3:GetScript("OnHide")
        BII3:SetScript("OnHide", function(self, ...)
            releaseSearchEdit(self.searchEdit)
            if oldHide then oldHide(self, ...) end
        end)
    end

    -- Integrated.lua's public Search(query) intentionally SetFocus()es and
    -- HighlightText()s after searching.  External Korean searches therefore
    -- capture movement keys unless we release the same exposed searchEdit here.
    if BII3.Search and not BII3._aaeR5PublicSearchWrapped then
        BII3._aaeR5PublicSearchWrapped = true
        local oldSearch = BII3.Search
        BII3.Search = function(self, ...)
            local result = oldSearch(self, ...)
            releaseSearchEdit(self.searchEdit)
            return result
        end
    end
end

local function installCreatureSearchImeR5()
    local frame = addon.creatureBrowserFrame
    local edit = addon.creatureBrowserSearch
    if not frame or not edit then return end

    makeEditClickableAgain(edit)
    hookEditEnter(edit)
    hookButtonsRecursive(frame, edit, {
        ["검색"] = true,
        ["전체 DB 검색"] = true,
    })
end

installBlueItemImeR5()
installCreatureSearchImeR5()

-- ---------------------------------------------------------------------------
-- Creature model cache / model replacement
-- ---------------------------------------------------------------------------

-- 3.3.5 PlayerModel:SetCreature takes a creature entry.  AzerothCore answers
-- CMSG_CREATURE_QUERY with the creature_template_model CreatureDisplayID values.
-- A hidden unit tooltip is used only to make the legacy client ask the server
-- for an uncached creature entry before SetCreature(entry) is retried.
local cacheTip = CreateFrame("GameTooltip", "AzerothAdminCreatureCacheQueryTooltip", UIParent, "GameTooltipTemplate")
cacheTip:SetOwner(WorldFrame, "ANCHOR_NONE")
cacheTip:Hide()

local function makeCreatureGuid(entry)
    entry = tonumber(entry)
    if not entry or entry < 1 or entry > 0xFFFFFF then return nil end
    -- Legacy creature GUID: F130 + 24-bit creature entry + 24-bit low GUID.
    -- AzerothCore's creature-query handler uses the entry for static template
    -- lookup; the low part is not needed for that template response.
    return string.format("0xF130%06X%06X", entry, 1)
end

local function requestCreatureCache(record)
    local entry = tonumber(record and record[1])
    if not entry or not cacheTip or not cacheTip.SetHyperlink then return false end

    local guid = makeCreatureGuid(entry)
    if not guid then return false end

    cacheTip:ClearLines()
    cacheTip:SetOwner(WorldFrame, "ANCHOR_NONE")

    -- Unit hyperlink support is handled through pcall because private 3.3.5
    -- client builds differ.  If unsupported, ordinary SetCreature/SetUnit paths
    -- still work and no Lua error is raised.
    local ok = pcall(cacheTip.SetHyperlink, cacheTip, "unit:" .. guid .. ":AzerothAdminCacheQuery")
    cacheTip:Hide()
    return ok
end

local function getTargetCreatureEntry()
    if not UnitGUID then return nil end
    local guid = UnitGUID("target")
    if type(guid) ~= "string" or string.len(guid) < 12 then return nil end
    if string.sub(guid, 3, 6) ~= "F130" then return nil end
    return tonumber(string.sub(guid, 7, 12), 16)
end

local function targetMatchesRecord(record)
    local entry = tonumber(record and record[1])
    return entry and getTargetCreatureEntry() == entry
end

local function clearCreatureModel()
    local model = addon.creatureBrowserModel
    if not model then return end
    if model.Hide then model:Hide() end
    if model.ClearModel then safeCall(model.ClearModel, model) end
    if model.SetAlpha then safeCall(model.SetAlpha, model, 0) end
end

local function hasLoadedModel(model)
    if not model or not model.GetModel then return false end
    local ok, path = pcall(model.GetModel, model)
    return ok and type(path) == "string" and path ~= ""
end

local function showLoadedModel()
    local model = addon.creatureBrowserModel
    if not model then return end
    if model.SetCamDistanceScale then safeCall(model.SetCamDistanceScale, model, 1.05) end
    if model.SetRotation then safeCall(model.SetRotation, model, addon.creatureBrowserModelRotation or 0) end
    if model.SetAlpha then safeCall(model.SetAlpha, model, 1) end
    model:Show()
    if addon.creatureBrowserModelFallback then addon.creatureBrowserModelFallback:Hide() end
end

local function ensureModelStatus()
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

local function setModelStatus(text)
    ensureModelStatus()
    local status = addon.creatureBrowserModelStatus
    if not status then return end
    status:SetText(text or "")
    if text and text ~= "" then status:Show() else status:Hide() end
end

local function setCreatureAttempt(record)
    local model = addon.creatureBrowserModel
    local entry = tonumber(record and record[1])
    if not model or not entry then return false end

    clearCreatureModel()

    -- If this exact NPC is the live target, SetUnit is the strongest legacy
    -- path and includes the server-provided live model/equipment immediately.
    if targetMatchesRecord(record) and model.SetUnit then
        local ok = safeCall(model.SetUnit, model, "target")
        if ok then return true end
    end

    if not model.SetCreature then return false end
    return safeCall(model.SetCreature, model, entry)
end

local function finishModelAttempt(record, final)
    if addon.creatureBrowserSelected ~= record then return false end
    local model = addon.creatureBrowserModel
    if not model then return false end

    if hasLoadedModel(model) then
        showLoadedModel()
        setModelStatus("")
        return true
    end

    if final then
        clearCreatureModel()
        if addon.creatureBrowserModelFallback then addon.creatureBrowserModelFallback:Show() end
        setModelStatus("R5: 모델 캐시 응답 대기 실패\nEntry " .. tostring(record and record[1] or "?")
            .. "\n실제 NPC를 대상으로 지정하면 다시 시도합니다.")
    end
    return false
end

local function startModelR5(record)
    if not record then
        clearCreatureModel()
        setModelStatus("")
        return
    end

    addon._aaeR5ModelSerial = (addon._aaeR5ModelSerial or 0) + 1
    local serial = addon._aaeR5ModelSerial
    local entry = tonumber(record[1])

    -- Critical stale-model fix: erase the previous NPC BEFORE any new request.
    clearCreatureModel()
    if addon.creatureBrowserModelFallback then addon.creatureBrowserModelFallback:Hide() end
    setModelStatus("R5: Entry " .. tostring(entry or "?") .. " 모델 요청 중...")

    -- Ask the server for the creature template/display IDs, then try the normal
    -- WotLK SetCreature(entry) path.  No tiny hard-coded DisplayID table is used.
    requestCreatureCache(record)
    setCreatureAttempt(record)

    runAfter(0.12, function()
        if serial ~= addon._aaeR5ModelSerial or addon.creatureBrowserSelected ~= record then return end
        if finishModelAttempt(record, false) then return end
        requestCreatureCache(record)
        setCreatureAttempt(record)
    end)

    runAfter(0.35, function()
        if serial ~= addon._aaeR5ModelSerial or addon.creatureBrowserSelected ~= record then return end
        if finishModelAttempt(record, false) then return end
        setCreatureAttempt(record)
    end)

    runAfter(0.85, function()
        if serial ~= addon._aaeR5ModelSerial or addon.creatureBrowserSelected ~= record then return end
        if finishModelAttempt(record, false) then return end
        setCreatureAttempt(record)
        runAfter(0.12, function()
            if serial == addon._aaeR5ModelSerial and addon.creatureBrowserSelected == record then
                finishModelAttempt(record, true)
            end
        end)
    end)
end

-- Loaded last: wrap whatever the original browser and CreatureBrowserFixes have
-- installed, preserve their text/buttons/row refresh, then replace only the
-- model rendering attempt with the R5 cache-aware sequence.
if addon.SelectFeaturedCreature and not addon._aaeR5SelectWrapped then
    addon._aaeR5SelectWrapped = true
    local oldSelectFeaturedCreature = addon.SelectFeaturedCreature
    addon.SelectFeaturedCreature = function(self, record)
        local result = oldSelectFeaturedCreature(self, record)
        startModelR5(record)
        return result
    end
end

local modelEvents = CreateFrame("Frame")
modelEvents:RegisterEvent("PLAYER_TARGET_CHANGED")
modelEvents:RegisterEvent("UNIT_MODEL_CHANGED")
modelEvents:SetScript("OnEvent", function(self, event, unit)
    if event == "UNIT_MODEL_CHANGED" and unit and unit ~= "target" then return end
    local record = addon.creatureBrowserSelected
    if not record then return end
    if not addon.creatureBrowserFrame or not addon.creatureBrowserFrame:IsShown() then return end
    if targetMatchesRecord(record) then startModelR5(record) end
end)

-- CreateCreatureBrowser is normally already called later by the main UI, but
-- keep the installer safe if creation happens after this file in a custom build.
if addon.CreateCreatureBrowser and not addon._aaeR5CreateWrapped then
    addon._aaeR5CreateWrapped = true
    local oldCreateCreatureBrowser = addon.CreateCreatureBrowser
    addon.CreateCreatureBrowser = function(self, ...)
        local result = oldCreateCreatureBrowser(self, ...)
        installCreatureSearchImeR5()
        ensureModelStatus()
        return result
    end
end
