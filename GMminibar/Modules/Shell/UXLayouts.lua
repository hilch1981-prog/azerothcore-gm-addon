-- Reflow module content, preserving each module's controls and execution handlers.
local A = AzerothAdminAC335
local N, W, D = A.NativeUI, A.Workbench, A.WorkbenchAdapter
local function descendants(frame, out)
    for _, child in ipairs({ frame:GetChildren() }) do
        out[#out + 1] = child
        descendants(child, out)
    end
end
function N:PageWheel(frame, previous, following)
    if not previous or not following then return end
    local function wheel(_, delta)
        local button = delta > 0 and previous or following
        if button:IsEnabled() then local fn = button:GetScript("OnClick"); if fn then fn(button, "LeftButton") end end
    end
    local function install(node)
        if node:GetObjectType() == "ScrollFrame" then return end
        if not node:GetScript("OnMouseWheel") then node:EnableMouseWheel(true); node:SetScript("OnMouseWheel", wheel) end
        for _, child in ipairs({ node:GetChildren() }) do install(child) end
    end
    install(frame)
end
function N:FindPageButtons(frame)
    local previous = frame.previous or frame.prev
    local following = frame.next or frame.nextButton
    local nodes = {}; descendants(frame, nodes)
    for _, node in ipairs(nodes) do
        if node:IsObjectType("Button") and not node:IsObjectType("CheckButton") then
            local text = node.GetText and node:GetText() or ""
            if node.aaeLabel then text = node.aaeLabel:GetText() or text end
            text = text or ""
            if text:find("◀", 1, true) or text:find(A:T("이전"), 1, true) or text:lower():find("previous", 1, true) then previous = previous or node end
            if text:find("▶", 1, true) or text:find(A:T("다음"), 1, true) or text:lower():find("next", 1, true) then following = following or node end
        end
    end
    return previous, following
end
function W:LayoutModule(frame, key)
    if frame == self.commandPanel then return end
    local previous, following = N:FindPageButtons(frame)
    if key == "search" then previous = previous or A.localeSearchPrev; following = following or A.localeSearchNext end
    if key == "teleports" then previous = previous or A.teleportPrevious; following = following or A.teleportNext end
    N:PageWheel(frame, previous, following)
    if key == "teleports" then self:LayoutTeleports(frame) end
end
function W:LayoutTeleports(frame)
    if frame.aaeCards then return end
    frame.aaeCards = true
    frame:SetWidth(760); frame:SetHeight(520)
    local footer=frame.pageText or A.teleportPageText
    if footer then footer:SetWidth(520);footer:SetHeight(30);footer:ClearAllPoints();footer:SetPoint("BOTTOM",frame,"BOTTOM",0,17) end
    if frame.search then frame.search:ClearAllPoints(); frame.search:SetPoint("TOPLEFT",frame,"TOPLEFT",70,-58);frame.search:SetWidth(370) end
    if frame.serverCheck then frame.serverCheck:ClearAllPoints();frame.serverCheck:SetPoint("TOPLEFT",frame,"TOPLEFT",465,-58) end
    if frame.regionDropdown then frame.regionDropdown:ClearAllPoints();frame.regionDropdown:SetPoint("TOPLEFT",frame,"TOPLEFT",90,-83) end
    if frame.progressCheck then frame.progressCheck:ClearAllPoints();frame.progressCheck:SetPoint("TOPLEFT",frame,"TOPLEFT",540,-85) end
    if frame.modeText then frame.modeText:ClearAllPoints();frame.modeText:SetPoint("TOPRIGHT",frame,"TOPRIGHT",-20,-113) end
    if A.teleportSearch and not frame.search then A.teleportSearch:SetWidth(625) end
    for i,key in ipairs({"area","destination","level","faction"}) do
        local header=frame.sortHeaders and frame.sortHeaders[key]
        if header then
            header:ClearAllPoints();header:SetPoint("TOPLEFT",frame,"TOPLEFT",180+(i-1)*140,-130);header:SetWidth(135);header:SetHeight(18)
            if header.aaeLabel then header.aaeLabel:ClearAllPoints();header.aaeLabel:SetPoint("LEFT",header,"LEFT",5,0);header.aaeLabel:SetWidth(125);header.aaeLabel:SetHeight(15) end
        end
    end
    local categories = frame.categoryButtons or A.teleportCategoryButtons or {}
    for i, button in ipairs(categories) do
        button:ClearAllPoints(); button:SetPoint("TOPLEFT", frame, "TOPLEFT", 14, -155 - (i - 1) * 32)
        button:SetWidth(150); button:SetHeight(27)
    end
    if frame.filterCaption then frame.filterCaption:Hide() end
    local rows = frame.rows or A.teleportButtons or {}
    for i, row in ipairs(rows) do
        row:ClearAllPoints(); row:SetPoint("TOPLEFT", frame, "TOPLEFT", 180 + ((i - 1) % 2) * 286, -155 - math.floor((i - 1) / 2) * 52)
        row:SetWidth(278); row:SetHeight(50); N:Panel(row, true)
        row:SetNormalTexture(""); row:SetPushedTexture(""); row:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")
        local icon = row:CreateTexture(nil, "ARTWORK"); icon:SetWidth(34); icon:SetHeight(34)
        icon:SetPoint("LEFT", row, "LEFT", 7, 0); icon:SetTexture("Interface\\Icons\\INV_Misc_Map_01")
        local title = N:Text(row, "", 222, true); title:SetPoint("TOPLEFT", row, "TOPLEFT", 49, -4);title:SetHeight(14)
        local detail = N:Text(row, "", 222, true); detail:SetPoint("TOPLEFT", row, "TOPLEFT", 49, -19);detail:SetHeight(14); detail:SetTextColor(0.7,0.8,0.85)
        local info = N:Text(row, "", 222, true); info:SetPoint("TOPLEFT", row, "TOPLEFT", 49, -34);info:SetHeight(14)
        row.aaeCardTitle, row.aaeCardDetail, row.aaeCardInfo = title, detail, info
        for _,key in ipairs({"aaeLabel","pathText","nameText","levelText","factionText"}) do local label=row[key];if label then label:Hide() end end
        local function refresh()
            local tp = row.aaeTeleport
            if not tp then return end
            title:SetText(tp.name_ko or tp.name or "")
            detail:SetText(tp.zone_ko or tp.zone or tp.region_ko or "")
            info:SetText(tp.levelText or tp.command or tp.name or "")
            icon:SetTexture(tp.icon or "Interface\\Icons\\INV_Misc_Map_01")
        end
        row:HookScript("OnLeave",function() row:SetNormalTexture(""); N:Panel(row,true) end)
        row.aaeRefreshCard = refresh; refresh()
    end
end
function W:RefreshTeleportCards()
    for _, row in ipairs((A.teleportFrame and A.teleportFrame.rows) or A.teleportButtons or {}) do
        if row.aaeRefreshCard then row.aaeRefreshCard() end
    end
end
if A.RefreshTeleportWindow then hooksecurefunc(A, "RefreshTeleportWindow", function() W:RefreshTeleportCards() end) end
if A.RefreshTeleportList then hooksecurefunc(A, "RefreshTeleportList", function() W:RefreshTeleportCards() end) end
