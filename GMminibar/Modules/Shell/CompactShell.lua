-- Small attached navigation; feature windows retain their own useful dimensions.
local A = AzerothAdminAC335
local W,D,N,C=A.Workbench,A.WorkbenchAdapter,A.NativeUI,A.WorkbenchCatalog
local function L(key) return A:WL(key) end
local function X(key) return A:XL(key) end
W.width,W.height=740,612
function W:IsOpen() return self.active and self.active:IsShown() end
function W:AnchorDock()
    if not self.dock or not self.active then return end
    self.dock:SetScale(self.active:GetScale())
    self.dock:ClearAllPoints()
    local left=(self.active:GetLeft() or 0)*self.active:GetEffectiveScale()/UIParent:GetEffectiveScale()
    if left<170*self.dock:GetScale() then self.dock:SetPoint("TOPLEFT",self.active,"TOPRIGHT",0,0)
    else self.dock:SetPoint("TOPRIGHT",self.active,"TOPLEFT",0,0) end
end
function W:EscapeEnabled(enabled)
    if not self.frame then return end
    self:RemoveSpecial(self.frame)
    if self.active then self:RemoveSpecial(self.active) end
    if enabled and self.active and self.active:GetName() then
        for i,name in ipairs(UISpecialFrames) do
            if name=='GMminibarUnusedEscapeSlot' then UISpecialFrames[i]=self.active:GetName();return end
        end
        UISpecialFrames[#UISpecialFrames+1]=self.active:GetName()
    end
end
function W:Mount(frame,key,showFunc)
    if self.switching then return true end
    if frame~=A.teleportFrame then A.teleportReturn=nil end
    self:Create()
    local active=frame==self.commandPanel and self.frame or frame
    self:Watch(frame,key or self.panels[frame] or "commands")
    self.switching=true
    local ok,err=pcall(function()
    if self.active and self.active~=active then
        self.active.aaeReturnFrame=nil; self.active.aaeSuppressRestore=true; self.active:Hide(); self.active.aaeSuppressRestore=nil
        self:RemoveSpecial(self.active)
    end
    self.active,self.key=active,key or self.panels[frame]
    if active~=self.frame then
        active.aaeReturnFrame=nil; active:SetParent(UIParent)
        if self.LayoutModule then self:LayoutModule(active,self.key) end
        if not active.aaeCompactPositioned then
            active.aaeCompactPositioned=true; active:ClearAllPoints(); active:SetPoint("CENTER",UIParent,"CENTER",55,0)
        end
        active:SetMovable(true); active:SetClampedToScreen(true); active:RegisterForDrag("LeftButton")
        active:SetFrameStrata("DIALOG")
        if not active.aaeCompactDrag then active.aaeCompactDrag=true; active:HookScript("OnDragStop",function() W:AnchorDock() end) end
        if active.aaeBack then active.aaeBack:Hide() end
    end
    N:Fit(active,active:GetWidth(),active:GetHeight(),tonumber(self:DB().scale) or .85)
    if showFunc then
        showFunc(frame)
    else frame:Show() end
    self:ApplyWindowPosition(active);active:Show(); self:AnchorDock(); self.dock:Show()
    end)
    self.switching=false
    if not ok then self:Close();error(err) end
    self:EscapeEnabled((self.popupDepth or 0)==0)
    self:RefreshHeader(); self:RefreshNavigation()
    return true
end
function W:Close()
    if self.closing or self.switching or self.captureHidden then return end
    self.closing=true
    self:ClearFocus()
    if self.active then self.active.aaeReturnFrame=nil; self.active.aaeSuppressRestore=true; self.active:Hide(); self.active.aaeSuppressRestore=nil end
    if self.frame then self.frame:Hide() end
    if self.dock then self.dock:Hide() end
    if self.settings then self.settings:Hide() end
    if self.picker then self.picker:Hide() end
    self.closing=false
end
function W:Navigate(key)
    self:Create(); self:ClearFocus()
    if key=="commands" or key=="favorites" or key=="history" then
        self.mode=key;self.page=1;self.group='all';self.categoryPage=1
        self:Mount(self.commandPanel,key,function(panel) W.content:Show();panel:Show() end);self:RefreshCommands()
    elseif key=="bank" then self:Close(); D:Open(key)
    elseif self.key~=key or not self:IsOpen() then D:Open(key) end
end
function W:Show() self:Navigate("favorites") end
function W:Toggle() if self:IsOpen() and self.active==self.frame then self:Close() else self:Show() end end
function W:Back() self:Navigate("commands") end
function W:CollapseDock()
    self:DB().dockCollapsed=not self:DB().dockCollapsed
    self:RefreshDock()
end
function W:RefreshDock()
    if not self.dock then return end
    local collapsed=false;self:DB().dockCollapsed=false
    self.dock:SetHeight(collapsed and 35 or self.dock.fullHeight)
    for _,button in pairs(self.nav) do if collapsed then button:Hide() else button:Show() end end
end
function W:ShowSettings()
    self:Create()
    if not self.settings then
        local p=CreateFrame("Frame",D.namespace.."Settings",UIParent); self.settings=p
        p:SetWidth(380);p:SetHeight(420);p:SetPoint("CENTER",UIParent,"CENTER",0,0);p:SetFrameStrata("TOOLTIP");p:SetClampedToScreen(true);p:EnableMouse(true);N:Panel(p);p:SetBackdrop({bgFile="Interface\\ChatFrame\\ChatFrameBackground",edgeFile=N.window.edgeFile,tile=true,tileSize=16,edgeSize=24,insets=N.window.insets});p:SetBackdropColor(0,0,0,1);p:Hide()
        local title=N:Text(p,X("SETTINGS"),300);title:SetPoint("TOPLEFT",p,"TOPLEFT",18,-18)
        local close=CreateFrame("Button",nil,p,"UIPanelCloseButton");close:SetPoint("TOPRIGHT",p,"TOPRIGHT",-3,-3);close:SetScript("OnClick",function() p:Hide() end)
        local language=N:Text(p,L("LANGUAGE"),330,true);language:SetPoint("TOPLEFT",p,"TOPLEFT",18,-52)
        for i,locale in ipairs({"auto","koKR","enUS","zhCN","zhTW","ruRU"}) do
            local lang=locale;local b=N:Button(p,({"AUTO","KO","EN","CN","TW","RU"})[i],51,24,function() D:Language(lang) end)
            b:SetPoint("TOPLEFT",p,"TOPLEFT",18+(i-1)*58,-73);N:Hint(b,L("LANGUAGE"),L("RELOAD_LANGUAGE"))
        end
        local scale=N:Text(p,L("UI_SCALE"),260,true);scale:SetPoint("TOPLEFT",p,"TOPLEFT",18,-114)
        local function resize(delta)
            local db=W:DB();db.scale=math.max(.6,math.min(1.1,(tonumber(db.scale) or .85)+delta))
            if W.active then N:Fit(W.active,W.active:GetWidth(),W.active:GetHeight(),db.scale);W:AnchorDock() end
        end
        local less=N:Button(p,"-",36,24,function() resize(-.05) end);less:SetPoint("TOPRIGHT",p,"TOPRIGHT",-65,-107)
        local more=N:Button(p,"+",36,24,function() resize(.05) end);more:SetPoint("LEFT",less,"RIGHT",7,0)
        p.checks={}
        for i,entry in ipairs({{"questCompanion",L("QUEST_AUTO")},{"hideCombat",X("HIDE_COMBAT")}}) do
            local option=entry[1];local b=CreateFrame("CheckButton",nil,p,"UICheckButtonTemplate");b:SetWidth(24);b:SetHeight(24);b:SetPoint("TOPLEFT",p,"TOPLEFT",18,-145-(i-1)*33)
            local label=N:Text(p,entry[2],310,true);label:SetPoint("LEFT",b,"RIGHT",5,0);p.checks[option]=b
            b:SetScript("OnClick",function(self)
                W:DB()[option]=self:GetChecked() and true or false
                if option=="questCompanion" then A.QuestLogBridge:UpdateVisibility() end
            end)
        end
        local loot=CreateFrame("CheckButton",nil,p,"UICheckButtonTemplate");loot:SetWidth(24);loot:SetHeight(24);loot:SetPoint("TOPLEFT",p,"TOPLEFT",18,-223);p.autoLoot=loot
        local lootLabel=N:Text(p,A:T("전리품 자동 획득"),300,true);lootLabel:SetPoint("LEFT",loot,"RIGHT",5,0)
        loot:SetScript("OnClick",function(self) SetCVar("autoLootDefault",self:GetChecked() and "1" or "0") end)
        N:Hint(loot,A:T("전리품 자동 획득"),A:T("전리품 창을 열면 획득 가능한 아이템을 자동으로 가방에 넣습니다. 게임 기본 자동 루팅 설정과 연동합니다."))
        local unified=CreateFrame("CheckButton",nil,p,"UICheckButtonTemplate");unified:SetWidth(24);unified:SetHeight(24);unified:SetPoint("TOPLEFT",p,"TOPLEFT",18,-289);p.unified=unified
        local unifiedLabel=N:Text(p,A:T("통합 가방 사용"),230,true);unifiedLabel:SetPoint("LEFT",unified,"RIGHT",5,0)
        unified:SetScript("OnClick",function(self) W:DB().unifiedBags=self:GetChecked() and true or false;if A.UnifiedBags then A.UnifiedBags:Close();if A.UnifiedBags.UpdateBindings then A.UnifiedBags.UpdateBindings() end end end)
        local sort=CreateFrame("CheckButton",nil,p,"UICheckButtonTemplate");sort:SetWidth(24);sort:SetHeight(24);sort:SetPoint("TOPLEFT",p,"TOPLEFT",18,-256);p.autoSort=sort
        local sortLabel=N:Text(p,A:T("가방 종류별 자동 정렬"),190,true);sortLabel:SetPoint("LEFT",sort,"RIGHT",5,0)
        sort:SetScript("OnClick",function(self) W:DB().autoSortBags=self:GetChecked() and true or false;if W:DB().autoSortBags then A.BagSort:Request(false) else A.BagSort:Stop() end end)
        N:Hint(sort,A:T("가방 자동 정렬"),A:T("아이템 변경 후 종류·세부 종류·이름 순으로 정렬합니다. 전투·루팅·거래 또는 아이템 이동 중에는 기다립니다. 전문 가방은 같은 가방 종류끼리 정렬합니다."))
        local now=N:Button(p,A:T("지금 정렬"),100,24,function() A.BagSort:Request(true) end);now:SetPoint("TOPRIGHT",p,"TOPRIGHT",-18,-256);p.sortNow=now
        local sell=CreateFrame("CheckButton",nil,p,"UICheckButtonTemplate");sell:SetWidth(24);sell:SetHeight(24);sell:SetPoint("TOPLEFT",p,"TOPLEFT",18,-322);p.autoSell=sell
        local sellLabel=N:Text(p,A:T("상인 방문 시 회색 잡템 자동 판매"),310,true);sellLabel:SetPoint("LEFT",sell,"RIGHT",5,0)
        sell:SetScript("OnClick",function(self) W:DB().autoSellJunk=self:GetChecked() and true or false end)
        local center=N:Button(p,A:T("창 정위치 복원"),170,25,function()
            W:DB().windowPosition=nil;W:DB().windowLocked=false;if A.UnifiedBags then W:DB().bagPosition=nil;A.UnifiedBags:RestorePosition() end;if W.active then W:ApplyWindowPosition(W.active);W:AnchorDock() end
        end);center:SetPoint("BOTTOM",p,"BOTTOM",0,20)
        UISpecialFrames[#UISpecialFrames+1]=p:GetName()
    end
    for key,check in pairs(self.settings.checks) do check:SetChecked(self:DB()[key]~=false) end
    self.settings.autoSell:SetChecked(self:DB().autoSellJunk~=false)
    self.settings.unified:SetChecked(self:DB().unifiedBags~=false)
    self.settings.autoSort:SetChecked(self:DB().autoSortBags==true)
    self.settings.autoLoot:SetChecked(GetCVar("autoLootDefault")=="1")
    self.settings:Show();self:SuspendForPopup(self.settings)
end
function W:Create()
    if self.frame then return end
    C:Build(D);local db=self:DB()
    local f=CreateFrame("Frame",D.namespace,UIParent);self.frame=f
    f:SetWidth(1080);f:SetHeight(700);f:SetPoint("CENTER",UIParent,"CENTER",55,0);f:SetFrameStrata("DIALOG");f:SetClampedToScreen(true);f:EnableMouse(true);f:SetMovable(true);N:Panel(f);f:Hide()
    local drag=CreateFrame("Frame",nil,f);drag:SetPoint("TOPLEFT",f,"TOPLEFT",10,-6);drag:SetWidth(650);drag:SetHeight(29);drag:EnableMouse(true);drag:RegisterForDrag("LeftButton")
    drag:SetScript("OnDragStart",function() if not W:DB().windowLocked then f:StartMoving() end end);drag:SetScript("OnDragStop",function() f:StopMovingOrSizing();W:SaveWindowPosition(f);W:AnchorDock() end)
    local title=N:Text(drag,A:ProductName(),290);title:SetPoint("LEFT",drag,"LEFT",7,0)
    self.security=N:Text(drag,"",330,true);self.security:SetPoint("LEFT",title,"RIGHT",8,0)
    local close=CreateFrame("Button",nil,f,"UIPanelCloseButton");close:SetPoint("TOPRIGHT",f,"TOPRIGHT",-3,-3);close:SetScript("OnClick",function() W:Close() end)
    f:SetScript("OnHide",function() if W.active==f and not W.switching then W:Close() end end)
    local bar=CreateFrame("Frame",nil,f);bar:SetWidth(1052);bar:SetHeight(70);bar:SetPoint("TOPLEFT",f,"TOPLEFT",14,-40);N:Panel(bar,true)
    local specs={{"target",L("TARGET"),8,140},{"args",L("ARGS"),157,184},{"raw",L("RAW"),350,604}}
    for _,s in ipairs(specs) do
        local label=N:Text(bar,s[2],s[4],true);label:SetPoint("TOPLEFT",bar,"TOPLEFT",s[3],-7);label:SetHeight(22)
        local edit=N:Edit(bar,s[4]);edit:SetPoint("TOPLEFT",bar,"TOPLEFT",s[3],-32);self[s[1]]=edit
        edit:SetScript("OnEnterPressed",function() W:Run() end)
    end
    self.target:SetScript("OnTextChanged",function() W:UpdatePreview() end);self.args:SetScript("OnTextChanged",function() W:UpdatePreview() end)
    self.raw:SetScript("OnTextChanged",function(_,user) if user and not W.updatingPreview then W.rawMode=true end end)
    local run=N:Button(bar,L("RUN"),78,28,function() W:Run() end);run:SetPoint("LEFT",self.raw,"RIGHT",9,0)
    self.content=CreateFrame("Frame",nil,f);self.content:SetWidth(1052);self.content:SetHeight(552);self.content:SetPoint("TOPLEFT",f,"TOPLEFT",14,-119)
    self:CreateCommands()
    self.status=N:Text(f,L("READY"),1030,true);self.status:SetHeight(16);self.status:SetPoint("BOTTOMLEFT",f,"BOTTOMLEFT",20,14)
    local dock=CreateFrame("Frame",D.namespace.."Dock",UIParent);self.dock=dock;dock:SetWidth(154);dock:SetFrameStrata("DIALOG");dock:EnableMouse(true);dock:SetClampedToScreen(true);N:Panel(dock);dock:Hide()
    local collapse=N:Button(dock,X("MENU"),76,24);collapse:Disable();collapse:SetAlpha(.45);self.menuTitle=collapse;collapse:SetPoint("TOPLEFT",dock,"TOPLEFT",7,-6)
    local gear=CreateFrame("Button",nil,dock);gear:SetWidth(25);gear:SetHeight(25);gear:SetPoint("TOPRIGHT",dock,"TOPRIGHT",-7,-6);gear:SetNormalTexture("Interface\\Icons\\INV_Misc_Gear_01");self.settingsButton=gear;gear:SetScript("OnClick",function() W:ShowSettings() end);N:Hint(gear,X("SETTINGS"),X("SETTINGS_HINT"))
    self.nav={};local menus={"teleports","items","spells","professions","favorites","commands","gmisland"}
    for i,key in ipairs(menus) do
        local route=key;local button=N:Button(dock,key=="gmisland" and A:L("UX_GM_ISLAND") or key=="spells" and A:L('SPY_TITLE') or key=="favorites" and A:T("GM편의기능") or key=="commands" and A:L("UX_ALL_COMMANDS") or key=="items" and A:T("아이템") or L(string.upper(key)),140,26,function() W:Navigate(route) end)
        button:SetPoint("TOPLEFT",dock,"TOPLEFT",7,-36-(i-1)*29);self.nav[key]=button
    end
    dock.fullHeight=44+#menus*29;self:RefreshDock()
    f:RegisterEvent("PLAYER_TARGET_CHANGED");f:RegisterEvent("CHAT_MSG_SYSTEM")
    f:SetScript("OnEvent",function(_,event,message)
        if event=="PLAYER_TARGET_CHANGED" then W:RefreshHeader() end
        if event=="CHAT_MSG_SYSTEM" and W:IsOpen() and type(message)=="string" then W.status:SetText(message:gsub("[\r\n]"," ")) end
    end)
    N:OnViewportChanged(function() if W.active then N:Fit(W.active,W.active:GetWidth(),W.active:GetHeight(),tonumber(W:DB().scale) or .85);W:AnchorDock() end end)
    self:RefreshHeader()
end
function W:TakeScreenshot()
    if self.captureHidden then return end
    local active=self.active;local shown=active and active:IsShown();self.captureHidden=true
    if shown then active:Hide();self.dock:Hide() end
    A:RunAfter(.1,function() if Screenshot then Screenshot() end;A:RunAfter(.5,function() if shown then active:Show();W.dock:Show() end;W.captureHidden=nil end) end)
end
local combat=CreateFrame("Frame");combat:RegisterEvent("PLAYER_REGEN_DISABLED")
combat:SetScript("OnEvent",function() if W:DB().hideCombat~=false then W:Close(); end end)

local bank=CreateFrame("Frame");bank:RegisterEvent("BANKFRAME_OPENED")
bank:SetScript("OnEvent",function() W:Close() end)
