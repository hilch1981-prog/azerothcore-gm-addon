local A = AzerothAdminAC335
local PER_PAGE=12
function A:RefreshDatabaseWindow()
    local frame=self.databaseWindow; if not frame then return end
    local rows=self.Data:SearchDatabase(frame.search:GetText(),frame.database or "all"); local pages=math.max(1,math.ceil(table.getn(rows)/PER_PAGE)); frame.page=math.max(1,math.min(frame.page or 1,pages)); local start=(frame.page-1)*PER_PAGE+1
    for i=1,PER_PAGE do local b=frame.rows[i]; local row=rows[start+i-1]; b.aaeDatabase=row; if row then b:SetText("["..row.database.."] "..row.name.." — "..row.description); b:Show() else b:Hide() end end
    frame.pageText:SetText(self:L("PAGE",frame.page,pages)); frame.status:SetText("Catalog: "..table.getn(self.Data.databaseCatalog).." entries · server baseline "..self.ReleaseSourceInfo.server_baseline); self.UI:SetEnabled(frame.prev,frame.page>1); self.UI:SetEnabled(frame.next,frame.page<pages)
end
function A:OpenDatabaseWindow()
    local frame=self.databaseWindow
    if not frame then
        frame=self.UI:CreateWindow("database",self:L("DATABASE"),700,460); self.databaseWindow=frame; frame.page=1; frame.database="all"
        local search=self.UI:EditBox(frame,300,24); search:SetPoint("TOPLEFT",frame,"TOPLEFT",16,-54); frame.search=search; search:SetScript("OnEnterPressed",function(self) self:ClearFocus(); frame.page=1; A:RefreshDatabaseWindow() end)
        local go=self.UI:Button(frame,80,24,self:L("SEARCH"),"utility"); go:SetPoint("LEFT",search,"RIGHT",8,0); go:SetScript("OnClick",function() frame.page=1; A:RefreshDatabaseWindow() end)
        local filters={{"all","ALL"},{"auth","auth"},{"characters","characters"},{"world","world"},{"addon","EMBEDDED_DATA"}}
        for i,f in ipairs(filters) do local databaseID=f[1]; local filterLabel=f[2]; local b=self.UI:Button(frame,120,22,self:L(filterLabel),"utility"); b:SetPoint("TOPLEFT",frame,"TOPLEFT",16+(i-1)*130,-86); b:SetScript("OnClick",function() frame.database=databaseID; frame.page=1; A:RefreshDatabaseWindow() end) end
        frame.rows={}
        for i=1,PER_PAGE do local b=self.UI:RowLabel(frame,660,23); b:SetPoint("TOPLEFT",frame,"TOPLEFT",16,-118-(i-1)*25); b:SetScript("OnClick",function(self) if self.aaeDatabase then A:Print("["..self.aaeDatabase.database.."] "..self.aaeDatabase.name.." — "..self.aaeDatabase.description) end end); frame.rows[i]=b end
        local counts=self.ReleaseSourceInfo.counts; local server=self.ReleaseSourceInfo.server_counts
        local data=self.UI:Text(frame,self:L("DATA_COUNTS",counts.item_sources,counts.professions,counts.mop_teleports).."\n"..self:L("SERVER_COUNTS",server.items,server.quests,server.creatures,server.teleports),"small"); data:SetPoint("BOTTOMLEFT",frame,"BOTTOMLEFT",16,48); data:SetWidth(660); data:SetJustifyH("LEFT")
        local prev=self.UI:Button(frame,70,22,self:L("PREVIOUS"),"utility"); prev:SetPoint("BOTTOMLEFT",frame,"BOTTOMLEFT",220,16); prev:SetScript("OnClick",function() frame.page=frame.page-1; A:RefreshDatabaseWindow() end); frame.prev=prev
        local page=self.UI:Text(frame,"","small"); page:SetWidth(120); page:SetJustifyH("CENTER"); page:SetPoint("LEFT",prev,"RIGHT",8,0); frame.pageText=page
        local next=self.UI:Button(frame,70,22,self:L("NEXT"),"utility"); next:SetPoint("LEFT",page,"RIGHT",8,0); next:SetScript("OnClick",function() frame.page=frame.page+1; A:RefreshDatabaseWindow() end); frame.next=next
        local status=self.UI:Text(frame,"","small"); status:SetPoint("BOTTOMLEFT",frame,"BOTTOMLEFT",16,18); frame.status=status
    end
    self:RefreshDatabaseWindow(); self.UI:ShowWindow(frame)
end
