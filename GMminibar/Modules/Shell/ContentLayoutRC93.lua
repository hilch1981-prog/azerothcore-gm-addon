local A=AzerothAdminAC335
local W,N=A.Workbench,A.NativeUI
local function place(o,p,x,y,w,h)
    if not o then return end
    o:ClearAllPoints();o:SetPoint("TOPLEFT",p,"TOPLEFT",x,-y)
    if w then o:SetWidth(w) end;if h then o:SetHeight(h) end
end
function A:ReflowContentRC93(f)
    if f==self.teleportFrame then
        local step=27;local width=f:GetWidth()-28
        -- Headers and data share the same available width. The legacy fixed
        -- widths totalled 1126px and extended past the 1052px row boundary.
        local weights={30,112,68,148,448,114,106};local columns={};local used=0
        for i,weight in ipairs(weights) do
            columns[i]=i==#weights and (width-10-used) or math.floor((width-10)*weight/1126)
            used=used+columns[i]
        end
        local headerX=19
        for i,header in ipairs(f.rc3Headers or {}) do
            place(header,f,headerX,155,columns[i]-6,18)
            local label=header:GetFontString();if label then label:SetWidth(columns[i]-6) end
            headerX=headerX+columns[i]
        end
        for i,row in ipairs(f.rows or {}) do
            place(row,f,14,180+(i-1)*step,width,25)
            local cellX=5
            for column,cell in ipairs(row.rc3Cells or {}) do
                place(cell,row,cellX,4,columns[column]-6,18)
                cellX=cellX+columns[column]
            end
            row:SetScript("OnClick",function(s,mouse)
                if not s.aaeTeleport then return end
                if mouse=="RightButton" then W:ToggleMapFavorite(s.aaeTeleport) else A:RunTeleportRow(s.aaeTeleport) end
            end)
        end
        if not f.dispatchText then f.dispatchText=N:Text(f,A:T("좌표를 선택하면 이동 요청을 보냅니다."),width,true) end
        place(f.dispatchText,f,200,f:GetHeight()-57,width-375,18)
    elseif f==self.itemBrowser then
        local x=246;local w=(f:GetWidth()-x-28)/2;local y=f.advancedVisible and 191 or 131
        for i,row in ipairs(f.rows or {}) do
            place(row,f,x+((i-1)%2)*(w+10),y+math.floor((i-1)/2)*48,w,44)
            row.name:SetWidth(w-54);row.meta:SetWidth(w-54)
        end
        if f.categoryScroll then f.categoryScroll:SetHeight(f:GetHeight()-130) end
        if f.pageText then f.pageText:SetWidth(f:GetWidth()-x-220) end
        if f.next then f.next:ClearAllPoints();f.next:SetPoint("BOTTOMRIGHT",f,"BOTTOMRIGHT",-20,22) end
    elseif f==self.professionFrame then
        local h=f:GetHeight()-92;local pw=190;local rw=math.floor((f:GetWidth()-pw-52)*.51);local dw=f:GetWidth()-pw-rw-52
        place(f.professionPanel,f,15,72,pw,h);place(f.recipePanel,f,15+pw+10,72,rw,h);place(f.detailPanel,f,15+pw+rw+20,72,dw,h)
        local step=(h-48)/math.max(1,#f.professionButtons)
        for i,b in ipairs(f.professionButtons or {}) do place(b,f.professionPanel,10,34+(i-1)*step,pw-20,math.min(42,step-5)) end
        f.searchBox:SetWidth(rw-166)
        if f.tierDropdown then place(f.tierDropdown,f.recipePanel,math.floor(rw/2)-4,48) end
        if UIDropDownMenu_SetWidth then UIDropDownMenu_SetWidth(f.categoryDropdown,math.floor(rw/2)-35);UIDropDownMenu_SetWidth(f.tierDropdown,math.floor(rw/2)-35) end
        for _,row in ipairs(f.recipeRows or {}) do row:SetWidth(rw-20) end
        f.pageText:SetWidth(rw-174)
        f.next:ClearAllPoints();f.next:SetPoint("BOTTOMRIGHT",f.recipePanel,"BOTTOMRIGHT",-10,9)
        if f.outputButton then f.outputButton:SetWidth(dw-20);if f.outputButton.name then f.outputButton.name:SetWidth(dw-84) end end
        for _,key in ipairs({"sourceText","noReagentText"}) do if f[key] then f[key]:SetWidth(dw-24) end end
        for i,b in ipairs(f.reagentButtons or {}) do
            local bw=(dw-30)/2;local bh=math.min(98,math.floor((h-210)/4)-6)
            place(b,f.detailPanel,10+((i-1)%2)*(bw+10),190+math.floor((i-1)/2)*(bh+6),bw,bh)
            b.name:SetWidth(bw-54);b.count:SetWidth(bw-54)
        end
    end
end
local position=W.ApplyWindowPosition
local pending={}
local updates=CreateFrame("Frame")
updates:SetScript("OnUpdate",function()
    local queue=pending;pending={}
    for f in pairs(queue) do
        if f:IsShown() then
            if f==A.teleportFrame then A:RefreshTeleportWindow()
            elseif f==A.itemBrowser then A:RefreshItemBrowserRows(false)
            elseif f==A.professionFrame then A:RefreshProfessionRows() end
        end
    end
end)
function W:ApplyWindowPosition(f)
    position(self,f)
    A:ReflowContentRC93(f)
    if f==A.teleportFrame then A:RefreshTeleportWindow()
    elseif f==A.itemBrowser then A:RefreshItemBrowserRows(false)
    elseif f==A.professionFrame then A:RefreshProfessionRows() end
    pending[f]=nil
    if not f.rc93SizeHook then
        f.rc93SizeHook=true;f:HookScript("OnSizeChanged",function(s)
            if not s:IsShown() or s.rc93RefreshingSize then return end
            -- Size setters can fire synchronously in FrameXML. Refresh once
            -- after the final dimensions settle, never inside a size callback.
            pending[s]=true
        end)
    end
    if f==A.teleportFrame or f==A.itemBrowser or f==A.professionFrame then
        local backdrop={};for key,value in pairs(N.window) do backdrop[key]=value end
        backdrop.bgFile="Interface\\ChatFrame\\ChatFrameBackground"
        f:SetBackdrop(backdrop);f:SetBackdropColor(.025,.035,.045,1)
    end
end
for _,name in ipairs({"RefreshItemBrowserRows","RefreshProfessionRows","RefreshTeleportWindow"}) do
    local refresh=A[name]
    A[name]=function(self,...)
        local f=name=="RefreshItemBrowserRows" and self.itemBrowser or name=="RefreshProfessionRows" and self.professionFrame or self.teleportFrame
        if f then self:ReflowContentRC93(f) end
        return refresh(self,...)
    end
end
