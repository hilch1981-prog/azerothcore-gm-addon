-- Hardware targeting lives in Blizzard's secure action template. The transparent
-- hit buttons are anchored to UIParent coordinates, never to Blizzard quest frames.
local A=AzerothAdminAC335
local P={buttons={},pending={}};A.PlayerActions=P
local function combat()return InCombatLockdown and InCombatLockdown()end
function P:ValidName(name)
 return type(name)=='string' and #name>0 and #name<=48 and not name:find('[%s%c%p%d]')
end
function P:Sync(b)
 if combat()then return end
 local source=b.source
 local enabled=source:IsEnabled()
 local visible=source:IsVisible() and enabled and enabled~=0
 local left,bottom=source:GetLeft(),source:GetBottom()
 visible=visible and left~=nil and bottom~=nil
 if b.gmVisible~=visible then b:SetAttribute('gm-visible',visible and true or false);b.gmVisible=visible end
 if not visible then if b:IsShown()then b:Hide()end;return end
 local scale=source:GetEffectiveScale()/UIParent:GetEffectiveScale()
 local width,height=source:GetWidth()*scale,source:GetHeight()*scale
 left,bottom=left*scale,bottom*scale
 if b.x~=left or b.y~=bottom or b.w~=width or b.h~=height then
  b:ClearAllPoints();b:SetPoint('BOTTOMLEFT',UIParent,'BOTTOMLEFT',left,bottom)
  b:SetSize(width,height);b.x,b.y,b.w,b.h=left,bottom,width,height
 end
 local strata,level=source:GetFrameStrata(),source:GetFrameLevel()+4
 if b:GetFrameStrata()~=strata then b:SetFrameStrata(strata)end
 if b:GetFrameLevel()~=level then b:SetFrameLevel(level)end
 if b.prepare then b.prepare(b,source)end
 if not b:IsShown()then b:Show()end
end
function P:Attach(source,callback,options)
 options=options or {}
 if combat()then
  self.deferred=self.deferred or {};self.deferred[#self.deferred+1]={source,callback,options}
  source:SetScript('OnClick',function()A:Print('전투 종료 후 사용할 수 있습니다.',true)end)
  return nil
 end
 local b=CreateFrame('Button',nil,UIParent,'SecureActionButtonTemplate,SecureHandlerStateTemplate')
 b.source=source;source.gmSecureClick=b;b:EnableMouse(true);b:Hide()
 if options.leftOnly then b:RegisterForClicks('LeftButtonUp')else b:RegisterForClicks('LeftButtonUp','RightButtonUp')end
 b:SetAttribute('*type1','target');b:SetAttribute('*unit1','player')
 if options.rightTarget then b:SetAttribute('*type2','target');b:SetAttribute('*unit2','target')end
 b.prepare=options.prepare
 b:SetScript('PreClick',function()if not combat()and b.prepare then b.prepare(b,source)end end)
 b:SetAttribute('_onstate-combat',[[if newstate == '1' then self:Hide() elseif self:GetAttribute('gm-visible') then self:Show() end]])
 if RegisterStateDriver then RegisterStateDriver(b,'combat','[combat] 1; 0')end
 b:SetScript('PostClick',function(_,mouse)
  if not source:IsVisible() or not source:IsEnabled() or combat()then return end
  if options.leftOnly and mouse~='LeftButton'then return end
  callback(source,mouse)
  P:Sync(b)
 end)
 b:SetScript('OnEnter',function()local f=source:GetScript('OnEnter');if f then f(source)end end)
 b:SetScript('OnLeave',function()local f=source:GetScript('OnLeave');if f then f(source)end end)
 source:SetScript('OnClick',function(s,mouse)
  if combat()then A:Print('이 기능은 전투 종료 후 사용할 수 있습니다.',true);return end
  -- A direct Lua invocation is never a hardware click and cannot select a unit.
  if UnitIsUnit and UnitIsUnit('target','player')then callback(s,mouse or 'LeftButton')end
 end)
 source:HookScript('OnShow',function()P:Sync(b)end)
 source:HookScript('OnHide',function()P:Sync(b)end)
 self.buttons[#self.buttons+1]=b;self:Sync(b)
 return b
end
function P:Refresh()
 if combat()then return end
 local deferred=self.deferred;self.deferred=nil
 for _,item in ipairs(deferred or {})do self:Attach(item[1],item[2],item[3])end
 for _,b in ipairs(self.buttons)do self:Sync(b)end
end
local ticker=CreateFrame('Frame');local elapsed=0
ticker:SetScript('OnUpdate',function(_,dt)
 elapsed=elapsed+dt;if elapsed<.1 then return end;elapsed=0
 P:Refresh()
end)
ticker:RegisterEvent('PLAYER_REGEN_ENABLED');ticker:SetScript('OnEvent',function()P:Refresh()end)

-- Known passives are not consistently returned by IsSpellKnown in 3.3.5a.
function P:RefreshKnown()
 self.known={}
 if GetNumSpellTabs and GetSpellTabInfo and GetSpellBookItemInfo then
  for tab=1,GetNumSpellTabs()do
   local _,_,offset,count=GetSpellTabInfo(tab)
   for slot=(offset or 0)+1,(offset or 0)+(count or 0)do
    local kind,id=GetSpellBookItemInfo(slot,BOOKTYPE_SPELL or 'spell')
    if kind=='SPELL' and id then self.known[id]=true end
   end
  end
 end
 if A.interface==30300 and GetNumTalentTabs and GetNumTalents and GetTalentInfo and GetTalentLink then
  for tab=1,GetNumTalentTabs()do for index=1,GetNumTalents(tab)do
   local _,_,_,_,rank=GetTalentInfo(tab,index)
   local link=GetTalentLink(tab,index);local talent=link and tonumber(link:match('talent:(%d+)'))
   local ids=talent and A.TalentSpellRanks and A.TalentSpellRanks[talent]
   if ids then for i=1,tonumber(rank)or 0 do if ids[i]then self.known[ids[i]]=true end end end
  end end
 end
end
function P:Known(id,exact)
 id=tonumber(id);if not id then return false end
 if not self.known then self:RefreshKnown()end
 if self.serverKnown and self.serverKnown[id]then return true end
 if self.known[id]or(IsSpellKnown and IsSpellKnown(id))or(IsPlayerSpell and IsPlayerSpell(id))then return true end
 if not exact then
  local data=A.SpellRankData and A.SpellRankData[id]
  local family=data and A.SpellBrowser.families and A.SpellBrowser.families[data.family]
  for _,other in ipairs(family or {})do
   if A.SpellRankData[other].rank>=data.rank and self:Known(other,true)then return true end
  end
 end
 return false
end
function P:Track(key,check,label)
 local request={check=check,label=label,started=GetTime()};self.pending[key]=request
 label:SetText('서버 응답 확인 중…')
 A:RunAfter(6,function()
  local p=P.pending[key];if p~=request then return end
  if p.check()then p.label:SetText('|cff55bbff반영 완료|r')
  else p.label:SetText('변경을 확인하지 못했습니다. 서버 메시지를 확인하세요.')end
  P.pending[key]=nil
 end)
end
function P:NotifyKnownChanged()
 for key,p in pairs(self.pending)do if p.check()then p.label:SetText('|cff55bbff반영 완료|r');self.pending[key]=nil end end
 if A.RefreshTrainingViews then A:RefreshTrainingViews()end
end
function P:ForgetKnown(id)
 id=tonumber(id);if not id then return end
 if self.serverKnown then self.serverKnown[id]=nil end
 if self.known then self.known[id]=nil end
 if A.professionKnownCache then A.professionKnownCache[id]=nil end
 if self.knownQueries then self.knownQueries[id]=nil end
end
-- Both core handlers report HasSpell for the selected player, including GM
-- passives which the client spellbook/talent APIs cannot always see.
-- Ask only after a hardware self-targeted action. Never infer success from send.
function P:VerifyKnown(id)
 id=tonumber(id)
 if not id or id<=0 or id~=math.floor(id)or not UnitIsUnit('target','player')then return end
 local owner=UnitGUID('player')
 self.knownRequests=self.knownRequests or {}
 local request={};self.knownRequests[id]=request
 A:RunAfter(.25,function()
  if P.knownRequests[id]~=request then return end
  P.knownRequests[id]=nil
  if not UnitIsUnit('target','player')or UnitGUID('player')~=owner then return end
  P.knownQueries=P.knownQueries or {}
  local query={owner=owner,expires=GetTime()+4};P.knownQueries[id]=query
  if not A:SendCommand('.lookup spell id '..id)then P.knownQueries[id]=nil;return end
  A:RunAfter(4,function()if P.knownQueries[id]==query then P.knownQueries[id]=nil end end)
 end)
end
function P:ReceiveKnown(message)
 if type(message)~='string'or not self.knownQueries then return false end
 local number,linked,flags=message:match('^%s*(%d+)%s*%-%s*|c%x%x%x%x%x%x%x%x|Hspell:(%d+)|h.-|h|r(.*)$')
 local id=tonumber(number);local query=id and self.knownQueries[id]
 if not query or linked~=number then return false end
 self.knownQueries[id]=nil
 if GetTime()>query.expires or UnitGUID('player')~=query.owner or not UnitIsUnit('target','player')then return false end
 -- LANG_KNOWN (31), checked against the core databases. Match only after the
 -- hyperlink: a spell name containing "[known]" is not a learned-state marker.
 local learned=false
 for _,marker in ipairs({'[known]','[습득]','[bekannt]','[已学会]','[conocido]'})do
  if flags:find(marker,1,true)then learned=true;break end
 end
 self.serverKnown=self.serverKnown or {};self.serverKnown[id]=learned or nil
 if A.professionKnownCache then A.professionKnownCache[id]=nil end
 self:RefreshKnown();self:NotifyKnownChanged()
 return true
end
local updates=CreateFrame('Frame')
for _,name in ipairs({'SPELLS_CHANGED','SKILL_LINES_CHANGED','LEARNED_SPELL_IN_TAB','CHARACTER_POINTS_CHANGED','PLAYER_TALENT_UPDATE'})do updates:RegisterEvent(name)end
updates:RegisterEvent('CHAT_MSG_SYSTEM');updates:RegisterEvent('PLAYER_TARGET_CHANGED');updates:RegisterEvent('PLAYER_LOGIN')
updates:SetScript('OnEvent',function(_,event,message)
 if event=='CHAT_MSG_SYSTEM'then P:ReceiveKnown(message);return end
 if event=='PLAYER_TARGET_CHANGED'then
  P.knownQueries={}
  if not UnitIsUnit('target','player')then P.knownRequests={}end
  return
 end
 if event=='PLAYER_LOGIN'then P.serverKnown={};P.knownQueries={};P.knownRequests={}end
 P:RefreshKnown()
 for key,p in pairs(P.pending)do if p.check()then p.label:SetText('|cff55bbff반영 완료|r');P.pending[key]=nil end end
end)
