local A=AzerothAdminAC335
local B,D,P,N=A.QuestLogBridge,A.WorkbenchAdapter,A.PlayerActions,A.NativeUI
function B:PartyMembers(quest,requireQuest)
 local out={}
 for i=1,4 do
  local unit='party'..i
  if UnitExists(unit)and UnitIsPlayer(unit)and UnitIsConnected(unit)then
   local name=UnitName(unit)
   if P:ValidName(name)and (not requireQuest or IsUnitOnQuest and quest and quest.logIndex and IsUnitOnQuest(quest.logIndex,unit))then
    out[#out+1]={unit=unit,name=name,guid=UnitGUID(unit)}
   end
  end
 end
 return out
end
local function present(member)
 return UnitExists(member.unit)and UnitIsConnected(member.unit)and UnitGUID(member.unit)==member.guid and UnitName(member.unit)==member.name
end
function B:CompletePartyQuest()
 local quest=D:SelectedQuest();if not quest or not A:CanRunCommand('quest_complete')then return false end
 if not A:CompleteOwnQuest(quest)then return false end
 if A.interface==30300 and self.partyApply and self.partyApply:GetChecked()then
  local members=self:PartyMembers(quest,true)
  for _,member in ipairs(members)do if present(member)then A:SendCommand('.quest complete '..quest.id..' '..member.name)end end
  A:Print('본인과 해당 퀘스트를 가진 파티원 '..#members..'명에게 조건 완료를 요청했습니다.')
 end
 return true
end
function A:SetupPartyQuestCompanion()
 if B.partyApply then return end
 local check=CreateFrame('CheckButton',nil,B.frame,'UICheckButtonTemplate');B.partyApply=check
 check:SetSize(24,24);check:SetPoint('TOPLEFT',B.frame,'TOPLEFT',176,-35);check:SetChecked(false)
 local label=N:Text(B.frame,'파티원 적용',105,true);label:SetPoint('LEFT',check,'RIGHT',1,0)
 N:Hint(check,'파티원 적용','이동: 본인 도착 확인 후 같은 위치로 파티원 소환\n조건 완료: 해당 퀘스트를 가진 접속 중인 파티원만 적용')
 check:SetScript('OnClick',function()B.partyMove=nil;P:Refresh()end)
 P:Attach(B.buttons.complete,function()
  if A.interface~=30300 and B.partyApply:GetChecked()then
   A:Print('본인과 확인된 파티원에게 조건 완료를 요청했습니다.');B.dirty=true
  else B:CompletePartyQuest()end
 end,{leftOnly=true,prepare=function(overlay)
  local quest=D:SelectedQuest()
  if A.interface~=30300 and B.partyApply:GetChecked()and quest and A:CanRunCommand('quest_complete')then
   local lines={'/target [@player]','/say .quest complete '..quest.id}
   for _,member in ipairs(B:PartyMembers(quest,true))do
    lines[#lines+1]='/target [@'..member.unit..',exists]'
    lines[#lines+1]='/say .quest complete '..quest.id
   end
   lines[#lines+1]='/target [@player]'
   overlay:SetAttribute('*type1','macro');overlay:SetAttribute('*macrotext1',table.concat(lines,'\n'))
  else overlay:SetAttribute('*type1','target');overlay:SetAttribute('*unit1','player');overlay:SetAttribute('*macrotext1',nil)end
 end})
 -- The party macro can run only through Blizzard's secure hardware handler.
 B.buttons.complete:SetScript('OnClick',function()
  if A.interface~=30300 and B.partyApply:GetChecked()then return end
  if not InCombatLockdown()and UnitIsUnit('target','player')then B:CompletePartyQuest()end
 end)
end
function A:ReadPlayerWorldPosition()
 if not GetPlayerMapPosition or not GetCurrentMapAreaID or not SetMapToCurrentZone then return end
 if WorldMapFrame and WorldMapFrame:IsShown()then return end
 local previous=GetCurrentMapAreaID();local floor=GetCurrentMapDungeonLevel and GetCurrentMapDungeonLevel()
 SetMapToCurrentZone()
 local id=GetCurrentMapAreaID();local x,y=GetPlayerMapPosition('player');local rect=self.WorldMapRects[id]
 if previous and previous>0 and SetMapByID then SetMapByID(previous);if floor and SetDungeonMapLevel then SetDungeonMapLevel(floor)end end
 if not rect or not x or not y or x==0 and y==0 then return end
 return {map=rect.map,x=rect.x1+y*(rect.x2-rect.x1),y=rect.y1+x*(rect.y2-rect.y1)}
end
function B:BeginPartyMove(target)
 self.partyMove=nil
 if not self.partyApply or not self.partyApply:GetChecked()then return end
 local members=self:PartyMembers(nil,false);if #members==0 then return end
 if not target or not tonumber(target.m)or not tonumber(target.x)or not tonumber(target.y)then
  A:Print('본인 이동만 요청합니다. 파티 이동을 확인할 목적지 좌표가 없습니다.',true);return
 end
 self.partyMove={target={map=tonumber(target.m),x=target.x,y=target.y},members=members,started=GetTime(),origin=A:ReadPlayerWorldPosition()}
end
function B:CheckPartyMove()
 local job=self.partyMove;if not job then return end
 if GetTime()-job.started>12 then self.partyMove=nil;A:Print('본인 도착이 확인되지 않아 파티원 이동을 중단했습니다.',true);return end
 if GetTime()-job.started<.5 or A.loadingWorld then return end
 local pos=A:ReadPlayerWorldPosition();if not pos then return end
 local target=job.target
 local arrived=pos.map==target.map and (pos.x-target.x)^2+(pos.y-target.y)^2<20^2
 local moved=job.worldChanged or job.origin and (job.origin.map~=pos.map or (pos.x-job.origin.x)^2+(pos.y-job.origin.y)^2>1)
 if not arrived or not moved then return end
 self.partyMove=nil
 local count=0
 for _,member in ipairs(job.members)do if present(member)then
  if A:SendCommand('.summon '..member.name)then count=count+1 end
 end end
 A:Print('본인 도착 확인 · 파티원 '..count..'명에게 같은 위치로 이동을 요청했습니다.')
end
local watcher=CreateFrame('Frame');local elapsed=0
watcher:SetScript('OnUpdate',function(_,dt)elapsed=elapsed+dt;if elapsed<.3 then return end;elapsed=0;B:CheckPartyMove()end)
for _,event in ipairs({A.interface==30300 and 'PARTY_MEMBERS_CHANGED'or 'GROUP_ROSTER_UPDATE','PLAYER_ENTERING_WORLD','CHAT_MSG_SYSTEM'})do watcher:RegisterEvent(event)end
watcher:SetScript('OnEvent',function(_,event,message)
 if not B.partyMove then return end
 if event=='PLAYER_ENTERING_WORLD'then B.partyMove.worldChanged=true
 elseif event=='CHAT_MSG_SYSTEM'and type(message)=='string'then
  local lower=message:lower()
  if lower:find('not found',1,true)or lower:find('cannot teleport',1,true)or lower:find('찾을 수 없',1,true)or lower:find('이동할 수 없',1,true)or lower:find('unknown command',1,true)then B.partyMove=nil end
 else
  for _,member in ipairs(B.partyMove.members)do if not present(member)then B.partyMove=nil;break end end
 end
end)
