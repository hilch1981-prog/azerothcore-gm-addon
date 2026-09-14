local A=AzerothAdminAC335
function A:OpenIntegrationsWindow()
 local frame=self.windows.integrations
 if not frame then
  frame=self.UI:CreateWindow("integrations",self:L("INTEGRATIONS"),600,390)
  local text="AzerothCore 3.3.5a / RC9.4.11 UI\n\n"..self:L("DATA_ONLY_NOTE").."\n\n"..self.ReleaseSourceInfo.server_repository.."\n"..self.ReleaseSourceInfo.server_baseline
  local body=self.UI:Text(frame,text,"small");body:SetPoint("TOPLEFT",frame,"TOPLEFT",16,-55);body:SetWidth(560);body:SetJustifyH("LEFT")
 end
 self.UI:ShowWindow(frame)
end
