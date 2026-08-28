AzerothAdminEasy = AzerothAdminEasy or {}
local addon = AzerothAdminEasy

-- Runtime input corrections for WoW WotLK 3.3.5a Build 12340 + AzerothCore.
--
-- Keyboard:
--   Preserve the R6 koKR input-release sequence that was confirmed in game.
--   It completes the input-language transition, clears any keyboard focus,
--   disables keyboard capture on the finished search EditBox, and restores it
--   when the player clicks the field again. It never submits chat text.
addon.CreatureBrowserRuntimeRevision = "IME R6 / NO PLAYERMODEL"

local function safeCall(method, object, ...)
    if not method or not object then return false end
    return pcall(method, object, ...)
end

local function chatMessage(text)
    if DEFAULT_CHAT_FRAME and DEFAULT_CHAT_FRAME.AddMessage then
        DEFAULT_CHAT_FRAME:AddMessage(text)
    end
end

chatMessage("|cffffd24aAzerothAdmin · IME R6 로드됨|r")

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

if addon.CreateCreatureBrowser and not addon._aaeImeCreateWrapped then
    addon._aaeImeCreateWrapped = true
    local oldCreateCreatureBrowser = addon.CreateCreatureBrowser
    addon.CreateCreatureBrowser = function(self, ...)
        local result = oldCreateCreatureBrowser(self, ...)
        installCreatureSearchImeR6()
        return result
    end
end
