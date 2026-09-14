local A=AzerothAdminAC335
local W,D,C,N=A.Workbench,A.WorkbenchAdapter,A.WorkbenchCatalog,A.NativeUI
-- Catalog rebuilds create new entry objects. Match persisted slots by command,
-- not by identity against a previously cached FullEntries table.
local build=C.Build
function C:Build(adapter)
    W.fullEntries=nil
    return build(self,adapter)
end
function W:ResolveSlot(key)
    if not C.entries then C:Build(D) end
    local views=self:FullEntries()
    local entry=C.byKey[key]
    local root=type(key)=="string" and key:match("^toggle:(.+)$")
    if not root and entry then root=(entry.definition.command or ""):gsub(" (on)$",""):gsub(" (off)$","") end
    for _,v in ipairs(views) do
        if v.viewKey==root and v.choices.on and v.choices.off then return entry or v.choices.on,v end
    end
    return entry
end
function W:SlotArgumentDefinition(entry)
    local d=entry.definition
    if d.action then return end
    local command=d.command or ""
    local prompt=d.promptKey
    for _,known in pairs(A.CommandCatalog or {}) do
        if known.command==command and known.promptKey then prompt=known.promptKey;break end
    end
    local meta=A.CommandWorkbook and A.CommandWorkbook[command]
    local syntax=(meta and meta.method or "").." "..(d.help or "")
    if not prompt and not d.requires and not syntax:find("[#%$<]") then return end
    local definition={};for key,value in pairs(d) do definition[key]=value end
    definition.promptKey=prompt or "ARGUMENT"
    return definition
end
function W:RunSlot(slot,mouse)
    self:Create()
    local entry,view=self:ResolveSlot(self:DB().quick[slot])
    if not entry then return end
    if view then
        self:DB().quick[slot]="toggle:"..view.viewKey
        local state=mouse=="MiddleButton" and "off" or (self.toggleRequested and self.toggleRequested[view.viewKey] and "off" or "on")
        local chosen=view.choices[state]
        if D:Allowed(chosen) then D:Execute(chosen,"","") end
    elseif D:Allowed(entry) then
        local definition=self:SlotArgumentDefinition(entry)
        if definition then
            self:ClearFocus()
            A:ShowArgumentPrompt(definition,function(args) D:Execute(entry,args,"") end)
        else D:Execute(entry,"","") end
    end
    self:RefreshMiniSlots()
end
-- SendCommand's true return means dispatched, not server-confirmed. A failed
-- transport must not advance the next toggle request.
local send=A.SendCommand
function A:SendCommand(command,...)
    local root,state
    if type(command)=="string" then root,state=command:match("^(.-) (on)$") end
    if not root and type(command)=="string" then root,state=command:match("^(.-) (off)$") end
    W.toggleRequested=W.toggleRequested or {}
    local previous=root and W.toggleRequested[root]
    local result=send(self,command,...)
    if root then W.toggleRequested[root]=result==true and state=="on" or (result~=true and previous or false) end
    return result
end
local refresh=W.RefreshMiniSlots
function W:RefreshMiniSlots()
    refresh(self)
    for i,b in ipairs(A.commandQuickSlots or {}) do
        local _,view=self:ResolveSlot(self:DB().quick[i])
        if view then
            local requested=self.toggleRequested and self.toggleRequested[view.viewKey]
            b.aaeHint=b.aaeHint..A:T("\n왼쪽 클릭: ")..(requested and "OFF" or "ON")..A:T(" 요청 · 가운데 클릭: OFF 요청\n표시는 마지막 전송 요청 기준입니다.")
        end
    end
end
function W:LayoutMiniBar()
 if not A.toolbar or not A.rc8Revive then return end
 local bar=A.toolbar
 for _,key in ipairs({'craftInfoButton','itemInfoButton'})do
  local b=A[key];if b then b:Hide();if not b.rc93Hidden then b.rc93Hidden=true;b:HookScript('OnShow',function(s)s:Hide()end)end end
 end
 if not bar.dragHandle then
  local grip=CreateFrame('Button',nil,bar);bar.dragHandle=grip;grip:SetSize(16,26);grip:SetPoint('LEFT',bar,'LEFT',3,0)
  for column=0,1 do for row=0,3 do
   local dot=grip:CreateTexture(nil,'ARTWORK');dot:SetTexture(.75,.67,.44,1);dot:SetSize(2,2);dot:SetPoint('TOPLEFT',grip,'TOPLEFT',5+column*4,-5-row*5)
  end end
  grip:SetHighlightTexture('Interface\\Buttons\\ButtonHilight-Square','ADD')
  grip:RegisterForDrag('LeftButton');grip:SetScript('OnDragStart',function()bar:StartMoving()end)
  grip:SetScript('OnDragStop',function()bar:StopMovingOrSizing();A.UI:SavePoint(bar,'toolbar')end)
  N:Hint(grip,'미니바 이동','이 손잡이를 왼쪽 버튼으로 잡고 끌어 이동하세요.')
  local resize=CreateFrame('Frame',nil,bar);bar.sizeControl=resize;resize:SetSize(26,26)
  for i,delta in ipairs({.05,-.05})do
   local step=delta;local b=CreateFrame('Button',nil,resize);b:SetSize(26,13);b:SetPoint('TOPLEFT',resize,'TOPLEFT',0,-(i-1)*13)
   b:SetNormalTexture(i==1 and 'Interface\\Buttons\\UI-ScrollBar-ScrollUpButton-Up'or 'Interface\\Buttons\\UI-ScrollBar-ScrollDownButton-Up')
   b:SetHighlightTexture('Interface\\Buttons\\ButtonHilight-Square','ADD')
   b:SetScript('OnClick',function()local db=W:DB();db.miniBarScale=math.max(.65,math.min(1.6,(db.miniBarScale or 1)+step));W:LayoutMiniBar()end)
   N:Hint(b,i==1 and '미니바 확대'or '미니바 축소','한 번 클릭하면 크기가 5% 바뀝니다.')
   if i==1 then bar.sizeUp=b else bar.sizeDown=b end
  end
 end
 local x=21
 for _,key in ipairs({'gmMenuButton','bankButton','questHelperButton','teleportButton','rc8Revive','gmModeButton','godButton','visibilityButton','killButton','flightButton','speedButton'})do
  local b=A[key];local width=key=='gmMenuButton'and 82 or 26
  if b then
   b:ClearAllPoints();b:SetPoint('LEFT',bar,'LEFT',x,0);b:SetSize(width,26);b:Show()
   if key=='gmMenuButton'then
    b:SetText(A:L('MAIN_MENU'));local label=b.aaeLabel or b:GetFontString()
    if label then label:ClearAllPoints();label:SetPoint('LEFT',b,'LEFT',4,0);label:SetPoint('RIGHT',b,'RIGHT',-4,0);label:SetJustifyH('CENTER');A:ApplyLocaleFont(label)end
   end
   x=x+width+2
  end
 end
 -- The revive artwork must remain visible underneath its optional highlight.
 A.rc8Revive:SetNormalTexture('Interface\\Icons\\Spell_Holy_Resurrection')
 local revive=A.rc8Revive:GetNormalTexture();if revive then revive:ClearAllPoints();revive:SetPoint('TOPLEFT',A.rc8Revive,'TOPLEFT',2,-2);revive:SetPoint('BOTTOMRIGHT',A.rc8Revive,'BOTTOMRIGHT',-2,2)end
 for _,b in ipairs(A.commandQuickSlots or {})do b:Hide();b:Disable()end
 bar.sizeControl:ClearAllPoints();bar.sizeControl:SetPoint('LEFT',bar,'LEFT',x,0)
 bar:SetSize(x+29,32);bar:SetScale(math.max(.65,math.min(1.6,tonumber(self:DB().miniBarScale)or 1)))
end

local install=W.InstallMiniSlots
function W:InstallMiniSlots() install(self);self:LayoutMiniBar() end
local settings=W.ShowSettings
function W:ShowSettings()
    settings(self)
    local b=self.settings and self.settings.checks and self.settings.checks.questCompanion
    if b then b:SetChecked(true);b:Disable();N:Hint(b,A:T("퀘스트 도우미"),A:L('UX_QUEST_LOG_ONLY')) end
end
local events=CreateFrame("Frame");events:RegisterEvent("PLAYER_LOGIN")
events:SetScript("OnEvent",function()W:InstallMiniSlots();W:RefreshMiniSlots()end)

-- Only suppress the Warlock pet attack flash. Do not modify attacks, autocast,
-- checked-state textures or the separate battle-pet selection frame.
local function stopWarlockAttackFlash(button)
    local _,class=UnitClass("player")
    if class~="WARLOCK" or not button or not button.GetID or not IsPetAttackAction or not IsPetAttackAction(button:GetID()) then return end
    if PetActionButton_StopFlash then PetActionButton_StopFlash(button) end
end
A.StopWarlockAttackFlash=stopWarlockAttackFlash
if hooksecurefunc and type(PetActionButton_StartFlash)=="function" then hooksecurefunc("PetActionButton_StartFlash",stopWarlockAttackFlash) end
