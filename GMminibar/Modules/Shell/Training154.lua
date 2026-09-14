local A=AzerothAdminAC335
local S,N,UI=A.SpellBrowser,A.NativeUI,A.UI
local function known(id)return A.PlayerActions:Known(id)end
local index=S.BuildIndex
function S:BuildIndex()
 index(self)
 if self.families then return end
 self.families={}
 for id,rank in pairs(A.SpellRankData or {})do
  if self.byID[id]then
   self.families[rank.family]=self.families[rank.family]or{}
   table.insert(self.families[rank.family],id)
  end
 end
 for _,ids in pairs(self.families)do table.sort(ids,function(a,b)return A.SpellRankData[a].rank<A.SpellRankData[b].rank end)end
end
function S:SelectedRanks()
 if not self.selected then return {}end
 local rank=A.SpellRankData and A.SpellRankData[self.selected.id]
 return rank and self.families[rank.family] or {self.selected.id}
end
function S:RefreshTraining()
 local f=self.frame;if not f or not f.learn then return end
 local row=self.selected;local ranks=self:SelectedRanks();local current
 for _,id in ipairs(ranks)do if known(id)then current=id end end
 local currentInfo=current and self:Info(current);local rankData=current and A.SpellRankData[current];local currentText=currentInfo and currentInfo.rank~=''and currentInfo.rank or rankData and A:L('UX_RANK_NUMBER',rankData.rank)or A:L('UX_SINGLE_RANK')
 f.currentRank:SetText('주문 단계 · '..(current and A:L('UX_CURRENT_RANK',currentText)or '현재 습득 단계 없음'))
 f.learn:SetText(A:L(row and known(row.id)and 'UX_KNOWN' or 'UX_LEARN_SPELL'))
 UI:SetEnabled(f.learn,row and not known(row.id)and A:CanRunCommand('learn')or false)
 local pages=math.max(1,math.ceil(#ranks/#f.rankRows));self.rankPage=math.max(1,math.min(self.rankPage or 1,pages))
 for i,b in ipairs(f.rankRows)do
  local id=ranks[(self.rankPage-1)*#f.rankRows+i];b.spellID=id
  if id then
   local info=self:Info(id);local data=A.SpellRankData and A.SpellRankData[id]
   local rank=info and info.rank~=''and info.rank or data and A:L('UX_RANK_NUMBER',data.rank)or A:L('UX_SINGLE_RANK')
   local text=rank..' · ID '..id
   if id==current then text='|cff55bbff'..text..'  '..A:L('UX_KNOWN')..'|r'end
   b:SetText(text);b:SetBackdropBorderColor(id==current and .2 or .52,id==current and .65 or .48,id==current and 1 or .39,1)
   b.aaeLabel:SetShadowColor(0,id==current and .35 or 0,id==current and .7 or 0,1);b.aaeLabel:SetShadowOffset(1,-1)
   b:Show()
  else b:Hide()end
 end
 f.rankPage:SetText(self.rankPage..' / '..pages)
 UI:SetEnabled(f.rankPrev,self.rankPage>1);UI:SetEnabled(f.rankNext,self.rankPage<pages)
end
function S:LayoutTraining()
 local f=self.frame;if not f.learn then return end
 local w,h=f.detailPanel:GetWidth(),f.detailPanel:GetHeight()
 f.detailInfo:SetHeight(158)
 f.learn:ClearAllPoints();f.learn:SetPoint('TOPLEFT',f.detailPanel,'TOPLEFT',13,-268);f.learn:SetWidth(w-26)
 f.learnStatus:SetWidth(w-26)
 f.currentRank:SetWidth(w-26)
 for i,b in ipairs(f.rankRows)do
  b:ClearAllPoints();b:SetPoint('TOPLEFT',f.detailPanel,'TOPLEFT',13,-379-(i-1)*31);b:SetWidth(w-26)
 end
end
local create=S.Create
function S:Create()
 if self.frame then return end
 create(self);local f=self.frame
 f.learn=N:Button(f.detailPanel,A:L('UX_LEARN_SPELL'),220,27,function()
  if not S.selected then return end
  local id=S.selected.id;local ok=A:LearnOwnSpell(id);if ok then A.PlayerActions:Track('spell',function()return known(id)end,f.learnStatus)else f.learnStatus:SetText(known(id)and '이미 습득한 주문입니다.'or A:L('UX_REQUEST_FAILED'))end
 end)
 A.PlayerActions:Attach(f.learn,f.learn:GetScript('OnClick'))
 f.learnStatus=N:Text(f.detailPanel,'',230,true);f.learnStatus:SetHeight(42);f.learnStatus:SetPoint('TOPLEFT',f.detailPanel,'TOPLEFT',13,-302)
 f.currentRank=N:Text(f.detailPanel,'',230);f.currentRank:SetPoint('TOPLEFT',f.detailPanel,'TOPLEFT',13,-350);f.currentRank:SetHeight(23);f.currentRank:SetTextColor(.3,.7,1);f.currentRank:SetShadowColor(0,.3,.65,1)
 f.rankRows={}
 for i=1,6 do
  local b=N:Choice(f.detailPanel,'',230,28,nil,function(button)
   local row=button.spellID and S:Info(button.spellID);if row then S:Select(row,true)end
  end);f.rankRows[i]=b
 end
 f.rankPrev=N:Button(f.detailPanel,'<',35,22,function()S.rankPage=S.rankPage-1;S:RefreshTraining()end);f.rankPrev:SetPoint('BOTTOMLEFT',f.detailPanel,'BOTTOMLEFT',13,15)
 f.rankNext=N:Button(f.detailPanel,'>',35,22,function()S.rankPage=S.rankPage+1;S:RefreshTraining()end);f.rankNext:SetPoint('BOTTOMRIGHT',f.detailPanel,'BOTTOMRIGHT',-13,15)
 f.rankPage=N:Text(f.detailPanel,'',80,true);f.rankPage:SetPoint('BOTTOM',f.detailPanel,'BOTTOM',0,19);f.rankPage:SetJustifyH('CENTER')
 f:HookScript('OnSizeChanged',function()S:LayoutTraining()end)
 self:LayoutTraining();self:RefreshTraining()
end
local selectSpell=S.Select
function S:Select(row,preservePage)
 selectSpell(self,row)
 if not preservePage then self.rankPage=1 end
 if self.frame.learnStatus and not preservePage then self.frame.learnStatus:SetText('')end
 self:RefreshTraining()
end
local layout=S.Layout
function S:Layout()layout(self);self:LayoutTraining()end

-- Profession overview replaces the empty recipe detail until a recipe is selected.
local function panel()
 local f=A.professionFrame;if not f or f.trainingPanel then return end
 local p=CreateFrame('Frame',nil,f.detailPanel);f.trainingPanel=p;p:SetAllPoints(f.detailPanel);p:SetFrameLevel(f.detailPanel:GetFrameLevel()+5);N:Panel(p,true);p:Hide()
 f.detailPanel:HookScript('OnSizeChanged',function()A:RefreshProfessionTraining()end)
 p.title=N:Text(p,A:L('UX_PROF_TRAINING'),300);p.title:SetPoint('TOPLEFT',p,'TOPLEFT',12,-12)
 p.state=N:Text(p,'',300,true);p.state:SetPoint('TOPLEFT',p,'TOPLEFT',12,-42);p.state:SetHeight(35)
 p.status=N:Text(p,'',300,true);p.status:SetPoint('BOTTOMLEFT',p,'BOTTOMLEFT',12,14);p.status:SetHeight(40)
 p.rows={}
 local count=A.interface==30300 and 6 or 8
 for i=1,count do
  local tier=i;local r=CreateFrame('Frame',nil,p);N:Panel(r,true);p.rows[i]=r
  r.label=N:Text(r,'',280,true);r.label:SetPoint('TOPLEFT',r,'TOPLEFT',8,-6);r.label:SetHeight(20)
  r.learn=N:Button(r,A:L('UX_LEARN_TIER'),118,24,function()A:TrainProfessionTier(tier,false)end);r.learn:SetPoint('BOTTOMLEFT',r,'BOTTOMLEFT',8,6)
  r.max=N:Button(r,A:L('UX_MAX_SKILL'),118,24,function()A:TrainProfessionTier(tier,true)end);r.max:SetPoint('BOTTOMRIGHT',r,'BOTTOMRIGHT',-8,6)
  A.PlayerActions:Attach(r.learn,r.learn:GetScript('OnClick'));A.PlayerActions:Attach(r.max,r.max:GetScript('OnClick'))
  A:RegisterLocalizedWidget(r.max,'UX_MAX_SKILL')
 end
 local returnButton=N:Button(f.detailPanel,A:L('UX_PROF_TRAINING'),150,24,function()A:ShowProfessionTraining()end);f.trainingReturn=returnButton
 returnButton:SetPoint('TOPRIGHT',f.detailPanel,'TOPRIGHT',-10,-4);returnButton:Hide();A:RegisterLocalizedWidget(returnButton,'UX_PROF_TRAINING')
 A:RegisterLocalizedWidget(p.title,'UX_PROF_TRAINING')
end
function A:ShowProfessionTraining()
 local f=self.professionFrame;if not f or not f.selectedProfession then return end
 panel();self:ClearProfessionDetail();f.trainingPanel:Show();f.trainingReturn:Hide();self:RefreshProfessionTraining()
end
function A:RefreshProfessionTraining()
 local f=self.professionFrame;local p=f and f.trainingPanel
 if not p or not p:IsShown()or not f.selectedProfession then return end
 local id=f.selectedProfession.id;local state=self:GetPlayerProfessionState(id,true);local data=self.ProfessionTraining[id]or{}
 local name=self:TranslateLabel(f.selectedProfession.name_ko or f.selectedProfession.name or tostring(id))
 p.state:SetText(name..'  |cff55bbff'..(state.known and state.current..' / '..state.maximum or self:L('PROF_NOT_LEARNED_SHORT')..' 0 / 0')..'|r')
 local width=f.detailPanel:GetWidth();local step=math.min(70,math.floor((f.detailPanel:GetHeight()-134)/#p.rows))
 p.state:SetWidth(width-24);p.status:SetWidth(width-24)
 for i,r in ipairs(p.rows)do
  local tier=data[i];r:SetPoint('TOPLEFT',p,'TOPLEFT',10,-82-(i-1)*step);r:SetSize(width-20,step-5)
  r.label:SetWidth(width-38);r.learn:SetWidth((width-46)/2);r.max:SetWidth((width-46)/2)
  if tier then
   local tierName=self:L(self.ProfessionTierOrder[i].label)
   r.label:SetText(tierName..'  '..math.min(state.current,tier.maximum)..' / '..tier.maximum)
   local reached=state.known and state.maximum>=tier.maximum
   r.label:SetTextColor(reached and .3 or 1,reached and .7 or .82,reached and 1 or .2)
   local previous=i==1 or state.known and state.maximum>=data[i-1].maximum
   local required=tier.required or 0
   r.learn:SetText(reached and '습득 완료' or previous and '등급 습득' or '이전 등급 필요')
   if not reached and previous and state.current<required then r.learn:SetText('숙련 '..required..' 필요')end
   UI:SetEnabled(r.learn,not reached and previous and state.current>=required and self:CanRunCommand('learn'))
   UI:SetEnabled(r.max,reached and state.current<tier.maximum and self:CanRunCommand('learn'))
   r:Show()
  else r:Hide()end
 end
end
function A:TrainProfessionTier(index,maximize)
 local f=self.professionFrame;local id=f and f.selectedProfession and f.selectedProfession.id
 local tier=id and self.ProfessionTraining[id]and self.ProfessionTraining[id][index]
 if not tier or not self:CanRunCommand('learn')then return false end
 local state=self:GetPlayerProfessionState(id,true);local ok=false
 if maximize then
  if not state.known or state.maximum<tier.maximum or not self:SelectSelfForUtility()then return false end
  -- Never downgrade the current value or capacity when clicking an earlier tier.
  ok=self:SendCommand('.setskill '..id..' '..math.max(math.min(state.current,state.maximum),tier.maximum)..' '..state.maximum)
 else
  local previous=index==1 or state.known and state.maximum>=self.ProfessionTraining[id][index-1].maximum
  if state.maximum>=tier.maximum or not previous or state.current<(tier.required or 0)then return false end
  ok=self:LearnOwnSpell(tier.spell)
 end
 if ok then self.PlayerActions:Track('profession',function()
  local current=A:GetPlayerProfessionState(id,true)
  return maximize and current.current>=tier.maximum or not maximize and current.maximum>=tier.maximum
 end,f.trainingPanel.status)else f.trainingPanel.status:SetText(self:L('UX_REQUEST_FAILED'))end
 return ok
end
local selectProfession=A.SelectProfession
function A:SelectProfession(id)
 selectProfession(self,id);self:ShowProfessionTraining()
 -- Allow the selected profession to reopen its overview after viewing a recipe.
 for _,b in ipairs(self.professionFrame.professionButtons)do b:Enable()end
end
local selectRecipe=A.SelectProfessionRecipe
function A:SelectProfessionRecipe(recipe)
 selectRecipe(self,recipe)
 local f=self.professionFrame
 if f and f.trainingPanel then f.trainingPanel:Hide();f.trainingReturn:Show()end
end
local event=CreateFrame('Frame')
for _,name in ipairs({'SPELLS_CHANGED','SKILL_LINES_CHANGED','LEARNED_SPELL_IN_TAB'})do event:RegisterEvent(name)end
function A:RefreshTrainingViews()
 A.PlayerActions:RefreshKnown()
 if S.frame and S.frame:IsShown()then
  local selected=S.selected;local page=S.page;local status=S.frame.learnStatus:GetText()
  S:Search(S.query or '');S.restorePage=page;S:Select(selected,true)
  S.frame.learnStatus:SetText(status or '')
 end
 A:RefreshProfessionTraining()
 local f=A.professionFrame
 if f and f:IsShown()then
  A:BuildProfessionFilter()
  if f.selectedRecipe then A:SelectProfessionRecipe(f.selectedRecipe)end
 end
end
event:SetScript('OnEvent',function()A:RefreshTrainingViews()end)
local refresh=A.RefreshLocalizedUI
function A:RefreshLocalizedUI()
 refresh(self);S:RefreshTraining();self:RefreshProfessionTraining()
end
