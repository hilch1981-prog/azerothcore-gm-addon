local A=AzerothAdminAC335
local W,N,UI,P=A.Workbench,A.NativeUI,A.UI,A.PlayerActions
local isAC=A.interface==30300
-- Scope is part of the command contract, not inferred from the card's label.
local actions={
 {id='repair',name='아이템 수리',icon='Trade_BlackSmithing',group='캐릭터',scope='named',command=isAC and '.gear repair'or '.repairitems'},
 {id='cooldown',name='재사용 시간 초기화',icon='Spell_Nature_TimeStop',group='캐릭터',scope='selected',command='.cooldown'},
 {id='combat',name='전투 중지',icon='Ability_Rogue_Feint',group='캐릭터',scope='named',command='.combatstop'},
 {id='unstuck',name='캐릭터 탈출',icon='INV_Misc_Rune_01',group='캐릭터',scope=isAC and 'named'or 'self',command='.unstuck',suffix=isAC and ' inn'or nil,note=not isAC and '이 MoP 코어의 게임 내 탈출 명령은 본인에게만 적용됩니다.'or nil},
 {id='dismount',name='탈것 내리기',icon='Ability_Mount_RidingHorse',group='캐릭터',scope='self',command='.dismount'},
 {id='demorph',name='외형 복원',icon='Spell_Shadow_Twilight',group='캐릭터',scope='selected',command=isAC and '.morph reset'or '.demorph'},
 {id='waterwalk',name='수면 보행 ON/OFF',icon='Spell_Frost_WindWalkOn',group='이동',scope='self',command='.cheat waterwalk',toggle=true},
 {id='save',name='캐릭터 저장',icon='INV_Misc_Book_09',group='캐릭터',scope='self',command='.save'},
 {id='level1',name='레벨 1 올리기',icon='Spell_Holy_InnerFire',group='성장',scope='named',command='.levelup',suffix=' 1'},
 {id='leveldown1',name='레벨 1 내리기',icon='Spell_Shadow_EnslaveDemon',group='성장',scope='named',command='.levelup',suffix=' -1'},
 {id='level10',name='레벨 10 올리기',icon='Spell_Holy_InnerFire',group='성장',scope='named',command='.levelup',suffix=' 10'},
 {id='leveldown10',name='레벨 10 내리기',icon='Spell_Shadow_EnslaveDemon',group='성장',scope='named',command='.levelup',suffix=' -10'},
 {id='explore',name='지도 개방',icon='INV_Misc_Map_01',group='이동',scope=isAC and 'selected'or 'self',command='.cheat explore 1'},
 {id='taxi',name='비행경로 제한 ON/OFF',icon='Ability_Mount_Gryphon_01',group='이동',scope='selected',command='.cheat taxi',toggle=true},
 {id='money',name='1000골 추가',icon='INV_Misc_Coin_01',group='캐릭터',scope='selected',command='.modify money 10000000'},
 {id='raid10',name='공격대 10인 일반',icon='Achievement_Dungeon_UlduarRaid_Misc_03',group='인스턴스',scope='client',difficulty=isAC and 1 or 3},
 {id='raid25',name='공격대 25인 일반',icon='Achievement_Dungeon_UlduarRaid_Misc_03',group='인스턴스',scope='client',difficulty=isAC and 2 or 4},
 {id='raid10h',name='공격대 10인 영웅',icon='Achievement_Dungeon_UlduarRaid_Misc_03',group='인스턴스',scope='client',difficulty=isAC and 3 or 5},
 {id='raid25h',name='공격대 25인 영웅',icon='Achievement_Dungeon_UlduarRaid_Misc_03',group='인스턴스',scope='client',difficulty=isAC and 4 or 6},
 {id='access',name='인던 출입 조건 해제',icon='INV_Misc_Key_14',group='인스턴스',scope='self',command='.gm on',note='GM 모드로 입장 조건 검사를 통과합니다. 귀속 초기화 기능은 아닙니다.'},
 {id='gmspells',name='GM 스킬 습득',icon='INV_Misc_Gear_01',group='성장',scope='self',command='.learn all gm'},
 {id='crafts',name='모든 전문기술·제작법 배우기',icon='Trade_Engineering',group='성장',scope='selected',selfOnly=isAC,batch='crafts',command='.learn all crafts',note='채집·낚시를 포함한 전문기술 등급과 제작법을 배우고 숙련도를 최대로 설정합니다.'},
 {id='cooking',name='모든 조리법 배우기',icon='INV_Misc_Food_15',group='성장',scope='selected',recipeSkill=185,note='요리 등급과 제작법을 배우고 요리 숙련도를 최대로 설정합니다.'},
 {id='recipes',name='전문기술별 모든 레시피',icon='INV_Misc_Book_08',group='성장',scope='recipes'},
 {id='class',name='내 직업 기술 배우기',icon='Spell_Holy_MagicalSentry',group='성장',scope='self',command=isAC and '.learn all my trainer'or '.learn all my spells'},
 {id='talents',name=isAC and '내 직업 모든 특성 배우기'or '내 직업 모든 특성 주문 배우기',icon='Ability_Marksmanship',group='성장',scope=isAC and 'self'or 'selected',selfOnly=true,batch=not isAC and 'talents'or nil,command=isAC and '.learn all my talents'or nil,note=not isAC and '내 직업의 특성 주문만 개별 습득합니다. 특성 창의 선택 조합을 바꾸는 기능은 아닙니다.'or nil},
 {id='maxskill',name='보유 스킬·숙련도 최대',icon='Trade_BlackSmithing',group='성장',scope='selected',command='.maxskill'},
 {id='summon',name='대상 소환',icon='Spell_Shadow_Twilight',group='이동',scope='peer',command='.summon'},
 {id='appear',name='대상에게 순간이동',icon='Spell_Arcane_TeleportStormWind',group='이동',scope='peer',command='.appear'},
 {id='respawn',name='선택한 몬스터 재생성',icon='Spell_Holy_Resurrection',group='인스턴스',scope='creature',command='.respawn',note='선택한 죽은 몬스터 한 마리만 재생성합니다.'},
}
for i,name in ipairs({'오리지널','불타는 성전','리치왕의 분노','대격변','판다리아의 안개'})do
 if i<=(isAC and 3 or 5)then actions[#actions+1]={id='expansion'..i,name='계정 확장팩 · '..name,icon='INV_Misc_Book_09',group='계정',scope='self',security=3,command='.account addon '..(i-1),note='현재 계정의 확장팩 이용 수준을 변경합니다. 접속한 다른 캐릭터에도 영향을 줍니다.'}end
end
A.UtilityActions=actions
local groups={'전체','캐릭터','성장','이동','인스턴스','계정'}
local recipes={{'대장기술',164},{'가죽세공',165},{'연금술',171},{'재봉술',197},{'기계공학',202},{'마법부여',333},{'보석세공',755},{'주문각인',773},{'요리',185},{'응급치료',129},{'제련술',186}}
local function selfName()return UnitName('player')end
local function targetName()return UnitIsPlayer and UnitIsPlayer('target')and UnitName('target')or nil end
local function status(text)if W.utilityStatus then W.utilityStatus:SetText(text)end end
function W:UtilityNamePrompt(spec)
 if not self.utilityPrompt then
  local f=CreateFrame('Frame',A.WorkbenchAdapter.namespace..'UtilityTarget',UIParent);self.utilityPrompt=f
  f:SetSize(340,188);f:SetPoint('CENTER');f:SetFrameStrata('FULLSCREEN_DIALOG');f:EnableMouse(true);N:Panel(f);f:Hide()
  f.title=N:Text(f,'',302);f.title:SetPoint('TOPLEFT',f,'TOPLEFT',18,-18)
  f.info=N:Text(f,'캐릭터 이름을 입력하세요.',300,true);f.info:SetPoint('TOPLEFT',f,'TOPLEFT',18,-48);f.info:SetHeight(34)
  f.name=N:Edit(f,300);f.name:SetPoint('TOPLEFT',f,'TOPLEFT',18,-87)
  f.apply=N:Button(f,'적용',130,26);f.apply:SetPoint('BOTTOMLEFT',f,'BOTTOMLEFT',18,18)
  local cancel=N:Button(f,'취소',130,26,function()f:Hide()end);cancel:SetPoint('BOTTOMRIGHT',f,'BOTTOMRIGHT',-18,18)
  local click=function()
   local name=A:Trim(f.name:GetText());if not P:ValidName(name)then f.info:SetText('올바른 캐릭터 이름을 입력하세요.');return end
   if f.spec.scope=='selected'and (not targetName()or targetName()~=name)then f.info:SetText('이 명령은 가까이 있는 플레이어를 선택해야 합니다.');return end
   f:Hide();W:ExecuteUtility(f.spec,name)
  end
  P:Attach(f.apply,click,{prepare=function(b)
   local name=A:Trim(f.name:GetText())
   b:SetAttribute('*type1',f.spec and f.spec.scope=='selected'and 'macro'or nil)
   b:SetAttribute('*unit1',nil)
   b:SetAttribute('*macrotext1',P:ValidName(name)and '/targetexact '..name or '')
 end,leftOnly=true})
  -- Named commands, including combatstop, remain usable during combat.
  f.apply:SetScript('OnClick',function()if f.spec.scope~='selected'then click()else A:Print('전투 종료 후 사용할 수 있습니다.',true)end end)
  UISpecialFrames[#UISpecialFrames+1]=f:GetName()
 end
 local f=self.utilityPrompt;f.spec=spec;f.title:SetText(spec.name);f.info:SetText(spec.scope=='selected'and '캐릭터 이름 · 가까이 있는 플레이어를 선택해 적용합니다.'or '캐릭터 이름을 입력하세요.')
 f.name:SetText('');f:Show();f.name:SetFocus();P:Refresh()
end
function W:RecipeChoices(mouse)
 if not self.recipeChoices then
  local f=CreateFrame('Frame',nil,UIParent);self.recipeChoices=f;f:SetSize(380,410);f:SetPoint('CENTER');f:SetFrameStrata('FULLSCREEN_DIALOG');N:Panel(f);f:EnableMouse(true);f:Hide()
  local title=N:Text(f,'모든 레시피 · 전문기술 선택',330);title:SetPoint('TOPLEFT',f,'TOPLEFT',18,-18)
  for i,r in ipairs(recipes)do
   local item=r;local b=N:Choice(f,item[1],344,27,'Interface\\Icons\\INV_Misc_Book_08',function()
     f:Hide();local spec={id='recipe_'..i,name=item[1]..' 모든 레시피',scope='selected',recipeSkill=item[2]}
    if f.other then local name=targetName();if name then W:ExecuteUtility(spec,name)else W:UtilityNamePrompt(spec)end else W:ExecuteUtility(spec,selfName())end
   end);b:SetPoint('TOPLEFT',f,'TOPLEFT',18,-48-(i-1)*29)
   P:Attach(b,b:GetScript('OnClick'),{prepare=function(overlay)overlay:SetAttribute('*unit1',f.other and 'target'or 'player')end})
  end
  local close=N:Button(f,'닫기',100,25,function()f:Hide()end);close:SetPoint('BOTTOM',f,'BOTTOM',0,12)
 end
 self.recipeChoices.other=mouse=='RightButton';self.recipeChoices:Show();P:Refresh()
end
local function recipeCommand(skill)
 local names=A.ProfessionCommandNames or {};local locale=GetLocale()
 local name=names[locale]and names[locale][skill]or names.enUS and names.enUS[skill]
 return name and '.learn all recipes '..name or nil
end
function W:RunUtilityBatch(spec,name)
 if self.utilityBatch then status('현재 진행 중인 습득 요청이 끝난 뒤 다시 사용하세요.');return false end
 local commands={};local own=name==selfName();local skills={};local expected={}
 if spec.batch=='talents'then
  local _,class,id=UnitClass('player')
  if not id then local classes={WARRIOR=1,PALADIN=2,HUNTER=3,ROGUE=4,PRIEST=5,DEATHKNIGHT=6,SHAMAN=7,MAGE=8,WARLOCK=9,MONK=10,DRUID=11};id=classes[class]end
  for _,spell in ipairs(A.ClassTalentSpells and A.ClassTalentSpells[id]or {})do
   expected[#expected+1]=spell
   if not P:Known(spell,true)then commands[#commands+1]='.learn '..spell end
  end
 else
  if spec.recipeSkill then skills[1]=spec.recipeSkill
  else for skill in pairs(A.UtilityProfessionTiers or {})do skills[#skills+1]=skill end;table.sort(skills)end
  for _,skill in ipairs(skills)do
   local tiers=A.UtilityProfessionTiers[skill]or{}
   for _,tier in ipairs(tiers)do
    if not own or not P:Known(tier.spell,true)then commands[#commands+1]='.learn '..tier.spell end
   end
   local highest=tiers[#tiers]
   if highest then commands[#commands+1]='.setskill '..skill..' '..highest.maximum..' '..highest.maximum end
  end
  local final=spec.recipeSkill and recipeCommand(spec.recipeSkill)or spec.command
  if not final then status('이 전문기술의 서버 명칭을 확인할 수 없습니다.');return false end
  commands[#commands+1]=final
 end
 if #commands==0 then status('이미 습득한 주문입니다.');return false end
 local job={name=name,commands=commands,index=0};self.utilityBatch=job
 local function step()
  if W.utilityBatch~=job then return end
  if InCombatLockdown()or targetName()~=job.name then W.utilityBatch=nil;status('대상 또는 전투 상태가 바뀌어 남은 습득 요청을 중단했습니다.');return end
  job.index=job.index+1
  if job.index>#job.commands then
   W.utilityBatch=nil
   if own then P:Track('utilityTraining',function()
    if spec.batch=='talents'then for _,id in ipairs(expected)do if not P:Known(id,true)then return false end end
    else for _,skill in ipairs(skills)do local t=A.UtilityProfessionTiers[skill];local state=A:GetPlayerProfessionState(skill,true);if state.current<t[#t].maximum then return false end end end
    return true
   end,W.utilityStatus)else status('모든 요청을 보냈습니다. 상대방의 습득 상태와 서버 메시지를 확인하세요.')end
   return
  end
  if not A:SendCommand(job.commands[job.index])then W.utilityBatch=nil;status('전송이 실패하여 남은 요청을 중단했습니다.');return end
  status(spec.name..' · '..job.index..' / '..#job.commands)
  A:RunAfter(.2,step)
 end
 step();return true
end
function W:ExecuteUtility(spec,name)
 if A:GetAccountSecurity()<(spec.security or 2)then status('GM 권한이 부족합니다.');return false end
 if spec.scope=='selected'then
  if not targetName()or targetName()~=name then status('적용할 플레이어를 선택하지 못했습니다.');return false end
 end
 if spec.selfOnly and name~=selfName()then status('이 기능은 본인에게만 적용됩니다.');return false end
 if spec.batch or spec.recipeSkill then return self:RunUtilityBatch(spec,name)end
 local command=spec.command
 if spec.scope=='named'or spec.scope=='peer'then
  if not P:ValidName(name)then return false end
  command=command..' '..name..(spec.suffix or '')
 end
 if spec.toggle then
  self.utilityToggle=self.utilityToggle or {};local key=spec.id..':'..(name or selfName())
  local state=self.utilityToggle[key];local enable=state~=true
  if self.pendingUtility and self.pendingUtility.expires>GetTime()then status('앞선 요청의 서버 응답을 확인 중입니다.');return false end
  command=command..(enable and ' on'or ' off')
  self.pendingUtility={spec=spec,key=key,enable=enable,expires=GetTime()+6}
   A:RunAfter(6,function()if W.pendingUtility and W.pendingUtility.key==key then W.pendingUtility=nil;W.utilityToggle[key]=nil;status('서버 상태를 확인하지 못했습니다. 다시 누르면 ON을 요청합니다.');W:RefreshUtilities()end end)
 end
 if spec.scope=='client'then
  local setter=isAC and SetRaidDifficulty or SetRaidDifficultyID
  if not setter then status('현재 클라이언트에서 이 난이도 변경을 지원하지 않습니다.');return false end
  local ok=pcall(setter,spec.difficulty)
  if not ok then status('난이도를 변경하지 못했습니다.');return false end
  local getter=isAC and GetRaidDifficulty or GetRaidDifficultyID
  if getter then P:Track('raidDifficulty',function()return getter()==spec.difficulty end,self.utilityStatus)end
  return true
 end
 local ok=A:SendCommand(command)
 status(ok and (spec.name..' · '..(name or selfName()or '')..' · 서버 응답 확인 중')or '요청을 보내지 못했습니다.')
 if not ok then self.pendingUtility=nil end
 return ok
end
function W:RunUtility(spec,button,mouse)
 mouse=mouse or 'LeftButton'
 if spec.scope=='recipes'then return self:RecipeChoices(mouse)end
 if spec.scope=='creature'then
  if not UnitExists('target')or UnitIsPlayer('target')or not UnitIsDead('target')or (UnitIsUnit and UnitIsUnit('target','pet'))then status('재생성할 죽은 몬스터를 선택하세요.');return false end
  return self:ExecuteUtility(spec)
 end
 if spec.scope=='peer'then local name=targetName();if not name or name==selfName()then return self:UtilityNamePrompt(spec)end;return self:ExecuteUtility(spec,name)end
 if mouse=='RightButton'then
   if spec.selfOnly or spec.scope=='self'or spec.scope=='client'then status('이 기능은 본인에게만 적용됩니다.');return false end
  local name=targetName();if not name then return self:UtilityNamePrompt(spec)end
  return self:ExecuteUtility(spec,name)
 end
 return self:ExecuteUtility(spec,selfName())
end
function W:RefreshUtilities()
 local f=self.utilityPanel;if not f then return end
 local filtered={};for _,spec in ipairs(actions)do if not f.group or f.group=='전체'or spec.group==f.group then filtered[#filtered+1]=spec end end
 local pages=math.max(1,math.ceil(#filtered/18));f.page=math.max(1,math.min(f.page or 1,pages))
 for i,b in ipairs(f.buttons)do
  local spec=filtered[(f.page-1)*18+i];b.spec=spec
  if spec then
   local state=spec.toggle and self.utilityToggle and self.utilityToggle[spec.id..':'..(selfName()or '')]
   b:SetText(spec.name..(state~=nil and (state and '  |cff55bbffON|r'or '  |cffaaaaaaOFF|r')or ''))
   b.icon:SetTexture('Interface\\Icons\\'..spec.icon)
    local hint=(spec.selfOnly or spec.scope=='self'or spec.scope=='client')and '본인 전용'or '왼쪽 클릭: 본인 · 오른쪽 클릭: 선택한 플레이어 / 이름 입력'
   if spec.scope=='peer'then hint='선택한 플레이어에게 적용 · 선택하지 않았으면 이름 입력' end
   N:Hint(b,spec.name,(spec.note and spec.note..'\n'or '')..hint)
   UI:SetEnabled(b,A:GetAccountSecurity()>=(spec.security or 2));b:Show()
  else b:Hide()end
 end
 f.pageText:SetText(#filtered..'개 · '..f.page..' / '..pages)
 UI:SetEnabled(f.prev,f.page>1);UI:SetEnabled(f.next,f.page<pages);P:Refresh()
end
function W:CreateUtilityPanel()
 if self.utilityPanel then return end
 local f=CreateFrame('Frame',A.WorkbenchAdapter.namespace..'Utilities',UIParent);self.utilityPanel=f
 f:SetSize(1080,700);f:SetFrameStrata('DIALOG');f:EnableMouse(true);N:Panel(f);f:Hide()
 local title=N:Text(f,A:L('UX_UTILITIES'),970);title:SetPoint('TOPLEFT',f,'TOPLEFT',18,-17)
 local close=CreateFrame('Button',nil,f,'UIPanelCloseButton');close:SetPoint('TOPRIGHT',f,'TOPRIGHT',-3,-3);close:SetScript('OnClick',function()W:Close()end)
 for i,group in ipairs(groups)do local value=group;local b=N:Button(f,value,120,25,function()f.group=value;f.page=1;W:RefreshUtilities()end);b:SetPoint('TOPLEFT',f,'TOPLEFT',18+(i-1)*128,-48)end
 f.buttons={}
 for i=1,18 do
  local b=N:Choice(f,'',513,48,'Interface\\Icons\\INV_Misc_Book_09');f.buttons[i]=b
  b:SetPoint('TOPLEFT',f,'TOPLEFT',18+(i-1)%2*530,-88-math.floor((i-1)/2)*55)
  b:RegisterForClicks('LeftButtonUp','RightButtonUp')
  local click=function(button,mouse)if button.spec then W:RunUtility(button.spec,button,mouse)end end
  local secure=P:Attach(b,click,{rightTarget=true,prepare=function(overlay,source)
   local needs=source.spec and source.spec.scope=='selected'
   overlay:SetAttribute('*type1',needs and 'target'or nil)
   overlay:SetAttribute('*unit1',needs and 'player'or nil)
  end})
  b:SetScript('OnClick',function(button,mouse)
   if not button.spec then return end
   if button.spec.scope=='selected'then status('전투 종료 후 사용할 수 있습니다.');return end
   click(button,mouse)
  end)
 end
 f.prev=N:Button(f,'이전',90,25,function()f.page=f.page-1;W:RefreshUtilities()end);f.prev:SetPoint('BOTTOMLEFT',f,'BOTTOMLEFT',18,75)
 f.next=N:Button(f,'다음',90,25,function()f.page=f.page+1;W:RefreshUtilities()end);f.next:SetPoint('BOTTOMRIGHT',f,'BOTTOMRIGHT',-18,75)
 f.pageText=N:Text(f,'',400,true);f.pageText:SetPoint('BOTTOM',f,'BOTTOM',0,81);f.pageText:SetJustifyH('CENTER')
 self.utilityStatus=N:Text(f,'왼쪽 클릭: 본인 · 오른쪽 클릭: 상대방',1030,true);self.utilityStatus:SetPoint('BOTTOMLEFT',f,'BOTTOMLEFT',18,20);self.utilityStatus:SetHeight(40)
 f:SetScript('OnDragStart',function()if not W:DB().windowLocked then f:StartMoving()end end)
 f:SetScript('OnDragStop',function()f:StopMovingOrSizing();W:SaveWindowPosition(f);W:AnchorDock();P:Refresh()end)
 self:Watch(f,'favorites');self:RefreshUtilities()
end
local messages=CreateFrame('Frame');messages:RegisterEvent('CHAT_MSG_SYSTEM')
messages:SetScript('OnEvent',function(_,_,message)
 if W.utilityPanel and W.utilityPanel:IsShown()then status(message)end
 local pending=W.pendingUtility;if not pending then return end
 local lower=message:lower();local state
 if pending.spec.id=='waterwalk'and (lower:find('waterwalk',1,true)or lower:find('수면',1,true))then
  if lower:find(' off',1,true)then state=false elseif lower:find(' on',1,true)then state=true end
 elseif pending.spec.id=='taxi'and (lower:find('taxi',1,true)or lower:find('비행',1,true))then
  if lower:find('remove',1,true)or lower:find('제거',1,true)then state=false
  elseif lower:find('given',1,true)or lower:find('give',1,true)or lower:find('추가',1,true)then state=true end
 end
 if state~=nil then W.utilityToggle[pending.key]=state;W.pendingUtility=nil;W:RefreshUtilities()end
end)
