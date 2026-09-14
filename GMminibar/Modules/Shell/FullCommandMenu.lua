local A=AzerothAdminAC335
local W,D,N,C=A.Workbench,A.WorkbenchAdapter,A.NativeUI,A.WorkbenchCatalog
local oldInfo=W.CommandInfo
local function base(cmd) return (cmd or ""):gsub(" o[nf]+$","") end
function W:CommandInfo(e)
 local cmd=e.definition.command or "";local b=base(cmd)
 local m=A.CommandWorkbook[cmd] or A.CommandWorkbook[b]
 if not m and e.defaultConvenience then
  return {name=A:TranslateLabel(e.label or cmd),feature=A:T("저장된 순간이동 위치로 이동합니다."),method=cmd,group=A:T("순간이동"),command=cmd,example=".help tele"}
 end
 if not m then return oldInfo(self,e) end
 local key=A.commandLocaleKeys and (A.commandLocaleKeys[cmd] or A.commandLocaleKeys[b])
 local localized=A:GetConfiguredLocale()~="koKR" and key
 return {name=localized and A:T(m.group) or m.name,feature=localized and A:L(key) or m.feature,method=m.method,group=A:T(m.group),command=cmd,example=".help "..b:gsub("^%.","")}
end
function W:FullEntries()
 if self.fullEntries then return self.fullEntries end
 local out,by={},{}
 for _,e in ipairs(C.entries) do
  local cmd=e.definition.command or "";local key=cmd~="" and base(cmd) or e.key
  local v=by[key]
  if not v then v={key=e.key,definition=e.definition,label=e.label,group=e.group,category=e.category,aliases=e.aliases,choices={},viewKey=key};by[key]=v;out[#out+1]=v end
  local state=cmd:match(" (on)$") or cmd:match(" (off)$")
  if state then v.choices[state]=e else v.entry=e end
 end
 for _,v in ipairs(out) do
  local cmd=v.viewKey;local m=A.CommandWorkbook[cmd]
  -- Base commands with documented on/off syntax share one row; execution still uses original definitions.
  local syntax=(m and m.method or (v.entry and v.entry.definition.help) or ""):lower()
  if v.entry and (syntax:find("on/off",1,true) or syntax:find("on|off",1,true) or syntax:find("on off",1,true)) then
   for _,state in ipairs({"on","off"}) do if not v.choices[state] then
    local original=v.entry;local def={};for k,value in pairs(original.definition) do def[k]=value end
    def.command=cmd.." "..state;def.requires=nil;def.promptKey=nil;def.action=nil;def.rc8Literal=true
    local e={key="full-state:"..cmd..":"..state,definition=def,label=original.label,group=original.group,category=original.category}
    v.choices[state]=e;C.byKey[e.key]=e
   end end
  end
  v.entry=v.entry or v.choices.on or v.choices.off
  v.key=v.entry.key;v.definition=v.entry.definition
 end
 self.fullEntries=out;return out
end
function W:Convenience()
 local db=self:DB();db.convenience=db.convenience or {}
 local defaults={};for _,cmd in ipairs(A.ConvenienceDefaults) do defaults[cmd]=true end
 local out={}
 for _,v in ipairs(self:FullEntries()) do
  local enabled=db.convenience[v.viewKey]
  if enabled==nil then enabled=defaults[v.viewKey] or v.defaultConvenience or false end
  if enabled then out[#out+1]=v end
 end
 return out
end
local function label(p,s,x,y,w,h)
 local t=N:Text(p,s,w,true);t:SetPoint("TOPLEFT",p,"TOPLEFT",x,y);t:SetHeight(h or 18);t:SetJustifyH("LEFT");return t
end
function W:CreateCommands()
 local p=CreateFrame("Frame",nil,self.content);self.commandPanel=p;p:SetWidth(1052);p:SetHeight(552);p:SetPoint("TOPLEFT",self.content,"TOPLEFT",0,0);p:Hide();self:Watch(p,"commands")
 self.searchLabel=N:Text(p,A:L("SEARCH"),50,true);self.searchLabel:SetPoint("TOPLEFT",p,"TOPLEFT",14,-14);self.search=N:Edit(p,965);self.search:SetPoint("TOPLEFT",p,"TOPLEFT",73,-8);self.search:SetScript("OnTextChanged",function() W.page=1;W.categoryPage=1;W:RefreshCommands() end)
 self.categoryButtons={};self.group="all";self.categoryPage=1
 local cats=CreateFrame("Frame",nil,p);cats:SetWidth(170);cats:SetHeight(408);cats:SetPoint("TOPLEFT",p,"TOPLEFT",14,-40);N:Panel(cats,true);self.categories=cats
 for i=1,15 do local b=N:Button(cats,"",158,24,function(self) W.group=self.category;W.page=1;W:RefreshCommands() end);b:SetPoint("TOPLEFT",cats,"TOPLEFT",6,-6-(i-1)*26);self.categoryButtons[i]=b end
 cats:EnableMouseWheel(true);cats:SetScript("OnMouseWheel",function(_,delta) W.categoryPage=math.max(1,(W.categoryPage or 1)+(delta>0 and -1 or 1));W:RefreshCommands() end)
 self.categoryText=label(p,A:T("분류 · 마우스 휠"),14,-451,170)
 self.rows={}
 for i=1,9 do
  local row=CreateFrame("Button",nil,p);row:SetWidth(848);row:SetHeight(42);row:SetPoint("TOPLEFT",p,"TOPLEFT",190,-40-(i-1)*44);N:Panel(row,true)
  row.icon=row:CreateTexture(nil,"ARTWORK");row.icon:SetWidth(26);row.icon:SetHeight(26);row.icon:SetPoint("LEFT",row,"LEFT",5,0)
  row.cells={label(row,"",36,-4,805),label(row,"",36,-23,805)};row:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight","ADD")
  row:EnableMouse(true);row:RegisterForClicks("LeftButtonUp");row:SetScript("OnClick",function(self) W:ChooseView(self.entry) end);self.rows[i]=row
 end
 self.prev=N:Button(p,"<",35,22,function() W.page=W.page-1;W:RefreshCommands() end);self.prev:SetPoint("TOPLEFT",p,"TOPLEFT",190,-440)
 self.next=N:Button(p,">",35,22,function() W.page=W.page+1;W:RefreshCommands() end);self.next:SetPoint("TOPRIGHT",p,"TOPRIGHT",-14,-440)
 self.pageText=label(p,"",230,-443,750);self.pageText:SetJustifyH("CENTER")
 self.detail=label(p,A:T("명령어를 선택하면 방법과 설명을 확인할 수 있습니다."),190,-468,848,42)
 self.stateButtons={}
 for i,state in ipairs({"on","off"}) do
  local value=state;local b=N:Button(p,state=="on" and A:T("켜기 ON") or A:T("끄기 OFF"),78,24,function() if W.selectedView and W.selectedView.choices[value] then W:Choose(W.selectedView.choices[value]);W:UpdateSelectionActions();if not W.slotTarget then W:Run(W.selectedView.choices[value]) end end end)
  b:SetPoint("TOPLEFT",p,"TOPLEFT",14+(i-1)*84,-488);self.stateButtons[state]=b;b:Hide()
 end
 self.addConvenience=N:Button(p,A:T("편의 기능에 추가"),150,24,function()
  if not W.selectedView then return end
  local key=W.selectedView.viewKey;W:DB().convenience=W:DB().convenience or {};W:DB().convenience[key]=not W:IsConvenience(key);W:RefreshCommands();W:UpdateSelectionActions()
 end);self.addConvenience:SetPoint("TOPLEFT",p,"TOPLEFT",190,-518)
 self.assignSlot=N:Button(p,A:T("퀵슬롯 등록"),145,24,function()
  if W.slotTarget and W.selected then W:DB().quick[W.slotTarget]=(W.selectedView and W.selectedView.choices.on and W.selectedView.choices.off) and ("toggle:"..W.selectedView.viewKey) or W.selected.key;W:RefreshMiniSlots();W.slotTarget=nil;W:UpdateSelectionActions();W.status:SetText(A:T("퀵슬롯에 등록했습니다.")) end
 end);self.assignSlot:SetPoint("TOPLEFT",p,"TOPLEFT",347,-518)
 self.cancelSlot=N:Button(p,A:T("등록 취소"),92,24,function() W.slotTarget=nil;W:UpdateSelectionActions() end);self.cancelSlot:SetPoint("TOPLEFT",p,"TOPLEFT",500,-518)
 self.clearSlot=N:Button(p,A:T("비우기"),92,24,function() if W.slotTarget then W:DB().quick[W.slotTarget]=nil;W:RefreshMiniSlots();W.slotTarget=nil;W:UpdateSelectionActions() end end);self.clearSlot:SetPoint("TOPLEFT",p,"TOPLEFT",598,-518)
 self.empty=label(p,"",195,-70,830)
 N:PageWheel(p,self.prev,self.next)
 local function categoryWheel(_,delta) W.categoryPage=math.max(1,(W.categoryPage or 1)+(delta>0 and -1 or 1));W:RefreshCommands() end
 cats:SetScript("OnMouseWheel",categoryWheel);for _,b in ipairs(self.categoryButtons) do b:EnableMouseWheel(true);b:SetScript("OnMouseWheel",categoryWheel) end
 self:RefreshCommands()
end
function W:IsConvenience(key) for _,v in ipairs(self:Convenience()) do if v.viewKey==key then return true end end return false end
function W:UpdateSelectionActions()
 if not self.assignSlot then return end
 if self.slotTarget then self.assignSlot:Show();self.cancelSlot:Show();self.clearSlot:Show();self.assignSlot:SetText(A:T("퀵슬롯 ")..self.slotTarget..A:T("에 등록")) else self.assignSlot:Hide();self.cancelSlot:Hide();self.clearSlot:Hide() end
 if self.selectedView then self.addConvenience:Enable();self.addConvenience:SetText(self:IsConvenience(self.selectedView.viewKey) and A:T("편의 기능에서 제거") or A:T("편의 기능에 추가")) else self.addConvenience:Disable() end
 for state,b in pairs(self.stateButtons) do if self.selectedView and self.selectedView.choices[state] then b:Show();b:SetButtonState(self.selected==self.selectedView.choices[state] and "PUSHED" or "NORMAL") else b:Hide() end end
 if self.selected then self.assignSlot:Enable() else self.assignSlot:Disable() end
end
function W:ChooseView(v)
 if not v then return end
 self.selectedView=v;self:Choose(v.choices.on or v.entry);self:UpdateSelectionActions()
end
function W:RefreshCommands()
 if not self.commandPanel then return end
 local source=self.mode=="favorites" and self:Convenience() or self:FullEntries();local categories={"all"};local seen={};local matches={};local q=(self.search:GetText() or ""):lower()
 for _,v in ipairs(source) do
  local m=self:CommandInfo(v);local hay=(v.viewKey.." "..m.name.." "..m.feature.." "..m.group):lower()
  if q=="" or hay:find(q,1,true) then
   matches[#matches+1]=v;if not seen[m.group] then seen[m.group]=true;categories[#categories+1]=m.group end
  end
 end
 table.sort(categories,function(a,b) if a==b then return false elseif a=="all" then return true elseif b=="all" then return false else return a<b end end)
 if self.group~="all" and not seen[self.group] then self.group="all" end
 local cp=math.max(1,math.ceil(#categories/15));self.categoryPage=math.min(self.categoryPage or 1,cp)
 for i,b in ipairs(self.categoryButtons) do local cat=categories[(self.categoryPage-1)*15+i];b.category=cat;if cat then b:SetText(cat=="all" and A:T("전체") or cat);b:SetButtonState(cat==self.group and "PUSHED" or "NORMAL");b:Show() else b:Hide() end end
 self.categoryText:SetText(A:T("분류 ")..self.categoryPage.." / "..cp..A:T(" · 휠 이동"))
 local results={};for _,v in ipairs(matches) do if self.group=="all" or self:CommandInfo(v).group==self.group then results[#results+1]=v end end
 self.results=results;self.pageCount=math.max(1,math.ceil(#results/9));self.page=math.max(1,math.min(self.page or 1,self.pageCount))
 for i,row in ipairs(self.rows) do local v=results[(self.page-1)*9+i];row.entry=v
  if v then local m=self:CommandInfo(v);local toggle=v.choices.on and v.choices.off and " [ON/OFF]" or "";row.icon:SetTexture(v.definition.icon or "Interface\\Icons\\INV_Misc_Book_09");row.cells[1]:SetText((v.defaultConvenience and m.command or v.viewKey)..toggle.." · "..m.name);row.cells[2]:SetText(m.feature);N:Hint(row,m.name,m.group.."\n"..m.feature..A:T("\n방법: ")..m.method.."\n"..m.example..A:T("\n클릭: 선택 (실행하지 않음)"));row:SetBackdropBorderColor(self.selectedView==v and 1 or .4,self.selectedView==v and .82 or .4,self.selectedView==v and 0 or .4,1);row:SetBackdropColor(self.selectedView==v and .22 or .025,self.selectedView==v and .16 or .025,.025,1);row:Show() else row:Hide() end
 end
 self.pageText:SetText(#results..A:T("개 · ")..self.page.." / "..self.pageCount..A:T(" · 휠 이동"));self.empty:SetText(#results==0 and A:T("검색 결과가 없습니다.") or "")
 if self.page>1 then self.prev:Enable() else self.prev:Disable() end;if self.page<self.pageCount then self.next:Enable() else self.next:Disable() end
 self:UpdateSelectionActions()
end
function W:OpenSlotPicker(slot)
 self:Navigate("commands");self.slotTarget=slot;self.selectedView=nil;self.selected=nil;self.group="all";self.search:SetText("");self:UpdateSelectionActions();self.status:SetText(A:T("퀵슬롯 ")..slot..A:T(": 명령어 또는 주요 편의 기능에서 선택한 뒤 등록하세요."))
end

function A:ProductName()
 return D:Locale()=="koKR" and "GM MINI BAR[WotLK-아제로스코어]" or "GM MINI BAR[WotLK-AzerothCore]"
end

function A:Print(message,isError)
 if DEFAULT_CHAT_FRAME then DEFAULT_CHAT_FRAME:AddMessage((isError and "|cffff5b45" or "|cffffd24a")..self:ProductName()..":|r "..tostring(self:T(message) or "")) end
end
