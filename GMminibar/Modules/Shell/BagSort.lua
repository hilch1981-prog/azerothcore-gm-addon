-- Incremental bag sorting. Never touches bank, equipment, mail, or item deletion APIs.
local A=AzerothAdminAC335
local W=A.Workbench
local S={elapsed=0};A.BagSort=S
local function busy()
 if InCombatLockdown() or GetCursorInfo() then return true end
 if A.UnifiedBags and (A.UnifiedBags.selling or A.UnifiedBags.destroyPrompt) then return true end
 for _,name in ipairs({"LootFrame","TradeFrame","MailFrame","AuctionFrame","MerchantFrame","BankFrame"}) do local f=_G[name];if f and f:IsShown() then return true end end
 return false
end
local function identity(bag,slot) return GetContainerItemID(bag,slot) end
local function key(id)
 if not id then return "\255" end
 local name,_,_,level,_,class,subclass=GetItemInfo(id)
 if not name or not class or not subclass then return nil end
 return class.."\031"..subclass.."\031"..name.."\031"..string.format("%010d",id)
end
function S:Request(manual)
 if not GetContainerItemID or not PickupContainerItem then return end
 self.queued=true;self.due=GetTime()+.7;self.manual=manual or false;self.started=nil;self.moves=0
end
function S:Stop(message)
 self.queued=false;self.pending=nil;self.started=nil
 if message and self.manual then A:Print(message) end
 self.manual=false
end
function S:Snapshot()
 local groups={}
 for bag=0,4 do
  local _,family=GetContainerNumFreeSlots(bag);family=family or 0
  local group=groups[family] or {};groups[family]=group
  for slot=1,GetContainerNumSlots(bag) do
   if not (A.UnifiedBags and A.UnifiedBags:IsPinned(bag,slot)) then
   local _,_,locked=GetContainerItemInfo(bag,slot)
   if locked==true or locked==1 then return nil end
   local id=identity(bag,slot);local sortKey=key(id);if not sortKey then return nil end
   group[#group+1]={bag=bag,slot=slot,id=id,key=sortKey}
   end
  end
 end
 return groups
end
function S:Step()
 if not self.queued then return end
 local now=GetTime()
 if self.pending then
  local p=self.pending
  if identity(p.a.bag,p.a.slot)==p.b.id and identity(p.b.bag,p.b.slot)==p.a.id and not GetCursorInfo() then self.pending=nil;self.due=now+.15
  elseif now>p.deadline then self:Stop(A:T("가방 정렬을 중단했습니다. 아이템 잠금이나 이동 상태를 확인한 뒤 다시 눌러주세요.")) end
  return
 end
 if now<(self.due or 0) or busy() then return end
 self.started=self.started or now
 if now-self.started>30 or (self.moves or 0)>400 then self:Stop(A:T("가방 정렬을 중단했습니다. 잠시 후 다시 실행해주세요."));return end
 local groups=self:Snapshot();if not groups then return end
 for _,group in pairs(groups) do
  for i,a in ipairs(group) do
   local best=i
   for j=i+1,#group do if group[j].key<group[best].key then best=j end end
   if best~=i then
    local b=group[best]
    if A.UnifiedBags and (A.UnifiedBags:IsPinned(a.bag,a.slot) or A.UnifiedBags:IsPinned(b.bag,b.slot)) then return end
    -- Pick up the earlier slot unless empty. No same-item swaps or stack merges.
    if not a.id then a,b=b,a end
    local ok=pcall(function()
     PickupContainerItem(a.bag,a.slot)
     local cursorType,cursorID=GetCursorInfo()
     if cursorType~="item" or cursorID~=a.id then return end
     PickupContainerItem(b.bag,b.slot)
     if GetCursorInfo() then PickupContainerItem(a.bag,a.slot) end
    end)
    if GetCursorInfo() then ClearCursor();self:Stop(A:T("가방 정렬이 중단되어 들고 있던 아이템을 돌려놓았습니다."));return end
    if not ok then self:Stop(A:T("현재 아이템을 이동할 수 없습니다."));return end
    self.moves=(self.moves or 0)+1;self.pending={a=a,b=b,deadline=now+3};return
   end
  end
 end
 self:Stop(A:T("가방을 종류별로 정렬했습니다."))
end
local f=CreateFrame("Frame");S.owner=f
for _,e in ipairs({"BAG_UPDATE","GET_ITEM_INFO_RECEIVED","PLAYER_REGEN_ENABLED","LOOT_CLOSED"}) do f:RegisterEvent(e) end
f:SetScript("OnEvent",function()
 if W:DB().autoSortBags then if not S.queued then S:Request(false) elseif not S.pending then S.due=GetTime()+.7 end end
end)
f:SetScript("OnUpdate",function(_,elapsed) S.elapsed=S.elapsed+elapsed;if S.elapsed>=.15 then S.elapsed=0;S:Step() end end)
