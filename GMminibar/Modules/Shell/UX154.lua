local A=AzerothAdminAC335
local N,UI,W,K=A.NativeUI,A.UI,A.Workbench,A.MiniBarBindings
local EDGE={.52,.48,.39,1}
N.window.bgFile='Interface\\ChatFrame\\ChatFrameBackground'
N.inset.edgeSize=14
UI.windowBackdrop=N.window;UI.buttonBackdrop=N.inset
for name,s in pairs(UI.styles)do
 if name~='active' and name~='disabled' then
  s[1],s[2],s[3],s[4]=.035,.035,.04,1
  s[5],s[6],s[7],s[8]=unpack(EDGE)
 end
end
function N:Panel(frame,inset)
 frame:SetBackdrop(inset and self.inset or self.window)
 frame:SetBackdropColor(.025,.025,.03,1)
 frame:SetBackdropBorderColor(unpack(EDGE))
end
function N:Choice(parent,text,width,height,icon,onClick)
 local b=UI:Button(parent,width,height,text,'normal','LEFT');b.gmQuietButton=true
 if icon then
  b.icon=b:CreateTexture(nil,'ARTWORK');b.icon:SetSize(26,26);b.icon:SetPoint('RIGHT',b,'RIGHT',-6,0);b.icon:SetTexture(icon)
  b.aaeLabel:ClearAllPoints();b.aaeLabel:SetPoint('LEFT',b,'LEFT',8,0);b.aaeLabel:SetPoint('RIGHT',b,'RIGHT',-36,0)
 end
 b:SetHighlightTexture('Interface\\QuestFrame\\UI-QuestTitleHighlight','ADD')
 if onClick then b:SetScript('OnClick',onClick)end
 return b
end
function N:RefreshTypography(frame,depth)
 if not frame or (depth or 0)>9 then return end
 if frame.GetRegions then for _,r in ipairs({frame:GetRegions()})do if r.IsObjectType and r:IsObjectType('FontString')then A:ApplyLocaleFont(r)end end end
 if frame.GetChildren then for _,c in ipairs({frame:GetChildren()})do self:RefreshTypography(c,(depth or 0)+1)end end
end
local mount=W.Mount
function W:Mount(frame,...)
 local ok=mount(self,frame,...)
 if ok then N:RefreshTypography(self.active);N:RefreshTypography(self.dock) end
 return ok
end
-- Both cores' learn/setskill commands act on the selected player.
-- Only the hardware click changes target; never delay or restore a different
-- target before the server has processed the request.
function A:SelectSelfForUtility()
 if UnitIsUnit and UnitIsUnit('target','player')then return true end
 self:Print(self:L('UX_SELF_FAILED'),true);return false
end
function A:LearnOwnSpell(id)
 id=tonumber(id)
 if not id or id<=0 or id~=math.floor(id)or not GetSpellInfo(id)then return false end
 if self.PlayerActions:Known(id)then return false end
 if not self:CanRunCommand('learn')or not self:SelectSelfForUtility()then return false end
 local sent=self:RunRegisteredCommand('learn',tostring(id),true)
 if sent then self.PlayerActions:VerifyKnown(id)end
 return sent
end
function A:UnlearnOwnSpell(id)
 id=tonumber(id)
 if not id or id<=0 or id~=math.floor(id)or not self:SelectSelfForUtility()then return false end
 local sent=self:RunRegisteredCommand('unlearn',tostring(id),true)
 if sent then self.PlayerActions:ForgetKnown(id);self.PlayerActions:VerifyKnown(id)end
 return sent
end
function K:OpenAll()
 if InCombatLockdown and InCombatLockdown()then A:Print(A:L('HOTKEY_COMBAT'),true);return false end
 if not KeyBindingFrame and UIParentLoadAddOn then UIParentLoadAddOn('Blizzard_BindingUI')end
 if KeyBindingFrame then
  W:Close();if ShowUIPanel then ShowUIPanel(KeyBindingFrame)else KeyBindingFrame:Show()end
  return true
 end
 A:Print(A:L('UX_BINDINGS_UNAVAILABLE'),true);return false
end
function A:GoToGMIsland()
 if not self:CanRunCommand('go_xyz')then return false end
 if not self:SendCommand('.gm on')then return false end
 W:Close()
 -- Exact GMIsland record from the corresponding server catalog; no alias required.
 return self:SendCommand('.go xyz 16226.2 16257 13.2022 1 1.65007')
end
local navigate=W.Navigate
local position=W.ApplyWindowPosition
function W:ApplyWindowPosition(f)
 if f==self.utilityPanel then
  f:SetSize(1080,700);N:Fit(f,1080,700,tonumber(self:DB().scale)or .85)
  f:ClearAllPoints();f:SetPoint('CENTER',UIParent,'CENTER',55,0);return
 end
 return position(self,f)
end
function W:Navigate(key)
 if key=='gmisland'then return A:GoToGMIsland()end
 if key=='favorites'then
  self:Create();self:ClearFocus();self:CreateUtilityPanel();self:Mount(self.utilityPanel,'favorites')
  self:RefreshUtilities()
  return
 end
 return navigate(self,key)
end
function W:Toggle()if self:IsOpen()then self:Close()else self:Show()end end
local create=W.Create
function W:Create()
 create(self)
 -- The curated icon panel replaces the old user-maintained list.
 if self.addConvenience then self.addConvenience:Hide()end
 if self.nav then
  if not self.nav.gmisland.gmLocalized then
   A:RegisterLocalizedWidget(self.nav.gmisland,'UX_GM_ISLAND');A:RegisterLocalizedWidget(self.nav.commands,'UX_ALL_COMMANDS');self.nav.gmisland.gmLocalized=true
  end
  self.nav.commands:SetText(A:L('UX_ALL_COMMANDS'));self.nav.gmisland:SetText(A:L('UX_GM_ISLAND'))
 end
end
