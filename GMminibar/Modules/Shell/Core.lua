local A = AzerothAdminAC335
function A:ShowArgumentPrompt(definition,submit)
    local frame=self.argumentFrame
    if not frame then
        frame=self.UI:CreateWindow("argument",self:L("ARGUMENT"),430,190); self.argumentFrame=frame
        local prompt=self.UI:Text(frame,"","normal"); prompt:SetPoint("TOPLEFT",frame,"TOPLEFT",18,-58); prompt:SetWidth(390); prompt:SetJustifyH("LEFT"); frame.prompt=prompt
        local input=self.UI:EditBox(frame,390,26); input:SetPoint("TOPLEFT",frame,"TOPLEFT",18,-88); frame.input=input
        local ok=self.UI:Button(frame,100,25,self:L("CONFIRM"),"reward"); ok:SetPoint("BOTTOMRIGHT",frame,"BOTTOMRIGHT",-120,18); frame.ok=ok
        local cancel=self.UI:Button(frame,100,25,self:L("CANCEL"),"danger"); cancel:SetPoint("LEFT",ok,"RIGHT",8,0); cancel:SetScript("OnClick",function() frame:Hide() end)
        input:SetScript("OnEnterPressed",function() if frame.ok and frame.ok:GetScript("OnClick") then frame.ok:GetScript("OnClick")(frame.ok) end end)
    end
    frame.definition=definition; frame.prompt:SetText(self:L(definition.promptKey or "ARGUMENT").."\n"..self:L(definition.labelKey)); frame.input:SetText("")
    frame.ok:SetScript("OnClick",function()
        local suffix=A:Trim(frame.input:GetText())
        if suffix=="" or suffix:find("[\r\n]") then return end
        frame:Hide()
        if submit then submit(suffix)
        elseif definition.dangerous then A:ShowCommandConfirmation(definition,suffix)
        else A:RunRegisteredCommand(definition.id,suffix,true) end
    end)
    self.UI:ShowWindow(frame); frame.input:SetFocus()
end
function A:ShowCommandConfirmation(definition,suffix)
    local frame=self.confirmFrame
    if not frame then
        frame=self.UI:CreateWindow("confirm",self:L("CONFIRM"),440,190); self.confirmFrame=frame
        local text=self.UI:Text(frame,"","normal"); text:SetPoint("TOPLEFT",frame,"TOPLEFT",18,-58); text:SetWidth(400); text:SetJustifyH("LEFT"); frame.text=text
        local ok=self.UI:Button(frame,100,25,self:L("CONFIRM"),"danger"); ok:SetPoint("BOTTOMRIGHT",frame,"BOTTOMRIGHT",-120,18); frame.ok=ok
        local cancel=self.UI:Button(frame,100,25,self:L("CANCEL"),"utility"); cancel:SetPoint("LEFT",ok,"RIGHT",8,0); cancel:SetScript("OnClick",function() frame:Hide() end)
    end
    frame.text:SetText(self:L("DANGEROUS_CONFIRM").."\n"..self:BuildCommand(definition,suffix)); frame.ok:SetScript("OnClick",function() frame:Hide(); A:SendCommand(A:BuildCommand(definition,suffix)) end); self.UI:ShowWindow(frame)
end
function A:OpenCommandFavoritesWindow()
    local frame=self.favoritesWindow
    if not frame then
        frame=self.UI:CreateWindow("favorites",self:L("FAVORITES"),600,420); self.favoritesWindow=frame; frame.page=1; frame.rows={}
        for i=1,12 do local b=self.UI:RowLabel(frame,560,23); b:SetPoint("TOPLEFT",frame,"TOPLEFT",16,-58-(i-1)*26); b:RegisterForClicks("LeftButtonUp","RightButtonUp"); b:SetScript("OnClick",function(self,button) if not self.aaeDefinition then return end; if button=="RightButton" then A:ToggleCommandFavorite(self.aaeDefinition.id); A:RefreshFavoritesWindow() else A:RunRegisteredCommand(self.aaeDefinition.id) end end); frame.rows[i]=b end
        local history=self.UI:Text(frame,self:L("COMMAND_HISTORY"),"small"); history:SetPoint("BOTTOMLEFT",frame,"BOTTOMLEFT",16,52); frame.historyTitle=history
        local historyText=self.UI:Text(frame,"","small"); historyText:SetPoint("BOTTOMLEFT",frame,"BOTTOMLEFT",16,18); historyText:SetWidth(560); historyText:SetJustifyH("LEFT"); frame.historyText=historyText
    end
    self:RefreshFavoritesWindow(); self.UI:ShowWindow(frame)
end
function A:RefreshFavoritesWindow()
    local frame=self.favoritesWindow; if not frame then return end
    local defs={}
    for _,id in ipairs(self.CommandOrder) do if self:IsCommandFavorite(id) then table.insert(defs,self:GetCommand(id)) end end
    for i=1,12 do local b=frame.rows[i]; local def=defs[i]; b.aaeDefinition=def; if def then b:SetText(self:L(def.labelKey).."  "..(def.command or "[action]")); b:Show() else b:Hide() end end
    if table.getn(defs)==0 then frame.rows[1]:SetText(self:L("NO_FAVORITES")); frame.rows[1].aaeDefinition=nil; frame.rows[1]:Show() end
    local history=self:GetDB().commandHistory; local parts={}; for i=1,math.min(2,table.getn(history)) do table.insert(parts,history[i]) end; frame.historyText:SetText(table.concat(parts,"   |   "))
end
function A:ShowMainWindow()
    if self.Workbench then self.Workbench:Show(); return true end
    if not self.frame and type(self.CreateUI) == "function" then self:SafeCall("CreateUI", self.CreateUI, self) end
    if not self.frame then self:Print("Main window could not be created. Run /aaac repair.", true); return false end
    self:HideAddonWindows(self.frame); self.frame:Show(); self.frame:Raise(); return true
end
function A:ToggleMainWindow()
    if self.Workbench then self.Workbench:Toggle(); return true end
    if not self.frame and type(self.CreateUI) == "function" then self:SafeCall("CreateUI", self.CreateUI, self) end
    if not self.frame then self:Print("Main window could not be created. Run /aaac repair.", true); return false end
    if self.frame:IsShown() then self.frame:Hide() else self:ShowMainWindow() end
    return true
end
function A:ToggleToolbar()
    if not self.toolbar then return end
    local db=self:GetDB(); db.toolbarHidden=not db.toolbarHidden
    if db.toolbarHidden then self.toolbar:Hide() else self.toolbar:Show() end
end
function A:Initialize()
    if self.initializing then return self.initialized and true or false end
    self.initializing = true
    self:GetDB()

    local uiOK = false
    if type(self.CreateUI) == "function" then
        uiOK = self:SafeCall("CreateUI", self.CreateUI, self) and true or false
    else
        self:Print("CreateUI is missing. Reinstall the complete addon folder.", true)
    end

    -- Launchers are constructed independently from the main command window.  A
    -- broken category/panel must never remove the minibar or minimap recovery path.
    if type(self.EnsureLaunchers) == "function" then
        self:SafeCall("EnsureLaunchers", self.EnsureLaunchers, self)
    end
    if type(self.RefreshSecurityDisplays) == "function" then
        self:SafeCall("RefreshSecurityDisplays", self.RefreshSecurityDisplays, self)
    end

    local ready = type(self.UI) == "table"
        and type(self.UI.CreateWindow) == "function"
        and self.toolbar ~= nil
        and self.minimapButton ~= nil
        and self.frame ~= nil
    self.initialized = ready and true or false
    self.initializing = false

    if ready and not self.loadedNoticeShown then
        self.loadedNoticeShown = true
        self:Print("v"..self.version.." loaded. /aaac · /aaac test · raw commands: /mopgm")
    elseif not ready then
        self:Print("UI startup incomplete. Run /aaac repair after verifying a clean R8 install.", true)
    end
    return ready, uiOK
end
