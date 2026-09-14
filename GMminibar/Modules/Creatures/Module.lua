local A = AzerothAdminAC335
function A:OpenCreatureWindow()
    local frame=self.windows.creature_tools
    if not frame then
        frame=self.UI:CreateWindow("creature_tools",self:L("CREATURE_TOOLS"),480,300)
        local input=self.UI:EditBox(frame,300,24); input:SetPoint("TOPLEFT",frame,"TOPLEFT",16,-58); frame.input=input
        local lookup=self.UI:Button(frame,120,24,self:L("CMD_LOOKUP_CREATURE"),"utility"); lookup:SetPoint("LEFT",input,"RIGHT",8,0); lookup:SetScript("OnClick",function() local q=A:Trim(input:GetText()); if q~="" then A:RunRegisteredCommand("lookup_creature",q,true) end end)
        local actions={{"guid","CMD_GUID"},{"distance","CMD_DISTANCE"},{"die","CMD_DIE"},{"revive","CMD_REVIVE"},{"respawn","CMD_RESPAWN"},{"combatstop","CMD_COMBATSTOP"},{"freeze","CMD_FREEZE"},{"unfreeze","CMD_UNFREEZE"},{"aura","CMD_AURA"},{"morph","CMD_MORPH"}}
        for i,row in ipairs(actions) do
            local commandID = row[1]
            local labelKey = row[2]
            local def=A:GetCommand(commandID); local b=A.UI:Button(frame,135,24,A:L(labelKey),def and def.style or "normal"); b:SetPoint("TOPLEFT",frame,"TOPLEFT",16+((i-1)%3)*145,-100-math.floor((i-1)/3)*31); b:SetScript("OnClick",function() A:RunRegisteredCommand(commandID) end)
        end
        local hint=self.UI:Text(frame,self:L("SELECT_TARGET"),"small"); hint:SetPoint("BOTTOMLEFT",frame,"BOTTOMLEFT",16,16); hint:SetWidth(430); hint:SetJustifyH("LEFT")
    end
    self.UI:ShowWindow(frame)
end
