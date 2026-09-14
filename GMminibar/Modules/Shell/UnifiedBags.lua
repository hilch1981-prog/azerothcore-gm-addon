-- Shared legacy bag presentation; native item templates retain click/drag behavior.
local A=AzerothAdminAC335
local N,W=A.NativeUI,A.Workbench
local U={parents={},buttons={},originals={},elapsed=0};A.UnifiedBags=U
local function active(value) return value==true or value==1 end
local function merchant() return MerchantFrame and MerchantFrame:IsShown() and MerchantFrame.selectedTab~=2 end
local function link(b,s) return GetContainerItemLink(b,s) end
local function itemKey(item) return item and (item:match('item:(%d+)') or item) end
function U:Pins()
 local db=W:DB();db.bagPins=db.bagPins or {}
 local character=(GetRealmName() or '')..':'..(UnitGUID('player') or UnitName('player') or '')
 db.bagPins[character]=db.bagPins[character] or {};return db.bagPins[character]
end
function U:IsPinned(b,s)
 local item=link(b,s);local pin=self:Pins()[b..':'..s]
 if not pin then return false end
 if item then return pin==itemKey(item) end
 local id=GetContainerItemID and GetContainerItemID(b,s)
 return id~=nil and pin==tostring(id)
end
function U:TogglePin(b,s)
 if self.selling or self.destroyPrompt or GetCursorInfo() or (A.BagSort and A.BagSort.pending) then
  A:Print(A:T('아이템 처리가 끝난 뒤 고정을 변경해 주세요.'));return false
 end
 local item=link(b,s);if not item then return false end
 local _,_,locked=GetContainerItemInfo(b,s);if active(locked) then return false end
 local pins=self:Pins();local key=b..':'..s
 if self:IsPinned(b,s) then pins[key]=nil else pins[key]=itemKey(item) end
 if self.selected then self.selected[key]=nil end
 if A.BagSort then A.BagSort:Stop() end
 self:Refresh();return true
end
-- Keep Blizzard's XML click/drag scripts intact: an addon wrapper taints
-- UseContainerItem for food, drinks, potions and item-targeted spells.
function U:UpdateButtonGuards(button,b,s,visible)
 local pinned=visible and self:IsPinned(b,s)
 if pinned and not button.pinGuard then
  local guard=CreateFrame('Button',nil,button);button.pinGuard=guard
  guard:SetAllPoints(button);guard:SetFrameLevel(button:GetFrameLevel()+4)
  guard:RegisterForClicks('LeftButtonUp','RightButtonUp');guard:RegisterForDrag('LeftButton')
  local function blocked() A:Print(A:T('고정된 아이템입니다. 아이템 고정 버튼으로 고정을 해제해 주세요.')) end
  guard:SetScript('OnClick',blocked);guard:SetScript('OnDragStart',blocked);guard:SetScript('OnReceiveDrag',blocked)
  guard:SetScript('OnEnter',function(g)
   local tip=A:BeginHintTooltip(g,'ANCHOR_RIGHT');tip:SetBagItem(b,s)
   tip:AddLine(A:T('아이템 고정: 이동·사용·판매·파괴 방지'),.3,.7,1);A:StyleHintTooltip();tip:Show()
  end)
  guard:SetScript('OnLeave',function(g) A:HideHintTooltip(g) end)
  guard:EnableMouseWheel(true);guard:SetScript('OnMouseWheel',function(_,d) U:Scroll(d) end)
 end
 if button.pinGuard then if pinned then button.pinGuard:Show() else button.pinGuard:Hide() end end
 local protectQuest=visible and not pinned and merchant() and self:IsQuestItem(b,s)
 if protectQuest and not button.questGuard then
  -- This sibling has the same bag/slot IDs and native scripts. Only left clicks
  -- are registered, so quest items retain native pickup, links and dragging
  -- while right-click sales cannot run. Allocate only for slots that need it.
  local guard=CreateFrame('Button',button:GetName()..'QuestGuard',button:GetParent(),'ContainerFrameItemButtonTemplate')
  button.questGuard=guard;guard:SetID(s);guard:SetAllPoints(button)
  guard:SetFrameLevel(button:GetFrameLevel()+3);guard:SetAlpha(0)
  guard:RegisterForClicks('LeftButtonUp')
  guard:HookScript('OnMouseDown',function(_,mouse)
   if mouse=='RightButton' then A:Print(A:T('퀘스트 아이템은 판매할 수 없습니다.')) end
  end)
  guard:EnableMouseWheel(true);guard:SetScript('OnMouseWheel',function(_,d) U:Scroll(d) end)
 end
 if button.questGuard then
  local guard=button.questGuard;guard.hasItem=button.hasItem;guard.readable=button.readable;guard.count=button.count
  if protectQuest then guard:Show() else guard:Hide() end
 end
end
function U:IsQuestItem(b,s)
 local quest,qid
 if GetContainerItemQuestInfo then quest,qid=GetContainerItemQuestInfo(b,s) end
 if active(quest) or (tonumber(qid) or 0)>0 then return true end
 local item=link(b,s)
 if item then local _,_,_,_,_,class=GetItemInfo(item)
  return class=='Quest' or class=='퀘스트' or (GetItemClassInfo and class==GetItemClassInfo(12)) or false
 end
 return false
end
function U:Scroll(delta)
 self.offset=math.max(0,math.min(self.maxScroll or 0,(self.offset or 0)-delta*42))
 self.scroll:SetVerticalScroll(self.offset)
end
function U:StartMove()
 if W:DB().bagLocked or not self.frame then return end
 self.frame:SetMovable(true);self.moving=true;self.frame:StartMoving()
end
function U:StopMove()
 if not self.frame or not self.moving then return end
 self.frame:StopMovingOrSizing();self.moving=nil
 local x,y=self.frame:GetCenter()
 if x and y then local r=self.frame:GetEffectiveScale()/UIParent:GetEffectiveScale();W:DB().bagPosition={x=x*r,y=y*r} end
end
function U:UpdateMoney()
 if not self.money then return end
 local copper=type(GetMoney)=="function" and GetMoney() or 0
 self.money:SetText(string.format(A:T("소지금: |cffffd700%d금|r |cffc0c0c0%d은|r |cffcd7f32%d동|r"),math.floor(copper/10000),math.floor(copper/100)%100,copper%100))
end
function U:CreateBagSlots()
 if self.bagSlots then return end
 self.bagSlots={}
 local label=N:Text(self.frame,A:T('장착 가방'),150,true)
 label:SetPoint('BOTTOMLEFT',self.frame,'BOTTOMLEFT',14,22)
 for bag=1,4 do
  local id,empty=GetInventorySlotInfo('Bag'..(bag-1)..'Slot')
  local button=CreateFrame('CheckButton','GMminibarEquippedBag'..bag,self.frame,'ItemButtonTemplate')
  self.bagSlots[bag]=button;button:SetID(id);button.emptyTexture=empty
  button:SetSize(30,30);button:SetPoint('BOTTOMRIGHT',self.frame,'BOTTOMRIGHT',-18-(4-bag)*40,12)
  button:RegisterForClicks('LeftButtonUp','RightButtonUp');button:RegisterForDrag('LeftButton')
  -- The native bag handlers support both empty-slot installation and replacing
  -- a bag with its contents, as well as dragging an equipped bag out.
  button:SetScript('OnClick',BagSlotButton_OnClick)
  button:SetScript('OnReceiveDrag',BagSlotButton_OnClick)
  button:SetScript('OnDragStart',BagSlotButton_OnDrag)
  button:SetScript('OnEnter',function(s)
   local tip=A:BeginHintTooltip(s,'ANCHOR_LEFT')
   if not tip:SetInventoryItem('player',s:GetID()) then tip:SetText(A:T('빈 가방칸 ')..bag,1,.82,0) end
   local slots=GetContainerNumSlots(bag)
   if slots>0 then local free=GetContainerNumFreeSlots(bag);tip:AddLine(A:T('빈칸 ')..(free or 0)..' / '..slots,1,1,1) end
   tip:AddLine(A:T('가방을 끌어 놓아 장착/교체'),.3,1,.3)
   tip:AddLine(A:T('클릭: 개별 가방 열기 · 드래그: 가방 꺼내기'),.7,.7,.7)
   A:StyleHintTooltip();tip:Show()
  end)
  button:SetScript('OnLeave',function(s) A:HideHintTooltip(s) end)
  button.number=N:Text(button,tostring(bag),12,true);button.number:SetPoint('TOPLEFT',button,'TOPLEFT',0,1)
  button.number:SetTextColor(.4,1,1)
 end
end
function U:UpdateBagSlots()
 for bag,button in ipairs(self.bagSlots or {}) do
  local texture=GetInventoryItemTexture('player',button:GetID())
  SetItemButtonTexture(button,texture or button.emptyTexture)
  SetItemButtonCount(button,texture and GetContainerNumSlots(bag) or 0)
  SetItemButtonDesaturated(button,IsInventoryItemLocked and active(IsInventoryItemLocked(button:GetID())))
  if A.hintOwner==button and A.hintTooltip and A.hintTooltip:IsShown() then button:GetScript('OnEnter')(button) end
 end
end
function U:Create()
 if self.frame then return end
 local f=CreateFrame("Frame","AzerothAdminUnifiedBags",UIParent);self.frame=f
 f:SetWidth(384);f:SetPoint("TOPRIGHT",UIParent,"TOPRIGHT",-8,-65);f:SetFrameStrata("HIGH");f:SetClampedToScreen(true);f:EnableMouse(true);N:Panel(f);f:SetBackdropColor(0,0,0,1);f:Hide();self:RestorePosition();f:SetMovable(true)
 local title=N:Text(f,A:T("통합 가방"),118,true);title:SetPoint("TOPLEFT",f,"TOPLEFT",14,-15)
 local close=CreateFrame("Button",nil,f,"UIPanelCloseButton");close:SetPoint("TOPRIGHT",f,"TOPRIGHT",0,0);close:SetScript("OnClick",function() f:Hide() end)
 local drag=CreateFrame("Frame",nil,f);self.drag=drag;drag:SetWidth(210);drag:SetHeight(30);drag:SetPoint("TOPLEFT",f,"TOPLEFT",10,-8);drag:EnableMouse(true);drag:RegisterForDrag("LeftButton");drag:SetFrameLevel(f:GetFrameLevel()+2)
 drag:SetScript("OnDragStart",function() U:StartMove() end)
 drag:SetScript("OnDragStop",function() U:StopMove() end)
 f:RegisterForDrag("LeftButton");f:SetScript("OnDragStart",function() U:StartMove() end);f:SetScript("OnDragStop",function() U:StopMove() end)
 local lock=CreateFrame("Button",nil,f);self.lock=lock;lock:SetWidth(22);lock:SetHeight(22);lock:SetPoint("TOPRIGHT",f,"TOPRIGHT",-33,-10);N:LockIcon(lock,W:DB().bagLocked)
 lock:SetFrameLevel(f:GetFrameLevel()+3);lock:RegisterForDrag("LeftButton")
 lock:SetScript("OnMouseDown",function() lock.dragged=false end);lock:SetScript("OnDragStart",function() if not W:DB().bagLocked then lock.dragged=true;U:StartMove() end end);lock:SetScript("OnDragStop",function() U:StopMove() end)
 lock:SetScript("OnClick",function() if lock.dragged then lock.dragged=false;return end;U:StopMove();W:DB().bagLocked=not W:DB().bagLocked;f:SetMovable(not W:DB().bagLocked);N:LockIcon(lock,W:DB().bagLocked) end);N:Hint(lock,A:T("가방 위치 잠금"),A:T("클릭: 잠금/해제. 잠금 해제 후 제목 또는 이 아이콘을 드래그하세요."))
 local destroy=CreateFrame("Button",nil,f);destroy:SetWidth(24);destroy:SetHeight(24);destroy:SetPoint("TOPRIGHT",f,"TOPRIGHT",-124,-10);destroy:SetNormalTexture("Interface\\Icons\\INV_Misc_Bone_01");self.destroy=destroy
 destroy:SetScript("OnClick",function() U:ConfirmDestroy() end);N:Hint(destroy,A:T("회색 잡템 일괄 파괴"),A:T("대상 목록을 확인한 뒤 회색 잡템을 파괴합니다. 파괴한 아이템은 되돌릴 수 없습니다."))
 local sell=CreateFrame("Button",nil,f);sell:SetWidth(24);sell:SetHeight(24);sell:SetPoint("TOPRIGHT",f,"TOPRIGHT",-62,-10);sell:SetNormalTexture("Interface\\Icons\\INV_Misc_Coin_01");self.sell=sell
 sell:SetScript("OnClick",function() U:SellJunk() end);N:Hint(sell,A:T("잡템 일괄 판매"),A:T("상인 거래 중 회색 등급 잡템만 판매합니다. 판매 가격이 없거나 잠긴 아이템은 제외합니다."))
 local sort=CreateFrame("Button",nil,f);self.sort=sort;sort:SetWidth(24);sort:SetHeight(24);sort:SetPoint("RIGHT",sell,"LEFT",-8,0);sort:SetNormalTexture("Interface\\Icons\\INV_Misc_Bag_08");sort:SetScript("OnClick",function() A.BagSort:Request(true) end);N:Hint(sort,A:T("가방 정렬"),A:T("종류별로 지금 정렬합니다."))
 local sc=CreateFrame("ScrollFrame",nil,f);self.scroll=sc;sc:SetPoint("TOPLEFT",f,"TOPLEFT",14,-46);sc:SetWidth(336);sc:EnableMouseWheel(true);sc:SetScript("OnMouseWheel",function(_,d) U:Scroll(d) end)
 local content=CreateFrame("Frame",nil,sc);self.content=content;content:SetWidth(336);sc:SetScrollChild(content)
 local up=N:Button(f,"▲",22,24,function() U:Scroll(1) end);up:SetPoint("TOPRIGHT",f,"TOPRIGHT",-7,-46)
 local down=N:Button(f,"▼",22,24,function() U:Scroll(-1) end);down:SetPoint("BOTTOMRIGHT",f,"BOTTOMRIGHT",-7,130)
 self.status=N:Text(f,"",340,true);self.status:SetPoint("BOTTOMLEFT",f,"BOTTOMLEFT",14,73)
 self.money=N:Text(f,"",340,true);self.money:SetPoint("BOTTOMLEFT",f,"BOTTOMLEFT",14,56);self:UpdateMoney()
 local label=N:Text(f,A:T("검색"),34,true);label:SetPoint("BOTTOMLEFT",f,"BOTTOMLEFT",14,103)
 self.search=N:Edit(f,210);self.search:SetPoint("BOTTOMLEFT",f,"BOTTOMLEFT",51,93)
 self.pinButton=N:Button(f,A:T('아이템 고정'),94,24,function(button)
  U.pinMode=not U.pinMode;U.multiSelect=false;U.selected={}
  if U.selectButton then U.selectButton:SetText(A:T('선택')) end
  button:SetText(U.pinMode and A:T('고정 완료') or A:T('아이템 고정'));U:Refresh()
 end);self.pinButton:SetPoint('BOTTOMRIGHT',f,'BOTTOMRIGHT',-14,93)
 N:Hint(self.pinButton,A:T('아이템 고정'),A:T('클릭 후 아이템을 눌러 고정/해제합니다. 파란 테두리 아이템은 이동·정렬·판매·파괴에서 보호됩니다.'))
 self:CreateBagSlots()
 self.search:SetAutoFocus(false)
 self.search:SetScript("OnTextChanged",function(s) U.query=string.lower(s:GetText() or '');U.offset=0;U:Refresh() end)
 self.search:SetScript("OnEscapePressed",function(s) s:SetText('');s:ClearFocus() end)
 self.search:SetScript("OnEnterPressed",function(s) s:ClearFocus() end)
 f:SetScript("OnHide",function() U.search:ClearFocus();U:StopMove();U.selling=nil;U.autoSellPending=nil;U.destroyPrompt=nil;if StaticPopup_Hide then StaticPopup_Hide("AZEROTHADMIN_DESTROY_JUNK") end;GameTooltip:Hide() end)
 tinsert(UISpecialFrames,"AzerothAdminUnifiedBags")
end
function U:Refresh()
 if not self.frame or not self.frame:IsShown() then return end
 local index,free,total=0,0,0
 for b=0,4 do
  local parent=self.parents[b]
  if not parent then parent=CreateFrame("Frame",nil,self.content);parent:SetID(b);parent:SetAllPoints(self.content);self.parents[b]=parent end
  for s=1,GetContainerNumSlots(b) do
   total=total+1
   local item=link(b,s);local name=item and GetItemInfo(item)
   local visible=not self.query or self.query=='' or (name and string.find(string.lower(name),self.query,1,true))
   if visible then index=index+1 end
   local k=b..":"..s;local button=self.buttons[k]
   if not button then
    button=CreateFrame("Button","AzerothAdminBag"..b.."Slot"..s,parent,"ContainerFrameItemButtonTemplate");button:SetID(s);button:SetNormalTexture("Interface\\Buttons\\UI-Quickslot2");button:SetPushedTexture("Interface\\Buttons\\UI-Quickslot-Depress");button:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square","ADD");button:SetWidth(36);button:SetHeight(36);self.buttons[k]=button
    button:EnableMouseWheel(true);button:SetScript("OnMouseWheel",function(_,d) U:Scroll(d) end)
    button.questMark=button:CreateTexture(nil,'OVERLAY')
    button.questMark:SetPoint('CENTER',button,'CENTER',0,0);button.questMark:SetSize(24,24)
    button.questMark:SetTexture('Interface\\GossipFrame\\AvailableQuestIcon');button.questMark:Hide()
   end
   button:ClearAllPoints();button:SetPoint("TOPLEFT",self.content,"TOPLEFT",((index-1)%(self.columns or 8))*42,-math.floor((index-1)/(self.columns or 8))*42);button:Show();button.present=true
   if not visible then button:Hide() end
   button:UnlockHighlight();button:SetButtonState("NORMAL")
   local highlight=button:GetHighlightTexture();if highlight and (not MouseIsOver or not MouseIsOver(button)) then highlight:Hide() end
   local texture,count,locked,quality,readable=GetContainerItemInfo(b,s)
   button.hasItem=texture~=nil;button.readable=readable;button.count=count
   SetItemButtonTexture(button,texture);SetItemButtonCount(button,count or 0);SetItemButtonDesaturated(button,active(locked))
   -- AC335's native OnEnter clears NewItemTexture. Initialise it here as well.
   local newItem=_G[button:GetName().."NewItemTexture"]
   if newItem then newItem:Hide() end
   if button.searchOverlay then button.searchOverlay:Hide() end
   local cd=_G[button:GetName().."Cooldown"]
   if cd then if texture and GetContainerItemCooldown and CooldownFrame_SetTimer then local start,duration,enable=GetContainerItemCooldown(b,s);CooldownFrame_SetTimer(cd,start,duration,enable) else cd:Hide() end end
   local quest=_G[button:GetName().."IconQuestTexture"]
   local isQuest=self:IsQuestItem(b,s)
   if quest then quest:Hide();if isQuest then quest:SetTexture("Interface\\ContainerFrame\\UI-Icon-QuestBorder");quest:Show() end end
   if isQuest and texture then button.questMark:Show() else button.questMark:Hide() end
   self:UpdateButtonGuards(button,b,s,visible)
   if not texture then free=free+1 end
  end
 end
 for _,button in pairs(self.buttons) do if not button.present then button:Hide();if button.questGuard then button.questGuard:Hide() end end;button.present=nil end
 local rows=math.max(1,math.ceil(index/(self.columns or 8)));local height=rows*42
 local screen=UIParent:GetHeight();if screen<100 then screen=GetScreenHeight()/UIParent:GetEffectiveScale() end
 local maximum=math.max(3,math.floor((screen-204)/42))
 local visible=math.max(3,math.min(maximum,self.visibleRows or rows))*42
 self.content:SetHeight(height);self.scroll:SetHeight(visible);self.frame:SetHeight(visible+176)
 self.maxScroll=math.max(0,height-visible);self:Scroll(0)
 self.status:SetText(A:T("빈칸 ")..free.." / "..total..((self.query and self.query~='') and (A:T(' · 검색 ')..index..A:T('칸')) or A:T(' · 마우스 휠: 스크롤')))
 self:UpdateMoney();self:UpdateBagSlots()
 if not self.selling then self.sell:Enable() else self.sell:Disable() end
 if self.Decorate then self:Decorate() end
end
function U:Open(owner)
 self:Create();if not self.frame:IsShown() then self.owner=owner end
 self.frame:Show();self:Refresh()
end
function U:Close(owner)
 if owner and self.owner~=owner then return end
 if self.frame then self.frame:Hide() end;self.owner=nil
end
function U:Toggle() if self.frame and self.frame:IsShown() then self:Close() else self:Open() end end
local function eligible(b,s,destroy)
 if U:IsPinned(b,s) then return end
 local item=link(b,s);if not item then return end
 local _,_,locked=GetContainerItemInfo(b,s);if active(locked) then return nil,true end
 local _,_,quality,_,_,_,_,_,_,_,price=GetItemInfo(item)
 if quality==nil or (not destroy and price==nil) then return nil,true end
 local quest,questID;if GetContainerItemQuestInfo then quest,questID=GetContainerItemQuestInfo(b,s) end
 if quality==0 and not U:IsQuestItem(b,s) and (destroy or (price and price>0)) then return item end
end
function U:SellJunk(automatic,allowPartial)
 if self.selling or self.destroyPrompt or not merchant() or InCombatLockdown() or GetCursorInfo() or (InRepairMode and active(InRepairMode())) or (A.BagSort and A.BagSort.pending) then return end
 local queue,waiting={},false
 for b=0,4 do for s=1,GetContainerNumSlots(b) do local item,pending=eligible(b,s);waiting=waiting or pending;if item then queue[#queue+1]={b=b,s=s,item=item} end end end
 if automatic and waiting and not allowPartial then return end
 self.autoSellPending=nil
 if #queue==0 then if not automatic then A:Print(A:T("판매 가능한 회색 잡템이 없습니다. 아이템 정보를 확인한 뒤 다시 눌러주세요.")) end;return end
 self.selling={queue=queue,index=1,sold=0,automatic=automatic};self:Refresh()
end
function U:AutoSellStep()
 local pending=self.autoSellPending;if not pending then return end
 if W:DB().autoSellJunk==false or not MerchantFrame or not MerchantFrame:IsShown() then self.autoSellPending=nil;return end
 local expired=GetTime()>=pending.deadline
 -- Wait for cached item info, slot unlocks, and a pending bag move. Never retry a dispatched sale.
 self:SellJunk(true,expired)
 if expired then self.autoSellPending=nil end
end
function U:SellStep()
 local run=self.selling;if not run then return end
 if (run.automatic and W:DB().autoSellJunk==false) or (not run.destroy and not merchant()) or InCombatLockdown() or GetCursorInfo() or (InRepairMode and active(InRepairMode())) then self.selling=nil;self.dirty=true;return end
 if run.pending then
  if link(run.pending.b,run.pending.s)~=run.pending.item then run.sold=run.sold+1;run.pending=nil
  elseif GetTime()>run.deadline then self.selling=nil;A:Print(A:T("잡템 판매가 중단되었습니다. 아이템 이동 상태를 확인해주세요."));return
  else return end
 end
 local v=run.queue[run.index]
 if not v then A:Print(A:T("잡템 ")..run.sold..(run.destroy and A:T("칸을 파괴했습니다.") or A:T("칸을 판매했습니다.")));self.selling=nil;self:Refresh();return end
 run.index=run.index+1
 local _,currentCount=GetContainerItemInfo(v.b,v.s)
 local valid=run.custom and U:Matches(v.b,v.s,run.destroy and "destroy" or "sell",run.filters,run.selection) or (not run.custom and eligible(v.b,v.s,run.destroy))
 if valid==v.item and (currentCount or 1)==(v.count or currentCount or 1) then
  if run.destroy then
   PickupContainerItem(v.b,v.s);local cursor,id=GetCursorInfo();local expected=tonumber(v.item:match("item:(%d+)"))
   if cursor=="item" and id==expected then DeleteCursorItem() else if cursor then ClearCursor() end;self.selling=nil;self.dirty=true;return end
  else UseContainerItem(v.b,v.s) end
  run.pending=v;run.deadline=GetTime()+3
 end
end
function U:RestorePosition()
 if not self.frame then return end;self.frame:ClearAllPoints();local p=W:DB().bagPosition
 if p then local r=UIParent:GetEffectiveScale()/self.frame:GetEffectiveScale();self.frame:SetPoint("CENTER",UIParent,"BOTTOMLEFT",p.x*r,p.y*r)
 else self.frame:SetPoint("TOPRIGHT",UIParent,"TOPRIGHT",-8,-65) end
end
function U:ConfirmDestroy()
 if self.selling or self.destroyPrompt or InCombatLockdown() or GetCursorInfo() or not self.frame or not self.frame:IsShown() or (A.BagSort and A.BagSort.pending) then return end
 local queue,lines={},{}
 for b=0,4 do for slot=1,GetContainerNumSlots(b) do local item=eligible(b,slot,true)
  if item then local _,count=GetContainerItemInfo(b,slot);queue[#queue+1]={b=b,s=slot,item=item,count=count or 1};if #lines<8 then lines[#lines+1]=item.." ×"..tostring(count or 1) end end
 end end
 if #queue==0 then A:Print(A:T("파괴할 회색 잡템이 없습니다."));return end
 self.autoSellPending=nil;self.destroyPrompt=queue
 local function dismiss() if U.destroyPrompt==queue then U.destroyPrompt=nil end end
 StaticPopupDialogs.AZEROTHADMIN_DESTROY_JUNK={text=A:T("회색 잡템 %s칸을 영구 파괴합니까?\n%s"),button1=A:T("파괴"),button2=A:T("취소"),timeout=0,whileDead=true,hideOnEscape=true,preferredIndex=3,
 OnCancel=dismiss,OnHide=dismiss,
 OnAccept=function()
  if U.destroyPrompt~=queue then return end;dismiss()
  if U.selling or InCombatLockdown() or GetCursorInfo() or not U.frame:IsShown() then return end
  U.selling={queue=queue,index=1,sold=0,destroy=true};U:Refresh()
 end}
 StaticPopup_Show("AZEROTHADMIN_DESTROY_JUNK",#queue,table.concat(lines,"\n"))
end
function U:Install()
 if self.installed then return end;self.installed=true
 -- Never replace Blizzard bag globals: Escape calls them from secure UI code.
 local owner=CreateFrame('Frame');self.bindingOwner=owner
 local button=CreateFrame('Button','GMminibarBagToggle',UIParent)
 button:SetScript('OnClick',function() U:Toggle() end)
 button:SetSize(1,1);button:SetPoint('TOPLEFT',UIParent,'TOPLEFT',0,0)
 button:SetAlpha(0);button:EnableMouse(false);button:RegisterForClicks('AnyUp');button:Show()
 local updatingBindings=false
 local function bindings()
  if InCombatLockdown() or updatingBindings then return end
  updatingBindings=true
  local ok,err=pcall(function()
  ClearOverrideBindings(owner)
  if W:DB().unifiedBags==false then return end
  for _,action in ipairs({'OPENALLBAGS','TOGGLEBACKPACK'}) do
   local keys={GetBindingKey(action)}
   for _,key in ipairs(keys) do SetOverrideBindingClick(owner,false,key,'GMminibarBagToggle','LeftButton') end
  end
  end)
  updatingBindings=false
  if not ok then error(err) end
 end
 self.UpdateBindings=bindings
 for _,event in ipairs({'UPDATE_BINDINGS','PLAYER_REGEN_ENABLED','PLAYER_ENTERING_WORLD','BANKFRAME_OPENED','BANKFRAME_CLOSED','MERCHANT_SHOW','MERCHANT_CLOSED','BAG_OPEN'}) do owner:RegisterEvent(event) end
 owner:SetScript('OnEvent',function(_,event)
  bindings()
  if event=='BANKFRAME_OPENED' then U.bankInventoryPending=true;U.bankInventoryDeadline=GetTime()+2
  elseif event=='BANKFRAME_CLOSED' then U.bankInventoryPending=nil end
  if event=='MERCHANT_SHOW' then U.merchantInventoryPending=true;U.merchantInventoryDeadline=GetTime()+2
  elseif event=='MERCHANT_CLOSED' then U.merchantInventoryPending=nil
  elseif event=='BAG_OPEN' and merchant() then U.merchantInventoryPending=true;U.merchantInventoryDeadline=GetTime()+2 end
 end)
 owner:SetScript('OnUpdate',function()
  if U.merchantInventoryPending and not InCombatLockdown() then
   if W:DB().unifiedBags==false or GetTime()>(U.merchantInventoryDeadline or 0) then U.merchantInventoryPending=nil
   elseif merchant() then
    U.merchantInventoryPending=nil;U:Open()
    for i=1,(NUM_CONTAINER_FRAMES or 13) do
     local f=_G['ContainerFrame'..i];local b=f and f:GetID()
     if f and f:IsShown() and b and b>=0 and b<=4 then f:Hide() end
    end
   end
  end
  if not U.bankInventoryPending or InCombatLockdown() then return end
  if W:DB().unifiedBags==false or GetTime()>(U.bankInventoryDeadline or 0) then U.bankInventoryPending=nil;return end
  if not BankFrame or not BankFrame:IsShown() then return end
  U.bankInventoryPending=nil
  U:Open()
  for i=1,(NUM_CONTAINER_FRAMES or 13) do
   local f=_G['ContainerFrame'..i];local bag=f and f:GetID()
   if f and f:IsShown() and bag and bag>=0 and bag<=4 then f:Hide() end
  end
 end)
 bindings()
end

local events=CreateFrame("Frame")
for _,e in ipairs({"PLAYER_LOGIN","PLAYER_MONEY","BAG_UPDATE","UNIT_INVENTORY_CHANGED","PLAYER_EQUIPMENT_CHANGED","ITEM_LOCK_CHANGED","BAG_UPDATE_COOLDOWN","MERCHANT_SHOW","MERCHANT_CLOSED","UI_SCALE_CHANGED","DISPLAY_SIZE_CHANGED"}) do events:RegisterEvent(e) end
events:SetScript("OnEvent",function(_,e,unit) if e=="UNIT_INVENTORY_CHANGED" and unit~="player" then return end;if e=="PLAYER_LOGIN" then U:Install() elseif e=="MERCHANT_CLOSED" then if U.selling and not U.selling.destroy then U.selling=nil end;U.autoSellPending=nil elseif e=="MERCHANT_SHOW" and W:DB().autoSellJunk~=false and not U.destroyPrompt and not U.selling then U.autoSellPending={deadline=GetTime()+10} end;U.dirty=true end)
events:SetScript("OnUpdate",function(_,dt) U.elapsed=U.elapsed+dt;if U.elapsed<.2 then return end;U.elapsed=0;U:AutoSellStep();U:SellStep();if U.dirty then U.dirty=nil;U:Refresh() end end)
