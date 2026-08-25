AzerothAdminEasy = AzerothAdminEasy or {}
local addon = AzerothAdminEasy

local CREATURE_ROW_HEIGHT = 44
local CREATURE_ICON = "Interface\\Icons\\INV_Misc_Head_Dragon_01"

local function makeText(parent, text, fontObject)
    local fs = parent:CreateFontString(nil, "OVERLAY")
    fs:SetFontObject(fontObject or GameFontNormal)
    fs:SetText(text or "")
    return fs
end

local function makeButton(parent, width, height, text)
    local button = CreateFrame("Button", nil, parent)
    button:SetWidth(width)
    button:SetHeight(height)
    button:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 12, edgeSize = 8,
        insets = { left = 2, right = 2, top = 2, bottom = 2 },
    })
    button:SetBackdropColor(0.02, 0.035, 0.045, 0.92)
    button:SetBackdropBorderColor(0.30, 0.34, 0.37, 1)
    local label = button:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    label:SetPoint("LEFT", button, "LEFT", 5, 0)
    label:SetPoint("RIGHT", button, "RIGHT", -5, 0)
    label:SetJustifyH("CENTER")
    label:SetText(text or "")
    button.label = label
    button.SetText = function(self, value) self.label:SetText(value or "") end
    return button
end

local function makeEdit(parent, width, height)
    local edit = CreateFrame("EditBox", nil, parent)
    edit:SetWidth(width)
    edit:SetHeight(height)
    edit:SetAutoFocus(false)
    edit:SetFontObject(ChatFontNormal)
    edit:SetTextInsets(6, 6, 0, 0)
    edit:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 12, edgeSize = 8,
        insets = { left = 2, right = 2, top = 2, bottom = 2 },
    })
    edit:SetBackdropColor(0.01, 0.02, 0.025, 1)
    edit:SetBackdropBorderColor(0.48, 0.43, 0.31, 1)
    return edit
end

local function makeCheck(parent, x, y, label, checked, onClick)
    local check = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    check:SetWidth(22)
    check:SetHeight(22)
    check:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    check:SetChecked(checked)
    local text = makeText(parent, label, GameFontHighlightSmall)
    text:SetPoint("LEFT", check, "RIGHT", 1, 0)
    check.aaeLabel = text
    check:SetScript("OnClick", onClick)
    return check
end

local function normalized(value)
    value = tostring(value or "")
    value = string.gsub(value, "^%s*(.-)%s*$", "%1")
    return string.lower(value)
end

local function setCategoryActive(button, active)
    if not button then return end
    if active then
        button:SetBackdropColor(0.18, 0.12, 0.025, 1)
        button:SetBackdropBorderColor(0.95, 0.66, 0.18, 1)
    else
        button:SetBackdropColor(0.02, 0.035, 0.045, 0.92)
        button:SetBackdropBorderColor(0.30, 0.34, 0.37, 1)
    end
end

function addon:GetFeaturedCreatureFavorites()
    AzerothAdminEasyDB = AzerothAdminEasyDB or {}
    AzerothAdminEasyDB.featuredCreatureFavorites = AzerothAdminEasyDB.featuredCreatureFavorites or {}
    return AzerothAdminEasyDB.featuredCreatureFavorites
end

function addon:IsFeaturedCreatureFavorite(entry)
    return self:GetFeaturedCreatureFavorites()[tostring(entry)] and true or false
end

function addon:ToggleFeaturedCreatureFavorite(entry)
    entry = tonumber(entry)
    if not entry then return end
    local favorites = self:GetFeaturedCreatureFavorites()
    local key = tostring(entry)
    if favorites[key] then favorites[key] = nil else favorites[key] = true end
    self:RefreshCreatureBrowser()
end

function addon:FeaturedCreatureMatchesCategory(record)
    local key = self.creatureBrowserCategory or "all"
    local group = record[3]
    local expansion = record[4]
    if key == "all" then return true end
    if key == "favorite" then return self:IsFeaturedCreatureFavorite(record[1]) end
    if key == "raid" then return group == "raid" end
    if key == "raid_classic" then return group == "raid" and expansion == "classic" end
    if key == "raid_tbc" then return group == "raid" and expansion == "tbc" end
    if key == "raid_wotlk" then return group == "raid" and expansion == "wotlk" end
    if key == "dungeon_classic" then return group == "dungeon" and expansion == "classic" end
    if key == "dungeon_tbc" then return group == "dungeon" and expansion == "tbc" end
    if key == "dungeon_wotlk" then return group == "dungeon" and expansion == "wotlk" end
    return group == key
end

function addon:GetFilteredFeaturedCreatures()
    local data = self.FeaturedCreatures or {}
    local query = normalized(self.creatureBrowserSearch and self.creatureBrowserSearch:GetText() or "")
    local results = {}
    local i
    for i = 1, table.getn(data) do
        local record = data[i]
        local entry = tonumber(record[1])
        local name = tostring(record[2] or "")
        local expansion = record[4]
        local restricted = record[6] and true or false
        local expansionCheck = self.creatureBrowserExpansionChecks and self.creatureBrowserExpansionChecks[expansion]
        local expansionMatch = not expansionCheck or expansionCheck:GetChecked()
        local safetyCheck = restricted and self.creatureBrowserRestrictedCheck or self.creatureBrowserOpenCheck
        local safetyMatch = not safetyCheck or safetyCheck:GetChecked()
        local queryMatch = query == "" or string.find(string.lower(name), query, 1, true)
            or string.find(tostring(entry or ""), query, 1, true)
        if entry and self:FeaturedCreatureMatchesCategory(record) and expansionMatch and safetyMatch and queryMatch then
            table.insert(results, record)
        end
    end
    return results
end

function addon:SetCreatureBrowserCategory(key, label)
    self.creatureBrowserCategory = key or "all"
    local i
    for i = 1, table.getn(self.creatureBrowserCategoryButtons or {}) do
        local button = self.creatureBrowserCategoryButtons[i]
        setCategoryActive(button, button.aaeCategoryKey == self.creatureBrowserCategory)
    end
    if self.creatureBrowserCurrent then
        self.creatureBrowserCurrent:SetText("선택 분류: " .. tostring(label or "주요 크리처 전체"))
    end
    self:RefreshCreatureBrowser()
end

function addon:SelectFeaturedCreature(record)
    self.creatureBrowserSelected = record
    if not record then
        if self.creatureBrowserSelectedText then self.creatureBrowserSelectedText:SetText("크리처를 선택하세요.") end
        if self.creatureBrowserWarning then self.creatureBrowserWarning:SetText("") end
        if self.creatureBrowserFavoriteButton then self.creatureBrowserFavoriteButton:SetText("☆ 즐겨찾기") end
        self:RefreshCreatureBrowserRows()
        return
    end
    local entry, name, _, _, place, restricted = record[1], record[2], record[3], record[4], record[5], record[6]
    if self.creatureBrowserSelectedText then
        self.creatureBrowserSelectedText:SetText("선택: [" .. tostring(entry) .. "] " .. tostring(name) .. " · " .. tostring(place))
    end
    if self.creatureBrowserWarning then
        if restricted then
            self.creatureBrowserWarning:SetText("|cffffaa33⚠ 지역 제한 가능: " .. tostring(place)
                .. " 전용 AI·인스턴스·조우 스크립트가 연결되었을 수 있습니다. 다른 지역에 소환하면 오류 또는 비정상 전투가 발생할 수 있습니다.|r")
        else
            self.creatureBrowserWarning:SetText("|cff88ddaa일반 지역 NPC입니다. 영구 생성은 DB에 저장되므로 위치를 확인하세요.|r")
        end
    end
    if self.creatureBrowserFavoriteButton then
        self.creatureBrowserFavoriteButton:SetText(self:IsFeaturedCreatureFavorite(entry) and "★ 해제" or "☆ 즐겨찾기")
    end
    self:RefreshCreatureBrowserRows()
end

local function creatureDefinition(command, label, confirm, danger)
    local name = addon:GetCommandName(command)
    return {
        label = label,
        command = command,
        permissionCommand = command,
        commandName = name,
        requiredSecurity = name and addon.CommandSecurity and addon.CommandSecurity[name] or nil,
        officialSyntax = name and addon.CommandSyntax and addon.CommandSyntax[name] or nil,
        confirm = confirm and true or false,
        danger = danger and true or false,
    }
end

function addon:RunFeaturedCreatureAction(action)
    local record = self.creatureBrowserSelected
    if not record then
        self:Print("먼저 주요 크리처를 선택하세요.", true)
        return
    end
    local entry, name, _, _, place, restricted = record[1], record[2], record[3], record[4], record[5], record[6]
    local prefix = "[" .. tostring(entry) .. "] " .. tostring(name)
    if action == "go" then
        self:ExecuteDefinition(creatureDefinition(".go creature id " .. tostring(entry), "스폰 위치로 이동: " .. prefix, false, false))
    elseif action == "list" then
        self:ExecuteDefinition(creatureDefinition(".list creature " .. tostring(entry) .. " 20", "스폰 목록: " .. prefix, false, false))
    elseif action == "favorite" then
        self:ToggleFeaturedCreatureFavorite(entry)
    elseif action == "temp" then
        local label = "임시 소환: " .. prefix .. "\nDB에는 저장되지 않습니다."
        if restricted then
            label = label .. "\n|cffff6633경고: " .. tostring(place) .. " 전용 스크립트가 다른 지역에서 오류를 일으킬 수 있습니다.|r"
        end
        self:ExecuteDefinition(creatureDefinition(".npc add temp " .. tostring(entry), label, true, false))
    elseif action == "permanent" then
        local label = "영구 생성(DB 저장): " .. prefix
            .. "\n|cffff6633재시작 후에도 남습니다. 잘못 생성하면 직접 삭제해야 합니다.|r"
        if restricted then
            label = label .. "\n|cffff6633추가 경고: " .. tostring(place) .. " 전용 스크립트가 다른 지역에서 오류를 일으킬 수 있습니다.|r"
        end
        self:ExecuteDefinition(creatureDefinition(".npc add " .. tostring(entry), label, true, true))
    end
end

function addon:RefreshCreatureBrowserRows()
    if not self.creatureBrowserRows then return end
    local results = self.creatureBrowserResults or {}
    local count = table.getn(results)
    local groupLabels = self.FeaturedCreatureGroupLabels or {}
    local expansionLabels = self.FeaturedCreatureExpansionLabels or {}
    local i
    for i = 1, table.getn(self.creatureBrowserRows) do
        local record = results[i]
        local row = self.creatureBrowserRows[i]
        row.aaeCreature = record
        if record then
            local entry, name, group, expansion, place, restricted = record[1], record[2], record[3], record[4], record[5], record[6]
            row.name:SetText("[" .. tostring(entry) .. "] " .. tostring(name))
            row.meta:SetText(tostring(place) .. " · " .. tostring(expansionLabels[expansion] or expansion)
                .. (restricted and " · |cffffaa33지역 제한|r" or ""))
            if self.creatureBrowserSelected == record then
                row:SetBackdropColor(0.18, 0.12, 0.025, 1)
                row:SetBackdropBorderColor(0.95, 0.66, 0.18, 1)
            else
                row:SetBackdropColor(0.02, 0.035, 0.045, 0.78)
                row:SetBackdropBorderColor(0.30, 0.34, 0.37, 1)
            end
            row.aaeGroupLabel = groupLabels[group] or group
            row:Show()
        else
            row.aaeGroupLabel = nil
            row:Hide()
        end
    end
    if self.creatureBrowserResultChild then
        self.creatureBrowserResultChild:SetHeight(math.max(270, count * CREATURE_ROW_HEIGHT + 4))
    end
    if self.creatureBrowserCountText then
        self.creatureBrowserCountText:SetText("주요 목록 " .. tostring(count) .. "개 · 마우스 휠/스크롤바로 이동")
    end
end

function addon:RefreshCreatureBrowser()
    self.creatureBrowserResults = self:GetFilteredFeaturedCreatures()
    if self.creatureBrowserResultScroll then self.creatureBrowserResultScroll:SetVerticalScroll(0) end
    local selectedFound = false
    local i
    for i = 1, table.getn(self.creatureBrowserResults) do
        if self.creatureBrowserResults[i] == self.creatureBrowserSelected then
            selectedFound = true
            break
        end
    end
    if selectedFound then
        self:RefreshCreatureBrowserRows()
    else
        self:SelectFeaturedCreature(self.creatureBrowserResults[1])
    end
end

function addon:CreateCreatureBrowser()
    if self.creatureBrowserFrame then return end
    local frame = CreateFrame("Frame", "AzerothAdminCreatureBrowserFrame", UIParent)
    frame:SetWidth(900)
    frame:SetHeight(610)
    frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    frame:SetFrameStrata("FULLSCREEN_DIALOG")
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:SetClampedToScreen(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", function(self) self:StartMoving() end)
    frame:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
    frame:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 14,
        insets = { left = 4, right = 4, top = 4, bottom = 4 },
    })
    frame:SetBackdropColor(0.018, 0.025, 0.035, 0.985)
    frame:SetBackdropBorderColor(0.95, 0.58, 0.10, 1)
    frame:Hide()
    self.creatureBrowserFrame = frame
    if self.RegisterEscapeFrame then self:RegisterEscapeFrame(frame) end

    local icon = frame:CreateTexture(nil, "ARTWORK")
    icon:SetTexture(CREATURE_ICON)
    icon:SetWidth(32)
    icon:SetHeight(32)
    icon:SetPoint("TOPLEFT", frame, "TOPLEFT", 14, -10)
    local title = makeText(frame, "크리처 정보 · WotLK 3.3.5a", GameFontNormalLarge)
    title:SetPoint("TOPLEFT", frame, "TOPLEFT", 54, -17)
    title:SetTextColor(1, 0.78, 0.25)
    local close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -5, -5)
    local hint = makeText(frame,
        "왼쪽 분류 선택 → 확장팩/소환 조건 필터 → 크리처 선택 → 이동 또는 임시·영구 소환",
        GameFontHighlightSmall)
    hint:SetPoint("TOPLEFT", frame, "TOPLEFT", 18, -47)
    hint:SetTextColor(0.55, 0.88, 0.92)

    local categoryTitle = makeText(frame, "분류", GameFontNormal)
    categoryTitle:SetPoint("TOPLEFT", frame, "TOPLEFT", 18, -78)
    categoryTitle:SetTextColor(1, 0.82, 0.18)
    local categoryScroll = CreateFrame("ScrollFrame", "AzerothAdminCreatureCategoryScroll", frame, "UIPanelScrollFrameTemplate")
    categoryScroll:SetPoint("TOPLEFT", frame, "TOPLEFT", 16, -96)
    categoryScroll:SetWidth(205)
    categoryScroll:SetHeight(460)
    local categories = self.FeaturedCreatureCategories or {}
    local categoryChild = CreateFrame("Frame", nil, categoryScroll)
    categoryChild:SetWidth(178)
    categoryChild:SetHeight(math.max(460, table.getn(categories) * 25 + 4))
    categoryScroll:SetScrollChild(categoryChild)
    self.creatureBrowserCategoryButtons = {}
    local i
    for i = 1, table.getn(categories) do
        local category = categories[i]
        local button = makeButton(categoryChild, 174, 23, category.label)
        button:SetPoint("TOPLEFT", categoryChild, "TOPLEFT", 2, -(i - 1) * 25)
        button.label:SetJustifyH("LEFT")
        if category.parent then button.label:SetTextColor(0.83, 0.88, 0.92) else button.label:SetTextColor(1, 0.78, 0.22) end
        button.aaeCategoryKey = category.key
        button.aaeCategoryLabel = category.label
        button:SetScript("OnClick", function(self)
            addon:SetCreatureBrowserCategory(self.aaeCategoryKey, string.gsub(self.aaeCategoryLabel or "", "^%s+", ""))
        end)
        self.creatureBrowserCategoryButtons[i] = button
    end

    local filterX = 245
    local expansionTitle = makeText(frame, "확장팩", GameFontNormal)
    expansionTitle:SetPoint("TOPLEFT", frame, "TOPLEFT", filterX, -72)
    expansionTitle:SetTextColor(1, 0.82, 0.18)
    self.creatureBrowserExpansionChecks = {}
    local expansionDefs = {
        { "classic", "클래식", 60 },
        { "tbc", "불타는 성전", 150 },
        { "wotlk", "리치 왕의 분노", 285 },
    }
    for i = 1, table.getn(expansionDefs) do
        local def = expansionDefs[i]
        self.creatureBrowserExpansionChecks[def[1]] = makeCheck(frame, filterX + def[3], -68, def[2], true, function()
            addon:RefreshCreatureBrowser()
        end)
    end

    local safetyTitle = makeText(frame, "소환 조건", GameFontNormal)
    safetyTitle:SetPoint("TOPLEFT", frame, "TOPLEFT", filterX, -101)
    safetyTitle:SetTextColor(1, 0.82, 0.18)
    self.creatureBrowserRestrictedCheck = makeCheck(frame, filterX + 72, -97, "지역 제한 가능", true, function()
        addon:RefreshCreatureBrowser()
    end)
    self.creatureBrowserOpenCheck = makeCheck(frame, filterX + 205, -97, "일반 지역 NPC", true, function()
        addon:RefreshCreatureBrowser()
    end)

    local searchLabel = makeText(frame, "한글/ID", GameFontNormal)
    searchLabel:SetPoint("TOPLEFT", frame, "TOPLEFT", filterX, -136)
    searchLabel:SetTextColor(1, 0.82, 0.18)
    local searchEdit = makeEdit(frame, 300, 24)
    searchEdit:SetPoint("TOPLEFT", frame, "TOPLEFT", filterX + 60, -130)
    self.creatureBrowserSearch = searchEdit
    local searchButton = makeButton(frame, 60, 24, "검색")
    searchButton:SetPoint("LEFT", searchEdit, "RIGHT", 7, 0)
    searchButton:SetScript("OnClick", function()
        addon:RefreshCreatureBrowser()
    end)
    local fullSearchButton = makeButton(frame, 96, 24, "전체 DB 검색")
    fullSearchButton:SetPoint("LEFT", searchButton, "RIGHT", 7, 0)
    fullSearchButton:SetScript("OnClick", function()
        addon:OpenLocaleSearch("creature", searchEdit:GetText() or "")
    end)
    searchEdit:SetScript("OnEnterPressed", function(self)
        addon:RefreshCreatureBrowser()
        self:ClearFocus()
    end)
    searchEdit:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)

    local current = makeText(frame, "선택 분류: 주요 크리처 전체", GameFontHighlightSmall)
    current:SetPoint("TOPLEFT", frame, "TOPLEFT", filterX, -162)
    current:SetTextColor(0.45, 0.9, 1)
    self.creatureBrowserCurrent = current

    local resultScroll = CreateFrame("ScrollFrame", "AzerothAdminCreatureResultScroll", frame, "UIPanelScrollFrameTemplate")
    resultScroll:SetPoint("TOPLEFT", frame, "TOPLEFT", filterX, -184)
    resultScroll:SetWidth(636)
    resultScroll:SetHeight(270)
    resultScroll:EnableMouseWheel(true)
    resultScroll:SetScript("OnMouseWheel", function(self, delta)
        local currentScroll = self:GetVerticalScroll() or 0
        local maxScroll = math.max(0, (self:GetVerticalScrollRange() or 0))
        self:SetVerticalScroll(math.max(0, math.min(maxScroll, currentScroll - delta * (CREATURE_ROW_HEIGHT * 3))))
    end)
    local resultChild = CreateFrame("Frame", nil, resultScroll)
    resultChild:SetWidth(608)
    resultChild:SetHeight(270)
    resultScroll:SetScrollChild(resultChild)
    self.creatureBrowserResultScroll = resultScroll
    self.creatureBrowserResultChild = resultChild

    self.creatureBrowserRows = {}
    for i = 1, table.getn(self.FeaturedCreatures or {}) do
        local row = CreateFrame("Button", nil, resultChild)
        row:SetWidth(604)
        row:SetHeight(40)
        row:SetPoint("TOPLEFT", resultChild, "TOPLEFT", 2, -((i - 1) * CREATURE_ROW_HEIGHT))
        row:SetBackdrop({
            bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true, tileSize = 12, edgeSize = 8,
            insets = { left = 2, right = 2, top = 2, bottom = 2 },
        })
        row:SetBackdropColor(0.02, 0.035, 0.045, 0.78)
        row:SetBackdropBorderColor(0.30, 0.34, 0.37, 1)
        row:RegisterForClicks("LeftButtonUp", "RightButtonUp")
        local rowIcon = row:CreateTexture(nil, "ARTWORK")
        rowIcon:SetTexture(CREATURE_ICON)
        rowIcon:SetWidth(34)
        rowIcon:SetHeight(34)
        rowIcon:SetPoint("LEFT", row, "LEFT", 6, 0)
        local name = makeText(row, "", GameFontHighlightSmall)
        name:SetWidth(548)
        name:SetJustifyH("LEFT")
        name:SetPoint("TOPLEFT", row, "TOPLEFT", 46, -6)
        row.name = name
        local meta = makeText(row, "", GameFontHighlightSmall)
        meta:SetWidth(548)
        meta:SetJustifyH("LEFT")
        meta:SetPoint("BOTTOMLEFT", row, "BOTTOMLEFT", 46, 6)
        meta:SetTextColor(0.65, 0.82, 0.90)
        row.meta = meta
        row:SetScript("OnClick", function(self, mouseButton)
            if not self.aaeCreature then return end
            if mouseButton == "RightButton" and addon.ShowSearchContextMenu then
                addon:ShowSearchContextMenu("creature", { self.aaeCreature[1], self.aaeCreature[2], self.aaeCreature })
            else
                addon:SelectFeaturedCreature(self.aaeCreature)
            end
        end)
        row:SetScript("OnEnter", function(self)
            local record = self.aaeCreature
            if not record then return end
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText("[" .. tostring(record[1]) .. "] " .. tostring(record[2]), 1, 0.82, 0.18)
            GameTooltip:AddLine(tostring(self.aaeGroupLabel or "") .. " · " .. tostring(record[5]), 0.55, 0.88, 0.95, true)
            if record[6] then
                GameTooltip:AddLine("지역·인스턴스 전용 스크립트 가능: 다른 지역 소환 시 오류 또는 비정상 동작 주의", 1, 0.48, 0.22, true)
            end
            GameTooltip:AddLine("좌클릭: 선택 / 우클릭: 이동·임시 소환·영구 생성 메뉴", 0.65, 0.95, 0.78, true)
            GameTooltip:Show()
        end)
        row:SetScript("OnLeave", function() GameTooltip:Hide() end)
        self.creatureBrowserRows[i] = row
    end

    local selectedText = makeText(frame, "크리처를 선택하세요.", GameFontNormal)
    selectedText:SetWidth(636)
    selectedText:SetJustifyH("LEFT")
    selectedText:SetPoint("TOPLEFT", frame, "TOPLEFT", filterX, -466)
    selectedText:SetTextColor(1, 0.82, 0.18)
    self.creatureBrowserSelectedText = selectedText

    local goButton = makeButton(frame, 88, 24, "위치 이동")
    goButton:SetPoint("TOPLEFT", frame, "TOPLEFT", filterX, -490)
    goButton:SetScript("OnClick", function() addon:RunFeaturedCreatureAction("go") end)
    local tempButton = makeButton(frame, 92, 24, "임시 소환")
    tempButton:SetPoint("LEFT", goButton, "RIGHT", 7, 0)
    tempButton:SetBackdropBorderColor(0.30, 0.62, 0.78, 1)
    tempButton:SetScript("OnClick", function() addon:RunFeaturedCreatureAction("temp") end)
    local permanentButton = makeButton(frame, 92, 24, "영구 생성")
    permanentButton:SetPoint("LEFT", tempButton, "RIGHT", 7, 0)
    permanentButton:SetBackdropColor(0.13, 0.045, 0.025, 1)
    permanentButton:SetBackdropBorderColor(0.72, 0.25, 0.12, 1)
    permanentButton:SetScript("OnClick", function() addon:RunFeaturedCreatureAction("permanent") end)
    local listButton = makeButton(frame, 88, 24, "스폰 목록")
    listButton:SetPoint("LEFT", permanentButton, "RIGHT", 7, 0)
    listButton:SetScript("OnClick", function() addon:RunFeaturedCreatureAction("list") end)
    local favoriteButton = makeButton(frame, 102, 24, "☆ 즐겨찾기")
    favoriteButton:SetPoint("LEFT", listButton, "RIGHT", 7, 0)
    favoriteButton:SetScript("OnClick", function() addon:RunFeaturedCreatureAction("favorite") end)
    self.creatureBrowserFavoriteButton = favoriteButton

    local warning = makeText(frame, "", GameFontHighlightSmall)
    warning:SetWidth(640)
    warning:SetHeight(42)
    warning:SetJustifyH("LEFT")
    warning:SetJustifyV("TOP")
    warning:SetPoint("TOPLEFT", frame, "TOPLEFT", filterX, -526)
    self.creatureBrowserWarning = warning

    local countText = makeText(frame, "", GameFontHighlightSmall)
    countText:SetWidth(636)
    countText:SetJustifyH("CENTER")
    countText:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", filterX, 22)
    self.creatureBrowserCountText = countText
    self.creatureBrowserCategory = "all"
    self:SetCreatureBrowserCategory("all", "주요 크리처 전체")
    self:SelectFeaturedCreature(self.FeaturedCreatures and self.FeaturedCreatures[1] or nil)
end

function addon:ToggleCreatureBrowser()
    if not self.creatureBrowserFrame then self:CreateCreatureBrowser() end
    if self.creatureBrowserFrame:IsShown() then
        self.creatureBrowserFrame:Hide()
        return
    end
    self:HideAddonPopups(nil)
    self:RefreshCreatureBrowser()
    self:OpenManagedFrame(self.creatureBrowserFrame)
end
