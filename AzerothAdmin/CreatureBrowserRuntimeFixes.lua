AzerothAdminEasy = AzerothAdminEasy or {}
local addon = AzerothAdminEasy

-- R6 runtime corrections for WoW WotLK 3.3.5a Build 12340 + AzerothCore.
-- Keyboard and PlayerModel ownership is intentionally centralized in this file.
addon.CreatureBrowserRuntimeRevision = "IME/MODEL R6"

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

chatMessage("|cffffd24aAzerothAdmin R6 FULL TEST 로드됨|r")

-- ---------------------------------------------------------------------------
-- koKR IME release
-- ---------------------------------------------------------------------------
--
-- 3.3.5 FrameXML treats input-language changes asynchronously:
-- ChatEdit_OnInputLanguageChanged() reads EditBox:GetInputLanguage() only after
-- the OnInputLanguageChanged script fires.  Clearing focus immediately after
-- ToggleInputLanguage() can therefore leave Windows/klient IME in Hangul mode.
-- R6 keeps the submitted EditBox focused until it actually reports ROMAN (or a
-- short fail-safe timeout), then releases keyboard focus.

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
        -- Prevent the submitted custom search box from immediately reclaiming
        -- the keyboard.  OnMouseDown/OnEditFocusGained hooks restore it.
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

    -- A physical Hangul/English key changes the same input-language state.  If
    -- the first request was swallowed while IME composition was completing,
    -- retry once while the EditBox still owns focus.
    if self.elapsed >= 0.12 and not self.retried then
        self.retried = true
        if edit.SetFocus then safeCall(edit.SetFocus, edit) end
        if edit.ToggleInputLanguage then safeCall(edit.ToggleInputLanguage, edit) end
    end

    -- Never trap the user in the search field indefinitely.  This is a fallback
    -- only; successful koKR conversion normally reaches ROMAN before this.
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
        -- Do NOT ClearFocus here.  Wait for GetInputLanguage()==ROMAN.
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
        -- Search first: runSearch() only reads edit:GetText().  Then perform the
        -- asynchronous Hangul -> ROMAN transition while focus remains valid.
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

    -- Public BII3:Search() previously called SetFocus()+HighlightText() after
    -- searching.  Wrap it last and always release that same exposed EditBox.
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
-- Creature PlayerModel
-- ---------------------------------------------------------------------------
-- The companion R6 package contains a Build-12340 koKR creaturecache.wdb built
-- from the supplied AzerothCore creature_template + creature_template_model
-- data.  Once that cache is installed, the stock 3.3.5 SetCreature(entry) path
-- has all 30k+ creature query records locally and no synthetic GUID trick is
-- required here.

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

local function targetEntry()
    if not UnitGUID then return nil end
    local guid = UnitGUID("target")
    if type(guid) ~= "string" or string.len(guid) < 12 then return nil end
    if string.sub(guid, 3, 6) ~= "F130" then return nil end
    return tonumber(string.sub(guid, 7, 12), 16)
end

local function loadCreatureModel(record)
    local model = addon.creatureBrowserModel
    local entry = tonumber(record and record[1])
    if not model or not entry then return false end

    clearModel()
    if addon.creatureBrowserModelFallback then addon.creatureBrowserModelFallback:Hide() end

    local ok = false
    if targetEntry() == entry and model.SetUnit then
        ok = safeCall(model.SetUnit, model, "target")
    end
    if not ok and model.SetCreature then
        ok = safeCall(model.SetCreature, model, entry)
    end

    if ok then
        if model.SetCamDistanceScale then safeCall(model.SetCamDistanceScale, model, 1.05) end
        if model.SetRotation then safeCall(model.SetRotation, model, addon.creatureBrowserModelRotation or 0) end
        if model.SetAlpha then safeCall(model.SetAlpha, model, 1) end
        model:Show()
    end
    return ok
end

local function verifyCreatureModel(record, final)
    if addon.creatureBrowserSelected ~= record then return false end
    local model = addon.creatureBrowserModel
    if modelLoaded(model) then
        if addon.creatureBrowserModelFallback then addon.creatureBrowserModelFallback:Hide() end
        setStatus("")
        return true
    end

    clearModel()
    if final then
        if addon.creatureBrowserModelFallback then addon.creatureBrowserModelFallback:Show() end
        setStatus("R6: creaturecache에서 Entry " .. tostring(record and record[1] or "?")
            .. " 외형을 찾지 못했습니다.\nR6 클라이언트 캐시 설치 여부를 확인하세요.")
    end
    return false
end

local function startCreatureModel(record)
    addon._aaeR6ModelSerial = (addon._aaeR6ModelSerial or 0) + 1
    local serial = addon._aaeR6ModelSerial
    clearModel()

    if not record then setStatus(""); return end
    setStatus("R6: Entry " .. tostring(record[1]) .. " 외형 로드 중...")
    loadCreatureModel(record)

    runAfter(0.12, function()
        if serial ~= addon._aaeR6ModelSerial then return end
        if not verifyCreatureModel(record, false) then loadCreatureModel(record) end
    end)
    runAfter(0.35, function()
        if serial ~= addon._aaeR6ModelSerial then return end
        verifyCreatureModel(record, true)
    end)
end

if addon.SelectFeaturedCreature and not addon._aaeR6SelectWrapped then
    addon._aaeR6SelectWrapped = true
    local oldSelectFeaturedCreature = addon.SelectFeaturedCreature
    addon.SelectFeaturedCreature = function(self, record)
        -- Preserve all existing selection text/warnings/favorites/row refresh.
        local result = oldSelectFeaturedCreature(self, record)
        -- Then become the sole owner of the visible model state.
        startCreatureModel(record)
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
    if targetEntry() == tonumber(record[1]) then startCreatureModel(record) end
end)

if addon.CreateCreatureBrowser and not addon._aaeR6CreateWrapped then
    addon._aaeR6CreateWrapped = true
    local oldCreateCreatureBrowser = addon.CreateCreatureBrowser
    addon.CreateCreatureBrowser = function(self, ...)
        local result = oldCreateCreatureBrowser(self, ...)
        installCreatureSearchImeR6()
        ensureStatus()
        return result
    end
end
