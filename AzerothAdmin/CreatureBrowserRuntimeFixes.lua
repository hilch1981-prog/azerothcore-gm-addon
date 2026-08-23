AzerothAdminEasy = AzerothAdminEasy or {}
local addon = AzerothAdminEasy

-- R8 runtime corrections for WoW WotLK 3.3.5a Build 12340 + AzerothCore.
--
-- Keyboard:
--   Do not force ToggleInputLanguage().  Korean WoW clients can leave the
--   internal IME/chat state active even after an addon EditBox loses focus.
--   R8 uses Blizzard's own 3.3.5 chat submit/escape path with whitespace only;
--   ChatEdit_SendText does not send whitespace, but ChatEdit_OnEnterPressed
--   still closes/deactivates the native chat EditBox and clears the stuck state.
--
-- PlayerModel:
--   Follow the real 3.3.5 _NPCScan sequence: keep PlayerModel visible,
--   ClearModel -> reset scale/position/facing -> install OnUpdateModel ->
--   SetCreature(entry).  Do not Hide/alpha-zero the model before loading.
--   A companion R8 cache installer merges the 414 curated creature records into
--   the user's existing valid creaturecache.wdb while preserving its 24-byte
--   server cache header/version.

addon.CreatureBrowserRuntimeRevision = "IME/MODEL R8"

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

chatMessage("|cffffd24aAzerothAdmin R8 IME/MODEL TEST 로드됨|r")

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

    -- Never destroy a real chat draft.  A focused chat box containing actual
    -- text already explains why movement is disabled; leave it to the player.
    if hasMeaningfulText(edit) then return false end

    if ChatEdit_ActivateChat then
        pcall(ChatEdit_ActivateChat, edit)
    else
        if edit.Show then edit:Show() end
        if edit.SetFocus then safeCall(edit.SetFocus, edit) end
    end

    -- Two spaces reproduce the field workaround reported by Korean WoW users.
    -- Blizzard 3.3.5 ChatEdit_SendText only calls SendChatMessage when there is
    -- at least one non-whitespace character, so this cannot emit chat text.
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
    -- First finish the custom addon EditBox normally.  We intentionally do not
    -- call ToggleInputLanguage(): that API does not reliably mirror the physical
    -- Hangul/English key on affected WoW clients.
    if edit and edit.ClearFocus then safeCall(edit.ClearFocus, edit) end

    -- Let the search click/IME composition finish, then pass through Blizzard's
    -- native chat enter/escape path.  The second pass catches composition that
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
    if not button or button._aaeR8ImeHooked then return end
    local text = getButtonText(button)
    if not text or not accepted[text] then return end
    local oldClick = button:GetScript("OnClick")
    if not oldClick then return end

    button._aaeR8ImeHooked = true
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
    if not edit or edit._aaeR8EnterHooked then return end
    local oldEnter = edit:GetScript("OnEnterPressed")
    if not oldEnter then return end
    edit._aaeR8EnterHooked = true
    edit:SetScript("OnEnterPressed", function(self, ...)
        oldEnter(self, ...)
        addon:ReleaseKoreanSearchInput(self)
    end)
end

local function installBlueItemImeR8()
    local BII3 = _G.BlueItemInfo3
    if not BII3 or not BII3.searchEdit then return end
    local edit = BII3.searchEdit
    hookEnter(edit)
    hookButtonsRecursive(BII3, edit, {
        ["검색"] = true,
        ["분류"] = true,
        ["필터 적용"] = true,
    })

    if BII3.Search and not BII3._aaeR8PublicSearchWrapped then
        BII3._aaeR8PublicSearchWrapped = true
        local oldSearch = BII3.Search
        BII3.Search = function(self, ...)
            local result = oldSearch(self, ...)
            addon:ReleaseKoreanSearchInput(self.searchEdit)
            return result
        end
    end
end

local function installCreatureSearchImeR8()
    local frame = addon.creatureBrowserFrame
    local edit = addon.creatureBrowserSearch
    if not frame or not edit then return end
    hookEnter(edit)
    hookButtonsRecursive(frame, edit, {
        ["검색"] = true,
        ["전체 DB 검색"] = true,
    })
end

if addon.RunLocaleSearch and not addon._aaeR8LocaleWrapped then
    addon._aaeR8LocaleWrapped = true
    local oldRunLocaleSearch = addon.RunLocaleSearch
    addon.RunLocaleSearch = function(self, ...)
        local result = oldRunLocaleSearch(self, ...)
        self:ReleaseKoreanSearchInput(self.localeSearchEdit)
        return result
    end
end

installBlueItemImeR8()
installCreatureSearchImeR8()

-- ---------------------------------------------------------------------------
-- Creature PlayerModel: 3.3.5 _NPCScan-compatible load lifecycle
-- ---------------------------------------------------------------------------

local MODEL_DEFAULT_SCALE = 0.75

-- Camera corrections borrowed only as behavioral guidance from 3.3.5 _NPCScan;
-- unknown model paths use the normal centered camera.
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

    -- Critical R8 regression fix: SetCreature must run on a visible PlayerModel.
    -- R7 hid the frame and set alpha=0 before SetCreature, which caused even
    -- previously working cached models to disappear on the user's client.
    model:Show()
    if model.SetAlpha then safeCall(model.SetAlpha, model, 1) end
    if model.ClearModel then safeCall(model.ClearModel, model) end
    if model.SetModelScale then safeCall(model.SetModelScale, model, 1) end
    if model.SetPosition then safeCall(model.SetPosition, model, 0, 0, 0) end
    if not keepFacing and model.SetFacing then safeCall(model.SetFacing, model, 0) end
end

-- _NPCScan 3.3.5 extracts the 20-bit NPC entry from characters 8..12.
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

    -- If direct SetCreature did not load, do not destroy the previously proven
    -- native behavior with morph hacks.  The R8 cache merge is the supported
    -- path for first-ever-seen entries.
    if addon.creatureBrowserModelFallback then addon.creatureBrowserModelFallback:Show() end
    setStatus("R8: Entry " .. tostring(record and record[1] or "?")
        .. " 가 클라이언트 creaturecache에 없습니다.\nR8 캐시 병합 설치 후 WoW를 완전히 재시작하세요.")
end

local function loadModelNative(record, useTarget)
    local model = addon.creatureBrowserModel
    local entry = tonumber(record and record[1])
    if not model or not entry then return end

    modelSerial = modelSerial + 1
    local serial = modelSerial
    setStatus("R8: Entry " .. tostring(entry) .. " 3D 외형 로드 중...")
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
        if modelReady then
            self:SetScript("OnUpdateModel", oldOnUpdateModel)
        end
    end

    model:SetScript("OnUpdateModel", function(self)
        if serial ~= modelSerial then return end
        -- _NPCScan waits one additional frame after the mesh-load event before
        -- applying relative scale/position.
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
        setStatus("R8: PlayerModel 호출 실패 · Entry " .. tostring(entry))
        return
    end

    -- Cached entries often have GetModel() ready before OnUpdateModel fires.
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

if addon.SelectFeaturedCreature and not addon._aaeR8SelectWrapped then
    addon._aaeR8SelectWrapped = true
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
    if targetCreatureEntry() == tonumber(record[1]) then
        loadModelNative(record, true)
    end
end)

if addon.CreateCreatureBrowser and not addon._aaeR8CreateWrapped then
    addon._aaeR8CreateWrapped = true
    local oldCreateCreatureBrowser = addon.CreateCreatureBrowser
    addon.CreateCreatureBrowser = function(self, ...)
        local result = oldCreateCreatureBrowser(self, ...)
        installCreatureSearchImeR8()
        ensureStatus()
        return result
    end
end
