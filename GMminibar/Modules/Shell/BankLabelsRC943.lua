local A=AzerothAdminAC335
local U,N=A.UnifiedBags,A.NativeUI
local function decorate(button,bag,slot)
 if not button then return end
 if not button.gmBagNumber then
  button.gmBagNumber=N:Text(button,'',28,true);button.gmBagNumber:SetPoint('BOTTOMLEFT',button,'BOTTOMLEFT',1,1);button.gmBagNumber:SetTextColor(.4,1,1)
  button.gmItemLevel=N:Text(button,'',36,true);button.gmItemLevel:SetPoint('TOP',button,'TOP',0,1);button.gmItemLevel:SetJustifyH('CENTER');button.gmItemLevel:SetTextColor(1,.85,.1)
 end
 local link=GetContainerItemLink(bag,slot)
 button.gmBagNumber:SetText(link and tostring(bag) or '')
 local level=link and U:ActualItemLevel(bag,slot,link)
 button.gmItemLevel:SetText(level and tostring(level) or '')
end
local events=CreateFrame('Frame');local elapsed=0
local function bankBagShown(bag)
 for i=1,(NUM_CONTAINER_FRAMES or 13) do
  local f=_G['ContainerFrame'..i]
  if f and f:IsShown() and f:GetID()==bag then return f end
 end
end
function A:SetBankBagsOpen(opened)
 if not BankFrame or not BankFrame:IsShown() or InCombatLockdown() then return end
 -- Toggle only the seven bank bag IDs. Never call a whole-inventory helper.
 local inventory={}
 for bag=0,4 do inventory[bag]=bankBagShown(bag) and true or false end
 for bag=5,11 do
  local frame=bankBagShown(bag)
  if opened then
   if not frame and GetContainerNumSlots(bag)>0 then ToggleBag(bag) end
  elseif frame then
   frame:Hide()
  end
 end
 -- Preserve the inventory state even if a client hook opens the backpack.
 for bag=0,4 do
  local frame=bankBagShown(bag)
  if frame and not inventory[bag] then frame:Hide() end
 end
 self:RefreshBankLabels()
end
function A:RefreshBankLabels()
 if not BankFrame or not BankFrame:IsShown() then return end
 if not self.bankBagsToggle then
  local button=N:Button(BankFrame,A:T('보조 가방 열기'),124,21,function()
   local opened=false
   for bag=5,11 do if bankBagShown(bag) then opened=true;break end end
   A:SetBankBagsOpen(not opened)
  end)
  self.bankBagsToggle=button
  N:Hint(button,A:T('은행 보조 가방'),A:T('장착한 은행 보조 가방을 모두 열거나 닫습니다.'))
 end
 local purchase=BankFramePurchaseInfo;local purchaseButton
 if purchase and purchase.GetChildren then
  for _,child in ipairs({purchase:GetChildren()}) do
   if child.IsObjectType and child:IsObjectType('Button') then purchaseButton=child;break end
  end
 end
 local button=self.bankBagsToggle;button:ClearAllPoints()
 if purchaseButton then
  button:SetSize(purchaseButton:GetWidth(),purchaseButton:GetHeight())
  button:SetPoint('BOTTOM',purchaseButton,'TOP',0,3)
 else button:SetSize(124,21);button:SetPoint('BOTTOMRIGHT',BankFrame,'BOTTOMRIGHT',-30,70) end
 -- Keep the purchase explanation left of the two stacked buttons.
 if purchase and purchase.GetRegions and not purchase.gmCompactLabel then
  for _,region in ipairs({purchase:GetRegions()}) do
   if region.IsObjectType and region:IsObjectType('FontString') and region.GetText and region:GetText()==BANKSLOTPURCHASE_LABEL then
    region:ClearAllPoints();region:SetPoint('TOPLEFT',purchase,'TOPLEFT',45,-2);region:SetSize(190,32);region:SetJustifyH('LEFT')
   end
  end
  purchase.gmCompactLabel=true
 end
 local opened=false
 for bag=5,11 do if bankBagShown(bag) then opened=true;break end end
 self.bankBagsToggle:SetText(opened and A:T('보조 가방 닫기') or A:T('보조 가방 열기'))
 local available=false;for bag=5,11 do if GetContainerNumSlots(bag)>0 then available=true;break end end
 if available then self.bankBagsToggle:Enable() else self.bankBagsToggle:Disable() end
 for slot=1,(NUM_BANKGENERIC_SLOTS or 28) do decorate(_G['BankFrameItem'..slot],-1,slot) end
 for i=1,(NUM_CONTAINER_FRAMES or 13) do
  local f=_G['ContainerFrame'..i];local bag=f and f:GetID()
  if f and f:IsShown() and bag and bag>=5 and bag<=11 then
   for n=1,GetContainerNumSlots(bag) do local b=_G[f:GetName()..'Item'..n];if b then decorate(b,bag,b:GetID()) end end
  end
 end
end
events:SetScript('OnUpdate',function(_,dt) elapsed=elapsed+dt;if elapsed<.25 then return end;elapsed=0;A:RefreshBankLabels() end)
