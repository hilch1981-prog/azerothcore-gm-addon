local A = AzerothAdminAC335
function A:EnsureBankFrame()
    if BankFrame then return true end
    if UIParentLoadAddOn then pcall(UIParentLoadAddOn,"Blizzard_BankUI") end
    if not BankFrame and LoadAddOn then pcall(LoadAddOn,"Blizzard_BankUI") end
    return BankFrame ~= nil
end
function A:OpenBank()
    if BankFrame and BankFrame:IsShown() then
        if HideUIPanel then HideUIPanel(BankFrame) else BankFrame:Hide() end
        return true
    end
    if not self:EnsureBankFrame() then self:Print("Blizzard_BankUI unavailable",true); return false end
    self.bankOpenRequested=true
    local ok=self:RunRegisteredCommand("bank",nil,true)
    if ok then self:Print(self:L("BANK_REQUESTED")) else self.bankOpenRequested=nil end
    return ok
end
A.ToggleBankWindow=A.OpenBank
local bankEvents=CreateFrame("Frame")
bankEvents:RegisterEvent("BANKFRAME_OPENED")
bankEvents:RegisterEvent("BANKFRAME_CLOSED")
bankEvents:SetScript("OnEvent",function(_,event)
    if event=="BANKFRAME_OPENED" then
        A.bankOpenRequested=nil; A.bankSessionOpen=true
        if A:EnsureBankFrame() then
            BankFrame:SetMovable(true); BankFrame:EnableMouse(true); BankFrame:SetClampedToScreen(true); BankFrame:RegisterForDrag("LeftButton")
            BankFrame:SetScript("OnDragStart",function(self) self:StartMoving() end); BankFrame:SetScript("OnDragStop",function(self) self:StopMovingOrSizing() end)
            BankFrame:ClearAllPoints(); BankFrame:SetPoint("CENTER",UIParent,"CENTER",0,0)
            if not BankFrame:IsShown() then if ShowUIPanel then ShowUIPanel(BankFrame) else BankFrame:Show() end end
        end
    else A.bankSessionOpen=false; A.bankOpenRequested=nil end
end)
