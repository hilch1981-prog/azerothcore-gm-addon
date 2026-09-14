local A = AzerothAdminAC335
function A:OpenPlayerBotWindow()
    local frame=self.windows.playerbot
    if not frame then
        frame=self.UI:CreateWindow("playerbot",self:L("PLAYERBOT"),520,260)
        local text=self.UI:Text(frame,self:L("PLAYERBOT_BLOCKED").."\n\nPOC branch: playerbot-v2-poc\nModule pin: 78bc93512f8c3b26175321e98eb0bede42917ce6\nG1 build gates: PASS\nWorldserver boot and human smoke: PENDING\n\nNo bot-control commands are loaded in this release.","normal"); text:SetPoint("TOPLEFT",frame,"TOPLEFT",20,-60); text:SetWidth(480); text:SetJustifyH("LEFT"); text:SetJustifyV("TOP")
    end
    self.UI:ShowWindow(frame)
end
