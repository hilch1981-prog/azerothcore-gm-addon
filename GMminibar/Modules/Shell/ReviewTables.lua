local A=AzerothAdminAC335
local W,D,N,C=A.Workbench,A.WorkbenchAdapter,A.NativeUI,A.WorkbenchCatalog
local kinds={all=A:T("전체"),character=A:T("유저 편의"),movement=A:T("이동 편의"),world=A:T("월드 수정"),gm=A:T("GM 관리"),content=A:T("콘텐츠 관리"),server=A:T("서버 운영")}
local roots={account=A:T("계정"),character=A:T("캐릭터"),modify=A:T("능력치 변경"),server=A:T("서버 운영"),reload=A:T("서버 데이터 갱신"),reset=A:T("초기화"),npc=A:T("NPC 관리"),gobject=A:T("오브젝트 관리"),go=A:T("좌표 이동"),tele=A:T("순간이동"),lookup=A:T("정보 조회"),list=A:T("목록 조회"),quest=A:T("퀘스트 관리"),learn=A:T("기술 습득"),unlearn=A:T("기술 삭제"),gm=A:T("GM 설정"),cheat=A:T("편의 설정"),cast=A:T("주문 시전"),aura=A:T("효과 부여"),unaura=A:T("효과 제거"),additem=A:T("아이템 지급"),additemset=A:T("세트 지급"),ban=A:T("접속 차단"),unban=A:T("차단 해제"),kick=A:T("접속 종료"),guild=A:T("길드 관리"),pet=A:T("소환수 관리"),event=A:T("이벤트 관리"),weather=A:T("날씨 변경"),wp=A:T("이동 경로"),waypoint=A:T("이동 경로"),debug=A:T("진단"),ip=A:T("진행 단계"),xp=A:T("경험치"),honor=A:T("명예"),achievement=A:T("업적"),instance=A:T("던전 관리"),bf=A:T("전장 관리"),player=A:T("플레이어 관리"),mail=A:T("우편"),send=A:T("메시지 전송")}
local known={
 [".levelup"]={A:T("레벨 올리기"),A:T("대상 레벨을 입력한 수만큼 조정"),A:T("증가할 레벨 입력"),".levelup 1"},
 [".character level"]={A:T("레벨 지정"),A:T("캐릭터의 레벨을 지정"),A:T("서버 도움말의 대상·레벨 인수 확인"),".help character level"},
 [".modify money"]={A:T("머니 입력"),A:T("선택 대상의 소지금을 조정"),A:T("동 단위 금액 입력 · 1골드=10000동"),".modify money 10000"},
 [".die"]={A:T("대상 처치"),A:T("선택한 대상을 즉시 처치"),A:T("먼저 대상을 선택"),".die"},
 [".revive"]={A:T("부활"),A:T("자신 또는 선택 대상을 부활"),A:T("죽은 대상 선택 또는 대상 해제"),".revive"},
 [".cheat waterwalk on"]={A:T("수면 걷기 켜기"),A:T("물 위를 걸을 수 있게 설정"),A:T("자신 또는 캐릭터 선택"),".cheat waterwalk on"},
 [".cheat waterwalk off"]={A:T("수면 걷기 끄기"),A:T("수면 걷기 설정을 해제"),A:T("자신 또는 캐릭터 선택"),".cheat waterwalk off"},
 [".cheat waterwalk"]={A:T("수면 걷기"),A:T("수면 걷기를 켜거나 해제"),A:T("on 또는 off 입력"),".cheat waterwalk on"},
 [".server restart"]={A:T("서버 재시작"),A:T("지정 시간 후 서버를 재시작"),A:T("초 단위 대기 시간 입력 · 운영 작업"),".help server restart"},
 [".server shutdown"]={A:T("서버 종료"),A:T("지정 시간 후 서버를 종료"),A:T("초 단위 대기 시간 입력 · 운영 작업"),".help server shutdown"},
 [".gm fly on"]={A:T("GM 비행 켜기"),A:T("캐릭터의 GM 비행을 활성화"),A:T("자신 또는 캐릭터 선택"),".gm fly on"},
 [".gm fly off"]={A:T("GM 비행 끄기"),A:T("캐릭터의 GM 비행을 해제"),A:T("착지 후 해제"),".gm fly off"},
 [".additem"]={A:T("아이템 지급"),A:T("아이템 ID와 수량으로 지급"),A:T("아이템 ID와 수량 입력"),".help additem"},
 [".gear repair"]={A:T("장비 수리"),A:T("선택한 캐릭터의 장비를 수리"),A:T("자신 또는 캐릭터 선택"),".gear repair"},
 [".cooldown"]={A:T("재사용 대기 복원"),A:T("재사용 대기 시간을 복원"),A:T("적용할 캐릭터 선택"),".cooldown"},
}

local terms={set=A:T("설정"),get=A:T("조회"),add=A:T("추가"),remove=A:T("제거"),delete=A:T("삭제"),list=A:T("목록"),info=A:T("정보"),create=A:T("생성"),level=A:T("레벨"),money=A:T("소지금"),name=A:T("이름"),password=A:T("비밀번호"),gmlevel=A:T("GM 권한"),addon=A:T("확장팩"),online=A:T("접속 중"),on=A:T("켜기"),off=A:T("끄기"),enable=A:T("활성화"),disable=A:T("비활성화"),start=A:T("시작"),stop=A:T("중지"),all=A:T("전체"),item=A:T("아이템"),items=A:T("아이템"),skill=A:T("기술"),skills=A:T("기술"),spell=A:T("주문"),spells=A:T("주문"),faction=A:T("진영"),reputation=A:T("평판"),honor=A:T("명예"),arena=A:T("투기장"),health=A:T("체력"),hp=A:T("체력"),mana=A:T("마나"),energy=A:T("기력"),rage=A:T("분노"),speed=A:T("속도"),fly=A:T("비행"),flight=A:T("비행"),walk=A:T("걷기"),run=A:T("달리기"),swim=A:T("수영"),waterwalk=A:T("수면 걷기"),god=A:T("무적"),visible=A:T("표시"),invisible=A:T("숨김"),chat=A:T("채팅"),repair=A:T("수리"),save=A:T("저장"),load=A:T("불러오기"),reload=A:T("갱신"),shutdown=A:T("종료"),restart=A:T("재시작"),cancel=A:T("취소"),loot=A:T("전리품"),quest="퀘스트",complete=A:T("완료"),reward=A:T("보상"),cast=A:T("시전"),aura=A:T("효과"),target=A:T("대상"),player=A:T("플레이어"),pet=A:T("소환수"),npc="NPC",creature=A:T("생물"),gobject=A:T("오브젝트"),gameobject=A:T("오브젝트"),model=A:T("외형"),display=A:T("외형"),move=A:T("이동"),tele=A:T("순간이동"),xyz=A:T("좌표"),zone=A:T("지역"),map=A:T("지도"),position=A:T("위치"),guid=A:T("고유번호"),entry=A:T("항목 번호"),id=A:T("번호"),account=A:T("계정"),character=A:T("캐릭터"),guild=A:T("길드"),rank=A:T("등급"),bank=A:T("은행"),mail=A:T("우편"),mute=A:T("채팅 금지"),unmute=A:T("채팅 허용"),kick=A:T("접속 종료"),ban=A:T("차단"),unban=A:T("차단 해제"),reset=A:T("초기화"),debug=A:T("진단"),status=A:T("상태"),phase=A:T("위상"),event=A:T("이벤트"),spawn=A:T("생성 위치"),respawn=A:T("재생성"),distance=A:T("거리"),limit=A:T("제한"),max=A:T("최대"),min=A:T("최소"),rate=A:T("배율"),xp=A:T("경험치"),combat=A:T("전투"),cooldown=A:T("재사용 대기"),damage=A:T("피해"),damageTaken=A:T("받는 피해"),talent=A:T("특성"),talents=A:T("특성"),learn=A:T("습득"),unlearn=A:T("습득 취소"),achievement=A:T("업적"),titles=A:T("칭호"),title=A:T("칭호"),currency=A:T("화폐"),explore=A:T("탐험"),taxi=A:T("비행 경로"),ticket=A:T("문의"),ip=A:T("접속 주소"),bots=A:T("봇"),bot=A:T("봇"),instance=A:T("던전"),difficulty=A:T("난이도"),raid=A:T("공격대"),dungeon=A:T("던전"),check=A:T("검사"),update=A:T("갱신"),reloadall=A:T("전체 갱신")}

function W:CommandInfo(entry)
 local d=entry.definition;local cmd=d.command or "";local k=known[cmd];local root=cmd:match("^%.(%S+)") or ""
 local group=kinds[entry.group] or A:T("GM 관리")
 if root=="server" or root=="reload" then group=A:T("서버 운영") elseif root=="npc" or root=="gobject" or root=="wp" then group=A:T("월드 수정") end
 if k then return {name=k[1],feature=k[2],method=k[3],example=k[4],group=group,command=cmd} end
 local name=entry.label or ""
 if d.serverIndex or name==cmd or not name:find("[\234-\237]") then
  local labels={roots[root] or group};local first=true
  for token in cmd:gmatch("%S+") do if first then first=false elseif terms[token] then labels[#labels+1]=terms[token] end end
  name=table.concat(labels," · ")..A:T(" 명령")
 end
 local feature=name..A:T(" 기능 · 도움말 확인")
 for line in (A:GetConfiguredLocale()=="koKR" and (d.help or "") or ""):gmatch("[^\r\n]+") do
  if line:find("[\234-\237]") and not line:find(A:T("사용법"),1,true) and not line:find("%.[a-z]") then feature=line;break end
 end
 return {name=name,feature=feature,method=cmd~="" and A:T("상단 인수 입력 · 서버 도움말 확인") or A:T("선택 후 실행"),example=cmd~="" and (".help "..cmd:gsub("^%.","")) or A:T("메뉴에서 실행"),group=group,command=cmd}
end
local function text(parent,value,x,y,width)
 local f=N:Text(parent,value,width,true);f:SetHeight(18);f:SetJustifyH("LEFT");f:SetPoint("TOPLEFT",parent,"TOPLEFT",x,y);return f
end
local function tableRows(parent,count,y,widths)
 local rows={}
 for i=1,count do
  local row=CreateFrame("Button",nil,parent);row:SetWidth(684);row:SetHeight(25);row:SetPoint("TOPLEFT",parent,"TOPLEFT",14,y-(i-1)*27);N:Panel(row,true)
  row.cells={};local x=5
  for _,width in ipairs(widths) do row.cells[#row.cells+1]=text(row,"",x,-4,width-8);x=x+width end
  row:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight","ADD");rows[i]=row
 end
 return rows
end
function W:Convenience()
 local out={};local seen={}
 for _,cmd in ipairs({".levelup",".modify money",".die",".revive",".cheat waterwalk on",".cheat waterwalk off",".cheat waterwalk",".gear repair",".cooldown",".gm fly on",".gm fly off"}) do
  for _,e in ipairs(C.entries) do
   local variants=e.variants or {e}
   for _,v in ipairs(variants) do
    if v.definition.command==cmd and not seen[cmd] then out[#out+1]=v;seen[cmd]=true;break end
   end
   if seen[cmd] then break end
  end
 end
 return out
end
function W:CreateCommands()
 local p=CreateFrame("Frame",nil,self.content);p:SetWidth(712);p:SetHeight(460);p:SetPoint("TOPLEFT",self.content,"TOPLEFT",0,0);self.commandPanel=p;p:Hide();self:Watch(p,"commands")
 self.search=N:Edit(p,684);self.search:SetPoint("TOPLEFT",p,"TOPLEFT",14,-8);self.search:SetScript("OnTextChanged",function() W.page=1;W:RefreshCommands() end)
 self.groupButtons={}
 for i,key in ipairs({"all","character","movement","world","gm","content","server"}) do
  local selected=key;local b=N:Button(p,kinds[key],94,23,function() W.group=selected;W.page=1;W:RefreshCommands() end);b:SetPoint("TOPLEFT",p,"TOPLEFT",14+(i-1)*98,-39);self.groupButtons[key]=b
 end
 local x=19;for i,label in ipairs({A:T("명령어"),A:T("기능"),A:T("방법"),A:T("예제 / 도움말")}) do text(p,label,x,-68,({166,166,166,186})[i]-8);x=x+({166,166,166,186})[i] end
 self.rows=tableRows(p,11,-90,{166,166,166,186})
 for _,row in ipairs(self.rows) do row:SetScript("OnClick",function(self) if self.entry then W:Choose(self.entry) end end) end
 self.prev=N:Button(p,"<",45,23,function() W.page=W.page-1;W:RefreshCommands() end);self.prev:SetPoint("TOPLEFT",p,"TOPLEFT",14,-391)
 self.next=N:Button(p,">",45,23,function() W.page=W.page+1;W:RefreshCommands() end);self.next:SetPoint("TOPRIGHT",p,"TOPRIGHT",-14,-391)
 self.pageText=text(p,"",75,-394,540);self.pageText:SetJustifyH("CENTER")
 self.detail=text(p,A:T("명령을 선택하면 전체 한글 안내가 표시됩니다."),14,-422,684);self.detail:SetHeight(34)
 self.empty=text(p,"",14,-120,684)
 N:PageWheel(p,self.prev,self.next);self:RefreshCommands()
end
function W:RefreshCommands()
 if not self.commandPanel then return end
 local source=self.mode=="favorites" and self:Convenience() or C.entries
 local q=(self.search:GetText() or ""):lower();local results={}
 for _,e in ipairs(source or {}) do
  local m=self:CommandInfo(e);local hay=(m.name.." "..m.command.." "..m.feature.." "..m.group):lower()
  if (self.mode=="favorites" or self.group=="all" or self.group==e.group) and (q=="" or hay:find(q,1,true)) then results[#results+1]=e end
 end
 self.results=results;self.pageCount=math.max(1,math.ceil(#results/11));self.page=math.max(1,math.min(self.page or 1,self.pageCount))
 for i,row in ipairs(self.rows) do
  local e=results[(self.page-1)*11+i];row.entry=e
  if e then
   local m=self:CommandInfo(e);local values={m.command~="" and m.command or m.name,m.name,m.method,m.example}
   for j,c in ipairs(row.cells) do c:SetText(values[j]) end
   N:Hint(row,m.name,m.group.."\n"..m.feature..A:T("\n방법: ")..m.method..A:T("\n예제/도움말: ")..m.example);row:Show()
  else row:Hide() end
 end
 self.empty:SetText(#results==0 and A:T("검색 결과가 없습니다.") or "")
 self.pageText:SetText((self.mode=="favorites" and A:T("주요 편의 기능") or A:T("전체 명령")).." · "..#results..A:T("개 · ")..self.page.." / "..self.pageCount..A:T(" · 마우스 휠로 페이지 이동"))
 if self.page>1 then self.prev:Enable() else self.prev:Disable() end;if self.page<self.pageCount then self.next:Enable() else self.next:Disable() end
end
local choose=W.Choose
function W:Choose(entry)
 choose(self,entry);local m=self:CommandInfo(entry);self.detail:SetText(m.name.." · "..m.feature.."\n"..m.method.." | "..m.example)
end
function W:OpenSlotPicker(slot)
 if not C.entries then C:Build(D) end
 if not self.picker then
  local p=CreateFrame("Frame",D.namespace.."SlotPicker",UIParent);self.picker=p;p:SetWidth(712);p:SetHeight(522);p:SetFrameStrata("TOOLTIP");p:SetClampedToScreen(true);p:EnableMouse(true);N:Panel(p);p:Hide()
  text(p,A:T("퀵슬롯 등록 · 클릭은 등록만 / 실행은 미니바 좌클릭"),14,-17,660)
  local close=CreateFrame("Button",nil,p,"UIPanelCloseButton");close:SetPoint("TOPRIGHT",p,"TOPRIGHT",-3,-3);close:SetScript("OnClick",function() p:Hide() end)
  p.search=N:Edit(p,684);p.search:SetPoint("TOPLEFT",p,"TOPLEFT",14,-45);p.search:SetScript("OnTextChanged",function() p.page=1;W:RefreshSlotPicker() end)
  local x=19;for i,label in ipairs({A:T("기능 종류"),A:T("한글명"),A:T("명령어"),A:T("해당 기능")}) do text(p,label,x,-105,({110,140,194,240})[i]-8);x=x+({110,140,194,240})[i] end
  p.sources={}
  for i,label in ipairs({A:T("명령어"),A:T("주요 편의 기능")}) do local source=i;local b=N:Button(p,label,180,23,function() p.source=source;p.page=1;W:RefreshSlotPicker() end);b:SetPoint("TOPLEFT",p,"TOPLEFT",14+(i-1)*188,-75);p.sources[i]=b end
  p.rows=tableRows(p,12,-126,{110,140,194,240})
  for _,row in ipairs(p.rows) do row:SetScript("OnClick",function(self) if self.entry then W:DB().quick[p.slot]=self.entry.key;W:RefreshMiniSlots();p:Hide() end end) end
  p.prev=N:Button(p,"<",45,23,function() p.page=p.page-1;W:RefreshSlotPicker() end);p.prev:SetPoint("BOTTOMLEFT",p,"BOTTOMLEFT",14,36)
  p.next=N:Button(p,">",45,23,function() p.page=p.page+1;W:RefreshSlotPicker() end);p.next:SetPoint("BOTTOMRIGHT",p,"BOTTOMRIGHT",-14,36)
  p.pageText=text(p,"",75,-466,550);p.pageText:SetJustifyH("CENTER")
  local clear=N:Button(p,A:T("슬롯 비우기"),150,22,function() W:DB().quick[p.slot]=nil;W:RefreshMiniSlots();p:Hide() end);clear:SetPoint("BOTTOM",p,"BOTTOM",0,8)
  N:PageWheel(p,p.prev,p.next);UISpecialFrames[#UISpecialFrames+1]=p:GetName()
 end
 local p=self.picker;p.slot=slot;p.page=1;p.source=1;p.search:SetText("");p:ClearAllPoints();p:SetPoint("CENTER",UIParent,"CENTER",0,0);N:Fit(p,712,522,.95);p:Show();self:SuspendForPopup(p);self:RefreshSlotPicker()
end
function W:RefreshSlotPicker()
 local p=self.picker;if not p then return end
 local q=(p.search:GetText() or ""):lower();local result={}
 for i,b in ipairs(p.sources or {}) do b:SetButtonState((p.source or 1)==i and "PUSHED" or "NORMAL") end
 for _,e in ipairs(p.source==2 and self:Convenience() or C.entries) do local m=self:CommandInfo(e);if q=="" or (m.name.." "..m.command.." "..m.feature.." "..m.group):lower():find(q,1,true) then result[#result+1]=e end end
 table.sort(result,function(a,b) local ma,mb=W:CommandInfo(a),W:CommandInfo(b);if ma.group~=mb.group then return ma.group<mb.group end;return ma.command<mb.command end)
 local pages=math.max(1,math.ceil(#result/12));p.page=math.max(1,math.min(p.page or 1,pages))
 for i,row in ipairs(p.rows) do local e=result[(p.page-1)*12+i];row.entry=e
  if e then local m=self:CommandInfo(e);for j,v in ipairs({m.group,m.name,m.command,m.feature}) do row.cells[j]:SetText(v) end;N:Hint(row,m.name,m.group.."\n"..m.feature.."\n"..m.method.."\n"..m.example..A:T("\n클릭: 등록만 합니다."));row:Show() else row:Hide() end
 end
 p.pageText:SetText(A:T("퀵슬롯 ")..p.slot.." · "..#result..A:T("개 · ")..p.page.." / "..pages..A:T(" · 마우스 휠 이동"))
 if p.page>1 then p.prev:Enable() else p.prev:Disable() end;if p.page<pages then p.next:Enable() else p.next:Disable() end
end

local definitions=D.Definitions
function D:Definitions()
 local result={};local removed={OpenCreatureWindow=true,OpenSearchWindow=true,OpenDatabaseWindow=true,kr_creature_search=true}
 for _,entry in ipairs(definitions(self)) do if not removed[entry.definition.action] then result[#result+1]=entry end end
 return result
end
