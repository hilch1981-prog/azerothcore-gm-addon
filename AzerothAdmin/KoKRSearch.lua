AzerothAdminEasy = AzerothAdminEasy or {}
local addon = AzerothAdminEasy

local RESULTS_PER_PAGE = 12

local KIND_INFO = {
    item = { title = "아이템", data = "item" },
    quest = { title = "퀘스트", data = "quest" },
    creature = { title = "크리쳐", data = "creature" },
}

local function makeText(parent, text, size)
    local fs = parent:CreateFontString(nil, "OVERLAY")
    if size == "large" then
        fs:SetFontObject(GameFontNormalLarge)
    elseif size == "small" then
        fs:SetFontObject(GameFontHighlightSmall)
    else
        fs:SetFontObject(GameFontNormal)
    end
    fs:SetText(text or "")
    return fs
end

local function makeButton(parent, width, height, text)
    local b = CreateFrame("Button", nil, parent)
    b:SetWidth(width)
    b:SetHeight(height)
    b:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 12, edgeSize = 8,
        insets = { left = 2, right = 2, top = 2, bottom = 2 },
    })
    b:SetBackdropColor(0.025, 0.04, 0.055, 1)
    b:SetBackdropBorderColor(0.48, 0.43, 0.31, 1)
    local label = b:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    label:SetPoint("LEFT", b, "LEFT", 5, 0)
    label:SetPoint("RIGHT", b, "RIGHT", -5, 0)
    label:SetJustifyH("CENTER")
    label:SetText(text or "")
    b.label = label
    b.SetText = function(self, value) self.label:SetText(value or "") end
    return b
end

local function makeEdit(parent, width, height)
    local e = CreateFrame("EditBox", nil, parent)
    e:SetWidth(width)
    e:SetHeight(height)
    e:SetAutoFocus(false)
    e:SetFontObject(ChatFontNormal)
    e:SetTextInsets(6, 6, 0, 0)
    e:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 12, edgeSize = 8,
        insets = { left = 2, right = 2, top = 2, bottom = 2 },
    })
    e:SetBackdropColor(0.01, 0.02, 0.025, 1)
    e:SetBackdropBorderColor(0.48, 0.43, 0.31, 1)
    return e
end

local function normalized(value)
    value = tostring(value or "")
    value = string.gsub(value, "^%s*(.-)%s*$", "%1")
    return string.lower(value)
end

function addon:FindLocaleID(kind, value)
    kind = KIND_INFO[kind] and kind or "item"
    local text = normalized(value)
    if text == "" then return nil end
    local numeric = tonumber(text)
    local data = self.KoKRSearchData and self.KoKRSearchData[kind] or {}
    local i
    if numeric then
        for i = 1, table.getn(data) do
            if data[i][1] == numeric then return numeric end
        end
        return nil
    end

    self.KoKRResolveCache = self.KoKRResolveCache or {}
    self.KoKRResolveCache[kind] = self.KoKRResolveCache[kind] or {}
    if self.KoKRResolveCache[kind][text] ~= nil then
        local cached = self.KoKRResolveCache[kind][text]
        return cached ~= false and cached or nil
    end

    for i = 1, table.getn(data) do
        if normalized(data[i][2]) == text then
            self.KoKRResolveCache[kind][text] = data[i][1]
            return data[i][1]
        end
    end

    local first = nil
    local matches = 0
    for i = 1, table.getn(data) do
        if string.find(normalized(data[i][2]), text, 1, true) then
            matches = matches + 1
            if not first then first = data[i][1] end
            if matches > 1 then break end
        end
    end
    if matches == 1 then
        self.KoKRResolveCache[kind][text] = first
        return first
    end
    self.KoKRResolveCache[kind][text] = false
    return nil
end

local function getQuantityPopupEditBox(dialog)
    if not dialog then return nil end
    if dialog.editBox then return dialog.editBox end
    local name = dialog.GetName and dialog:GetName() or nil
    if name and _G[name .. "EditBox"] then return _G[name .. "EditBox"] end
    return nil
end

local function getQuantityPopupButton(dialog, index)
    if not dialog then return nil end
    local direct = index == 1 and dialog.button1 or dialog.button2
    if direct then return direct end
    local name = dialog.GetName and dialog:GetName() or nil
    if name and _G[name .. "Button" .. tostring(index)] then return _G[name .. "Button" .. tostring(index)] end
    return nil
end

local function getOwnedItemCount(itemID)
    if not GetItemCount then return nil end
    local ok, count = pcall(GetItemCount, itemID, true)
    if ok and count ~= nil then return tonumber(count) or 0 end
    ok, count = pcall(GetItemCount, itemID)
    if ok and count ~= nil then return tonumber(count) or 0 end
    return nil
end

local function getItemCreateMeta(itemID)
    local name, _, _, itemLevel, _, _, _, stackCount, equipLoc = GetItemInfo(itemID)
    return {
        name = name or ("아이템 " .. tostring(itemID)),
        itemLevel = tonumber(itemLevel) or 0,
        stackCount = math.max(1, math.floor(tonumber(stackCount) or 1)),
        equipLoc = equipLoc,
        isBag = equipLoc == "INVTYPE_BAG",
    }
end

local function showItemAddResult(itemID, requested, before, after, meta)
    local delta = (before ~= nil and after ~= nil) and (after - before) or nil
    local message
    local success = delta ~= nil and delta == requested

    if delta ~= nil then
        message = "아이템 " .. tostring(itemID) .. " · 요청 " .. tostring(requested)
            .. "개 · 실제 증가 " .. tostring(delta) .. "개 · 보유 "
            .. tostring(before) .. "→" .. tostring(after)
    else
        message = "아이템 " .. tostring(itemID) .. " · 총 " .. tostring(requested) .. "개 생성 명령 전송 완료"
    end

    if meta and meta.isBag then
        message = message .. "\n가방 아이콘의 " .. tostring(meta.itemLevel)
            .. " 표시는 수량이 아니라 아이템 레벨(iLv)입니다. 가방 한 칸은 1개입니다."
    end

    addon:Print(message, delta ~= nil and not success)
    if UIErrorsFrame and UIErrorsFrame.AddMessage then
        local short
        if delta ~= nil then
            short = "[" .. tostring(itemID) .. "] 실제 증가 " .. tostring(delta) .. "/" .. tostring(requested) .. "개"
        else
            short = "[" .. tostring(itemID) .. "] " .. tostring(requested) .. "개 생성 요청"
        end
        if meta and meta.isBag then short = short .. " · 아이콘 숫자=iLv" end
        UIErrorsFrame:AddMessage(short, success and 0.25 or 1, success and 1 or 0.35, success and 0.35 or 0.25, 1)
    end
end

function addon:AddItemExact(itemID, amount)
    itemID = math.floor(tonumber(itemID) or 0)
    amount = math.floor(tonumber(amount) or 0)
    if itemID <= 0 or amount <= 0 then return end
    if amount > 9999 then amount = 9999 end

    local before = getOwnedItemCount(itemID)
    local meta = getItemCreateMeta(itemID)
    local lowGUID = self.GetSelfLowGUID and self:GetSelfLowGUID() or nil

    -- AzerothCore's additem count is a TOTAL item count.  Supplying the current
    -- character low GUID removes any selected-target ambiguity, while one command
    -- lets the core split stackable and non-stackable items correctly.
    local command
    if lowGUID then
        command = ".additem " .. tostring(lowGUID) .. " " .. tostring(itemID) .. " " .. tostring(amount)
    else
        command = ".additem " .. tostring(itemID) .. " " .. tostring(amount)
    end
    self:SendNow(command)

    -- Inventory updates are asynchronous. Poll long enough for a busy worldserver,
    -- then report the measured delta rather than interpreting icon overlay numbers.
    local attempts = 0
    local function verify()
        attempts = attempts + 1
        local after = getOwnedItemCount(itemID)
        local delta = (before ~= nil and after ~= nil) and (after - before) or nil
        if delta == amount or attempts >= 12 then
            showItemAddResult(itemID, amount, before, after, meta)
            local craft = _G.AzerothAdminCraftInfoFrame
            if craft and craft:IsShown() and craft.RefreshDetail then pcall(craft.RefreshDetail, craft) end
            return
        end
        self:RunAfter(0.4, verify)
    end
    self:RunAfter(0.7, verify)
end

StaticPopupDialogs["AZEROTHADMIN_ITEM_ADD_QUANTITY"] = {
    text = "가방에 추가할 수량을 입력하세요.\n\n|cffffff00[%s] %s|r",
    button1 = "가방에 추가",
    button2 = CANCEL,
    hasEditBox = true,
    maxLetters = 5,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
    OnShow = function(self)
        AzerothAdminEasy:RaisePopup(self)
        AzerothAdminEasy:SuspendManagedEscapeForPopup(self)
        local editBox = getQuantityPopupEditBox(self)
        if editBox then
            local amount = self.data and tonumber(self.data.defaultAmount) or 1
            amount = math.floor(amount or 1)
            if amount < 1 then amount = 1 end
            if amount > 9999 then amount = 9999 end
            editBox:SetText(tostring(amount))
            if editBox.SetNumeric then editBox:SetNumeric(true) end
            editBox:SetFocus()
            editBox:HighlightText()
        end
    end,
    OnHide = function(self)
        AzerothAdminEasy:ResumeManagedEscapeForPopup(self)
    end,
    OnAccept = function(self, data)
        data = data or self.data
        if not data or not data.id then return end
        local editBox = getQuantityPopupEditBox(self)
        local amount = editBox and tonumber(editBox:GetText()) or tonumber(data.defaultAmount) or 1
        amount = math.floor(amount or 1)
        if amount < 1 then amount = 1 end
        if amount > 9999 then amount = 9999 end

        -- Add exactly the requested TOTAL count with one explicit self-GUID command
        -- and verify the measured inventory delta.
        AzerothAdminEasy:AddItemExact(data.id, amount)
    end,
    EditBoxOnEnterPressed = function(self)
        local parent = self:GetParent()
        local button = getQuantityPopupButton(parent, 1)
        if button then button:Click() end
    end,
    EditBoxOnEscapePressed = function(self)
        local parent = self:GetParent()
        if parent then parent:Hide() end
    end,
}

StaticPopupDialogs["AZEROTHADMIN_QUEST_ADD_SEARCH"] = {
    text = "이 퀘스트를 퀘스트 로그에 추가하시겠습니까?\n\n|cffffff00[%s] %s|r",
    button1 = "퀘스트 추가",
    button2 = CANCEL,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
    OnShow = function(self)
        AzerothAdminEasy:RaisePopup(self)
        AzerothAdminEasy:SuspendManagedEscapeForPopup(self)
    end,
    OnHide = function(self)
        AzerothAdminEasy:ResumeManagedEscapeForPopup(self)
    end,
    OnAccept = function(self, data)
        if data and data.id then
            AzerothAdminEasy:SendNow(".quest add " .. tostring(data.id))
        end
    end,
}

function addon:ShowQuestAddPopup(questID, questName)
    if not questID then return end
    self:HideAddonPopups("AZEROTHADMIN_QUEST_ADD_SEARCH")
    StaticPopup_Show("AZEROTHADMIN_QUEST_ADD_SEARCH", tostring(questID), questName or "", {
        id = questID,
        name = questName or "",
    })
end
function addon:ShowItemQuantityPopup(itemID, itemName, defaultAmount)
    itemID = tonumber(itemID)
    if not itemID then return end
    defaultAmount = math.floor(tonumber(defaultAmount) or 1)
    if defaultAmount < 1 then defaultAmount = 1 end
    if defaultAmount > 9999 then defaultAmount = 9999 end
    local popupName = itemName or ""
    local _, _, _, itemLevel, _, _, _, _, equipLoc = GetItemInfo(itemID)
    if equipLoc == "INVTYPE_BAG" then
        popupName = popupName .. "\n|cff66ddff※ 아이콘의 " .. tostring(tonumber(itemLevel) or 0)
            .. "은 수량이 아닌 iLv입니다. 입력값은 총 생성 개수입니다.|r"
    end
    self:HideAddonPopups("AZEROTHADMIN_ITEM_ADD_QUANTITY")
    local dialog = StaticPopup_Show("AZEROTHADMIN_ITEM_ADD_QUANTITY", tostring(itemID), popupName, {
        id = itemID,
        name = itemName or "",
        defaultAmount = defaultAmount,
    })
    -- 3.3.5a builds are not consistent about exposing dialog.editBox.
    -- Also set the named StaticPopup edit box after StaticPopup_Show returns.
    local editBox = getQuantityPopupEditBox(dialog)
    if editBox then
        editBox:SetText(tostring(defaultAmount))
        editBox:SetFocus()
        editBox:HighlightText()
    end
end

function addon:ShowSearchContextMenu(kind, result)
    if not result then return end
    if not EasyMenu then
        self:Print("우클릭 메뉴 API를 사용할 수 없습니다.", true)
        return
    end
    if not self.searchContextMenu then
        self.searchContextMenu = CreateFrame("Frame", "AzerothAdminSearchContextMenu", UIParent, "UIDropDownMenuTemplate")
    end
    local id = tonumber(result[1]) or result[1]
    local name = tostring(result[2] or "")
    local menu = {
        { text = "[" .. tostring(id) .. "] " .. name, isTitle = true, notCheckable = true },
    }
    local function commandEntry(label, command, fn)
        local commandName = addon:GetCommandName(command)
        local def = { permissionCommand = command, commandName = commandName, requiredSecurity = commandName and addon.CommandSecurity and addon.CommandSecurity[commandName] or nil }
        local allowed, reason = addon:IsDefinitionAllowed(def)
        return {
            text = allowed and label or (label .. " |cff777777(권한 부족)|r"),
            notCheckable = true,
            disabled = not allowed,
            tooltipTitle = not allowed and "실행 불가" or nil,
            tooltipText = not allowed and tostring(reason or "권한 부족") or nil,
            func = fn,
        }
    end
    if kind == "item" then
        table.insert(menu, { text = "수량 입력 → 가방 추가", notCheckable = true, func = function() addon:ShowItemQuantityPopup(id, name) end })
        table.insert(menu, commandEntry("보유 목록 조회", ".list item " .. tostring(id) .. " 20", function() addon:SendNow(".list item " .. tostring(id) .. " 20") end))
        table.insert(menu, { text = "통합 아이템 정보 열기", notCheckable = true, func = function() addon:ToggleItemInfo() end })
    elseif kind == "quest" then
        table.insert(menu, { text = "퀘스트 추가", notCheckable = true, func = function() addon:ShowQuestAddPopup(id, name) end })
        table.insert(menu, commandEntry("시작 위치로 이동", ".go quest starter " .. tostring(id), function() addon:SendNow(".go quest starter " .. tostring(id)) end))
        table.insert(menu, commandEntry("종료 위치로 이동", ".go quest ender " .. tostring(id), function() addon:SendNow(".go quest ender " .. tostring(id)) end))
        table.insert(menu, { text = "퀘스트 도우미 열기", notCheckable = true, func = function() addon:ToggleQuestHelper() end })
    elseif kind == "creature" then
        table.insert(menu, commandEntry("Entry 위치로 이동", ".go creature id " .. tostring(id), function() addon:SendNow(".go creature id " .. tostring(id)) end))
        table.insert(menu, commandEntry("스폰 목록 조회", ".list creature " .. tostring(id) .. " 20", function() addon:SendNow(".list creature " .. tostring(id) .. " 20") end))
        table.insert(menu, commandEntry("현재 위치에 크리쳐 생성", ".npc add " .. tostring(id), function()
            addon:ExecuteDefinition({ label = "크리쳐 생성: " .. name, command = ".npc add " .. tostring(id), permissionCommand = ".npc add " .. tostring(id), confirm = true, danger = true, commandName = "npc add", requiredSecurity = addon.CommandSecurity and addon.CommandSecurity["npc add"], officialSyntax = addon.CommandSyntax and addon.CommandSyntax["npc add"] })
        end))
    end
    table.insert(menu, { text = "닫기", notCheckable = true, func = function() CloseDropDownMenus() end })
    EasyMenu(menu, self.searchContextMenu, "cursor", 0, 0, "MENU")
end

function addon:CreateLocaleSearchWindow()
    if self.localeSearchFrame then return end
    local f = CreateFrame("Frame", "AzerothAdminKoKRSearchFrame", UIParent)
    f:SetWidth(610); f:SetHeight(500); f:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    f:SetFrameStrata("FULLSCREEN_DIALOG"); f:SetMovable(true); f:EnableMouse(true); f:SetClampedToScreen(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", function(self) self:StartMoving() end)
    f:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
    f:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 },
    })
    f:SetBackdropColor(0.01, 0.018, 0.022, 0.97)
    f:SetBackdropBorderColor(0.95, 0.58, 0.10, 1)
    f:Hide()
    self.localeSearchFrame = f
    if self.RegisterEscapeFrame then self:RegisterEscapeFrame(f) end

    local title = makeText(f, "koKR Locale 한글/ID 검색", "large")
    title:SetPoint("TOPLEFT", f, "TOPLEFT", 18, -16); title:SetTextColor(1, 0.82, 0.18)
    self.localeSearchTitle = title
    local close = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", f, "TOPRIGHT", -4, -4)

    local edit = makeEdit(f, 400, 24)
    edit:SetPoint("TOPLEFT", f, "TOPLEFT", 18, -48)
    edit:SetScript("OnEscapePressed", function(self) self:ClearFocus(); f:Hide() end)
    self.localeSearchEdit = edit
    local search = makeButton(f, 80, 24, "검색")
    search:SetPoint("LEFT", edit, "RIGHT", 8, 0)
    search:SetScript("OnClick", function() addon:RunLocaleSearch() end)
    edit:SetScript("OnEnterPressed", function(self) addon:RunLocaleSearch(); self:ClearFocus() end)

    local hint = makeText(f, "한글명/부분문자열 또는 숫자 ID 검색", "small")
    hint:SetPoint("TOPLEFT", f, "TOPLEFT", 18, -78); hint:SetTextColor(0.55, 0.88, 0.92)
    self.localeSearchHint = hint

    self.localeSearchRows = {}
    local i
    for i = 1, RESULTS_PER_PAGE do
        local row = makeButton(f, 570, 24, "")
        row:SetPoint("TOPLEFT", f, "TOPLEFT", 18, -104 - (i - 1) * 28)
        row.label:SetJustifyH("LEFT")
        row:RegisterForClicks("LeftButtonUp", "RightButtonUp")
        row:SetScript("OnClick", function(self, mouseButton)
            local result = self.aaeResult
            if not result then return end
            local kind = addon.localeSearchKind or "item"
            if mouseButton == "RightButton" then
                addon:ShowSearchContextMenu(kind, result)
                return
            end
            if kind == "item" then
                addon:ShowItemQuantityPopup(result[1], result[2])
            elseif kind == "quest" then
                addon:ShowQuestAddPopup(result[1], result[2])
            else
                addon:HideAddonWindows(nil)
                addon:SendNow(".go creature id " .. tostring(result[1]))
            end
        end)
        row:SetScript("OnEnter", function(self)
            if not self.aaeResult then return end
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText("[" .. self.aaeResult[1] .. "] " .. self.aaeResult[2], 1, 0.82, 0.18)
            if addon.localeSearchKind == "item" then
                GameTooltip:AddLine("좌클릭: 수량 입력 후 가방에 생성", 0.55, 0.95, 0.75, true)
                GameTooltip:AddLine("우클릭: 추가 메뉴", 1, 0.82, 0.25, true)
            elseif addon.localeSearchKind == "quest" then
                GameTooltip:AddLine("좌클릭: 확인 후 퀘스트 로그에 추가", 0.55, 0.95, 0.75, true)
                GameTooltip:AddLine("우클릭: 추가/시작/종료 위치 메뉴", 1, 0.82, 0.25, true)
            else
                GameTooltip:AddLine("좌클릭: 해당 크리쳐 Entry의 스폰 위치로 이동", 0.55, 0.95, 0.75, true)
                GameTooltip:AddLine("우클릭: 이동/스폰목록/생성 메뉴", 1, 0.82, 0.25, true)
            end
            GameTooltip:Show()
        end)
        row:SetScript("OnLeave", function() GameTooltip:Hide() end)
        self.localeSearchRows[i] = row
    end

    local prev = makeButton(f, 80, 22, "◀ 이전")
    prev:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 20, 24)
    prev:SetScript("OnClick", function()
        if addon.localeSearchPage > 1 then addon.localeSearchPage = addon.localeSearchPage - 1; addon:RefreshLocaleSearchRows() end
    end)
    self.localeSearchPrev = prev
    local page = makeText(f, "", "small")
    page:SetWidth(280); page:SetJustifyH("CENTER"); page:SetPoint("LEFT", prev, "RIGHT", 24, 0)
    self.localeSearchPageText = page
    local nextb = makeButton(f, 80, 22, "다음 ▶")
    nextb:SetPoint("LEFT", page, "RIGHT", 24, 0)
    nextb:SetScript("OnClick", function()
        if addon.localeSearchPage < addon.localeSearchPageCount then addon.localeSearchPage = addon.localeSearchPage + 1; addon:RefreshLocaleSearchRows() end
    end)
    self.localeSearchNext = nextb
end

function addon:OpenLocaleSearch(kind, query)
    if not self.localeSearchFrame then self:CreateLocaleSearchWindow() end
    kind = KIND_INFO[kind] and kind or "item"
    self.localeSearchKind = kind
    self.localeSearchResults = {}
    self.localeSearchPage = 1
    self.localeSearchPageCount = 1

    local info = KIND_INFO[kind]
    self.localeSearchTitle:SetText(info.title .. " · koKR Locale 한글/ID 검색")
    if kind == "item" then
        self.localeSearchHint:SetText("한글명/부분문자열 또는 숫자 ID 검색 · 결과 클릭 → 수량 입력 → 가방 생성")
    elseif kind == "quest" then
        self.localeSearchHint:SetText("한글 퀘스트 제목/부분문자열 또는 숫자 ID 검색 · 결과 클릭 → 퀘스트 추가")
    else
        self.localeSearchHint:SetText("한글 크리쳐 이름/부분문자열 또는 숫자 ID 검색 · 결과 클릭 → 스폰 위치 이동")
    end

    self.localeSearchEdit:SetText(query or "")
    self:HideAddonPopups(nil)
    self:OpenManagedFrame(self.localeSearchFrame)
    if query and tostring(query) ~= "" then
        self:RunLocaleSearch()
    else
        self:RefreshLocaleSearchRows()
        self.localeSearchEdit:SetFocus()
    end
end

function addon:RunLocaleSearch()
    if not self.localeSearchEdit then return end
    local kind = self.localeSearchKind or "item"
    local query = self.Trim and self.Trim(self.localeSearchEdit:GetText()) or (self.localeSearchEdit:GetText() or "")
    local data = self.KoKRSearchData and self.KoKRSearchData[kind] or {}
    local results = {}
    local numeric = tonumber(query)
    if query ~= "" then
        local needle = string.lower(query)
        local i
        for i = 1, table.getn(data) do
            local row = data[i]
            if (numeric and row[1] == numeric) or string.find(string.lower(row[2]), needle, 1, true) then
                table.insert(results, row)
                if table.getn(results) >= 500 then break end
            end
        end
    end
    self.localeSearchResults = results
    self.localeSearchPage = 1
    self:RefreshLocaleSearchRows()
end

function addon:RefreshLocaleSearchRows()
    if not self.localeSearchRows then return end
    local results = self.localeSearchResults or {}
    local count = table.getn(results)
    self.localeSearchPageCount = math.max(1, math.ceil(count / RESULTS_PER_PAGE))
    if not self.localeSearchPage or self.localeSearchPage < 1 then self.localeSearchPage = 1 end
    if self.localeSearchPage > self.localeSearchPageCount then self.localeSearchPage = self.localeSearchPageCount end
    local first = (self.localeSearchPage - 1) * RESULTS_PER_PAGE + 1
    local i
    for i = 1, RESULTS_PER_PAGE do
        local result = results[first + i - 1]
        local row = self.localeSearchRows[i]
        row.aaeResult = result
        if result then row:SetText("[" .. result[1] .. "]  " .. result[2]); row:Show() else row:Hide() end
    end
    self.localeSearchPageText:SetText("검색 " .. count .. "개 · " .. self.localeSearchPage .. " / " .. self.localeSearchPageCount)
    if self.localeSearchPage <= 1 then self.localeSearchPrev:Disable() else self.localeSearchPrev:Enable() end
    if self.localeSearchPage >= self.localeSearchPageCount then self.localeSearchNext:Disable() else self.localeSearchNext:Enable() end
end
