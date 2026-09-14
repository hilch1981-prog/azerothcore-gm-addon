-- AzerothAdmin 3.5.0-335a item-browser UI contract, adapted to AC335 3.3.5a data.
local A = AzerothAdminAC335
A.UI = type(A.UI) == "table" and A.UI or {}
local UI = A.UI
local ROWS_PER_PAGE = 30
local function pageSize(frame)
    return math.max(2,math.min(ROWS_PER_PAGE,math.floor((frame:GetHeight()-(frame.advancedVisible and 191 or 131)-52)/48)*2))
end

local TYPE_ORDER = { "recipe", "weapon", "armor", "material", "consumable", "other" }
local TYPE_LABEL_KEYS = {
    recipe = "ITEM_TYPE_RECIPE", weapon = "ITEM_TYPE_WEAPON", armor = "ITEM_TYPE_ARMOR",
    material = "ITEM_TYPE_MATERIAL", consumable = "ITEM_TYPE_CONSUMABLE", other = "ITEM_TYPE_OTHER",
}
local ITEM_CLASS_TO_TYPE = {
    [0] = "consumable", [2] = "weapon", [4] = "armor", [7] = "material", [9] = "recipe",
}
local QUALITY_ORDER = { 1, 0, 2, 3, 4, 5, 6, 7 }
local QUALITY_LABEL_KEYS = {
    [0] = "QUALITY_POOR", [1] = "QUALITY_COMMON", [2] = "QUALITY_UNCOMMON",
    [3] = "QUALITY_RARE", [4] = "QUALITY_EPIC", [5] = "QUALITY_LEGENDARY", [6] = "QUALITY_ARTIFACT", [7] = "QUALITY_HEIRLOOM",
}
local QUALITY_FALLBACK = {
    [0] = { 0.62, 0.62, 0.62 }, [1] = { 1.00, 1.00, 1.00 }, [2] = { 0.12, 1.00, 0.00 },
    [3] = { 0.00, 0.44, 0.87 }, [4] = { 0.64, 0.21, 0.93 }, [5] = { 1.00, 0.50, 0.00 },
    [6] = { 0.90, 0.30, 0.20 }, [7] = { 0.90, 0.80, 0.50 },
}

local CLASS_OPTIONS = {
    { key = "ALL", label = "CLASS_ALL" },
    { key = "WARRIOR", label = "CLASS_WARRIOR" },
    { key = "PALADIN", label = "CLASS_PALADIN" },
    { key = "HUNTER", label = "CLASS_HUNTER" },
    { key = "ROGUE", label = "CLASS_ROGUE" },
    { key = "PRIEST", label = "CLASS_PRIEST" },
    { key = "DEATHKNIGHT", label = "CLASS_DEATHKNIGHT" },
    { key = "SHAMAN", label = "CLASS_SHAMAN" },
    { key = "MAGE", label = "CLASS_MAGE" },
    { key = "WARLOCK", label = "CLASS_WARLOCK" },
    { key = "DRUID", label = "CLASS_DRUID" },
}

local CLASS_WORDS = {
    WARRIOR = { "전사", "warrior" }, PALADIN = { "성기사", "paladin" }, HUNTER = { "사냥꾼", "hunter" },
    ROGUE = { "도적", "rogue" }, PRIEST = { "사제", "priest" }, DEATHKNIGHT = { "죽음의 기사", "death knight" },
    SHAMAN = { "주술사", "shaman" }, MAGE = { "마법사", "mage" }, WARLOCK = { "흑마법사", "warlock" },
    MONK = { "수도사", "monk" }, DRUID = { "드루이드", "druid" },
}
local ALL_CLASS_WORDS = {}
for _, words in pairs(CLASS_WORDS) do
    for _, word in ipairs(words) do table.insert(ALL_CLASS_WORDS, word) end
end

local CATEGORIES = {
    { header = true, label = "ITEM_CATEGORY_GENERAL" },
    { key = "all", label = "ALL" },
}

-- The verified AzerothAdmin 3.5.0-335a category tree is the product contract.
-- Keep it ahead of AC335-only extensions so the original raid/dungeon/set/weapon/
-- armor/recipe lists remain immediately available rather than buried at the end.
local legacyContract = (A.Data and A.Data.legacyItemCategories) or A.AC335LegacyItemCategories
if type(legacyContract) == "table" and type(legacyContract.entries) == "table" then
    table.insert(CATEGORIES, { header = true, label = "ITEM_CATEGORY_LEGACY" })
    for _, entry in ipairs(legacyContract.entries) do
        table.insert(CATEGORIES, {
            key = "legacy:" .. tostring(entry.key),
            text = entry.label,
            legacyKey = tostring(entry.key),
            kind = entry.kind,
            root = entry.root,
        })
    end
end

-- Core-specific category data above is authoritative; no MoP extensions.

local function categoryText(entry)
    if not entry then return A:L("ALL") end
    return entry.text and A:TranslateLabel(entry.text) or A:L(entry.label)
end

local function lower(value) return string.lower(tostring(value or "")) end
local function contains(value, query)
    query = lower(query)
    if query == "" then return true end
    return string.find(lower(value), query, 1, true) ~= nil
end

local function isPlaceholderItem(row)
    local original = tostring(row and row[2] or ""):gsub("^%s+", "")
    local name = lower(original)
    if name == "" then return true end
    -- Uppercase OLD* names in item_template are internal legacy placeholders,
    -- unlike legitimate localized names that merely contain the word "old".
    if string.sub(original, 1, 3) == "OLD" then return true end
    local anchored = {
        "^%[임시%]", "^임시[%s_%-:]", "^%[temp%]", "^temp[%s_%-:]", "^temporary[%s_%-:]",
        "^deprecated[%s_%-:]", "^unused[%s_%-:]", "^placeholder[%s_%-:]", "^test[%s_%-:]",
        "^qa[%s_%-:]", "^%[qa%]", "^%[ph%]", "^ph[%s_%-:]", "^nyi[%s_%-:]",
        "^internal[%s_%-:]", "^debug[%s_%-:]", "^zzold", "^zz[%s_%-:]", "^old[%s_%-:]", "^old%d", "^old%[",
    }
    for _, pattern in ipairs(anchored) do if string.find(name, pattern) then return true end end
    local markers = {
        "[임시]", "[미사용]", "[사용 안 함]", "[테스트]", "[개발]",
        "[deprecated]", "[unused]", "[test]", "[qa]", "[ph]", "[nyi]", "[debug]", "[internal]",
    }
    for _, marker in ipairs(markers) do
        if string.find(name, marker, 1, true) then return true end
    end
    return false
end

-- Public only for regression/self-test; normal callers use the browser filter.
function A:IsPlaceholderItemRow(row)
    return isPlaceholderItem(row)
end

local function qualityColor(quality)
    quality = tonumber(quality) or 1
    if GetItemQualityColor then
        local r, g, b = GetItemQualityColor(quality)
        if r then return r, g, b end
    end
    local color = QUALITY_FALLBACK[quality] or QUALITY_FALLBACK[1]
    return color[1], color[2], color[3]
end

local function itemType(row)
    return ITEM_CLASS_TO_TYPE[tonumber(row and row[6]) or -1] or "other"
end
local CLIENT_CLASS_NAMES={
    Consumable=0,Weapon=2,Armor=4,['Trade Goods']=7,Recipe=9,
    ['소모품']=0,['무기']=2,['방어구']=4,['직업용품']=7,['제조법']=9,
    ['消耗品']=0,['武器']=2,['护甲']=4,['護甲']=4,['商品']=7,['配方']=9,
    ['Расходуемые']=0,['Расходуемые материалы']=0,['Оружие']=2,['Доспехи']=4,['Хозяйственные товары']=7,['Рецепты']=9,['Рецепт']=9,
}
local scheduleItemRefresh
function A:ResolveBrowserItem(row,readClient)
    self.browserItemMetadata=self.browserItemMetadata or {}
    local id=tonumber(row[1]);local old=self.browserItemMetadata[id] or row
    if not readClient or not GetItemInfo then return old,false end
    local name,link,quality,level,required,class=GetItemInfo(id)
    if not name or quality==nil then return old,false end
    local classID=CLIENT_CLASS_NAMES[class]
    if class and GetItemClassInfo then
        for i=0,16 do if GetItemClassInfo(i)==class then classID=i;break end end
    end
    local value={id,name,tonumber(quality) or old[3],tonumber(level) or old[4],tonumber(required) or old[5],classID or old[6]}
    local changed=false;for i=2,6 do if value[i]~=old[i] then changed=true end end
    self.browserItemMetadata[id]=value
    return value,changed
end

local function sourceText(info)
    if type(info) ~= "table" then return "" end
    local out = {}
    if info.section and info.section ~= "" then table.insert(out, info.section) end
    if info.raw and info.raw ~= "" then table.insert(out, tostring(info.raw):gsub("@@", " / ")) end
    return table.concat(out, " · ")
end

local function categoryMatches(row, info, key)
    if key == "all" or not key then return true end
    local id = tonumber(row[1]) or 0
    local itemLevel = tonumber(row[4]) or 0
    local required = tonumber(row[5]) or 0
    if key == "mop" then return id >= 72000 or itemLevel >= 372 or required >= 80 end
    if string.sub(key, 1, 7) == "legacy:" then return true end
    local prefix, value = string.match(key, "^(%a+):(.*)$")
    if prefix == "source" then return info and tostring(info.category or "") == value end
    if prefix == "section" then return info and contains(info.section, value) end
    return true
end

local function classSpecificText(info, name)
    local text = lower((name or "") .. " " .. sourceText(info))
    local mentionsAny = false
    for _, word in ipairs(ALL_CLASS_WORDS) do
        if contains(text, word) then mentionsAny = true; break end
    end
    return text, mentionsAny
end

local function classMatches(row, info, selectedClass)
    if not selectedClass or selectedClass == "ALL" then return true end
    local text, mentionsAny = classSpecificText(info, row[2])
    if mentionsAny then
        for _, word in ipairs(CLASS_WORDS[selectedClass] or {}) do
            if contains(text, word) then return true end
        end
        return false
    end

    -- AC335 SQL row data does not carry the per-class bitmask. For cached client
    -- items we apply a conservative armor-family filter; uncached/generic items
    -- stay visible rather than being incorrectly removed.
    local itemClass = tonumber(row[6]) or -1
    if itemClass ~= 2 and itemClass ~= 4 then return true end
    local itemTypeName, itemSubType
    if GetItemInfo then
        local _, _, _, _, _, liveType, liveSubType = GetItemInfo(row[1])
        itemTypeName, itemSubType = liveType, liveSubType
    end
    if not itemTypeName and not itemSubType then return true end
    local combined = lower((itemTypeName or "") .. " " .. (itemSubType or ""))
    local armorWords = {
        WARRIOR = { "판금", "plate" }, PALADIN = { "판금", "plate" }, DEATHKNIGHT = { "판금", "plate" },
        HUNTER = { "사슬", "mail" }, SHAMAN = { "사슬", "mail" },
        ROGUE = { "가죽", "leather" }, MONK = { "가죽", "leather" }, DRUID = { "가죽", "leather" },
        PRIEST = { "천", "cloth" }, MAGE = { "천", "cloth" }, WARLOCK = { "천", "cloth" },
    }
    if itemClass == 4 then
        for _, word in ipairs(armorWords[selectedClass] or {}) do if contains(combined, word) then return true end end
        if contains(combined, "방패") or contains(combined, "shield") then
            return selectedClass == "WARRIOR" or selectedClass == "PALADIN" or selectedClass == "SHAMAN"
        end
        return not (contains(combined, "cloth") or contains(combined, "천") or contains(combined, "leather")
            or contains(combined, "가죽") or contains(combined, "mail") or contains(combined, "사슬")
            or contains(combined, "plate") or contains(combined, "판금") or contains(combined, "shield") or contains(combined, "방패"))
    end
    return true
end

local function itemLink(id)
    if GetItemInfo then
        local _, link = GetItemInfo(id)
        if link then return link end
    end
    return "|cffffffff|Hitem:" .. tostring(id) .. ":0:0:0:0:0:0:0:80|h[Item " .. tostring(id) .. "]|h|r"
end

local function itemIcon(id)
    if GetItemIcon then
        local texture = GetItemIcon(id)
        if texture then return texture end
    end
    if GetItemInfo then
        local texture = select(10, GetItemInfo(id))
        if texture then return texture end
    end
    return "Interface\\Icons\\INV_Misc_QuestionMark"
end

function A:ShowItemQuantityPopup(itemID, itemName, defaultAmount)
    itemID = tonumber(itemID)
    if not itemID then return end
    defaultAmount = math.max(1, math.min(9999, math.floor(tonumber(defaultAmount) or 1)))
    local popup = self.itemQuantityPopup
    if not popup then
        popup = CreateFrame("Frame", "AzerothAdminAC335ItemQuantityPopup", UIParent)
        popup:SetWidth(360); popup:SetHeight(176); popup:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
        popup:SetFrameStrata("TOOLTIP"); popup:SetMovable(true); popup:EnableMouse(true); popup:SetClampedToScreen(true)
        popup:RegisterForDrag("LeftButton")
        popup:SetBackdrop(UI.windowBackdrop); popup:SetBackdropColor(0.018, 0.025, 0.035, 0.995); popup:SetBackdropBorderColor(0.95, 0.58, 0.10, 1)
        popup:SetScript("OnDragStart", function(self) self:StartMoving() end)
        popup:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
        local title = UI:Text(popup, self:L("ITEM_ADD_QUANTITY"), "large")
        title:SetPoint("TOPLEFT", popup, "TOPLEFT", 16, -14); title:SetTextColor(1, 0.78, 0.25)
        local close = CreateFrame("Button", nil, popup, "UIPanelCloseButton"); close:SetPoint("TOPRIGHT", popup, "TOPRIGHT", -5, -5)
        local icon = popup:CreateTexture(nil, "ARTWORK"); icon:SetWidth(40); icon:SetHeight(40); icon:SetPoint("TOPLEFT", popup, "TOPLEFT", 18, -49); popup.icon = icon
        local name = UI:Text(popup, "", "normal"); name:SetPoint("TOPLEFT", popup, "TOPLEFT", 68, -51); name:SetWidth(270); name:SetJustifyH("LEFT"); popup.itemName = name
        local idText = UI:Text(popup, "", "small"); idText:SetPoint("TOPLEFT", popup, "TOPLEFT", 68, -73); idText:SetTextColor(0.50, 0.86, 1.00); popup.idText = idText
        local label = UI:Text(popup, self:L("QUANTITY"), "normal"); label:SetPoint("TOPLEFT", popup, "TOPLEFT", 18, -105)
        local amount = UI:EditBox(popup, 110, 24, "AzerothAdminAC335ItemQuantityEdit")
        amount:SetPoint("LEFT", label, "RIGHT", 12, 0); amount:SetNumeric(true); amount:SetMaxLetters(4); popup.amount = amount
        local add = UI:Button(popup, 92, 24, self:L("ADD"), "reward"); add:SetPoint("BOTTOMRIGHT", popup, "BOTTOMRIGHT", -112, 16); popup.add = add
        local cancel = UI:Button(popup, 92, 24, self:L("CANCEL"), "normal"); cancel:SetPoint("LEFT", add, "RIGHT", 8, 0); cancel:SetScript("OnClick", function() popup:Hide() end)
        local function accept()
            local count = math.max(1, math.min(9999, math.floor(tonumber(amount:GetText()) or 1)))
            if popup.itemID then
                local maximum=A.ItemCreationLimits and A.ItemCreationLimits[popup.itemID]
                if maximum then
                    local owned=GetItemCount and GetItemCount(popup.itemID,true) or 0
                    local available=math.max(0,maximum-owned)
                    if count>available then amount:SetText(tostring(available));A:Print(A:L("ITEM_UNIQUE_LIMIT",maximum,owned,available));return end
                end
                if not A:RunRegisteredCommand("additem", tostring(popup.itemID) .. " " .. tostring(count), true) then return end
            end
            popup:Hide()
        end
        add:SetScript("OnClick", accept)
        amount:SetScript("OnEnterPressed", accept)
        amount:SetScript("OnEscapePressed", function(self) self:ClearFocus(); popup:Hide() end)
        popup:Hide()
        self.itemQuantityPopup = popup
         table.insert(UISpecialFrames, popup:GetName())
    end
    popup.itemID = itemID
    popup.icon:SetTexture(itemIcon(itemID))
    popup.itemName:SetText(itemName or (self.Data:GetGeneratedById("Items", itemID) or {})[2] or ("Item " .. itemID))
    popup.idText:SetText("Item ID: " .. itemID)
    popup.amount:SetText(tostring(defaultAmount)); popup:Show(); popup:Raise(); popup.amount:SetFocus(); popup.amount:HighlightText()
end

local function categoryCandidates(frame)
    frame.categoryCache = frame.categoryCache or {}
    local key = frame.selectedCategory or "all"
    if key == "all" then return A.Data.Items or {} end
    if frame.categoryCache[key] then return frame.categoryCache[key] end

    local rows = {}
    if key == "mop" then
        for _, row in ipairs(A.Data.Items or {}) do
            if categoryMatches(row, A.Data:GetItemSource(row[1]), key) then table.insert(rows, row) end
        end
    else
        local prefix, value = string.match(key, "^(%a+):(.*)$")
        if prefix == "legacy" then
            local ids = A.Data:GetLegacyItemCategory(value) or {}
            for _, id in ipairs(ids) do
                local row = A.Data:GetGeneratedById("Items", id)
                if row then table.insert(rows, row) end
            end
        elseif prefix == "source" or prefix == "section" then
            for id, info in pairs(A.Data.itemSources or {}) do
                local matches = (prefix == "source" and tostring(info.category or "") == value)
                    or (prefix == "section" and contains(info.section, value))
                if matches then
                    local row = A.Data:GetGeneratedById("Items", id)
                    if row then table.insert(rows, row) end
                end
            end
            table.sort(rows, function(left, right) return (tonumber(left[1]) or 0) < (tonumber(right[1]) or 0) end)
        else
            for _, row in ipairs(A.Data.Items or {}) do
                if categoryMatches(row, A.Data:GetItemSource(row[1]), key) then table.insert(rows, row) end
            end
        end
    end
    frame.categoryCache[key] = rows
    return rows
end

local function buildFilters(frame)
    local query = lower(A:Trim(frame.searchEdit:GetText()))
    local numeric = tonumber(query)
    local results = {}
    local sourceRows
    if numeric then
        local direct = A.Data:GetGeneratedById("Items", numeric)
        sourceRows = direct and { direct } or {}
    else
        sourceRows = categoryCandidates(frame)
    end
    frame.placeholderFiltered = 0
    for _, sourceRow in ipairs(sourceRows) do
        local row=A:ResolveBrowserItem(sourceRow,false)
        local id = tonumber(row[1]) or 0
        local info = A.Data:GetItemSource(id)
        local name = tostring(row[2] or "")
        local matchesSearch = query == "" or (numeric and id == numeric) or contains(name, query)
            or (info and (contains(info.section, query) or contains(info.raw, query) or contains(info.category, query)))
        if isPlaceholderItem(row) then
            frame.placeholderFiltered = frame.placeholderFiltered + 1
        elseif matchesSearch and categoryMatches(row, info, frame.selectedCategory)
            and frame.typeFilter[itemType(row)]
            and frame.qualityFilter[tonumber(row[3]) or 1] then
            table.insert(results, row)
        end
    end
    frame.results = results
    frame.page = 1
    frame.filterDirty = false
end

local function activeCategoryLabel(frame)
    for _, entry in ipairs(CATEGORIES) do
        if entry.key == frame.selectedCategory then return categoryText(entry) end
    end
    return A:L("ALL")
end

function A:RefreshItemBrowserRows(rebuild)
    local frame = self.itemBrowser
    if not frame then return end
    if rebuild or frame.filterDirty or not frame.results then buildFilters(frame) end
    local total = table.getn(frame.results or {})
    local perPage=pageSize(frame);frame.perPage=perPage
    local maxPage = math.max(1, math.ceil(total / perPage))
    frame.page = math.max(1, math.min(frame.page or 1, maxPage))
    local first = (frame.page - 1) * perPage + 1
    for index = 1, ROWS_PER_PAGE do
        local rowButton = frame.rows[index]
        local data = index<=perPage and frame.results[first + index - 1] or nil
        rowButton.itemData = data
        if data then
            local changed;data,changed=self:ResolveBrowserItem(data,true)
            rowButton.itemData=data
            if changed and scheduleItemRefresh then scheduleItemRefresh(true) end
            local id = tonumber(data[1]) or 0
            local quality = tonumber(data[3]) or 1
            local r, g, b = qualityColor(quality)
            rowButton.itemID = id
            rowButton.icon:SetTexture(itemIcon(id))
            local clientName=GetItemInfo and GetItemInfo(id)
            rowButton.name:SetText("[" .. id .. "]  " .. tostring(clientName or (A:GetConfiguredLocale()=="koKR" and data[2]) or A:L("ITEM").." "..id))
            rowButton.name:SetTextColor(r, g, b)
            rowButton.meta:SetText(A:L(TYPE_LABEL_KEYS[itemType(data)]) .. " · " .. A:L(QUALITY_LABEL_KEYS[quality] or "QUALITY_COMMON")
                .. " · " .. A:T("템렙") .. " " .. tostring(data[4] or 0) .. " · " .. A:T("요구 레벨") .. " " .. tostring(data[5] or 0))
            if not changed and frame.typeFilter[itemType(data)] and frame.qualityFilter[tonumber(data[3]) or 1] then rowButton:Show() else rowButton:Hide() end
        else
            rowButton.itemID = nil; rowButton:Hide()
        end
    end
    frame.pageText:SetText(A:L("ITEM_RESULT_STATUS", total, frame.page, maxPage) .. " · " .. A:L("ITEM_PLACEHOLDER_FILTERED", frame.placeholderFiltered or 0))
    local advancedActive = false
    for _, key in ipairs(TYPE_ORDER) do if frame.typeFilter[key] == false then advancedActive = true; break end end
    if not advancedActive then for _, quality in ipairs(QUALITY_ORDER) do if frame.qualityFilter[quality] == false then advancedActive = true; break end end end
    frame.currentLabel:SetText(A:L("ITEM_CURRENT_FILTER_SIMPLE", activeCategoryLabel(frame))
        .. (advancedActive and ("  |cff55e6ef" .. A:L("ITEM_ADVANCED_ACTIVE") .. "|r") or ""))
    UI:SetEnabled(frame.previous, frame.page > 1)
    UI:SetEnabled(frame.next, frame.page < maxPage)
    for _, button in ipairs(frame.categoryButtons) do
        if button.aaeCategory then UI:SetActive(button, button.aaeCategory == frame.selectedCategory) end
    end
end

function A:SetItemCategory(key)
    local frame = self.itemBrowser
    if not frame then return end
    frame.selectedCategory = key or "all"
    self:RefreshItemBrowserRows(true)
end

function A:CreateItemBrowser()
    if self.itemBrowser then return end
    local frame = UI:CreateWindow("item_browser", self:L("ITEM_BROWSER"), 900, 610, "strong")
    self.itemBrowser = frame
    frame.aaeTitle:ClearAllPoints(); frame.aaeTitle:SetPoint("TOPLEFT", frame, "TOPLEFT", 54, -17)
    local icon = frame:CreateTexture(nil, "ARTWORK"); icon:SetTexture("Interface\\AddOns\\GMminibar\\Embedded\\BlueItemInfo3\\ItemInfoR3")
    icon:SetWidth(32); icon:SetHeight(32); icon:SetPoint("TOPLEFT", frame, "TOPLEFT", 14, -10)
    frame.aaeTitleIcon = icon
    local localeSource = UI:Text(frame, self:L("ITEM_LOCALE_SOURCE"), "small")
    localeSource:SetWidth(430); localeSource:SetJustifyH("RIGHT"); localeSource:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -42, -20); localeSource:SetTextColor(0.62, 0.68, 0.74)
    local hint = UI:Text(frame, self:L("ITEM_BROWSER_CANONICAL_HINT"), "small")
    hint:SetPoint("TOPLEFT", frame, "TOPLEFT", 18, -47); hint:SetTextColor(0.55, 0.88, 0.92)

    local catTitle = UI:Text(frame, self:L("CATEGORY"), "normal")
    catTitle:SetPoint("TOPLEFT", frame, "TOPLEFT", 18, -78); catTitle:SetTextColor(1, 0.82, 0.18)
    local catScroll = CreateFrame("ScrollFrame", "AzerothAdminAC335ItemCategoryScroll", frame, "UIPanelScrollFrameTemplate")
    catScroll:SetPoint("TOPLEFT", frame, "TOPLEFT", 16, -96); catScroll:SetWidth(205); catScroll:SetHeight(460)
    local catChild = CreateFrame("Frame", nil, catScroll); catChild:SetWidth(178); catChild:SetHeight(math.max(460, table.getn(CATEGORIES) * 23 + 4)); catScroll:SetScrollChild(catChild)
    catScroll:EnableMouseWheel(true)
    catScroll:SetScript("OnMouseWheel", function(self, delta)
        local current = self:GetVerticalScroll() or 0
        local maximum = self:GetVerticalScrollRange() or 0
        self:SetVerticalScroll(math.max(0, math.min(maximum, current - delta * 69)))
    end)
    frame.categoryScroll = catScroll; frame.categoryButtons = {}
    for index, entry in ipairs(CATEGORIES) do
        if entry.header then
            local label = UI:Text(catChild, categoryText(entry), "small")
            label:SetPoint("TOPLEFT", catChild, "TOPLEFT", 7, -4 - (index - 1) * 23); label:SetTextColor(1, 0.78, 0.22)
        else
            local display = entry.text and A:TranslateLabel(entry.text) or ("   └ " .. categoryText(entry))
            local button = UI:Button(catChild, 174, 21, display, entry.kind == "root" and "utility" or "normal", "LEFT")
            button:SetPoint("TOPLEFT", catChild, "TOPLEFT", 2, -(index - 1) * 23)
            button.aaeCategory = entry.key
            button:SetScript("OnClick", function(self) A:SetItemCategory(self.aaeCategory) end)
            frame.categoryButtons[index] = button
        end
    end

    local filterX = 245
    frame.typeFilter = {}; frame.typeChecks = {}; frame.qualityFilter = {}; frame.qualityChecks = {}
    for _, key in ipairs(TYPE_ORDER) do frame.typeFilter[key] = true end
    for _, quality in ipairs(QUALITY_ORDER) do frame.qualityFilter[quality] = true end

    local searchLabel = UI:Text(frame, self:L("NAME_OR_ID"), "normal")
    searchLabel:SetPoint("TOPLEFT", frame, "TOPLEFT", filterX, -75); searchLabel:SetTextColor(1, 0.82, 0.18)
    local edit = UI:EditBox(frame, 300, 24, "AzerothAdminAC335ItemSearch")
    edit:SetPoint("TOPLEFT", frame, "TOPLEFT", filterX + 60, -69); frame.searchEdit = edit
    local searchButton = UI:Button(frame, 58, 24, self:L("SEARCH"), "utility"); searchButton:SetPoint("LEFT", edit, "RIGHT", 7, 0)
    local resetButton = UI:Button(frame, 68, 24, self:L("RESET"), "normal"); resetButton:SetPoint("LEFT", searchButton, "RIGHT", 7, 0)
    local advancedButton = UI:Button(frame, 112, 24, "", "utility"); advancedButton:SetPoint("LEFT", resetButton, "RIGHT", 7, 0); frame.advancedButton = advancedButton

    local advancedControls = {}
    local typeTitle = UI:Text(frame, self:L("TYPE"), "normal"); typeTitle:SetTextColor(1, 0.82, 0.18); table.insert(advancedControls, typeTitle)
    local qualityTitle = UI:Text(frame, self:L("QUALITY"), "normal"); qualityTitle:SetTextColor(1, 0.82, 0.18); table.insert(advancedControls, qualityTitle)
    typeTitle:SetPoint("TOPLEFT", frame, "TOPLEFT", filterX, -112)
    qualityTitle:SetPoint("TOPLEFT", frame, "TOPLEFT", filterX, -141)
    for index, key in ipairs(TYPE_ORDER) do
        local check = UI:Check(frame, 94, self:L(TYPE_LABEL_KEYS[key]), true, function(self)
            local value=self:GetChecked();frame.typeFilter[self.aaeFilterKey] = value==true or value==1;frame.filterDirty = true; A:RefreshItemBrowserRows(true)
        end)
        check:SetPoint("TOPLEFT", frame, "TOPLEFT", filterX + 42 + (index - 1) * 96, -106)
        check.aaeFilterKey = key; frame.typeChecks[key] = check; table.insert(advancedControls, check)
    end
    for index, quality in ipairs(QUALITY_ORDER) do
        local check = UI:Check(frame, 68, self:L(QUALITY_LABEL_KEYS[quality]), true, function(self)
            local value=self:GetChecked();frame.qualityFilter[self.aaeQuality] = value==true or value==1;frame.filterDirty = true; A:RefreshItemBrowserRows(true)
        end)
        check:SetPoint("TOPLEFT", frame, "TOPLEFT", filterX + 42 + (index - 1) * 68, -135)
        check.aaeQuality = quality; frame.qualityChecks[quality] = check; table.insert(advancedControls, check)
    end
    frame.advancedControls = advancedControls
    frame.advancedVisible = A:GetDB().itemAdvancedFilters == true

    searchButton:SetScript("OnClick", function() A:RefreshItemBrowserRows(true) end)
    resetButton:SetScript("OnClick", function()
        edit:SetText(""); frame.selectedCategory = "all"
        for _, key in ipairs(TYPE_ORDER) do frame.typeFilter[key] = true; frame.typeChecks[key]:SetChecked(true) end
        for _, quality in ipairs(QUALITY_ORDER) do frame.qualityFilter[quality] = true; frame.qualityChecks[quality]:SetChecked(true) end
        frame.filterDirty = true; A:RefreshItemBrowserRows(true)
    end)
    edit:SetScript("OnEnterPressed", function(self) self:ClearFocus(); A:RefreshItemBrowserRows(true) end)
    edit:SetScript("OnEscapePressed", function(self) if self:GetText() ~= "" then self:SetText(""); A:RefreshItemBrowserRows(true) else self:ClearFocus(); frame:Hide() end end)
    local currentLabel = UI:Text(frame, "", "small"); currentLabel:SetTextColor(0.45, 0.90, 1); frame.currentLabel = currentLabel

    frame.rows = {}
    for index = 1, ROWS_PER_PAGE do
        local row = CreateFrame("Button", nil, frame)
        row:SetWidth(316); row:SetHeight(44)
        local col = (index - 1) % 2; local line = math.floor((index - 1) / 2)
        row:SetPoint("TOPLEFT", frame, "TOPLEFT", filterX + col * 326, -214 - line * 48)
        row:SetBackdrop(UI.buttonBackdrop); row:SetBackdropColor(0.02, 0.035, 0.045, 0.78); row:SetBackdropBorderColor(0.30, 0.34, 0.37, 1)
        row:RegisterForClicks("LeftButtonUp", "RightButtonUp")
        local texture = row:CreateTexture(nil, "ARTWORK"); texture:SetWidth(34); texture:SetHeight(34); texture:SetPoint("LEFT", row, "LEFT", 6, 0); row.icon = texture
        local name = UI:Text(row, "", "small"); name:SetWidth(262); name:SetJustifyH("LEFT"); name:SetPoint("TOPLEFT", row, "TOPLEFT", 46, -6); row.name = name
        local meta = UI:Text(row, "", "small"); meta:SetWidth(262); meta:SetJustifyH("LEFT"); meta:SetPoint("BOTTOMLEFT", row, "BOTTOMLEFT", 46, 6); meta:SetTextColor(0.65, 0.82, 0.90); row.meta = meta
        row:SetScript("OnEnter", function(self)
            if not self.itemID then return end
            self:SetBackdropColor(0.055, 0.12, 0.15, 0.96)
            local GameTooltip=A:BeginHintTooltip(self, "ANCHOR_RIGHT")
            pcall(GameTooltip.SetHyperlink, GameTooltip, "item:" .. tostring(self.itemID))
            local source = A:TranslateLabel(sourceText(A.Data:GetItemSource(self.itemID)))
            if source ~= "" then GameTooltip:AddLine(" "); GameTooltip:AddLine("|cffffd24a" .. A:L("ACQUISITION_INFO") .. "|r"); GameTooltip:AddLine(source, 1, 1, 1, true) end
            GameTooltip:AddLine(" "); GameTooltip:AddLine(A:L("ITEM_ROW_HINT"), 0.55, 0.95, 0.80, true); A:StyleHintTooltip();GameTooltip:Show()
        end)
        row:SetScript("OnLeave", function(self) self:SetBackdropColor(0.02, 0.035, 0.045, 0.78); A:HideHintTooltip(self) end)
        row:SetScript("OnClick", function(self, mouseButton)
            if not self.itemID then return end
            local link = itemLink(self.itemID)
            if link and HandleModifiedItemClick and HandleModifiedItemClick(link) then return end
            if mouseButton == "RightButton" then
                A:RunRegisteredCommand("lookup_item", tostring((self.itemData and self.itemData[2]) or self.itemID), true)
            else
                A:ShowItemQuantityPopup(self.itemID, self.itemData and self.itemData[2], 1)
            end
        end)
        frame.rows[index] = row
    end

    function frame:LayoutAdvancedFilters()
        local visible = self.advancedVisible == true
        for _, control in ipairs(self.advancedControls or {}) do if visible then control:Show() else control:Hide() end end
        self.advancedButton:SetText(A:L(visible and "ITEM_ADVANCED_FILTERS_HIDE" or "ITEM_ADVANCED_FILTERS"))
        self.currentLabel:ClearAllPoints(); self.currentLabel:SetPoint("TOPLEFT", self, "TOPLEFT", filterX, visible and -167 or -107)
        local baseY = visible and -191 or -131
        for index, row in ipairs(self.rows or {}) do
            local col = (index - 1) % 2; local line = math.floor((index - 1) / 2)
            row:ClearAllPoints(); row:SetPoint("TOPLEFT", self, "TOPLEFT", filterX + col * 326, baseY - line * 48)
        end
        A:GetDB().itemAdvancedFilters = visible
    end
    advancedButton:SetScript("OnClick", function()
        frame.advancedVisible = not frame.advancedVisible
        frame:LayoutAdvancedFilters()
        A:RefreshItemBrowserRows(false)
    end)
    frame:LayoutAdvancedFilters()

    local previous = UI:Button(frame, 82, 22, "◀ " .. self:L("PREVIOUS"), "utility"); previous:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", filterX, 22)
    previous:SetScript("OnClick", function() if frame.page > 1 then frame.page = frame.page - 1; A:RefreshItemBrowserRows(false) end end); frame.previous = previous
    local pageText = UI:Text(frame, "", "small"); pageText:SetWidth(420); pageText:SetJustifyH("CENTER"); pageText:SetPoint("LEFT", previous, "RIGHT", 14, 0); frame.pageText = pageText
    local nextButton = UI:Button(frame, 82, 22, self:L("NEXT") .. " ▶", "utility"); nextButton:SetPoint("LEFT", pageText, "RIGHT", 14, 0)
    nextButton:SetScript("OnClick", function()
        local maxPage = math.max(1, math.ceil(table.getn(frame.results or {}) / pageSize(frame)))
        if frame.page < maxPage then frame.page = frame.page + 1; A:RefreshItemBrowserRows(false) end
    end); frame.next = nextButton
    UI:BindMouseWheel(frame, previous, nextButton)
    frame.selectedCategory = "all"; frame.page = 1; frame.results = nil
    self:RefreshItemBrowserRows(true)
end

function A:OpenItemBrowser()
    if not self.itemBrowser then self:CreateItemBrowser() end
    self:RefreshItemBrowserRows(false)
    UI:ShowWindow(self.itemBrowser)
end

function A:ToggleItemBrowser()
    if not self.itemBrowser then self:CreateItemBrowser() end
    if self.itemBrowser:IsShown() then self.itemBrowser:Hide() else self:OpenItemBrowser() end
end

-- Item icons can be uncached when the 80k-row SQL table first loads. Refresh the
-- visible page after the client receives item information, without rebuilding
-- the whole result set or changing the user's page/filter selection.
local itemCacheEvents = CreateFrame("Frame")
itemCacheEvents:RegisterEvent("GET_ITEM_INFO_RECEIVED")
scheduleItemRefresh=function(rebuild)
    local frame = A.itemBrowser
    if not frame then return end
    if rebuild then frame.clientMetadataDirty=true end
    if not frame.IsShown or not frame:IsShown() then if rebuild then frame.filterDirty=true end;return end
    if A.itemBrowserCacheRefreshPending then return end
    A.itemBrowserCacheRefreshPending = true
    A:RunAfter(0.08, function()
        A.itemBrowserCacheRefreshPending = false
        if A.itemBrowser and A.itemBrowser:IsShown() then
            local f=A.itemBrowser;local page=f.page
            if f.clientMetadataDirty then f.clientMetadataDirty=nil;buildFilters(f);f.page=page end
            A:RefreshItemBrowserRows(false)
        end
    end)
end
itemCacheEvents:SetScript("OnEvent", function(_,_,id,success)
    local row=id and A.Data:GetGeneratedById('Items',id)
    local changed=false
    if row and success~=false then local value;value,changed=A:ResolveBrowserItem(row,true) end
    scheduleItemRefresh(changed)
end)
A.itemBrowserCacheEventFrame = itemCacheEvents


-- R8 search-first filter helpers exposed for deterministic self-tests.
A.ItemBrowserQualityOrder = QUALITY_ORDER
A.BuildItemBrowserFilters = buildFilters
