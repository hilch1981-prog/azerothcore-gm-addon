local A=AzerothAdminAC335
local N=A.NativeUI
local K={};A.MiniBarBindings=K
K.order={'gmMenuButton','bankButton','questHelperButton','teleportButton','rc8Revive','gmModeButton','godButton','visibilityButton','killButton','flightButton','speedButton'}
local labels={'MAIN_MENU','BANK','QUEST_HELPER','TELEPORTS','CMD_REVIVE','GM_MODE_TOGGLE','CMD_GOD_ON','CMD_VISIBLE_OFF','CMD_DIE','CMD_FLY_ON','CMD_SPEED_3'}
local prefix=A.interface==30300 and 'GMMINIBARAC335_' or 'GMMINIBARMOP548_'
function K:Action(index)return prefix..index end
function K:Refresh()
 _G['BINDING_HEADER_'..prefix..'HEADER']=A:L('TITLE')
 for i,key in ipairs(self.order) do
  local action=self:Action(i);_G['BINDING_NAME_'..action]=A:L(labels[i])
  local button=A[key]
  if button then
   local binding=GetBindingKey and GetBindingKey(action)
   if not button.gmHotkey then
    local text=button:CreateFontString(nil,'OVERLAY','NumberFontNormalSmall');text:SetPoint('TOPRIGHT',button,'TOPRIGHT',1,0);text:SetTextColor(1,1,1);text:SetWidth(key=='gmMenuButton' and 58 or 38);text:SetJustifyH('RIGHT');button.gmHotkey=text
   end
   local short=binding and binding:gsub('CTRL%-','C-'):gsub('SHIFT%-','S-'):gsub('ALT%-','A-'):gsub('NUMPAD','N'):gsub('BUTTON','M') or ''
   button.gmHotkey:SetText(short)
  end
 end
end
function A:ActivateMiniBar(index)
 local button=self[K.order[index]]
 if not button or (button.IsEnabled and not button:IsEnabled()) then return false end
 local click=button.gmOriginalClick or button:GetScript('OnClick')
 if click then click(button,'LeftButton');return true end
end
function K:StopCapture()
 if not self.frame then return end
 self.capturing=false;self.frame:EnableKeyboard(false);self.frame:SetScript('OnKeyDown',nil)
 self.frame.capture:SetText(A:L('HOTKEY_CAPTURE'))
end
function K:Assign(index,key)
 if InCombatLockdown and InCombatLockdown() then return false,A:L('HOTKEY_COMBAT') end
 local action=self:Action(index)
 -- Check both saved and temporary bindings. Never overwrite a WoW binding,
 -- another addon, or even a different minibar action.
 local normal=GetBindingAction and GetBindingAction(key) or ''
 local effective=GetBindingAction and GetBindingAction(key,true) or normal
 for _,existing in ipairs({normal,effective})do
  if existing~='' and existing~=action then return false,A:L('HOTKEY_CONFLICT',key,_G['BINDING_NAME_'..existing] or existing) end
 end
 if not SetBinding or not GetBindingKey or not SaveBindings then return false,A:L('HOTKEY_FAILED') end
 local old={GetBindingKey(action)}
 if not SetBinding(key,action) then return false,A:L('HOTKEY_FAILED') end
 for _,previous in ipairs(old)do if previous~=key then SetBinding(previous) end end
 SaveBindings(GetCurrentBindingSet and GetCurrentBindingSet() or 1)
 self:Refresh();return true,A:L('HOTKEY_ASSIGNED',key)
end
function K:Open(index)
 if InCombatLockdown and InCombatLockdown() then A:Print(A:L('HOTKEY_COMBAT'),true);return end
 if not self.frame then
  local f=CreateFrame('Frame',prefix..'BindingPopup',UIParent);self.frame=f
  f:SetSize(310,238);f:SetPoint('CENTER',UIParent,'CENTER',0,0);f:EnableMouse(true);f:SetClampedToScreen(true);N:Panel(f);f:Hide()
  f.aaeTitle=N:Text(f,A:L('HOTKEY_TITLE'),250);f.aaeTitle:SetPoint('TOPLEFT',f,'TOPLEFT',16,-16)
  local x=CreateFrame('Button',nil,f,'UIPanelCloseButton');x:SetPoint('TOPRIGHT',f,'TOPRIGHT',-3,-3);x:SetScript('OnClick',function()f:Hide()end)
  UISpecialFrames[#UISpecialFrames+1]=f:GetName()
  f:SetFrameStrata('DIALOG')
  f.action=N:Text(f,'',270,false);f.action:SetPoint('TOPLEFT',f,'TOPLEFT',20,-43)
  f.status=N:Text(f,'',270,true);f.status:SetPoint('TOPLEFT',f,'TOPLEFT',20,-70);f.status:SetHeight(66)
  f.capture=N:Button(f,A:L('HOTKEY_CAPTURE'),130,25,function()
   N:ClearInputFocus(A.Workbench.frame);K.capturing=true;f.capture:SetText(A:L('HOTKEY_WAIT'));f.status:SetText(A:L('HOTKEY_PRESS'))
   f:EnableKeyboard(true)
   f:SetScript('OnKeyDown',function(_,key)
    if key=='ESCAPE' then K:StopCapture();f:Hide();return end
    if key=='LSHIFT' or key=='RSHIFT' or key=='LCTRL' or key=='RCTRL' or key=='LALT' or key=='RALT' or key=='LGUI' or key=='RGUI' then return end
    if IsShiftKeyDown() then key='SHIFT-'..key end
    if IsControlKeyDown() then key='CTRL-'..key end
    if IsAltKeyDown() then key='ALT-'..key end
    K:StopCapture();local ok,message=K:Assign(K.index,key);f.status:SetText(message)
   end)
  end);f.capture:SetPoint('BOTTOMLEFT',f,'BOTTOMLEFT',20,63)
  f.clear=N:Button(f,A:L('HOTKEY_CLEAR'),130,26,function()
   K:StopCapture()
   if InCombatLockdown and InCombatLockdown() then f.status:SetText(A:L('HOTKEY_COMBAT'));return end
   for _,key in ipairs({GetBindingKey(K:Action(K.index))})do SetBinding(key)end
   SaveBindings(GetCurrentBindingSet and GetCurrentBindingSet() or 1);K:Refresh();f.status:SetText(A:L('HOTKEY_CLEARED'))
  end);f.clear:SetPoint('LEFT',f.capture,'RIGHT',8,0)
  local all=N:Button(f,A:L('UX_ALL_BINDINGS'),178,25,function()K:StopCapture();f:Hide();K:OpenAll()end);all:SetPoint('BOTTOMLEFT',f,'BOTTOMLEFT',20,25)
  A:RegisterLocalizedWidget(all,'UX_ALL_BINDINGS');f.all=all
  local close=N:Button(f,A:L('CLOSE'),80,25,function()f:Hide()end);close:SetPoint('LEFT',all,'RIGHT',8,0)
  for _,spec in ipairs({{f.aaeTitle,'HOTKEY_TITLE'},{f.capture,'HOTKEY_CAPTURE'},{f.clear,'HOTKEY_CLEAR'},{close,'CLOSE'}})do A:RegisterLocalizedWidget(spec[1],spec[2])end
  f:HookScript('OnHide',function()K:StopCapture()end)
 end
 self:StopCapture();self.index=index
 self.frame.action:SetText(A:L(labels[index]));self.frame.status:SetText(A:L('HOTKEY_HELP'));self.frame:Show()
end
function K:Install()
 for i,key in ipairs(self.order)do
  local index=i;local button=A[key]
  if button and not button.gmBindingInstalled then
   button.gmBindingInstalled=true;button.gmOriginalClick=button:GetScript('OnClick')
   A:RegisterLocalizedWidget(button,labels[index],function(b)b.aaeTitle=A:L(labels[index]);K:Refresh()end)
   button:RegisterForClicks('LeftButtonUp','RightButtonUp')
   button:SetScript('OnClick',function(b,mouse)
    if mouse=='RightButton' then K:Open(index) elseif b.gmOriginalClick then b.gmOriginalClick(b,mouse) end
   end)
   button:HookScript('OnEnter',function(b)
    local tip=A.hintTooltip and A.hintTooltip:IsShown() and A.hintTooltip or GameTooltip
    if tip then tip:AddLine(A:L('HOTKEY_RIGHT_CLICK'),.65,.85,1,true);tip:Show()end
   end)
  end
 end
 self:Refresh()
end
local event=CreateFrame('Frame')
for _,name in ipairs({'PLAYER_LOGIN','UPDATE_BINDINGS','PLAYER_REGEN_DISABLED'})do event:RegisterEvent(name)end
event:SetScript('OnEvent',function(_,name)
 if name=='PLAYER_LOGIN' then K:Install()
 elseif name=='UPDATE_BINDINGS' then K:Refresh()
 elseif K.frame then K:StopCapture();K.frame:Hide() end
end)
