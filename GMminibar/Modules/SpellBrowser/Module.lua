local A=AzerothAdminAC335
local S={BATCH=200,PAGE=9,class='ALL',level='ALL'};A.SpellBrowser=S
local N=A.NativeUI
local classes={'WARRIOR','PALADIN','HUNTER','ROGUE','PRIEST','DEATHKNIGHT','SHAMAN','MAGE','WARLOCK','MONK','DRUID'}
local classIcons={"INV_Sword_27","Spell_Holy_SealOfMight","INV_Weapon_Bow_07","INV_ThrowingKnife_04","Spell_Holy_PowerWordShield","Spell_Deathknight_ClassIcon","Spell_Nature_BloodLust","INV_Staff_13","Spell_Nature_Drowsy","Ability_Monk_ChiWave","Ability_Druid_Maul"}
local function lower(v)return string.lower(tostring(v or ''))end
function S:BuildIndex()
 if self.byID then return end
 self.byID={};self.catalog=A.PlayerSpellCatalog or {}
 for _,entry in ipairs(self.catalog)do self.byID[entry.id]=entry end
end
function S:Matches(entry)
 if self.hideKnown and A.PlayerActions:Known(entry.id)then return false end
 if self.class~='PROFESSIONS' and (entry.mask or 0)==0 then return false end
 if self.class=='PROFESSIONS' then if not entry.profession then return false end
 elseif self.class~='ALL' then
  local mask=2^(self.class-1);if math.floor((entry.mask or 0)/mask)%2~=1 then return false end
 end
 local level=entry.level or 0
 if level<(self.minLevel or 0) or level>(self.maxLevel or 999) then return false end
 return self.level=='ALL' or (self.level=='KNOWN_LEVEL' and level<=(UnitLevel('player') or 1)) or (type(self.level)=='number' and level>=self.level and level<self.level+10)
end
function S:Info(id)
 self:BuildIndex();local entry=self.byID[id];if not entry then return end
 local name,rank,icon,a,b,c,d,e,f=GetSpellInfo(id)
 if not name then return end
 local info={id=id,name=name,rank=rank or '',icon=icon,level=entry.level}
 if f~=nil then info.cost,info.power,info.cast,info.minimum,info.maximum=a,c,d,e,f
 else info.cast,info.minimum,info.maximum=a,b,c end
 return info
end
function S:Refresh()
 local f=self.frame;if not f then return end
 local count=#(self.results or {});local pages=math.max(1,math.ceil(count/self.PAGE));self.page=math.max(1,math.min(self.page or 1,pages))
 for i,b in ipairs(f.rows)do
  local row=(self.results or {})[(self.page-1)*self.PAGE+i];b.spell=row
  if row then
   b.icon:SetTexture(row.icon);b.title:SetText(row.name..(row.rank~='' and ' ('..row.rank..')' or ''))
   local level=row.level>0 and tostring(row.level) or A:L('SPY_BASE_TALENT')
   local cast=(tonumber(row.cast) or 0)==0 and A:L('SPY_INSTANT') or A:L('SPY_SECONDS',(tonumber(row.cast) or 0)/1000)
   b.title:SetTextColor(A.PlayerActions:Known(row.id)and .3 or 1,A.PlayerActions:Known(row.id)and .72 or 1,1)
   b.info:SetText((A.PlayerActions:Known(row.id)and '|cff55bbff[습득]|r · 'or '')..'ID: '..row.id..' · '..A:L('SPY_LEARN_LEVEL',level)..' · '..A:L('SPY_CAST',cast));b:Show()
  else b:Hide() end
 end
 f.status:SetText(self.scanning and A:L('SPY_SCAN',self.nextIndex-1,#self.catalog) or A:L('SPY_RESULTS',count,self.page,pages))
 if self.page>1 then f.previous:Enable() else f.previous:Disable() end
 if self.page<pages then f.next:Enable() else f.next:Disable() end
 for _,b in ipairs(f.classes)do b:SetBackdropBorderColor(b.key==self.class and 1 or .4,b.key==self.class and .82 or .4,b.key==self.class and .1 or .4,1);b:SetText(b.key=='ALL' and A:L('ALL') or b.key=='PROFESSIONS' and A:L('PROFESSIONS') or A:L('CLASS_'..classes[b.key])) end

end
function S:Search(query)
 self:BuildIndex();self.query=A:Trim(query or '');self.results={};self.page=1;self.nextIndex=1;self.scanning=false
 self:Select(nil)
 local id=tonumber(self.query:match('^%-%-(%d+)$') or self.query)
 if id then
  local entry=self.byID[id];local row=entry and self:Matches(entry) and self:Info(id);if row then self.results[1]=row end
 else self.scanning=true end
 self:Refresh()
end
function S:Step()
 if not self.scanning or not self.frame or not self.frame:IsShown() then return end
 local last=math.min(#self.catalog,self.nextIndex+self.BATCH-1);local query=lower(self.query)
 for i=self.nextIndex,last do
  local entry=self.catalog[i]
  if self:Matches(entry) then local row=self:Info(entry.id);if row and (query=='' or lower(row.name):find(query,1,true)) then self.results[#self.results+1]=row end end
 end
 self.nextIndex=last+1
 if last==#self.catalog then self.scanning=false;if self.restorePage then self.page=self.restorePage;self.restorePage=nil end;table.sort(self.results,function(a,b)if a.level~=b.level then return a.level<b.level end;if a.name~=b.name then return a.name<b.name end;return a.id<b.id end) end
 self:Refresh()
end
function S:Layout()
 local f=self.frame;if not f then return end
 local width,height=f:GetWidth(),f:GetHeight();local side=170;local middle=math.floor((width-side-58)*.59);local detail=width-side-middle-58
 local function place(b,parent,x,y,w,h)b:ClearAllPoints();b:SetPoint('TOPLEFT',parent,'TOPLEFT',x,-y);if w then b:SetWidth(w)end;if h then b:SetHeight(h)end end
 place(f.classPanel,f,14,43,side,height-61);place(f.listPanel,f,side+24,43,middle,height-61);place(f.detailPanel,f,side+middle+34,43,detail,height-61)
 place(f.search,f.listPanel,12,32,middle-105,26);place(f.searchButton,f.listPanel,middle-85,32,73,26)
 place(f.filterTitle,f.listPanel,12,70,middle-24,20)
 place(f.minLabel,f.listPanel,12,98,83,20);place(f.minimum,f.listPanel,95,93,50,25)
 place(f.maxLabel,f.listPanel,155,98,83,20);place(f.maximum,f.listPanel,238,93,50,25)
 place(f.myLevel,f.listPanel,10,125,24,24);place(f.myLevelText,f.listPanel,36,130,middle-160,20);place(f.reset,f.listPanel,middle-90,125,78,24)
 if f.hideKnown then place(f.hideKnown,f.listPanel,175,125,24,24);place(f.hideKnownText,f.listPanel,201,130,150,20)end
 local rowHeight=math.max(34,math.min(44,math.floor((height-265)/self.PAGE)))
 for i,b in ipairs(f.rows)do place(b,f.listPanel,10,160+(i-1)*rowHeight,middle-20,rowHeight-2);b.title:SetWidth(middle-76);b.info:SetWidth(middle-76)end
 f.status:ClearAllPoints();f.status:SetPoint('BOTTOM',f.listPanel,'BOTTOM',0,42);f.status:SetWidth(middle-20)
 f.previous:ClearAllPoints();f.previous:SetPoint('BOTTOMLEFT',f.listPanel,'BOTTOMLEFT',12,12)
 f.next:ClearAllPoints();f.next:SetPoint('BOTTOMRIGHT',f.listPanel,'BOTTOMRIGHT',-12,12)
 f.detailTitle:SetWidth(detail-74);f.detailInfo:SetWidth(detail-26);f.detailInfo:SetHeight(height-234)
end
function S:Select(row)
 self.selected=row;local f=self.frame
 f.detailIcon:SetTexture(row and row.icon or '')
 f.detailTitle:SetText(row and row.name or A:L('SPY_SELECT'))
 if not row then f.detailInfo:SetText(A:L('SPY_READY'));return end
 local level=row.level>0 and tostring(row.level) or A:L('SPY_BASE_TALENT')
 local cast=(tonumber(row.cast) or 0)==0 and A:L('SPY_INSTANT') or A:L('SPY_SECONDS',(tonumber(row.cast) or 0)/1000)
 local lines={'ID: '..row.id,A:L('SPY_LEARN_LEVEL',level),A:L('SPY_CAST',cast)}
 if row.rank~='' then table.insert(lines,row.rank)end
 if row.minimum and row.maximum then table.insert(lines,A:L('SPY_RANGE',tostring(row.minimum)..'–'..tostring(row.maximum)))end
 if GetSpellDescription then local description=GetSpellDescription(row.id);if description and description~='' then table.insert(lines,'\n'..description)end end
 f.detailInfo:SetText(table.concat(lines,'\n\n'))
end
function S:ApplyFilters()
 local f=self.frame;self.hideKnown=f.hideKnown and f.hideKnown:GetChecked()and true or false;local cap=A.interface==30300 and 80 or 90
 local minimum=tonumber(f.minimum:GetText());local maximum=tonumber(f.maximum:GetText())
 if not minimum or not maximum or minimum<0 or maximum>cap or minimum>maximum then self.scanning=false;self.results={};self.page=1;self:Refresh();self:Select(nil);f.status:SetText(A:L('SPY_LEVEL_BAD'));return false end
 self.minLevel=minimum;self.maxLevel=maximum;self.level=f.myLevel:GetChecked() and 'KNOWN_LEVEL' or 'ALL'
 N:ClearInputFocus(f);self:Search(f.search:GetText());return true
end
function S:Create()
 if self.frame then return end
 local f=A.UI:CreateWindow('spell_spy',A:L('SPY_TITLE'),1080,700);self.frame=f;f.rows={};f.classes={};self.results={}
 local backdrop={};for key,value in pairs(N.window)do backdrop[key]=value end;backdrop.bgFile='Interface\\ChatFrame\\ChatFrameBackground';f:SetBackdrop(backdrop);f:SetBackdropColor(.025,.035,.045,1)
 for _,key in ipairs({'classPanel','listPanel','detailPanel'})do local panel=CreateFrame('Frame',nil,f);N:Panel(panel,true);f[key]=panel end
 local function title(parent,key)local t=N:Text(parent,A:L(key),150,false);t:SetPoint('TOPLEFT',parent,'TOPLEFT',12,-10);A:RegisterLocalizedWidget(t,key);return t end
 title(f.classPanel,'CLASS');title(f.listPanel,'SPY_QUERY');title(f.detailPanel,'SPY_DETAILS')
 f.search=N:Edit(f.listPanel,300);f.searchButton=N:Button(f.listPanel,A:L('SEARCH'),73,26,function()S:ApplyFilters()end)
 f.filterTitle=title(f.listPanel,'SPY_FILTERS')
 f.minimum=N:Edit(f.listPanel,50);f.minimum:SetNumeric(true);f.minimum:SetText('0');f.minimum:SetMaxLetters(2)
 f.maximum=N:Edit(f.listPanel,50);f.maximum:SetNumeric(true);f.maximum:SetText(A.interface==30300 and '80' or '90');f.maximum:SetMaxLetters(2)
 f.minLabel=title(f.listPanel,'SPY_LEVEL_MIN');f.maxLabel=title(f.listPanel,'SPY_LEVEL_MAX')
 f.myLevel=CreateFrame('CheckButton',nil,f.listPanel,'UICheckButtonTemplate');f.myLevelText=N:Text(f.listPanel,A:L('SPY_MY_LEVEL'),180,true)
 f.myLevel:SetScript('OnClick',function()S:ApplyFilters()end)
 f.reset=N:Button(f.listPanel,A:L('SPY_RESET'),78,24,function()f.search:SetText('');f.minimum:SetText('0');f.maximum:SetText(A.interface==30300 and '80' or '90');f.myLevel:SetChecked(false);if f.hideKnown then f.hideKnown:SetChecked(false)end;S.class='ALL';S:ApplyFilters()end)
 for _,e in ipairs({f.search,f.minimum,f.maximum})do e:SetScript('OnEnterPressed',function()S:ApplyFilters()end)end
 local keys={'ALL'};for i=1,11 do if i~=10 or A.interface~=30300 then keys[#keys+1]=i end end;keys[#keys+1]='PROFESSIONS'
 for i,key in ipairs(keys)do
  local icon=type(key)=='number' and ('Interface\\Icons\\'..classIcons[key])or(key=='PROFESSIONS'and 'Interface\\Icons\\INV_Misc_Gear_01'or 'Interface\\Icons\\INV_Misc_Book_09')
  local b=N:Choice(f.classPanel,'',148,35,icon,function(button)S.class=button.key;S:ApplyFilters()end)
  b.key=key;b:SetPoint('TOPLEFT',f.classPanel,'TOPLEFT',11,-38-(i-1)*40);f.classes[#f.classes+1]=b
 end
 f.myClass=N:Button(f.classPanel,A:L('SPY_MY_CLASS'),148,26,function()local _,token=UnitClass('player');for i,c in ipairs(classes)do if c==token then S.class=i;break end end;S:ApplyFilters()end);f.myClass:SetPoint('BOTTOMLEFT',f.classPanel,'BOTTOMLEFT',11,14)
 for i=1,self.PAGE do
  local b=CreateFrame('Button',nil,f.listPanel);N:Panel(b,true)
  b.icon=b:CreateTexture(nil,'ARTWORK');b.icon:SetSize(30,30);b.icon:SetPoint('LEFT',b,'LEFT',5,0)
  b.title=N:Text(b,'',360,true);b.title:SetPoint('TOPLEFT',b,'TOPLEFT',42,-4);b.title:SetHeight(17)
  b.info=N:Text(b,'',360,true);b.info:SetPoint('BOTTOMLEFT',b,'BOTTOMLEFT',42,4);b.info:SetTextColor(.65,.8,.9);b.info:SetHeight(16)
  b:SetHighlightTexture('Interface\\QuestFrame\\UI-QuestLogTitleHighlight')
  b:SetScript('OnEnter',function(button)if not button.spell then return end;local tip=A:BeginHintTooltip(button);tip:SetHyperlink('spell:'..button.spell.id);A:StyleHintTooltip();tip:Show()end)
  b:SetScript('OnLeave',function()A:HideHintTooltip()end)
  b:SetScript('OnClick',function(button)
   if not button.spell then return end;S:Select(button.spell)
   if IsShiftKeyDown() then local chat=ChatEdit_GetActiveWindow and ChatEdit_GetActiveWindow();if chat and chat:IsShown() then chat:Insert((GetSpellLink and GetSpellLink(button.spell.id)) or ('|cff71d5ff|Hspell:'..button.spell.id..'|h['..button.spell.name..']|h|r'))end end
  end);f.rows[i]=b
 end
 f.detailIcon=f.detailPanel:CreateTexture(nil,'ARTWORK');f.detailIcon:SetSize(40,40);f.detailIcon:SetPoint('TOPLEFT',f.detailPanel,'TOPLEFT',12,-43)
 f.detailTitle=N:Text(f.detailPanel,'',200,false);f.detailTitle:SetPoint('TOPLEFT',f.detailPanel,'TOPLEFT',62,-44);f.detailTitle:SetHeight(48)
 f.detailInfo=N:Text(f.detailPanel,'',230,true);f.detailInfo:SetPoint('TOPLEFT',f.detailPanel,'TOPLEFT',13,-102);f.detailInfo:SetJustifyV('TOP')
 f.previous=N:Button(f.listPanel,A:L('PREVIOUS'),80,23,function()S.page=S.page-1;S:Refresh()end)
 f.next=N:Button(f.listPanel,A:L('NEXT'),80,23,function()S.page=S.page+1;S:Refresh()end)
 f.status=N:Text(f.listPanel,'',380,true);f.status:SetHeight(25);f.status:SetJustifyH('CENTER')
 for _,spec in ipairs({{f.searchButton,'SEARCH'},{f.reset,'SPY_RESET'},{f.myLevelText,'SPY_MY_LEVEL'},{f.myClass,'SPY_MY_CLASS'},{f.previous,'PREVIOUS'},{f.next,'NEXT'},{f.aaeTitle,'SPY_TITLE'}})do A:RegisterLocalizedWidget(spec[1],spec[2])end
 A:RegisterLocalizedWidget(f,'SPY_TITLE',function()S:Refresh();S:Select(S.selected)end)
 f:EnableMouseWheel(true);f:SetScript('OnMouseWheel',function(_,delta)S.page=(S.page or 1)-delta;S:Refresh()end)
 f:SetScript('OnUpdate',function()S:Step()end);f:HookScript('OnHide',function()N:ClearInputFocus(f)end)
 f.hideKnown=CreateFrame('CheckButton',nil,f.listPanel,'UICheckButtonTemplate');f.hideKnown:SetSize(24,24)
 f.hideKnownText=N:Text(f.listPanel,'습득한 주문 제외',150,true)
 f.hideKnown:SetScript('OnClick',function()S:ApplyFilters()end)
 f:HookScript('OnSizeChanged',function()S:Layout()end)
 self:Layout();self:Select(nil)
end

function A:OpenSpellBrowser(query)
 if not S.frame then local _,token=UnitClass('player');for i,c in ipairs(classes)do if c==token then S.class=i;break end end end
 S:Create();self.Workbench:Mount(S.frame,'spells');S:Layout()
 if query~=nil or not S.query then S.frame.search:SetText(query or '');S:Search(query or '') end
end
SLASH_GMMINIBARSPELLSPY1='/ss';SLASH_GMMINIBARSPELLSPY2='/gmspell'
SlashCmdList.GMMINIBARSPELLSPY=function(query)
 query=A:Trim(query or '')
 if query=='' and S.frame and S.frame:IsShown() then S.frame:Hide();return end
 if query=='--clear' then query='' end
 A:OpenSpellBrowser(query)
end
