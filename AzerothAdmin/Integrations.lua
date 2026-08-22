AzerothAdminEasy = AzerothAdminEasy or {}
local addon = AzerothAdminEasy

local function ensureDB()
    AzerothAdminEasyDB = AzerothAdminEasyDB or {}
    return AzerothAdminEasyDB
end

local function saveFramePoint(frame, prefix)
    if not frame or not frame.GetPoint then return end
    local db = ensureDB()
    local point, _, relativePoint, x, y = frame:GetPoint()
    db[prefix .. "Point"] = point
    db[prefix .. "RelativePoint"] = relativePoint
    db[prefix .. "X"] = x
    db[prefix .. "Y"] = y
end

local function centerFrame(frame)
    if not frame then return end
    frame:ClearAllPoints()
    frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
end

local function restoreFramePoint(frame, prefix, defaultX, defaultY)
    if not frame then return end
    local db = ensureDB()
    frame:ClearAllPoints()
    if db[prefix .. "Point"] then
        frame:SetPoint(db[prefix .. "Point"], UIParent,
            db[prefix .. "RelativePoint"] or db[prefix .. "Point"],
            db[prefix .. "X"] or 0, db[prefix .. "Y"] or 0)
    else
        frame:SetPoint("CENTER", UIParent, "CENTER", defaultX or 0, defaultY or 0)
    end
end

function addon:EnsureBankFrame()
    -- BankFrame is native 3.3.5a FrameXML.  It only represents a real,
    -- interactive bank when the server has opened a BANKFRAME session.
    if not BankFrame then
        if UIParentLoadAddOn then pcall(UIParentLoadAddOn, "Blizzard_BankUI") end
        if not BankFrame and LoadAddOn then pcall(LoadAddOn, "Blizzard_BankUI") end
    end
    return BankFrame ~= nil
end

function addon:PrepareBankFrame()
    if not self:EnsureBankFrame() then return false end
    if self.bankFramePrepared then return true end

    BankFrame:SetMovable(true)
    BankFrame:EnableMouse(true)
    BankFrame:SetClampedToScreen(true)
    BankFrame:RegisterForDrag("LeftButton")

    local oldDragStart = BankFrame:GetScript("OnDragStart")
    local oldDragStop = BankFrame:GetScript("OnDragStop")
    BankFrame:SetScript("OnDragStart", function(self)
        if oldDragStart then pcall(oldDragStart, self) end
        self:StartMoving()
    end)
    BankFrame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        saveFramePoint(self, "bank")
        if oldDragStop then pcall(oldDragStop, self) end
    end)
    centerFrame(BankFrame)
    self.bankFramePrepared = true
    return true
end

local function makeBankText(parent, text, font)
    local fs = parent:CreateFontString(nil, "OVERLAY", font or "GameFontHighlightSmall")
    fs:SetText(text or "")
    return fs
end

local function makeBankButton(parent, w, h, text)
    local b = CreateFrame("Button", nil, parent)
    b:SetWidth(w); b:SetHeight(h)
    b:SetBackdrop({bgFile="Interface\\Tooltips\\UI-Tooltip-Background",edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",tile=true,tileSize=12,edgeSize=8,insets={left=2,right=2,top=2,bottom=2}})
    b:SetBackdropColor(0.02,0.035,0.045,0.95); b:SetBackdropBorderColor(0.55,0.42,0.18,1)
    local fs = makeBankText(b, text, "GameFontHighlightSmall")
    fs:SetAllPoints(b); fs:SetJustifyH("CENTER"); b.label=fs
    b.SetText=function(self,v) self.label:SetText(v or "") end
    return b
end

-- v3.2.1: The remote text bank viewer was intentionally removed.  The bank
-- button now controls only Blizzard's native BankFrame.  Keep these compatibility
-- functions so older saved callbacks cannot recreate the removed window.
function addon:CreateRemoteBankFrame()
    if self.remoteBankFrame and self.remoteBankFrame.Hide then
        pcall(function() self.remoteBankFrame:Hide() end)
    end
    return nil
end

function addon:RenderRemoteBank()
end

function addon:HandleBankSystemMessage(message)
    -- Remote bank output capture is disabled in the native-bank-only build.
    self.bankCaptureActive = false
end

function addon:RefreshRemoteBank(clear)
    self.bankCaptureActive = false
    self:SuppressRemoteBankPopups()
end

local function hideNativeBank()
    if BankFrame and BankFrame:IsShown() then
        saveFramePoint(BankFrame, "bank")
        -- v2.9's direct Hide path was the most reliable on the target 3.3.5a client.
        pcall(function() BankFrame:Hide() end)
        if BankFrame:IsShown() and HideUIPanel then pcall(HideUIPanel, BankFrame) end
    end
end

function addon:SuppressRemoteBankPopups()
    -- Do NOT scan/hide arbitrary bank-looking frames: that broke the native bank.
    -- Only kill the obsolete AzerothAdmin remote viewer if an old frame survived a reload.
    self.bankCaptureActive = false
    if self.remoteBankSuppressor then
        self.remoteBankSuppressor:SetScript("OnUpdate", nil)
        self.remoteBankSuppressor:Hide()
    end
    if self.remoteBankFrame and self.remoteBankFrame.IsShown and self.remoteBankFrame:IsShown() then
        pcall(function() self.remoteBankFrame:Hide() end)
    end
    local old = _G.AzerothAdminRemoteBankFrame
    if old and old.IsShown and old:IsShown() then
        pcall(function() old:Hide() end)
    end
end

function addon:ScheduleRemoteBankPopupSuppression()
    self:SuppressRemoteBankPopups()
end

function addon:ToggleBankWindow()
    -- AzerothCore implements .character check bank by sending the real bank
    -- packet (SendShowBank) for the player's GUID.  Never fake this by merely
    -- showing BankFrame client-side; without the server session item movement
    -- is rejected and the frame may immediately close.
    self:SuppressRemoteBankPopups()
    self:HideAddonPopups(nil)
    if self.argumentFrame and self.argumentFrame:IsShown() then
        self.argumentFrame.aaeReturnFrame = nil
        self.argumentFrame:Hide()
    end

    if BankFrame and BankFrame:IsShown() then
        hideNativeBank()
        self.bankSessionOpen = false
        self.bankOpenRequested = nil
        return
    end
    if not self:PrepareBankFrame() then
        self:Print("기본 은행 프레임을 불러오지 못했습니다.", true)
        return
    end

    self:HideAddonWindows(BankFrame)
    centerFrame(BankFrame)
    BankFrame.aaeReturnFrame = nil
    self.bankOpenRequested = true

    -- This GM command opens a genuine remote bank session in AzerothCore.
    -- BANKFRAME_OPENED below is the only place that shows/manages the UI.
    local ok = self:SendNow(".character check bank")
    if ok == false then
        self.bankOpenRequested = nil
        self:Print("원격 은행 명령을 전송하지 못했습니다.", true)
    end
end

local bankEvent=CreateFrame("Frame")
bankEvent:RegisterEvent("BANKFRAME_OPENED")
bankEvent:RegisterEvent("BANKFRAME_CLOSED")
bankEvent:SetScript("OnEvent",function(self,event)
    addon:SuppressRemoteBankPopups()
    if event=="BANKFRAME_OPENED" then
        addon.bankSessionOpen=true
        addon.bankOpenRequested=nil
        if addon:PrepareBankFrame() then
            addon:HideAddonWindows(BankFrame)
            centerFrame(BankFrame)
            BankFrame.aaeReturnFrame = nil
            if not BankFrame:IsShown() then
                if ShowUIPanel then pcall(ShowUIPanel, BankFrame) end
                if not BankFrame:IsShown() then pcall(function() BankFrame:Show() end) end
            end
            addon:RegisterEscapeFrame(BankFrame)
            addon.currentManagedFrame = BankFrame
            addon:UpdateEscapeProxy()
        end
    else
        addon.bankSessionOpen=false
        addon.bankOpenRequested=nil
    end
end)

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
        AzerothAdminCraftInfoFrame.aaeReturnFrame = nil
        self._closingManagedWindows = true
        AzerothAdminCraftInfoFrame:Hide()
        if TradeSkillFrame and TradeSkillFrame:IsShown() then pcall(TradeSkillFrame.Hide, TradeSkillFrame) end
        self._closingManagedWindows = nil
        if self.currentManagedFrame == AzerothAdminCraftInfoFrame then self.currentManagedFrame = nil end
        self:UpdateEscapeProxy()
        return
    end
    self:HideAddonPopups(nil)
    if not AzerothAdminCraftInfoFrame then self:Print("전문기술 정보 UI를 찾지 못했습니다.", true); return end
    if not AzerothAdminCraftInfoFrame.enable and AzerothAdminCraftInfoFrame.ADDON_LOADED then pcall(AzerothAdminCraftInfoFrame.ADDON_LOADED, AzerothAdminCraftInfoFrame) end
    self:HideAddonWindows(AzerothAdminCraftInfoFrame)
    AzerothAdminCraftInfoFrame.aaeReturnFrame = nil
    if AzerothAdminCraftInfoFrame.ResetGMProfessionView then AzerothAdminCraftInfoFrame:ResetGMProfessionView() end
    AzerothAdminCraftInfoFrame:Show()
    self:RegisterEscapeFrame(AzerothAdminCraftInfoFrame)
    self.currentManagedFrame = AzerothAdminCraftInfoFrame
    self:ScheduleLegacyCraftSuppression()
    self:UpdateEscapeProxy()
end

function addon:ToggleItemInfo()
    if BlueItemInfo3 and BlueItemInfo3:IsShown() then
        BlueItemInfo3.aaeReturnFrame=nil
        BlueItemInfo3:Hide()
        return
    end
    if not BlueItemInfo3 or not BlueItemInfo3.OnClick then
        self:Print("통합 아이템 정보 모듈을 찾지 못했습니다.", true)
        return
    end
    self:HideAddonPopups(nil)
    local ok, err = pcall(BlueItemInfo3.OnClick, BlueItemInfo3, "LeftButton")
    if not ok then self:Print("아이템 정보 창을 열지 못했습니다: " .. tostring(err), true) end
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:SetScript("OnEvent", function()
    addon:PrepareBankFrame()
    addon:SuppressRemoteBankPopups()
end)
