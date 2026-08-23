AzerothAdminEasy = AzerothAdminEasy or {}
local addon = AzerothAdminEasy

-- Runtime corrections confirmed from WotLK 3.3.5a client testing.
-- Loaded last so the original UI and previous compatibility layer remain intact.

local DISPLAY_INFO_BY_ENTRY = {
    [4949] = 4527,   -- Thrall
    [10184] = 8570, -- Onyxia
    [36597] = 30721, -- The Lich King
}

local function clearFocus(edit)
    if edit and edit.ClearFocus then
        pcall(edit.ClearFocus, edit)
    end
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
            if edit.Hide then pcall(edit.Hide, edit) end
        end
    end
end

local function releaseSearchKeyboard()
    clearFocus(addon.creatureBrowserSearch)
    clearFocus(addon.localeSearchEdit)
    if _G.BlueItemInfo3 then
        clearFocus(_G.BlueItemInfo3.searchEdit)
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

-- Korean IME can hand focus to the default chat EditBox one frame after a
-- search click/Enter. Release both addon EditBoxes and the active chat EditBox
-- immediately and twice more after short delays.
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

local function setupCreatureModel(record)
    local model = addon.creatureBrowserModel
    local entry = tonumber(record and record[1])
    if not model or not entry then return end

    if model.Show then model:Show() end
    if model.ClearModel then pcall(model.ClearModel, model) end

    local displayID = DISPLAY_INFO_BY_ENTRY[entry]
    local setOK = false

    -- Direct display info is useful for known entries that fail to resolve via
    -- SetCreature on some 3.3.5a clients/caches.
    if displayID and model.SetDisplayInfo then
        setOK = pcall(model.SetDisplayInfo, model, displayID)
    end

    if not setOK and model.SetCreature then
        setOK = pcall(model.SetCreature, model, entry)
    end

    -- Match the proven 3.3.5a DBM model-preview initialization sequence.
    if setOK then
        if model.SetModelScale then pcall(model.SetModelScale, model, 0.72) end
        if model.SetFacing then pcall(model.SetFacing, model, 0) end
        if model.SetPosition then pcall(model.SetPosition, model, 0, 0, 0) end
        if model.SetSequence then pcall(model.SetSequence, model, 0) end
        if model.SetRotation then pcall(model.SetRotation, model, addon.creatureBrowserModelRotation or 0) end
        if model.SetAlpha then pcall(model.SetAlpha, model, 1) end
        model:Show()
        if addon.creatureBrowserModelFallback then addon.creatureBrowserModelFallback:Hide() end
    else
        model:Hide()
        if addon.creatureBrowserModelFallback then addon.creatureBrowserModelFallback:Show() end
    end
end

local previousSelectFeaturedCreature = addon.SelectFeaturedCreature
if previousSelectFeaturedCreature then
    addon.SelectFeaturedCreature = function(self, record)
        local result = previousSelectFeaturedCreature(self, record)
        if record then
            setupCreatureModel(record)
            self._runtimeModelSerial = (self._runtimeModelSerial or 0) + 1
            local serial = self._runtimeModelSerial
            if self.RunAfter then
                self:RunAfter(0.05, function()
                    if serial == addon._runtimeModelSerial and addon.creatureBrowserSelected == record then
                        setupCreatureModel(record)
                    end
                end)
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
