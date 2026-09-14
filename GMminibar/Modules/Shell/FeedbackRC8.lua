-- RC8 runtime integration. Server outcomes are not inferred from local display state.
local A=AzerothAdminAC335
local W,D,N,C=A.Workbench,A.WorkbenchAdapter,A.NativeUI,A.WorkbenchCatalog
local function send(command) if A.SendCommand then return A:SendCommand(command) else return A:SendNow(command) end end
-- Draw the lock from primitive textures; no additional client MPQ asset is required.
function N:LockIcon(button,locked)
 if not button.lockParts then
  button:SetNormalTexture("");button.lockParts={}
  for i,rect in ipairs({{4,10,14,10},{5,3,3,8},{14,3,3,8},{5,2,12,3},{10,13,2,4}}) do
   local t=button:CreateTexture(nil,"ARTWORK");t:SetPoint("TOPLEFT",button,"TOPLEFT",rect[1],-rect[2]);t:SetWidth(rect[3]);t:SetHeight(rect[4]);button.lockParts[i]=t
  end
 end
 for i,t in ipairs(button.lockParts) do if i==5 then t:SetTexture(.08,.06,.02,1) else t:SetTexture(locked and 1 or .65,locked and .78 or .65,locked and .24 or .65,1) end end
 if locked then button.lockParts[3]:Show() else button.lockParts[3]:Hide() end
end
function W:SaveWindowPosition(f)
 local x,y=f:GetCenter();if x and y then local r=f:GetEffectiveScale()/UIParent:GetEffectiveScale();self:DB().windowPosition={x=x*r,y=y*r} end
end
function W:ApplyWindowPosition(f)
 -- A shared outer footprint; content remains owned by each client module.
 f:SetWidth(1080);f:SetHeight(700);N:Fit(f,1080,700,tonumber(self:DB().scale) or .85)
 f:ClearAllPoints();local p=self:DB().windowPosition
 if p then local r=UIParent:GetEffectiveScale()/f:GetEffectiveScale();f:SetPoint("CENTER",UIParent,"BOTTOMLEFT",p.x*r,p.y*r) else f:SetPoint("CENTER",UIParent,"CENTER",55,0) end
 if not f.rc8Lock then
  f:SetMovable(true);f:RegisterForDrag("LeftButton")
  f:SetScript("OnDragStart",function() if not W:DB().windowLocked then f:StartMoving() end end)
  f:SetScript("OnDragStop",function() f:StopMovingOrSizing();W:SaveWindowPosition(f);W:AnchorDock() end)
  local b=CreateFrame("Button",nil,f);f.rc8Lock=b;b:SetWidth(22);b:SetHeight(22);b:SetPoint("TOPRIGHT",f,"TOPRIGHT",-35,-8)
  N:LockIcon(b,W:DB().windowLocked);b:SetScript("OnClick",function() W:DB().windowLocked=not W:DB().windowLocked;W:UpdateLocks() end)
  N:Hint(b,A:T("창 위치 잠금"),A:T("클릭: 이동 잠금/해제. 이동한 위치는 메뉴를 바꾸거나 재접속해도 유지됩니다."))
 end
 self:UpdateLocks()
end
function W:UpdateLocks()
 local frames={self.frame,self.active};for _,entry in ipairs(D:Frames()) do if entry[1] then frames[#frames+1]=entry[1] end end
 for _,f in ipairs(frames) do
  f:SetMovable(not self:DB().windowLocked)
  if f.rc8Lock then N:LockIcon(f.rc8Lock,self:DB().windowLocked) end
 end
end
-- Toggle slots store the group key, never an ON-only registry id.
function W:ResolveSlot(key)
 if type(key)=="string" and key:sub(1,7)=="toggle:" then
  local target=key:sub(8);for _,v in ipairs(self:FullEntries()) do if v.viewKey==target then return v.choices.on or v.entry,v end end
 end
 local entry=C.byKey[key];if not entry then return nil end
 for _,v in ipairs(self:FullEntries()) do
  if v.choices.on and v.choices.off and (entry==v.entry or entry==v.choices.on or entry==v.choices.off) then return entry,v end
 end
 return entry
end
function W:RunSlot(slot)
 local e,v=self:ResolveSlot(self:DB().quick[slot]);if not e then return end
 self:Create()
 if v and v.choices.on and v.choices.off then
  self.toggleRequested=self.toggleRequested or {};local state=self.toggleRequested[v.viewKey] and "off" or "on"
  e=v.choices[state];if not D:Allowed(e) then return end
  D:Execute(e,"","");self:RefreshMiniSlots()
 else self:Choose(e);self:Run(e) end
end
local execute=D.Execute
function D:Execute(e,args,target)
 local command=e.definition.command or ""
 local state=command:match(" (on)$") or command:match(" (off)$")
 local root=command:gsub(" (on)$",""):gsub(" (off)$","")
 local simple={ [".gm"]=true,[".gm fly"]=true,[".gm visible"]=true,[".gm chat"]=true,[".cheat god"]=true,[".cheat cooldown"]=true,[".cheat power"]=true,[".cheat waterwalk"]=true }
 if state and simple[root] and D:Allowed(e) then
  local def={};for k,v in pairs(e.definition) do def[k]=v end;def.confirm=nil;def.dangerous=nil;def.rc8Literal=true;def.promptKey=nil
  local entry={};for k,v in pairs(e) do entry[k]=v end;entry.definition=def;e=entry
 end
 local result=execute(self,e,args,target)

 return result
end
local function rememberDispatch(_,command)
 if type(command)~="string" then return end
 local root,state=command:match("^(.-) (on)$");if not root then root,state=command:match("^(.-) (off)$") end
 if root then W.toggleRequested=W.toggleRequested or {};W.toggleRequested[root]=state=="on" end
end
if A.SendCommand then hooksecurefunc(A,"SendCommand",rememberDispatch) else hooksecurefunc(A,"SendNow",rememberDispatch) end
local refreshHeader=W.RefreshHeader
function W:RefreshHeader()
 refreshHeader(self)
 if self.security then self.security:SetText(D.client..A:T(" | GM 권한: ")..tostring(A.actualSecurity or (not D.configuredSecurity and D:Security()) or A:T("확인 중"))) end
end
local oldShow=W.Show
function W:Show()
 oldShow(self)
 if not self.securityRequested then self.securityRequested=true;send(".account") end
end
local function sequence(commands)
 A.godSequence=(A.godSequence or 0)+1;local token=A.godSequence
 for i,cmd in ipairs(commands) do local text=cmd;A:RunAfter((i-1)*1.1,function() if A.godSequence==token then send(text) end end) end
end
function A:ToggleGod()
 local db=D:DB();local enabled=not db.godMode
 local ok=self:SendCommand(".cheat god "..(enabled and "on" or "off"))
 if ok then db.godMode=enabled end
 self:RefreshToolbarStates()
 return ok
end
function A:ToggleVisibility()
 if UnitExists('target') and not UnitIsUnit('target','player') then A:Print(A:T('자신을 선택하거나 대상을 해제한 뒤 은신을 사용해 주세요.'));return end
 local db=D:DB();db.gmInvisible=not db.gmInvisible
 send(db.gmInvisible and '.aura 1784' or '.unaura 1784')
 A:Print(db.gmInvisible and A:T('일반 은신 요청 · 전투/공격 시 해제될 수 있습니다.') or A:T('일반 은신 해제 요청'))
 if self.RefreshToolbarStates then self:RefreshToolbarStates() end
end
local install=W.InstallMiniSlots
function W:InstallMiniSlots()
 install(self)
 if not A.toolbar or A.rc8Revive then return end
 A.rc8Revive=CreateFrame("Button",nil,A.toolbar);local b=A.rc8Revive;b:SetWidth(24);b:SetHeight(24);b:SetPoint("LEFT",A.toolbar,"LEFT",530,0);b:SetNormalTexture("Interface\\Icons\\Spell_Holy_Resurrection")
 b:SetScript("OnClick",function() A:ReviveSmart() end);N:Hint(b,A:T("부활"),A:T("사망/유령 상태에서는 자신을 부활합니다. 살아 있을 때는 선택한 플레이어에게 적용합니다."));A.toolbar:SetWidth(561)
end
local events=CreateFrame("Frame")
events:RegisterEvent("CHAT_MSG_SYSTEM");events:RegisterEvent("LOOT_OPENED");events:RegisterEvent("LOOT_CLOSED")
events:SetScript("OnEvent",function(_,event,message)
 if event=="CHAT_MSG_SYSTEM" and type(message)=="string" then
  message=message:gsub("|c%x%x%x%x%x%x%x%x",""):gsub("|r","");local lower=message:lower();if lower:find("account level",1,true) or lower:find("security level",1,true) or message:find("계정 레벨",1,true) or message:find("보안 레벨",1,true) or message:find("계정 등급",1,true) then
   local level=tonumber(message:match("(%d+)%D*$"));if level then A.actualSecurity=level;W:RefreshHeader() end
  end
 elseif event=="LOOT_CLOSED" then A.rc8Loot=nil
 elseif event=="LOOT_OPENED" and GetCVar("autoLootDefault")=="1" then
  A.rc8Loot={next=GetNumLootItems(),due=GetTime()+.15}
 end
end)
events:SetScript("OnUpdate",function()
 local loot=A.rc8Loot;if not loot or GetTime()<loot.due then return end
 if GetCVar("autoLootDefault")~="1" or not LootFrame or not LootFrame:IsShown() then A.rc8Loot=nil;return end
 if loot.next<1 then A.rc8Loot=nil;return end
 -- One pass only; leave bind/roll confirmations and unavailable loot to the game.
 LootSlot(loot.next);loot.next=loot.next-1;loot.due=GetTime()+.15
end)

-- Name the recipient explicitly; do not call protected target functions from timers.
function A:ReviveSmart()
 local name=UnitIsDeadOrGhost("player") and UnitName("player") or (UnitIsPlayer("target") and UnitName("target")) or UnitName("player")
 if not name then return end
 local command=".revive "..name
 if A.SendCommand then A:SendCommand(command,"WHISPER",UnitName("player")) else A:SendNow(command,nil,"WHISPER",UnitName("player")) end
end

function A:CompleteOwnQuest(quest)
 if not quest or not tonumber(quest.id) then return false end
 local name=UnitName("player");if not name then return false end
 local ok=self:SendCommand(".quest complete "..quest.id.." "..name)
 A.QuestLogBridge.dirty=true
 return ok
end

local godFeedback=CreateFrame('Frame');godFeedback:RegisterEvent('CHAT_MSG_SYSTEM')
godFeedback:SetScript('OnEvent',function(_,_,message)
 local state=type(message)=='string' and message:match('Godmode is (%u+)%.')
 if state~='ON' and state~='OFF' then return end
 D:DB().godMode=state=='ON'
 if UIErrorsFrame then UIErrorsFrame:AddMessage(A:T('무적 ')..state,1,.1,.1) end
 if A.RefreshToolbarStates then A:RefreshToolbarStates() end
end)
