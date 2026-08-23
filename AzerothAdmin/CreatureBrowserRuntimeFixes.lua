AzerothAdminEasy = AzerothAdminEasy or {}
local addon = AzerothAdminEasy

-- Runtime corrections confirmed from WotLK 3.3.5a client testing.
-- Loaded last so the original UI and previous compatibility layer remain intact.

-- Known WotLK-compatible display IDs used as a fast path when SetCreature does
-- not have the creature cached yet. Unknown entries still use the cache-query
-- path below, so this is intentionally not a complete creature model database.
local DISPLAY_INFO_BY_ENTRY = {
    [3057] = 4307,    -- Cairne Bloodhoof
    [4949] = 4527,    -- Thrall
    [4968] = 30863,   -- Lady Jaina Proudmoore
    [7937] = 7006,    -- High Tinker Mekkatorque (3.3.5a verified model)
    [7999] = 7274,    -- Tyrande Whisperwind
    [10181] = 28213,  -- Lady Sylvanas Windrunner
    [10184] = 8570,   -- Onyxia
    [36597] = 30721,  -- The Lich King
}

local function clearFocus(edit)
    if edit and edit.ClearFocus then
        pcall(edit.ClearFocus, edit)
    end
end

-- WotLK 3.3.5a EditBox has GetInputLanguage/ToggleInputLanguage. Korean IME
-- can remain active even after ClearFocus(), which causes normal movement keys
-- to stay captured until the physical Hangul/English key is pressed once.
-- Reproduce that one-key language release in code before dropping focus.
local function forceRomanInput(edit)
    if not edit or not edit.GetInputLanguage or not edit.ToggleInputLanguage then return end
    local ok, language = pcall(edit.GetInputLanguage, edit)
    if ok and language and tostring(language) ~= "ROMAN" then
        pcall(edit.ToggleInputLanguage, edit)
    end
end

local function releaseEditBox(edit)
    forceRomanInput(edit)
    clearFocus(edit)
end

local function releaseChatFocus()
    local edit = nil
    if ChatEdit_GetActiveWindow then
        local ok, active = pcall(ChatEdit_GetActiveWindow)
        if ok then edit = active end
    end

    if edit then
        forceRomanInput(edit)
        if ChatEdit_DeactivateChat then
            pcall(ChatEdit_DeactivateChat, edit)
        else
            clearFocus(edit)
            if edit.Hide then pcall(edit.Hide, edit) end
        end
    end
end

local function releaseSearchKeyboard()
    releaseEditBox(addon.creatureBrowserSearch)
    releaseEditBox(addon.localeSearchEdit)
    if _G.BlueItemInfo3 then
        releaseEditBox(_G.BlueItemInfo3.searchEdit)
    end
    releaseChatFocus()
end

local function releaseSearchKeyboardDelayed()
    releaseSearchKeyboard()
    if addon.RunAfter then
        -- Delayed passes are still required because the Korean IME can finish
        -- composition after the search click/Enter handler has returned.
        addon:RunAfter(0.05, releaseSearchKeyboard)
        addon:RunAfter(0.20, releaseSearchKeyboard)
    end
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
        local result = previousBII3Search(self, ...)
        releaseSearchKeyboardDelayed()
        return result
    end
end

-- A synthetic 3.3.5a creature GUID is enough for AzerothCore's creature-query
-- handler: the server resolves static creature data by entry and returns the
-- display IDs in SMSG_CREATURE_QUERY_RESPONSE. The hidden tooltip is used only
-- to warm the client's CreatureCache; it never appears to the player.
local creatureCacheTooltip = nil
local function getCreatureCacheTooltip()
    if creatureCacheTooltip then return creatureCacheTooltip end
    creatureCacheTooltip = CreateFrame("GameTooltip", "AzerothAdminCreatureCacheTooltip", UIParent, "GameTooltipTemplate")
    creatureCacheTooltip:SetOwner(UIParent, "ANCHOR_NONE")
    creatureCacheTooltip:Hide()
    return creatureCacheTooltip
end

local function makeCreatureGuid(entry)
    entry = tonumber(entry)
    if not entry or entry < 0 or entry > 16777215 then return nil end
    return "0xF130" .. string.format("%06X", entry) .. "000001"
end

local function requestCreatureCache(record)
    local entry = tonumber(record and record[1])
    if not entry then return end
    local guid = makeCreatureGuid(entry)
    if not guid then return end

    local tooltip = getCreatureCacheTooltip()
    if not tooltip or not tooltip.SetHyperlink then return end
    if tooltip.ClearLines then pcall(tooltip.ClearLines, tooltip) end

    local name = tostring(record[2] or "")
    pcall(tooltip.SetHyperlink, tooltip, "unit:" .. guid .. ":" .. name)
    tooltip:Hide()
end

local function getLoadedModelPath(model)
    if not model or not model.GetModel then return nil end
    local ok, path = pcall(model.GetModel, model)
    if not ok or type(path) ~= "string" or path == "" then return nil end
    return path
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
        -- DBM's 3.3.5 model preview offsets ordinary creature models slightly
        -- on X so humanoids and ground creatures remain centered in the frame.
        if model.SetPosition then pcall(model.SetPosition, model, 0.4, 0, 0) end
    end
end

local function setupCreatureModel(record)
    local model = addon.creatureBrowserModel
    local entry = tonumber(record and record[1])
    if not model or not entry then return false end

    if model.Show then model:Show() end
    if model.ClearModel then pcall(model.ClearModel, model) end

    local displayID = DISPLAY_INFO_BY_ENTRY[entry]
    if displayID and model.SetDisplayInfo then
        pcall(model.SetDisplayInfo, model, displayID)
    elseif model.SetCreature then
        pcall(model.SetCreature, model, entry)
    end

    -- pcall(SetCreature) only proves the function did not throw. On 3.3.5a it
    -- can still leave PlayerModel empty while creature data is not cached.
    local path = getLoadedModelPath(model)
    if path then
        applyModelPresentation(model, path)
        model:Show()
        if addon.creatureBrowserModelFallback then addon.creatureBrowserModelFallback:Hide() end
        return true
    end

    model:Hide()
    if addon.creatureBrowserModelFallback then addon.creatureBrowserModelFallback:Show() end
    return false
end

local previousSelectFeaturedCreature = addon.SelectFeaturedCreature
if previousSelectFeaturedCreature then
    addon.SelectFeaturedCreature = function(self, record)
        local result = previousSelectFeaturedCreature(self, record)
        self._runtimeModelSerial = (self._runtimeModelSerial or 0) + 1
        local serial = self._runtimeModelSerial

        if record then
            requestCreatureCache(record)
            setupCreatureModel(record)

            if self.RunAfter then
                local delays = { 0.10, 0.35, 0.80, 1.50 }
                local i
                for i = 1, table.getn(delays) do
                    self:RunAfter(delays[i], function()
                        if serial ~= addon._runtimeModelSerial or addon.creatureBrowserSelected ~= record then return end
                        if not setupCreatureModel(record) then
                            requestCreatureCache(record)
                        end
                    end)
                end
            end
        end
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
