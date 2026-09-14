local A=AzerothAdminAC335
local L={};A.ItemLevels=L
local slots={'Head','Neck','Shoulder','Shirt','Chest','Waist','Legs','Feet','Wrist','Hands','Finger0','Finger1','Trinket0','Trinket1','Back','MainHand','SecondaryHand','Ranged','Tabard'}
function L:Level(link)
 if not link or not GetItemInfo then return end
 local value
 if GetDetailedItemLevelInfo then local ok,result=pcall(GetDetailedItemLevelInfo,link);if ok then value=tonumber(result)end end
 if not value then local _,_,_,itemLevel=GetItemInfo(link);value=tonumber(itemLevel) end
 if value and value>0 then return math.floor(value+.5)end
end
function L:Apply(button,link)
 if not button or not button:IsShown() then return end
 local level=self:Level(link)
 if not button.gmItemLevel then
  if not level then return end
  button.gmItemLevel=A.NativeUI:Text(button,'',40,true)
  button.gmItemLevel:SetPoint('TOP',button,'TOP',0,1);button.gmItemLevel:SetJustifyH('CENTER');button.gmItemLevel:SetTextColor(1,.85,.1)
  if button.gmItemLevel.SetDrawLayer then button.gmItemLevel:SetDrawLayer('OVERLAY')end
 end
 button.gmItemLevel:SetText(level and tostring(level) or '')
end
function L:Refresh()
 for i,name in ipairs(slots)do
  for _,prefix in ipairs({'Character','Inspect'})do
   local b=_G[prefix..name..'Slot'];local unit=prefix=='Character' and 'player' or (InspectFrame and InspectFrame.unit or 'target')
   if b and b:IsShown() then self:Apply(b,GetInventoryItemLink and GetInventoryItemLink(unit,i))end
  end
 end
 for index=1,(NUM_CONTAINER_FRAMES or 13)do
  local frame=_G['ContainerFrame'..index]
  if frame and frame:IsShown() then
   local bag=frame:GetID();local count=GetContainerNumSlots(bag)
   for n=1,count do local b=_G['ContainerFrame'..index..'Item'..n];if b then self:Apply(b,GetContainerItemLink(bag,b:GetID()))end end
  end
 end
 local surfaces={
  {'MerchantItem',12,'ItemButton',function(i)return GetMerchantItemLink and GetMerchantItemLink(i+((MerchantFrame and MerchantFrame.page or 1)-1)*(MERCHANT_ITEMS_PER_PAGE or 10))end},
  {'MerchantBuyBackItem',12,'ItemButton',function(i)return GetBuybackItemLink and GetBuybackItemLink(i)end},
  {'LootButton',4,'',function(i)return GetLootSlotLink and GetLootSlotLink(i)end},
  {'TradePlayerItem',7,'ItemButton',function(i)return GetTradePlayerItemLink and GetTradePlayerItemLink(i)end},
  {'TradeRecipientItem',7,'ItemButton',function(i)return GetTradeTargetItemLink and GetTradeTargetItemLink(i)end},
  {'OpenMailAttachmentButton',16,'',function(i)local id=OpenMailFrame and (OpenMailFrame.mailID or OpenMailFrame.id) or InboxFrame and InboxFrame.openMailID;return GetInboxItemLink and id and GetInboxItemLink(id,i)end},
  {'SendMailAttachment',12,'',function(i)return GetSendMailItemLink and GetSendMailItemLink(i)end},
 }
 for _,s in ipairs(surfaces)do for i=1,s[2]do local b=_G[s[1]..i..s[3]];if b and b:IsShown() then self:Apply(b,s[4](i))end end end
 if GuildBankFrame and GuildBankFrame:IsShown() and GetCurrentGuildBankTab then
  for column=1,7 do for row=1,14 do local b=_G['GuildBankColumn'..column..'Button'..row];if b then self:Apply(b,GetGuildBankItemLink(GetCurrentGuildBankTab(),(column-1)*14+row))end end end
 end
 if AuctionFrame and AuctionFrame:IsShown() and GetAuctionItemLink then
  for _,s in ipairs({{'BrowseButton','list','BrowseScrollFrame'},{'AuctionsButton','owner','AuctionsScrollFrame'},{'BidButton','bidder','BidScrollFrame'}})do
   local scroll=_G[s[3]];local offset=scroll and FauxScrollFrame_GetOffset and FauxScrollFrame_GetOffset(scroll) or 0
   for i=1,9 do local b=_G[s[1]..i..'Item'];if b and b:IsShown() then self:Apply(b,GetAuctionItemLink(s[2],i+offset))end end
  end
 end
end
local event=CreateFrame('Frame');local elapsed=0
event:SetScript('OnUpdate',function(_,dt)elapsed=elapsed+dt;if elapsed<.3 then return end;elapsed=0;L:Refresh()end)
-- A tooltip supplies the same information for item links and custom item views.
if GameTooltip and GameTooltip.HookScript then
 GameTooltip:HookScript('OnTooltipSetItem',function(tip)
  local _,link=tip:GetItem();local level=L:Level(link);if not level or tip.gmLevelLink==link then return end
  tip.gmLevelLink=link
  local name=tip:GetName()
  for i=1,tip:NumLines()do local text=name and _G[name..'TextLeft'..i];text=text and text:GetText() or ''
   if text:find(tostring(level),1,true) and (text:find('Item Level',1,true) or text:find('아이템 레벨',1,true) or text:find('物品等级',1,true) or text:find('物品等級',1,true) or text:find('Уровень предмета',1,true))then return end
  end
  tip:AddLine(A:L('GEAR_ITEM_LEVEL',level),1,.85,.1)
 end)
 GameTooltip:HookScript('OnTooltipCleared',function(tip)tip.gmLevelLink=nil end)
end
