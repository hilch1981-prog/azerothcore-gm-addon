AzerothAdminEasy = AzerothAdminEasy or {}
local addon = AzerothAdminEasy

-- R8.1 precheck runtime corrections for WoW WotLK 3.3.5a Build 12340 + AzerothCore.
--
-- Keyboard:
--   Do not force ToggleInputLanguage(). Korean WoW clients can leave the
--   internal IME/chat state active even after an addon EditBox loses focus.
--   Use Blizzard's own 3.3.5 chat submit/escape path with whitespace only;
--   ChatEdit_SendText does not send whitespace, but ChatEdit_OnEnterPressed
--   still closes/deactivates the native chat EditBox and clears the stuck state.
--   R8.1 applies the flush after submit, Enter, Escape and frame close.
--
-- PlayerModel:
--   Follow the real 3.3.5 _NPCScan sequence: keep PlayerModel visible,
--   ClearModel -> reset scale/position/facing -> install OnUpdateModel ->
--   SetCreature(entry). Do not Hide/alpha-zero the model before loading.

addon.CreatureBrowserRuntimeRevision = "IME/MODEL R8.1 PRECHECK"

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

chatMessage("|cffffd24aAzerothAdmin R8.1 PRECHECK 로드됨|r")

-- ---------------------------------------------------------------------------
-- koKR IME: native blank-chat flush
-- ---------------------------------------------------------------------------

local function chooseNativeChatEditBox()
    local edit = nil
    if ChatEdit_GetActiveWindow then
        local ok, active = pcall(ChatEdit_GetActiveWindow)
        if ok and active then edit = active end
    end
    if not edit and ChatEdit_ChooseBoxForSend then
        local ok, chosen = pcall(ChatEdit_ChooseBoxForSend, DEFAULT_CHAT_FRAME)
        if ok and chosen then edit = chosen end
    end
    if not edit then edit = _G.ChatFrame1EditBox end
    return edit
end

local function hasMeaningfulText(edit)
    if not edit or not edit.GetText then return false end
    local ok, text = pcall(edit.GetText, edit)
    if not ok or type(text) ~= "string" then return false end
    return string.find(text, "%S") ~= nil
end

local function nativeBlankChatFlush()
    local edit = chooseNativeChatEditBox()
    if not edit then return false end

    -- Never destroy a real chat draft. A focused chat box containing actual
    -- text already explains why movement is disabled; leave it to the player.
    if hasMeaningfulText(edit) then return false end

    if ChatEdit_ActivateChat then
        pcall(ChatEdit_ActivateChat, edit)
    else
        if edit.Show then edit:Show() end
        if edit.SetFocus then safeCall(edit.SetFocus, edit) end
    end

    -- Blizzard 3.3.5 ChatEdit_SendText only calls SendChatMessage when there is
    -- at least one non-whitespace character. Two spaces therefore drive the
    -- native Enter/Escape cleanup path without emitting a chat message.
    if edit.SetText then edit:SetText("  ") end

    if ChatEdit_OnEnterPressed then
        pcall(ChatEdit_OnEnterPressed, edit)
    else
        if ChatEdit_SendText then pcall(ChatEdit_SendText, edit, false) end
        if ChatEdit_OnEscapePressed then
            pcall(ChatEdit_OnEscapePressed, edit)
        elseif ChatEdit_DeactivateChat then
            pcall(ChatEdit_DeactivateChat, edit)
        elseif edit.ClearFocus then
            safeCall(edit.ClearFocus, edit)
        end
    end
    return true
end

function addon:ReleaseKoreanSearchInput(edit)
    if edit and edit.ClearFocus then safeCall(edit.ClearFocus, edit) end
    -- Let the search click/IME composition finish, then pass through Blizzard's
    -- native chat enter/escape path. The second pass catches composition that
    -- commits one frame late; both passes are whitespace-only and invisible.
    runAfter(0.02, nativeBlankChatFlush)
    runAfter(0.18, nativeBlankChatFlush)
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
    if not button or button._aaeR81ImeHooked then return end
    local text = getButtonText(button)
    if not text or not accepted[text] then return end
    local oldClick = button:GetScript("OnClick")
    if not oldClick then return end

    button._aaeR81ImeHooked = true
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
    if not edit or edit._aaeR81EnterHooked then return end
    local oldEnter = edit:GetScript("OnEnterPressed")
    if not oldEnter then return end
    edit._aaeR81EnterHooked = true
    edit:SetScript("OnEnterPressed", function(self, ...)
        oldEnter(self, ...)
        addon:ReleaseKoreanSearchInput(self)
    end)
end

local function hookEscape(edit)
    if not edit or edit._aaeR81EscapeHooked then return end
    local oldEscape = edit:GetScript("OnEscapePressed")
    edit._aaeR81EscapeHooked = true
    edit:SetScript("OnEscapePressed", function(self, ...)
        if oldEscape then oldEscape(self, ...) end
        addon:ReleaseKoreanSearchInput(self)
    end)
end

local function hookFrameHide(frame, edit)
    if not frame or frame._aaeR81ImeHideHooked then return end
    frame._aaeR81ImeHideHooked = true
    local oldHide = frame:GetScript("OnHide")
    frame:SetScript("OnHide", function(self, ...)
        if oldHide then oldHide(self, ...) end
        addon:ReleaseKoreanSearchInput(edit)
    end)
end

local function installBlueItemImeR81()
    local BII3 = _G.BlueItemInfo3
    if not BII3 or not BII3.searchEdit then return end
    local edit = BII3.searchEdit
    hookEnter(edit)
    hookEscape(edit)
    hookFrameHide(BII3, edit)
    hookButtonsRecursive(BII3, edit, {
        ["검색"] = true,
        ["분류"] = true,
        ["필터 적용"] = true,
    })

    if BII3.Search and not BII3._aaeR81PublicSearchWrapped then
        BII3._aaeR81PublicSearchWrapped = true
        local oldSearch = BII3.Search
        BII3.Search = function(self, ...)
            local result = oldSearch(self, ...)
            addon:ReleaseKoreanSearchInput(self.searchEdit)
            return result
        end
    end
end

local function installCreatureSearchImeR81()
    local frame = addon.creatureBrowserFrame
    local edit = addon.creatureBrowserSearch
    if not frame or not edit then return end
    hookEnter(edit)
    hookEscape(edit)
    hookFrameHide(frame, edit)
    hookButtonsRecursive(frame, edit, {
        ["검색"] = true,
        ["전체 DB 검색"] = true,
    })
end

if addon.RunLocaleSearch and not addon._aaeR81LocaleWrapped then
    addon._aaeR81LocaleWrapped = true
    local oldRunLocaleSearch = addon.RunLocaleSearch
    addon.RunLocaleSearch = function(self, ...)
        local result = oldRunLocaleSearch(self, ...)
        self:ReleaseKoreanSearchInput(self.localeSearchEdit)
        return result
    end
end

installBlueItemImeR81()
installCreatureSearchImeR81()

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
        installCreatureSearchImeR81()
        ensureStatus()
        return result
    end
end
