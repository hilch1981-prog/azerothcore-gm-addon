local A=AzerothAdminAC335
local W,D,N,B=A.Workbench,A.WorkbenchAdapter,A.NativeUI,A.QuestLogBridge
local create=B.Create
function B:Create()
 create(self)
 self.title:Hide();self.info:Hide();self.objectives:Hide();self.scrollChild:GetParent():Hide();self.buttons.full:Hide()
 if self.compactReady then return end;self.compactReady=true
 self.frame:HookScript("OnUpdate",function(_,elapsed) B.layoutElapsed=(B.layoutElapsed or 0)+elapsed;if B.layoutElapsed>.15 then B.layoutElapsed=0;B:Anchor() end end)
 self.frame:HookScript("OnHide",function() if B.native and B.native:IsShown() and not B.visibilityUpdate then B.native:Hide() end end)
 UISpecialFrames[#UISpecialFrames+1]=self.frame:GetName()
 self.buttons.find=N:Button(self.frame,A:T("조건 찾기"),90,24,function() B:FindCondition() end)
 self.buttons.complete:SetText(A:T("조건 완료"))
 N:Hint(self.buttons.find,A:T("조건 찾기"),A:T("클릭할 때마다 퀘스트 목표 위치를 순서대로 이동합니다.\n아이템을 가진 몬스터·오브젝트 위치도 포함합니다."))
 A:SetupPartyQuestCompanion()
end
function B:Anchor()
 if not self.frame or not self.native then return end
 self.frame:SetParent(self.native);self.frame:SetScale(1);self.frame:ClearAllPoints()
 self.frame:SetPoint('BOTTOMLEFT',self.native,'BOTTOMRIGHT',-6,0)
 self.frame:SetSize(310,132);self.frame:SetBackdropColor(.025,.025,.03,1)
 for i,action in ipairs({'find','complete','start','finish'})do
  local b=self.buttons[action];b:ClearAllPoints();b:SetSize(140,25);b:SetPoint('TOPLEFT',self.frame,'TOPLEFT',10+((i-1)%2)*150,-65-math.floor((i-1)/2)*29)
 end
end
function B:RefreshObjectives()
 if not self.frame then return end
 self.objectives:Hide();self.scrollChild:GetParent():Hide()
 if self.buttons.find then if self.quest then self.buttons.find:Enable() else self.buttons.find:Disable() end end
end
function B:FindCondition()
 local quest=D:SelectedQuest();if not quest then return end
 if self.conditionQuest~=quest.id then self.conditionQuest=quest.id;self.conditionIndex=0;self.conditionTargets={} end
 local objectives=A:GetQuestObjectives(quest) or {};local destinations={}
 if #objectives==1 and (objectives[1].type=="dialogue" or objectives[1].type=="interact") then D:QuestAction("finish",quest);return end
 for _,obj in ipairs(objectives) do
  if D.configuredSecurity then
   for _,target in ipairs(obj.targets or {}) do destinations[#destinations+1]={objective=obj,target=target} end
  else
   local sources=(obj.type=="item" or obj.type=="drop") and A:GetQuestItemDropSources(obj) or {}
   if #sources>0 then for _,source in ipairs(sources) do destinations[#destinations+1]={objective=obj,source=source} end
   else destinations[#destinations+1]={objective=obj} end
  end
 end
 if #destinations==0 then if #objectives==0 then D:QuestAction("finish",quest) elseif A.Print then A:Print(A:T("이 퀘스트의 목표 위치 자료가 없습니다.")) end;return end
 self.conditionIndex=(self.conditionIndex or 0)%#destinations+1;local dest=destinations[self.conditionIndex]
 if dest.target then A.questHelperSelectedQuestID=quest.id;A:GoToQuestTarget(dest.target,dest.objective.description or "")
 elseif dest.source then A:SendNow((dest.source.type=="object" and ".go gameobject id " or ".go creature id ")..dest.source.id)
 else B:ObjectiveAction("move",dest.objective) end
end
local open=D.Open
function D:Open(key)
 if key~="teleports" then A.teleportReturn=nil end
 if key=="quests" then
  if not QuestLogFrame then if A.Print then A:Print(A:T("기본 퀘스트 창을 불러온 뒤 다시 열어주세요.")) end;return end
  W:Close();B:Install();B.dismissed=false;W:DB().questCompanion=true
  QuestLogFrame:Show()
  B:UpdateVisibility();return
 end
 return open(self,key)
end
function W:MapKey(tp) return tp.id and "destination:"..tostring(tp.id)or tostring(tp.name or "").."|"..tostring(tp.command or "") end
function W:IsMapFavorite(tp)
 local db=self:DB();db.mapFavorites=db.mapFavorites or {};local value=db.mapFavorites[self:MapKey(tp)]
 if value~=nil then return value end
 return A.IsTeleportFavorite and A:IsTeleportFavorite(tp) or false
end
function W:ToggleMapFavorite(tp)
 if A.TeleportDestinationByID[tonumber(tp.id)or 0]and A.ToggleTeleportFavorite then
  local db=self:DB();db.mapFavorites=db.mapFavorites or {};db.mapFavorites[self:MapKey(tp)]=nil;return A:ToggleTeleportFavorite(tp)
 end
 local db=self:DB();db.mapFavorites=db.mapFavorites or {};db.mapFavorites[self:MapKey(tp)]=not self:IsMapFavorite(tp)
 if A.RefreshTeleportWindow then A:RefreshTeleportWindow() else A:RefreshTeleportList() end
end
local cities={{"스톰윈드","동부왕국","얼라이언스"},{"아이언포지","동부왕국","얼라이언스"},{"언더시티","동부왕국","호드"},{"실버문","동부왕국","호드"},{"오그리마","칼림도어","호드"},{"썬더 블러프","칼림도어","호드"},{"다르나서스","칼림도어","얼라이언스"},{"엑소다르","칼림도어","얼라이언스"},{"샤트라스","아웃랜드","중립"},{"달라란","노스렌드","중립"}}
function W:MapInfo(tp)
 local kind=({inn='여관',flight='비행 지점',dungeon='던전',raid='공격대',battleground='전장'})[tp.type]or '확인 필요'
 return {self:IsMapFavorite(tp)and '★'or '☆',tp.region_ko or '',kind,tp.zone_ko or '',tp.name_ko or tp.name or '',tp.levelText or '제한 정보 없음',({ALLIANCE='얼라이언스',HORDE='호드',NEUTRAL='중립'})[tp.faction]or '중립'}
end
function W:LayoutTeleports(f)
 if f.rc3List then return end;f.rc3List=true;f:SetWidth(1080);f:SetHeight(700)
 if f.search then f.search:SetWidth(520) elseif A.teleportSearch then A.teleportSearch:SetWidth(640) end
 if f.serverCheck then f.serverCheck:ClearAllPoints();f.serverCheck:SetPoint("TOPRIGHT",f,"TOPRIGHT",-145,-54);f.serverCheck:Hide() end
 if f.progressCheck then f.progressCheck:ClearAllPoints();f.progressCheck:SetPoint("TOPRIGHT",f,"TOPRIGHT",-145,-83) end
 if f.modeText then f.modeText:ClearAllPoints();f.modeText:SetPoint("TOPRIGHT",f,"TOPRIGHT",-25,-111) end
 for _,h in pairs(f.sortHeaders or {}) do h:Hide() end
 local cats=f.categoryButtons or A.teleportCategoryButtons or {}
 for i,b in ipairs(cats) do b:ClearAllPoints();b:SetPoint("TOPLEFT",f,"TOPLEFT",14+(i-1)*98,-122);b:SetWidth(94);b:SetHeight(24) end
 if not D.configuredSecurity then
  local function refresh() A.teleportPage=1;A:RefreshTeleportList() end
  f.regionIndex=f.regionIndex or 1
  local regions={"전체 대륙","동부왕국","칼림도어","아웃랜드","노스렌드"}
  local region=N:Button(f,regions[f.regionIndex],180,23,function(self) f.regionIndex=f.regionIndex%#regions+1;self:SetText(regions[f.regionIndex]);f.regionName=f.regionIndex>1 and regions[f.regionIndex] or nil;refresh() end);region:SetPoint("TOPLEFT",f,"TOPLEFT",14,-86)
  for i,spec in ipairs({{"allList","전체 목록"},{"ownFaction","내 진영만"}}) do
   local key=spec[1];local b=CreateFrame("CheckButton",nil,f,"UICheckButtonTemplate");b:SetWidth(24);b:SetHeight(24);b:SetPoint("TOPRIGHT",f,"TOPRIGHT",-130,-48-(i-1)*30);local t=N:Text(f,spec[2],100,true);t:SetPoint("LEFT",b,"RIGHT",2,0);b:SetChecked(key=="allList");b:SetScript("OnClick",function(self) f[key]=self:GetChecked() and true or false;if key=="allList" and f.allList then f.aaeFavOnly=false end;refresh() end)
  end
 end
 if f.filterCaption then f.filterCaption:Hide() end
 local star=N:Button(f,"지도 즐겨찾기",135,24,function() f.aaeFavOnly=not f.aaeFavOnly;if f.page then f.page=1 else A.teleportPage=1 end;if A.RefreshTeleportWindow then A:RefreshTeleportWindow() else A:RefreshTeleportList() end end);star:SetPoint("TOPRIGHT",f,"TOPRIGHT",-18,-122)
 N:Hint(star,A:T("지도 즐겨찾기"),A:T("행 우클릭: 즐겨찾기 등록/해제\n이 버튼: 전체 목록 / 즐겨찾기 전환"))
 local widths={30,112,68,148,448,114,106};local x=19;f.rc3Headers={}
 for i,label in ipairs({"★","대륙","분류","도시 / 지역","목적지","레벨","진영"}) do
  local column=i;local t=N:Button(f,label,widths[i]-6,18,function()
   if f.rc3Sort==column then f.rc3Ascending=not f.rc3Ascending else f.rc3Sort=column;f.rc3Ascending=true end
   f.page=1;A.teleportPage=1;if A.RefreshTeleportWindow then A:RefreshTeleportWindow() else A:RefreshTeleportList() end
  end);t:SetPoint("TOPLEFT",f,"TOPLEFT",x,-155);f.rc3Headers[i]=t;x=x+widths[i]
 end
 local rows=f.rows or A.teleportButtons
 for i,row in ipairs(rows) do
  row:ClearAllPoints();row:SetPoint("TOPLEFT",f,"TOPLEFT",14,-180-(i-1)*27);row:SetWidth(1052);row:SetHeight(25);row:SetNormalTexture("");N:Panel(row,true)
  for _,key in ipairs({"aaeLabel","pathText","nameText","levelText","factionText"}) do local t=row[key];if t then t:Hide() end end
  row.rc3Cells={};local rx=5
  for _,width in ipairs(widths) do local t=N:Text(row,"",width-6,true);t:SetPoint("TOPLEFT",row,"TOPLEFT",rx,-4);t:SetHeight(18);row.rc3Cells[#row.rc3Cells+1]=t;rx=rx+width end
  local click=row:GetScript("OnClick");row:RegisterForClicks("LeftButtonUp","RightButtonUp")
  row:SetScript("OnClick",function(self,button) if button=="RightButton" then if self.aaeTeleport then W:ToggleMapFavorite(self.aaeTeleport) end else click(self,button) end end)
  row:HookScript("OnLeave",function() row:SetNormalTexture("");N:Panel(row,true) end)
 end
 local footer=f.pageText or A.teleportPageText;if footer then footer:SetWidth(800);footer:SetHeight(30);footer:ClearAllPoints();footer:SetPoint("BOTTOM",f,"BOTTOM",0,15) end
 self:RefreshTeleportCards()
end
function W:RefreshTeleportCards()
 local f=A.teleportFrame;if not f or not f.rc3List then return end
 for _,row in ipairs(f.rows or A.teleportButtons or {}) do if row.aaeTeleport and row.rc3Cells then local values=self:MapInfo(row.aaeTeleport);for i,t in ipairs(row.rc3Cells) do t:SetText(values[i]) end end end
end

-- The toolbar and menu open the same native quest companion.
if A.OpenQuestHelper then A.OpenQuestHelper=function() D:Open("quests") end end
if A.ToggleQuestHelper then A.ToggleQuestHelper=function()
 local native=B:VisibleNative()
 if native then
  for _,name in ipairs({"QuestFrame","QuestLogFrame"}) do
   local frame=_G[name]
   if frame and frame:IsShown() then if HideUIPanel then HideUIPanel(frame) else frame:Hide() end end
  end
  B:UpdateVisibility()
 else D:Open("quests") end
end end

function W:SortMapRows(rows,frame)
 if not frame.rc3Sort then return end
 if frame.rc3Sort==6 then
  local levels={}
  for _,row in ipairs(rows)do local low,high=A.GetTeleportLevelRange(row);levels[row]={low or math.huge,high or math.huge}end
  table.sort(rows,function(a,b)
   local av,bv=levels[a],levels[b]
   -- Unknown ranges stay last in both directions; equal levels have stable names.
   if (av[1]==math.huge)~=(bv[1]==math.huge)then return bv[1]==math.huge end
   for i=1,2 do if av[i]~=bv[i]then
    if frame.rc3Ascending~=false then return av[i]<bv[i]else return av[i]>bv[i]end
   end end
   if a.baseID and a.baseID==b.baseID and a.difficulty~=b.difficulty then return a.difficulty<b.difficulty end
   local an,bn=tostring(a.baseName or a.name_ko or a.name or ''),tostring(b.baseName or b.name_ko or b.name or '')
   if an~=bn then return an<bn end
   return W:MapKey(a)<W:MapKey(b)
  end)
  return
 end
 local values={};for _,row in ipairs(rows) do values[row]=self:MapInfo(row)[frame.rc3Sort] or "" end
 table.sort(rows,function(a,b)
  local av,bv=values[a],values[b]
  if av==bv then
   if a.baseID and a.baseID==b.baseID and a.difficulty~=b.difficulty then return a.difficulty<b.difficulty end
   local an,bn=a.baseName or a.name or "",b.baseName or b.name or "";if an~=bn then return an<bn end
   return W:MapKey(a)<W:MapKey(b) end
  if frame.rc3Ascending then return av<bv else return av>bv end
 end)
end
