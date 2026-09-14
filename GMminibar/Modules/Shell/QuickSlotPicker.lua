local A = AzerothAdminAC335
local W, D, N, C = A.Workbench, A.WorkbenchAdapter, A.NativeUI, A.WorkbenchCatalog
function W:IsFixedToolbarEntry(entry)
    local d = entry.definition
    local command = d.command or ""
    local action = d.action or ""
    local fixed = { ".gm fly", ".die", ".cheat god", ".gm visible", ".modify speed all" }
    for _, prefix in ipairs(fixed) do if command == prefix or command:sub(1, #prefix + 1) == prefix .. " " then return true end end
    local actions = { toggle_flight=true, toggle_god=true, toggle_visibility=true, toggle_speed=true,
        toggle_quest_helper=true, toggle_bank=true, toggle_craft_info=true, toggle_item_info=true,
        quest_helper=true, bank=true, profession_info=true, item_browser=true, teleports=true }
    actions.flightToggle=true;actions.godToggle=true;actions.visibilityToggle=true;actions.speedToggle=true
    actions.questhelper=true;actions.bankToggle=true;actions.craftInfo=true;actions.itemInfo=true;actions.favorites=true
    for _,name in ipairs({"ToggleFlight","ToggleGod","ToggleVisibility","ToggleSpeed","OpenQuestHelper","OpenBank","OpenProfessionInfo","OpenItemBrowser","OpenTeleportWindow","OpenLanguageWindow"}) do actions[name]=true end
    return actions[action] or false
end
function W:SlotCandidates(query)
    if not C.entries then C:Build(D) end
    local result, assigned = {}, {}
    for i = 1, 4 do local key = self:DB().quick[i]; if key then assigned[key] = true end end
    for _, entry in ipairs(C:Filter(query or "", "all", false, D)) do
        local already = assigned[entry.key]
        if entry.variants then already = already or assigned[entry.variants[2].key] end
        if not already and not self:IsFixedToolbarEntry(entry) then result[#result + 1] = entry end
    end
    return result
end
function W:OpenSlotPicker(slot, owner)
    if not self.picker then
        local p = CreateFrame("Frame", D.namespace .. "SlotPicker", UIParent)
        self.picker = p; p:SetWidth(490); p:SetHeight(458); p:SetFrameStrata("TOOLTIP"); p:EnableMouse(true); p:SetClampedToScreen(true); N:Panel(p); p:Hide()
        local title = N:Text(p, A:XL("PICK_TITLE"), 440); title:SetPoint("TOPLEFT", p, "TOPLEFT", 16, -18)
        local help = N:Text(p, A:XL("PICK_HINT"), 448, true); help:SetHeight(35); help:SetPoint("TOPLEFT", p, "TOPLEFT", 16, -42)
        local close = CreateFrame("Button", nil, p, "UIPanelCloseButton"); close:SetPoint("TOPRIGHT", p, "TOPRIGHT", -3, -3); close:SetScript("OnClick", function() p:Hide() end)
        p.search = N:Edit(p, 452); p.search:SetPoint("TOPLEFT", p, "TOPLEFT", 16, -82)
        p.search:SetScript("OnTextChanged", function() p.page=1; W:RefreshSlotPicker() end)
        p.rows = {}
        for i = 1, 5 do
            local row = N:Button(p, "", 452, 48, function(self)
                if not self.entry then return end
                W:DB().quick[p.slot] = self.entry.key; W:RefreshQuick(); W:RefreshMiniSlots(); p:Hide()
            end)
            row:SetPoint("TOPLEFT", p, "TOPLEFT", 16, -116 - (i-1)*54)
            p.rows[i] = row
        end
        p.prev=N:Button(p,"<",45,24,function() p.page=math.max(1,p.page-1); W:RefreshSlotPicker() end); p.prev:SetPoint("BOTTOMLEFT",p,"BOTTOMLEFT",16,42)
        p.next=N:Button(p,">",45,24,function() p.page=p.page+1; W:RefreshSlotPicker() end); p.next:SetPoint("BOTTOMRIGHT",p,"BOTTOMRIGHT",-16,42)
        p.pageText=N:Text(p,"",320,true); p.pageText:SetPoint("LEFT",p.prev,"RIGHT",12,0)
        local clear=N:Button(p,A:XL("CLEAR_SLOT"),150,23,function() W:DB().quick[p.slot]=nil; W:RefreshQuick(); W:RefreshMiniSlots(); p:Hide() end); clear:SetPoint("BOTTOM",p,"BOTTOM",0,11)
        N:PageWheel(p,p.prev,p.next)
        UISpecialFrames[#UISpecialFrames+1]=p:GetName()
    end
    local p=self.picker; p.slot=slot; p.page=1; p.search:SetText("")
    p:ClearAllPoints(); p:SetPoint("CENTER",UIParent,"CENTER",0,0)
    N:Fit(p,490,458,1); p:Show(); self:SuspendForPopup(p); self:RefreshSlotPicker()
end
function W:RefreshSlotPicker()
    local p=self.picker; if not p then return end
    local entries=self:SlotCandidates(p.search:GetText())
    local pages=math.max(1,math.ceil(#entries/5)); p.page=math.min(p.page or 1,pages)
    for i,row in ipairs(p.rows) do
        local entry=entries[(p.page-1)*5+i]; row.entry=entry
        if entry then
            local d=entry.definition
            row:SetText(entry.label .. "\n" .. (d.command or entry.category or ""))
            N:Hint(row,entry.label,(d.hint or d.notes or A:XL("PICK_HINT")) .. "\n" .. A:XL("REGISTER_ONLY")); row:Show()
        else row:Hide() end
    end
    p.pageText:SetText(A:XL("SLOT") .. " " .. p.slot .. "   " .. p.page .. "/" .. pages .. "   (" .. #entries .. ")")
    if p.page>1 then p.prev:Enable() else p.prev:Disable() end
    if p.page<pages then p.next:Enable() else p.next:Disable() end
end
function W:RefreshMiniSlots()
    if not A.commandQuickSlots then return end
    if not C.entries then C:Build(D) end
    for i=1,4 do
        local b=A.commandQuickSlots[i]
        if b then
            local entry=self.ResolveSlot and self:ResolveSlot(self:DB().quick[i]) or C.byKey[self:DB().quick[i]]
            b.aaeUXEntry=entry; b:Enable()
            local info=entry and self:CommandInfo(entry)
            b.aaeTitle=info and info.name or (A:XL("SLOT") .. " " .. i)
            b.aaeHint=A:XL("QUICK_HINT2") .. (entry and ("\n" .. (info.feature.."\n"..info.method.."\n"..info.command)) or "")
            if b.aaeIcon then b.aaeIcon:SetTexture(entry and (entry.definition.icon or "Interface\\Icons\\INV_Misc_Book_09") or "Interface\\Icons\\INV_Misc_QuestionMark"); b.aaeIcon:SetVertexColor(1,1,1) end
        end
    end
end
function W:InstallMiniSlots()
    for _,b in ipairs(A.commandQuickSlots or {}) do b:Hide();b:Disable();b:SetScript('OnClick',nil) end
    A.commandQuickSlots={}
    if self.picker then self.picker:Hide() end
end
function W:OpenSlotPicker() end
if A.RefreshToolbarQuickSlots then hooksecurefunc(A,"RefreshToolbarQuickSlots",function() W:RefreshMiniSlots() end) end
if A.RefreshCommandQuickSlots then hooksecurefunc(A,"RefreshCommandQuickSlots",function() W:RefreshMiniSlots() end) end
hooksecurefunc(W,"RefreshQuick",function() W:RefreshMiniSlots() end)
local event=CreateFrame("Frame"); event:RegisterEvent("PLAYER_LOGIN")
event:SetScript("OnEvent",function()
    W:InstallMiniSlots()
    if A.favoriteButton then A.favoriteButton:Hide();A.favoriteButton:HookScript("OnShow",function(self) self:Hide() end) end
    for _,name in ipairs({"questHelperButton","bankButton","craftInfoButton","itemInfoButton","gmMenuButton"}) do
      local b=A[name];if b then local point,relative,other,x,y=b:GetPoint();b:ClearAllPoints();b:SetPoint(point,relative,other,(x or 0)-30,y or 0) end
    end
    if A.languageMinibarButton then A.languageMinibarButton:Hide(); A.languageMinibarButton:HookScript("OnShow",function(self) self:Hide() end) end
end)

local fullMenuEvents=CreateFrame("Frame");fullMenuEvents:RegisterEvent("PLAYER_LOGIN");fullMenuEvents:SetScript("OnEvent",function() if A.gmMenuButton then A.gmMenuButton:SetScript("OnClick",function() W:Toggle() end) end end)

local hintEvents=CreateFrame("Frame");hintEvents:RegisterEvent("PLAYER_LOGIN")
hintEvents:SetScript("OnEvent",function()
 if D:Locale()~="koKR" then return end
 local hints={flightButton={A:T("GM 비행 전환"),A:T("GM 비행을 켜고 끕니다.")},killButton={A:T("즉시 처치"),A:T("선택한 대상을 확인창 없이 즉시 처치합니다.")},godButton={A:T("무적 모드 전환"),A:T("무적 모드를 켜고 끕니다.")},visibilityButton={A:T("투명화 전환"),A:T("GM 표시를 켜고 끕니다.")},speedButton={A:T("이동속도 3배 전환"),A:T("전체 이동속도를 정상/3배로 전환합니다.")},teleportButton={A:T("순간이동 목록"),A:T("대륙·도시·던전·공격대·전장과 지도 즐겨찾기를 확인합니다.")},questHelperButton={A:T("퀘스트 도우미"),A:T("L키 또는 이 버튼으로 기본 퀘스트 창과 함께 열고 닫습니다.")},bankButton={A:T("은행 열기"),A:T("은행을 열고 GM 메뉴를 닫습니다.")},craftInfoButton={A:T("전문기술 정보"),A:T("현재 숙련도와 제작 아이템, 재료, 습득 조건을 확인합니다.")},itemInfoButton={A:T("아이템 정보"),A:T("아이템을 분류별로 찾고 정보를 확인합니다.")},gmMenuButton={A:T("GM 메뉴"),A:T("전체 명령어 및 주요 편의 기능을 열고 닫습니다.")}}
 for field,hint in pairs(hints) do if A[field] then A[field].aaeTitle=hint[1];A[field].aaeHint=hint[2] end end
end)
