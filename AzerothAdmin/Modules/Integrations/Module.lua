AzerothAdminEasy = AzerothAdminEasy or {}
local addon = AzerothAdminEasy


local function isDescendantOf(frame, ancestor)
    if not frame or not ancestor then return false end
    local current = frame
    local guard = 0
    while current and guard < 32 do
        if current == ancestor then return true end
        current = current.GetParent and current:GetParent() or nil
        guard = guard + 1
    end
    return false
end

local function legacyCraftFrameMatches(frame)
    if not frame then return false end
    local own = _G.AzerothAdminCraftInfoFrame
    if own and isDescendantOf(frame, own) then return false end
    local found = false
    local function scan(node, depth)
        if not node or found or depth > 3 then return end
        if own and isDescendantOf(node, own) then return end
        if node.GetRegions then
            local regions = { node:GetRegions() }
            local i
            for i = 1, table.getn(regions) do
                local region = regions[i]
                if region and region.GetObjectType and region:GetObjectType() == "FontString" and region.GetText then
                    local text = tostring(region:GetText() or "")
                    if string.find(text, "Inven Craft Info", 1, true)
                        or string.find(text, "InvenCraftInfo v", 1, true)
                        or string.find(text, "InvenCraftInfo 1.", 1, true) then
                        found = true
                        return
                    end
                end
            end
        end
        if node.GetChildren and depth < 3 then
            local children = { node:GetChildren() }
            local i
            for i = 1, table.getn(children) do scan(children[i], depth + 1) end
        end
    end
    scan(frame, 0)
    return found
end

function addon:SuppressLegacyCraftFrames()
    local own = _G.AzerothAdminCraftInfoFrame
    local f = EnumerateFrames and EnumerateFrames() or nil
    while f do
        local parent = f.GetParent and f:GetParent() or nil
        local topLevel = (parent == UIParent or parent == nil)
        local ownChild = own and isDescendantOf(f, own)
        if topLevel and not ownChild and f ~= own and f ~= TradeSkillFrame and f ~= UIParent and f.IsShown and f:IsShown() then
            local name = f.GetName and (f:GetName() or "") or ""
            local legacyName = name ~= "" and string.find(name, "InvenCraftInfo", 1, true) and name ~= "AzerothAdminCraftInfoFrame"
            if legacyName or legacyCraftFrameMatches(f) then
                pcall(function() f:Hide() end)
            end
        end
        f = EnumerateFrames and EnumerateFrames(f) or nil
    end
end

function addon:ScheduleLegacyCraftSuppression()
    -- One-shot checks only.  A persistent OnUpdate watcher previously hid children
    -- of the new integrated UI and made the profession window appear non-functional.
    local delays = { 0.05, 0.35, 1.0 }
    local i
    for i = 1, table.getn(delays) do
        self:RunAfter(delays[i], function() addon:SuppressLegacyCraftFrames() end)
    end
end

function addon:ToggleCraftInfo()
    if AzerothAdminCraftInfoFrame and AzerothAdminCraftInfoFrame:IsShown() then
        AzerothAdminCraftInfoFrame:Hide()
        if TradeSkillFrame and TradeSkillFrame:IsShown() then pcall(TradeSkillFrame.Hide, TradeSkillFrame) end
        return
    end
    self:HideAddonPopups(nil)
    if not AzerothAdminCraftInfoFrame then self:Print(self:T("INTEGRATIONS_CRAFT_UI_MISSING"), true); return end
    if not AzerothAdminCraftInfoFrame.enable and AzerothAdminCraftInfoFrame.ADDON_LOADED then pcall(AzerothAdminCraftInfoFrame.ADDON_LOADED, AzerothAdminCraftInfoFrame) end
    if AzerothAdminCraftInfoFrame.ResetGMProfessionView then AzerothAdminCraftInfoFrame:ResetGMProfessionView() end
    local opened
    if self.OpenManagedFrame then
        opened = self:OpenManagedFrame(AzerothAdminCraftInfoFrame)
    else
        self:HideAddonWindows(AzerothAdminCraftInfoFrame)
        AzerothAdminCraftInfoFrame:Show()
        opened = AzerothAdminCraftInfoFrame:IsShown()
        if opened then
            self:RegisterEscapeFrame(AzerothAdminCraftInfoFrame)
            self.currentManagedFrame = AzerothAdminCraftInfoFrame
            self:UpdateEscapeProxy()
        end
    end
    if opened then self:ScheduleLegacyCraftSuppression() end
end

function addon:ToggleItemInfo()
    if BlueItemInfo3 and BlueItemInfo3:IsShown() then
        BlueItemInfo3.aaeReturnFrame=nil
        BlueItemInfo3:Hide()
        return
    end
    if not BlueItemInfo3 or not BlueItemInfo3.OnClick then
        self:Print(self:T("INTEGRATIONS_ITEM_MODULE_MISSING"), true)
        return
    end
    self:HideAddonPopups(nil)
    local ok, err = pcall(BlueItemInfo3.OnClick, BlueItemInfo3, "LeftButton")
    if not ok then self:Print(self:T("INTEGRATIONS_ITEM_OPEN_FAILED", tostring(err)), true) end
end
