local A = AzerothAdminAC335
local PER_PAGE = 10
local localKinds = {
    { "Items", "ITEM" }, { "Quests", "QUEST" }, { "Creatures", "CREATURE" }, { "Teleports", "TELEPORTS" },
}

local function describe(kind, row)
    if kind == "Items" then
        return string.format("[%d] %s · iLv %s · Req %s · Q %s", row[1] or 0, row[2] or "", row[4] or 0, row[5] or 0, row[3] or 0)
    elseif kind == "Quests" then
        return string.format("[%d] %s · Lv %s · Min %s · Zone %s", row[1] or 0, row[2] or "", row[3] or 0, row[4] or 0, row[5] or 0)
    elseif kind == "Creatures" then
        return string.format("[%d] %s · Lv %s-%s · Rank %s", row[1] or 0, row[2] or "", row[3] or 0, row[4] or 0, row[5] or 0)
    elseif kind == "Teleports" then
        return string.format("[%d] %s · Map %s · %.1f, %.1f, %.1f", row[1] or 0, row[2] or "", row[3] or 0, tonumber(row[4]) or 0, tonumber(row[5]) or 0, tonumber(row[6]) or 0)
    end
    return tostring(row[2] or row[1] or "")
end

function A:RefreshSearchWindow()
    local frame = self.searchWindow
    if not frame then return end
    local query = self:Trim(frame.input:GetText())
    local rows, total = self.Data:SearchGenerated(frame.kind, query, PER_PAGE, ((frame.page or 1) - 1) * PER_PAGE)
    local pages = math.max(1, math.ceil(total / PER_PAGE))
    frame.page = math.max(1, math.min(frame.page or 1, pages))
    rows, total = self.Data:SearchGenerated(frame.kind, query, PER_PAGE, (frame.page - 1) * PER_PAGE)
    for index = 1, PER_PAGE do
        local button = frame.rows[index]
        local row = rows[index]
        button.aaeRow = row
        if row then button:SetText(describe(frame.kind, row)); button:Show() else button:Hide() end
    end
    frame.pageText:SetText(self:L("PAGE", frame.page, pages))
    frame.status:SetText(self:L("LOCAL_DATA_COUNTS", frame.kind, total, self.Data:GeneratedCount(frame.kind)))
    self.UI:SetEnabled(frame.prev, frame.page > 1)
    self.UI:SetEnabled(frame.next, frame.page < pages)
end

function A:SelectSearchKind(kind)
    if not self.searchWindow then return end
    self.searchWindow.kind = kind
    self.searchWindow.page = 1
    self:RefreshSearchWindow()
end

function A:UseSearchResult(row)
    local frame = self.searchWindow
    if not frame or not row then return end
    frame.input:SetText(tostring(row[1] or row[2] or ""))
    if frame.kind == "Items" and self.OpenItemBrowser then self:OpenItemBrowser(); self.itemBrowser.idbox:SetText(tostring(row[1])); self:ShowItemSource(row[1])
    elseif frame.kind == "Quests" then self:RunRegisteredCommand("lookup_quest", tostring(row[1]), true)
    elseif frame.kind == "Creatures" then self:RunRegisteredCommand("lookup_creature", tostring(row[2] or row[1]), true)
    elseif frame.kind == "Teleports" then self:RunTeleportRow(self.Data:EnrichTeleport(row, true)) end
end

function A:OpenSearchWindow()
    local frame = self.searchWindow
    if not frame then
        frame = self.UI:CreateWindow("search_tools", self:L("SEARCH_WINDOW"), 720, 455)
        self.searchWindow = frame
        frame.kind = "Items"
        frame.page = 1
        local input = self.UI:EditBox(frame, 390, 24)
        input:SetPoint("TOPLEFT", frame, "TOPLEFT", 16, -54)
        frame.input = input
        input:SetScript("OnEnterPressed", function(box) box:ClearFocus(); frame.page = 1; A:RefreshSearchWindow() end)
        local searchButton = self.UI:Button(frame, 100, 24, self:L("SEARCH"), "utility")
        searchButton:SetPoint("LEFT", input, "RIGHT", 8, 0)
        searchButton:SetScript("OnClick", function() frame.page = 1; A:RefreshSearchWindow() end)
        local serverButton = self.UI:Button(frame, 170, 24, self:L("SERVER_LOOKUP"), "reward")
        serverButton:SetPoint("LEFT", searchButton, "RIGHT", 8, 0)
        serverButton:SetScript("OnClick", function()
            local map = { Items="lookup_item", Quests="lookup_quest", Creatures="lookup_creature", Teleports="lookup_tele" }
            local commandID = map[frame.kind]
            local query = A:Trim(input:GetText())
            if commandID and query ~= "" then A:RunRegisteredCommand(commandID, query, true) end
        end)
        for index, entry in ipairs(localKinds) do
            local kind = entry[1]
            local labelKey = entry[2]
            local button = self.UI:Button(frame, 150, 22, self:L(labelKey), "utility")
            button:SetPoint("TOPLEFT", frame, "TOPLEFT", 16 + (index - 1) * 160, -86)
            button:SetScript("OnClick", function() A:SelectSearchKind(kind) end)
        end
        frame.rows = {}
        for index = 1, PER_PAGE do
            local button = self.UI:RowLabel(frame, 680, 24)
            button:SetPoint("TOPLEFT", frame, "TOPLEFT", 16, -118 - (index - 1) * 27)
            button:SetScript("OnClick", function(self) if self.aaeRow then A:UseSearchResult(self.aaeRow) end end)
            frame.rows[index] = button
        end
        local prev = self.UI:Button(frame, 70, 22, self:L("PREVIOUS"), "utility")
        prev:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 230, 16)
        prev:SetScript("OnClick", function() frame.page = frame.page - 1; A:RefreshSearchWindow() end)
        frame.prev = prev
        local pageText = self.UI:Text(frame, "", "small")
        pageText:SetWidth(120); pageText:SetJustifyH("CENTER"); pageText:SetPoint("LEFT", prev, "RIGHT", 8, 0)
        frame.pageText = pageText
        local nextButton = self.UI:Button(frame, 70, 22, self:L("NEXT"), "utility")
        nextButton:SetPoint("LEFT", pageText, "RIGHT", 8, 0)
        nextButton:SetScript("OnClick", function() frame.page = frame.page + 1; A:RefreshSearchWindow() end)
        frame.next = nextButton
        local status = self.UI:Text(frame, "", "small")
        status:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 16, 18)
        frame.status = status
    end
    self:RefreshSearchWindow()
    self.UI:ShowWindow(frame)
    frame.input:SetFocus()
end
