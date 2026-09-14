local A=AzerothAdminAC335
local U,W,N=A.UnifiedBags,A.Workbench,A.NativeUI
local function checked(v) return v==true or v==1 end
local function merchant() return MerchantFrame and MerchantFrame:IsShown() and MerchantFrame.selectedTab~=2 end
local function copy(t) local r={};for k,v in pairs(t or {}) do r[k]=v end;return r end
function U:ActualItemLevel(bag,slot,item)
    if GetDetailedItemLevelInfo then local v=GetDetailedItemLevelInfo(item);if v then return v end end
    self.levelCache=self.levelCache or {}
    if self.levelCache[item] then return self.levelCache[item] end
    if not self.levelTooltip then self.levelTooltip=CreateFrame("GameTooltip","GMminibarItemLevelTooltip",UIParent,"GameTooltipTemplate") end
    local tip=self.levelTooltip
    if tip.SetBagItem then
        tip:SetOwner(UIParent,"ANCHOR_NONE");tip:ClearLines();tip:SetBagItem(bag,slot)
        local pattern=ITEM_LEVEL and ITEM_LEVEL:gsub("%%d","(%%d+)")
        for i=1,tip:NumLines() do
            local line=_G["GMminibarItemLevelTooltipTextLeft"..i];local text=line and line:GetText()
            local v=text and ((pattern and text:match(pattern)) or text:match("아이템 레벨%s*(%d+)"))
            if v then tip:Hide();self.levelCache[item]=tonumber(v);return tonumber(v) end
        end
        tip:Hide()
    end
    local _,_,_,level=GetItemInfo(item)
    return level
end
function U:Filters(mode)
    local db=W:DB();db.bulkFilters=db.bulkFilters or {}
    db.bulkFilters[mode]=db.bulkFilters[mode] or {q0=true}
    return db.bulkFilters[mode]
end
function U:Matches(b,s,mode,filters,selection)
    if self:IsPinned(b,s) then return end
    local item=GetContainerItemLink(b,s);if not item then return end
    local _,count,locked=GetContainerItemInfo(b,s);if checked(locked) then return end
    local _,_,quality,_,_,class,subclass,_,_,_,price=GetItemInfo(item)
    if quality==nil or (mode=="sell" and (not price or price<=0)) then return end
    local key=b..":"..s
    if mode=='sell' and self:IsQuestItem(b,s) then return end
    if selection then
        local selected=selection[key]
        if selected and selected.link==item and selected.count==(count or 1) then return item end
        return
    end
    local quest,qid;if GetContainerItemQuestInfo then quest,qid=GetContainerItemQuestInfo(b,s) end
    local isQuest=self:IsQuestItem(b,s)
    -- Quest items require their own explicit checkbox even if quality matches.
    if isQuest then if filters.quest then return item end;return end
    local consumable=class=="Consumable" or class=="소모품" or (GetItemClassInfo and class==GetItemClassInfo(0))
    if filters['q'..quality] or (filters.consumable and consumable) then return item end
end
function U:QueueBulk(mode)
    if self.selling or InCombatLockdown() or GetCursorInfo() or (A.BagSort and A.BagSort.pending) then A:Print(A:T("전투·아이템 이동이 끝난 뒤 실행해 주세요."));return end
    if mode=="sell" and not merchant() then A:Print(A:T("판매 조건은 저장되었습니다. 상인과 대화한 뒤 판매를 실행해 주세요."));return end
    local filters=copy(self:Filters(mode));local selection=self.multiSelect and copy(self.selected) or nil
    local queue={};local preview={}
    for b=0,4 do for s=1,GetContainerNumSlots(b) do
        local item=self:Matches(b,s,mode,filters,selection)
        if item then local _,count=GetContainerItemInfo(b,s);queue[#queue+1]={b=b,s=s,item=item,count=count or 1};if #preview<8 then preview[#preview+1]=item.." ×"..(count or 1) end end
    end end
    if #queue==0 then A:Print(A:T("선택 조건에 맞는 처리 가능한 아이템이 없습니다."));return end
    self.destroyPrompt=queue
    local function cancel() if U.destroyPrompt==queue then U.destroyPrompt=nil end end
    StaticPopupDialogs.GMMINIBAR_BULK={text=(mode=="destroy" and A:T("일괄 파괴: %s칸\n%s\n파괴한 아이템은 복구할 수 없습니다.") or A:T("일괄 판매: %s칸\n%s")),button1=mode=="destroy" and A:T("파괴") or A:T("판매"),button2=A:T("취소"),timeout=0,whileDead=true,hideOnEscape=true,OnCancel=cancel,OnHide=cancel,
    OnAccept=function()
        if U.destroyPrompt~=queue then return end;cancel()
        if U.selling or InCombatLockdown() or GetCursorInfo() or not U.frame:IsShown() or (mode=="sell" and not merchant()) then return end
        U.selling={queue=queue,index=1,sold=0,destroy=mode=="destroy",custom=true,filters=filters,selection=selection};U.selected={};U:Refresh()
    end}
    StaticPopup_Show("GMMINIBAR_BULK",#queue,table.concat(preview,"\n"))
end
function U:BulkPanel(mode)
    self.autoSellPending=nil
    local p=self.bulkPanel
    if not p then
        p=CreateFrame("Frame",nil,UIParent);self.bulkPanel=p;p:SetSize(330,345);p:SetPoint("CENTER");p:SetFrameStrata("DIALOG");p:SetClampedToScreen(true);N:Panel(p)
        p.title=N:Text(p,"",290,true);p.title:SetPoint("TOPLEFT",p,"TOPLEFT",15,-14)
        p.checks={}
        local options={{"q0",A:T("회색 · 하급")},{"q1",A:T("흰색 · 일반")},{"q2",A:T("녹색 · 고급")},{"q3",A:T("파란색 · 희귀")},{"q4",A:T("보라색 · 영웅")},{"q5",A:T("주황색 · 전설")},{"q6",A:T("유물")},{"q7",A:T("계승품")},{"quest",A:T("퀘스트 아이템")},{"consumable",A:T("소모품 · 회복템 포함")}}
        for i,v in ipairs(options) do
            local key=v[1];local b=CreateFrame("CheckButton",nil,p,"UICheckButtonTemplate");b:SetSize(24,24);b:SetPoint("TOPLEFT",p,"TOPLEFT",12+((i-1)%2)*155,-45-math.floor((i-1)/2)*34)
            local t=N:Text(p,v[2],130,true);t:SetPoint("LEFT",b,"RIGHT",0,0)
            b:SetScript("OnClick",function(s) U:Filters(p.mode)[key]=checked(s:GetChecked()) end);p.checks[key]=b
        end
        local hint=N:Text(p,A:T("품질 또는 종류에 해당하면 포함합니다.\n퀘스트템은 판매에서 항상 제외됩니다.\n다중 선택 모드에서는 선택한 칸만 처리합니다.\n선택 조건은 즉시 저장됩니다."),300,true);hint:SetPoint("TOPLEFT",p,"TOPLEFT",15,-220)
        local run=N:Button(p,A:T("대상 확인 / 실행"),160,26,function() U:QueueBulk(p.mode) end);run:SetPoint("BOTTOMLEFT",p,"BOTTOMLEFT",15,14)
        local close=N:Button(p,A:T("닫기"),100,26,function() p:Hide() end);close:SetPoint("BOTTOMRIGHT",p,"BOTTOMRIGHT",-15,14)
    end
    p.mode=mode;p.title:SetText(mode=="sell" and A:T("일괄 판매 · 조건 선택") or A:T("일괄 파괴 · 조건 선택"))
    for key,b in pairs(p.checks) do b:SetChecked(self:Filters(mode)[key]);b:Enable() end
    if mode=='sell' then p.checks.quest:SetChecked(false);p.checks.quest:Disable() end;p:Show()
end
function U:Decorate()
    for key,b in pairs(self.buttons) do
        if not b.bagNumber then
            b.bagNumber=N:Text(b,"",18,true);b.bagNumber:SetPoint("BOTTOMLEFT",b,"BOTTOMLEFT",0,1);b.bagNumber:SetTextColor(.4,1,1)
            b.itemLevel=N:Text(b,"",36,true);b.itemLevel:SetPoint("TOP",b,"TOP",0,2);b.itemLevel:SetJustifyH("CENTER");b.itemLevel:SetTextColor(1,.85,.1)
            local overlay=CreateFrame("CheckButton",nil,b,"UICheckButtonTemplate");b.multi=overlay;overlay:SetAllPoints(b);overlay:SetFrameLevel(b:GetFrameLevel()+5)
            overlay:SetScript("OnClick",function(s)
                local bag,slot=key:match("^(%d+):(%d+)$");bag,slot=tonumber(bag),tonumber(slot)
                if U.pinMode then U:TogglePin(bag,slot);U:Refresh();return end
                if U:IsPinned(bag,slot) then s:SetChecked(false);return end
                local item=GetContainerItemLink(bag,slot);local _,count=GetContainerItemInfo(bag,slot)
                U.selected=U.selected or {};U.selected[key]=checked(s:GetChecked()) and item and {link=item,count=count or 1} or nil
            end)
            overlay:SetScript('OnEnter',function(s)
                local bag,slot=key:match('^(%d+):(%d+)$');bag,slot=tonumber(bag),tonumber(slot)
                local GameTooltip=A:BeginHintTooltip(s,'ANCHOR_RIGHT');GameTooltip:SetBagItem(bag,slot)
                if U.pinMode then GameTooltip:AddLine(U:IsPinned(bag,slot) and A:T('클릭: 고정 해제') or A:T('클릭: 이 위치에 고정'),.3,.7,1) end
                A:StyleHintTooltip();GameTooltip:Show()
            end)
            overlay:SetScript('OnLeave',function(s) A:HideHintTooltip(s) end)
            b.pinnedGlow=b:CreateTexture(nil,'OVERLAY');b.pinnedGlow:SetTexture('Interface\\Buttons\\UI-ActionButton-Border')
            b.pinnedGlow:SetBlendMode('ADD');b.pinnedGlow:SetVertexColor(.1,.5,1)
            b.pinnedGlow:SetSize(60,60);b.pinnedGlow:SetPoint('CENTER',b,'CENTER',0,0);b.pinnedGlow:Hide()
        end
        local bag,slot=key:match("^(%d+):(%d+)$");bag,slot=tonumber(bag),tonumber(slot)
        local item=GetContainerItemLink(bag,slot)
        local pinned=self:IsPinned(bag,slot)
        if pinned then b.pinnedGlow:Show() else b.pinnedGlow:Hide() end
        b.bagNumber:SetText(item and tostring(bag) or "")
        local level
        if item then
            level=self:ActualItemLevel(bag,slot,item)
        end
        b.itemLevel:SetText(level and tostring(level) or "")
        if self.pinMode then b.multi:Show();b.multi:SetChecked(pinned)
        elseif self.multiSelect then b.multi:Show();local selected=self.selected and self.selected[key];local _,count=GetContainerItemInfo(bag,slot)
            if selected and (selected.link~=item or selected.count~=(count or 1)) then self.selected[key]=nil;selected=nil end
            b.multi:SetChecked(selected~=nil)
        else b.multi:Hide() end
    end
end
local create=U.Create
function U:Create()
    create(self);if self.rc94 then return end;self.rc94=true
    local f=self.frame;local size=W:DB().bagSize or {columns=8,rows=3};self.columns=8;self.visibleRows=math.max(3,tonumber(size.rows) or 3)
    f:SetWidth(self.columns*42+48);self.scroll:SetWidth(self.columns*42);self.content:SetWidth(self.columns*42)
    f:SetResizable(false)
    function U:ChangeRows(delta)
        local maximum=math.max(3,math.floor((UIParent:GetHeight()-204)/42))
        self.visibleRows=math.max(3,math.min(maximum,self.visibleRows+delta))
        self.columns=8;W:DB().bagSize={columns=8,rows=self.visibleRows};self:Refresh()
    end
    self.growButton=N:Button(f,'▼',22,22,function() U:ChangeRows(1) end)
    self.shrinkButton=N:Button(f,'▲',22,22,function() U:ChangeRows(-1) end)
    self.drag:SetWidth(110)
    self.growButton:SetFrameLevel(f:GetFrameLevel()+6);self.shrinkButton:SetFrameLevel(f:GetFrameLevel()+6)
    self.growButton:Enable();self.shrinkButton:Enable()
    self.growButton:SetPoint('TOPLEFT',f,'TOPLEFT',180,-10)
    self.shrinkButton:SetPoint('TOPLEFT',f,'TOPLEFT',206,-10)
    N:Hint(self.growButton,A:T('가방 높이 늘리기'),A:T('세로 한 줄 추가 · 가로 8칸 고정'))
    N:Hint(self.shrinkButton,A:T('가방 높이 줄이기'),A:T('세로 한 줄 축소 · 최소 3줄'))
    self.sell:SetNormalTexture("Interface\\Icons\\INV_Misc_Bag_10_Blue")
    for _,spec in ipairs({{self.destroy,A:T('파괴')},{self.sort,A:T('정렬')}}) do
        local label=N:Text(spec[1],spec[2],26,true);label:SetPoint('BOTTOM',spec[1],'BOTTOM',0,-2);label:SetTextColor(1,.85,.2)
    end
    local sellLabel=N:Text(self.sell,A:T("판매"),26,true);sellLabel:SetPoint("BOTTOM",self.sell,"BOTTOM",0,-2);sellLabel:SetTextColor(1,.85,.2)
    self.sell:SetScript("OnClick",function() U:BulkPanel("sell") end);N:Hint(self.sell,A:T("일괄 판매"),A:T("조건 선택 및 저장 · 상인 거래 중 실행"))
    self.destroy:SetScript("OnClick",function() U:BulkPanel("destroy") end);N:Hint(self.destroy,A:T("일괄 파괴"),A:T("조건 선택 및 저장 · 처리할 아이템 확인"))
    local multi=N:Button(f,A:T("선택"),45,22,function(b) U.pinMode=false;U.pinButton:SetText(A:T('아이템 고정'));U.multiSelect=not U.multiSelect;U.selected={};b:SetText(U.multiSelect and A:T("선택 중") or A:T("선택"));U:Refresh() end);self.selectButton=multi;multi:SetPoint("TOPLEFT",f,"TOPLEFT",128,-10);multi:SetFrameLevel(f:GetFrameLevel()+5)
    f:HookScript("OnHide",function() if U.bulkPanel then U.bulkPanel:Hide() end;if StaticPopup_Hide then StaticPopup_Hide("GMMINIBAR_BULK") end end)
end
-- Bulk processing is initiated explicitly through the saved-condition panel.
function U:AutoSellStep() self.autoSellPending=nil end
local cache=CreateFrame("Frame");cache:RegisterEvent("GET_ITEM_INFO_RECEIVED");cache:SetScript("OnEvent",function() U.dirty=true end)

local defaults=CreateFrame("Frame");defaults:RegisterEvent("PLAYER_LOGIN")
defaults:SetScript("OnEvent",function()
    local db=W:DB()
    if not db.rc941BagDefaults then db.autoSortBags=true;db.rc941BagDefaults=true end
    if db.bagSize then db.bagSize.columns=8 end
end)
