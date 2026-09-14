local A=AzerothAdminAC335
local W,N=A.Workbench,A.NativeUI
local flight=A.RunTeleportRow
function A:RunTeleportRow(row)
    local frame=self.teleportFrame
    local restore=frame and frame:IsShown() and self:IsTeleportUsable(row)
    local request=restore and {expires=GetTime()+60} or nil
    if request then self.teleportReturn=request end
    local ok=flight(self,row)
    if request and ok then
        self.teleportReturn=request
        self:RunAfter(.1,function() if A.teleportReturn==request and not A.loadingWorld and not frame:IsShown() then A:OpenTeleportWindow() end end)
    elseif request then self.teleportReturn=nil end
    return ok
end
local close=W.Close
function W:Close()
    if not A.loadingWorld then A.teleportReturn=nil;A.pendingTeleportDifficulty=nil end
    return close(self)
end
local events=CreateFrame("Frame")
for _,e in ipairs({"LOADING_SCREEN_ENABLED","LOADING_SCREEN_DISABLED","PLAYER_LEAVING_WORLD","PLAYER_ENTERING_WORLD","PLAYER_LEVEL_UP","QUEST_LOG_UPDATE","QUEST_DETAIL"}) do events:RegisterEvent(e) end
events:SetScript("OnEvent",function(_,event)
    if event=="LOADING_SCREEN_ENABLED" or event=="PLAYER_LEAVING_WORLD" then A.loadingWorld=true
    elseif event=="PLAYER_ENTERING_WORLD" or event=="LOADING_SCREEN_DISABLED" then
        A.loadingWorld=nil
        if A.teleportReturn and GetTime()<A.teleportReturn.expires then
            local request=A.teleportReturn
            A:RunAfter(.4,function()
                if A.teleportReturn==request and not A.loadingWorld and GetTime()<request.expires then
                    A.teleportReturn=nil;A:OpenTeleportWindow()
                end
            end)
        end
    end
    if event=="PLAYER_LEVEL_UP" and A.teleportFrame then A:RefreshTeleportWindow() end
    if A.DecorateQuestTitles then A:DecorateQuestTitles() end
end)
function A:DecorateQuestTitles()
    if self.decoratingQuests then return end;self.decoratingQuests=true
    local offset=QuestLogListScrollFrame and FauxScrollFrame_GetOffset and FauxScrollFrame_GetOffset(QuestLogListScrollFrame) or 0
    for i=1,(QUESTS_DISPLAYED or 25) do
        local b=QuestLogScrollFrame and QuestLogScrollFrame.buttons and QuestLogScrollFrame.buttons[i] or _G["QuestLogTitle"..i]
        local label=b and (b.normalText or b:GetFontString()) or _G["QuestLogTitle"..i.."NormalText"]
        if b and label then
            local rowOffset=QuestLogScrollFrame and HybridScrollFrame_GetOffset and HybridScrollFrame_GetOffset(QuestLogScrollFrame) or offset
            local name,level,_,header,_,_,_,id=A.ReadQuestLogTitle(i+rowOffset)
            if name and not header and tonumber(id) and id>0 then
                label:SetText(name)
                if not b.gmQuestMeta then
                    b.gmQuestMeta=b:CreateFontString(nil,'OVERLAY','GameFontNormalSmall')
                    b.gmQuestMeta:SetWidth(105);b.gmQuestMeta:SetJustifyH('RIGHT')
                end
                b.gmQuestMeta:SetText('['..id..' · Lv.'..tostring(level)..']');b.gmQuestMeta:Show()
                -- Native check marks were anchored to the title's right edge.
                -- Reserve separate title, metadata, check, and native tag areas.
                local check=b.check or _G[(b:GetName() or 'QuestLogTitle'..i)..'Check']
                local tag=b.tag or _G[(b:GetName() or 'QuestLogTitle'..i)..'Tag']
                local tagWidth=64 -- reserve the same status column on every row
                local checkWidth=18
                local right=5+tagWidth+5
                if tag then tag:ClearAllPoints();tag:SetPoint('RIGHT',b,'RIGHT',-5,0);tag:SetWidth(tagWidth);tag:SetJustifyH('RIGHT') end
                A:ApplyLocaleFont(b.gmQuestMeta)
                if check then check:ClearAllPoints();check:SetPoint('RIGHT',b,'RIGHT',-right,0) end
                b.gmQuestMeta:ClearAllPoints();b.gmQuestMeta:SetPoint('RIGHT',b,'RIGHT',-(right+checkWidth+6),0)
                label:SetWidth(math.max(1,(b:GetWidth()>0 and b:GetWidth() or 285)-105-right-checkWidth-22))
            elseif b.gmQuestMeta then b.gmQuestMeta:Hide() end
        end
    end
    local q=A.WorkbenchAdapter:SelectedQuest()
    if q then
        local text=tostring(q.title or "")
        if QuestLogFrame and QuestLogFrame:IsShown() then
            if QuestLogQuestTitle then QuestLogQuestTitle:SetText(text) end
            if QuestInfoTitleHeader then QuestInfoTitleHeader:SetText(text) end
        end
    end
    self.decoratingQuests=nil
end
for _,name in ipairs({"QuestLog_Update","QuestLog_UpdateQuestDetails","QuestFrameDetailPanel_OnShow","QuestInfo_Display","QuestLogQuests_Update"}) do
    if type(_G[name])=="function" then hooksecurefunc(name,function() A:DecorateQuestTitles() end) end
end
local function values(row)
    row.faction=A.GetTeleportFaction(row)
    return W:MapInfo(row)
end
function A:MatchesTeleportColumns(row,f)
    if not next(f.columnFilters or {}) then return true end
    local v=values(row)
    for column,wanted in pairs(f.columnFilters or {}) do if v[column]~=wanted then return false end end
    return true
end
function A:TeleportLevelColor(row)
    local low,high=A.GetTeleportLevelRange(row)
    if not low then return .7,.7,.7 end
    local level=UnitLevel("player")
    local target=level<low and low or (level>(high or low) and (high or low) or level)
    local c=GetQuestDifficultyColor(target)
    return c.r,c.g,c.b
end
function A:ChooseTeleportColumn(column,anchor)
    local f=self.teleportFrame
    local menu=self.teleportFilterMenu
    if menu and menu:IsShown() and menu.column==column then menu:Hide();return end
    if not menu then
        menu=CreateFrame("Frame",nil,UIParent);self.teleportFilterMenu=menu;menu:SetSize(240,278);N:Panel(menu,true);menu:SetBackdropColor(.025,.035,.045,1);menu:SetFrameStrata("TOOLTIP");menu.rows={}
        menu:EnableMouseWheel(true)
        for i=1,10 do
            local index=i
            local b=N:Button(menu,"",220,24,function()
                local value=menu.options[menu.offset+index]
                if not value then return end
                f.columnFilters=f.columnFilters or {}
                if value==A:T("전체") then f.columnFilters[menu.column]=nil else f.columnFilters[menu.column]=value end
                if menu.column==2 then f.columnFilters[4]=nil end
                f.page=1;menu:Hide();A:RefreshTeleportWindow()
            end);b:SetPoint("TOPLEFT",menu,"TOPLEFT",10,-8-(i-1)*26);menu.rows[i]=b
        end
        function menu:Render()
            for i,b in ipairs(self.rows) do local value=self.options[self.offset+i];b:SetText(value or "");if value then b:Show() else b:Hide() end end
        end
        menu:SetScript("OnMouseWheel",function(s,d) s.offset=math.max(0,math.min(math.max(0,#s.options-10),s.offset-d));s:Render() end)
    end
    local seen={};menu.options={A:T("전체")};menu.offset=0;menu.column=column
    for _,row in ipairs(A.Data:SearchTeleports("","server")) do
        if A:IsTeleportUsable(row)and (f.category=="all"or row.group==f.category)and (f.regionFilter=="ALL"or row.regionKey==f.regionFilter)and (column==2 or not f.columnFilters or not f.columnFilters[2]or values(row)[2]==f.columnFilters[2])then local v=values(row)[column];if v and not seen[v] then seen[v]=true;menu.options[#menu.options+1]=v end end
    end
    table.sort(menu.options,function(a,b)
        if a==b then return false elseif a==A:T("전체")then return true elseif b==A:T("전체")then return false end
        if column==6 then
            local al,ah=A.GetTeleportLevelRange({levelText=a});local bl,bh=A.GetTeleportLevelRange({levelText=b})
            al,ah,bl,bh=al or math.huge,ah or math.huge,bl or math.huge,bh or math.huge
            if al~=bl then return al<bl elseif ah~=bh then return ah<bh end
        end
        return a<b
    end)
    menu:ClearAllPoints();menu:SetPoint("TOPLEFT",anchor,"BOTTOMLEFT",0,-3);menu:SetClampedToScreen(true);menu:Render();menu:Show()
end
local reflow=A.ReflowContentRC93
function A:ReflowContentRC93(f)
    reflow(self,f)
    if f~=self.teleportFrame or not f.rc3Headers then return end
    local order={1,2,4,5,3,6,7};local widths={.03,.11,.17,.39,.09,.10,.11}
    local width=f:GetWidth()-38;local x=19
    for j,column in ipairs(order) do
        local w=math.floor(width*widths[j]);local h=f.rc3Headers[column]
        h:ClearAllPoints();h:SetPoint("TOPLEFT",f,"TOPLEFT",x,-155);h:SetWidth(w-6)
        local label=({[1]="★",[7]=A:T("진영"),[3]=A:T("유형"),[2]=A:T("대륙"),[4]=A:T("지역·도시"),[5]=A:T("목적지"),[6]=A:T("권장 레벨")})[column]
        h:SetText(label..(column==6 and (f.rc3Sort==6 and f.rc3Ascending~=false and " ▲"or " ▼")or column~=1 and column~=5 and " ▼"or ""))
        if h:GetFontString() then h:GetFontString():SetWidth(w-6) end
        if column==6 then
            h:RegisterForClicks('LeftButtonUp','RightButtonUp')
            h:SetScript('OnClick',function(b,mouse)
                if mouse=='RightButton'then A:ChooseTeleportColumn(6,b);return end
                if f.rc3Sort==6 then f.rc3Ascending=not f.rc3Ascending else f.rc3Sort=6;f.rc3Ascending=true end
                f.sortKey='level';f.sortAscending=f.rc3Ascending;f.page=1
                if A.teleportFilterMenu then A.teleportFilterMenu:Hide()end
                A:RefreshTeleportWindow()
            end)
            N:Hint(h,A:T('권장 레벨'),A:T('왼쪽 클릭: 레벨 오름차순 / 내림차순\n오른쪽 클릭: 레벨 범위 선택'))
        elseif column~=1 and column~=5 then h:SetScript("OnClick",function(b) A:ChooseTeleportColumn(column,b) end) end
        for _,row in ipairs(f.rows or {}) do if row.rc3Cells then
            local c=row.rc3Cells[column];c:ClearAllPoints();c:SetPoint("TOPLEFT",row,"TOPLEFT",x-14,-4);c:SetWidth(w-6)
        end end
        x=x+w
    end
    if not f.allDestinations then
        f.allDestinations=N:Button(f,A:T("전체 보기"),100,24,function()
            f.columnFilters={};f.aaeFavOnly=false;f.category="all";f.regionFilter="ALL";f.page=1;f.search:SetText("");f.serverCheck:SetChecked(true);f.progressCheck:SetChecked(false)
            A:RefreshTeleportRegionDropdown();A:RefreshTeleportWindow()
        end)
        f.allDestinations:SetPoint("TOPRIGHT",f,"TOPRIGHT",-160,-122)
        f:HookScript("OnHide",function() if A.teleportFilterMenu then A.teleportFilterMenu:Hide() end;if not A.loadingWorld then A.pendingTeleportDifficulty=nil end end)
    end
end
local refresh=A.RefreshTeleportWindow
function A:RefreshTeleportWindow()
    refresh(self)
    local f=self.teleportFrame;if not f then return end
    self:ReflowContentRC93(f)
    for _,b in ipairs(f.rows or {}) do if b.aaeTeleport and b.rc3Cells then
        local r,g,blue=self:TeleportLevelColor(b.aaeTeleport)
        for _,i in ipairs({2,4,5,6}) do b.rc3Cells[i]:SetTextColor(r,g,blue) end
    end end
end

-- FrameXML can replace labels after QUEST_LOG_UPDATE and lazily create rows.
local titleRefresh=CreateFrame("Frame");local elapsed=0
titleRefresh:SetScript("OnUpdate",function(_,dt)
    elapsed=elapsed+dt;if elapsed<.2 then return end;elapsed=0
    if (QuestLogFrame and QuestLogFrame:IsShown()) or (QuestFrame and QuestFrame:IsShown()) then A:DecorateQuestTitles() end
end)
