-- Profession information UI for WoW 3.3.5a / AzerothCore exclusive build.

local addon = AzerothAdminEasy
local CraftData = AzerothAdminCraftData or InvenCraftInfo
if not addon or not CraftData then return end
AzerothAdminCraftData = CraftData

local UI = CreateFrame("Frame", "AzerothAdminCraftInfoFrame", UIParent)
addon.craftInfoFrame = UI
UI:SetWidth(850)
UI:SetHeight(570)
UI:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
UI:SetFrameStrata("FULLSCREEN_DIALOG")
UI:SetMovable(true)
UI:EnableMouse(true)
UI:SetClampedToScreen(true)
UI:RegisterForDrag("LeftButton")
UI:SetBackdrop({
    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 16, edgeSize = 14,
    insets = { left = 4, right = 4, top = 4, bottom = 4 },
})
UI:SetBackdropColor(0.018, 0.025, 0.035, 0.985)
UI:SetBackdropBorderColor(0.95, 0.58, 0.10, 1)
UI:SetScript("OnDragStart", function(self) self:StartMoving() end)
UI:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
UI:Hide()

if addon.RegisterEscapeFrame then addon:RegisterEscapeFrame(UI) end

local function makeText(parent, text, font)
    local fs = parent:CreateFontString(nil, "OVERLAY", font or "GameFontNormal")
    fs:SetText(text or "")
    return fs
end

local function makePanel(parent)
    local f = CreateFrame("Frame", nil, parent)
    f:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 12, edgeSize = 8,
        insets = { left = 2, right = 2, top = 2, bottom = 2 },
    })
    f:SetBackdropColor(0.012, 0.020, 0.028, 0.92)
    f:SetBackdropBorderColor(0.34, 0.31, 0.23, 1)
    return f
end

local function makeButton(parent, width, height, text, justify)
    local b = CreateFrame("Button", nil, parent)
    b:SetWidth(width)
    b:SetHeight(height)
    b:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 12, edgeSize = 8,
        insets = { left = 2, right = 2, top = 2, bottom = 2 },
    })
    b:SetBackdropColor(0.025, 0.040, 0.055, 0.96)
    b:SetBackdropBorderColor(0.40, 0.38, 0.30, 1)
    local label = b:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    label:SetPoint("LEFT", b, "LEFT", 6, 0)
    label:SetPoint("RIGHT", b, "RIGHT", -6, 0)
    label:SetJustifyH(justify or "CENTER")
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
    e:SetTextInsets(7, 7, 0, 0)
    e:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 12, edgeSize = 8,
        insets = { left = 2, right = 2, top = 2, bottom = 2 },
    })
    e:SetBackdropColor(0.008, 0.015, 0.020, 1)
    e:SetBackdropBorderColor(0.48, 0.43, 0.31, 1)
    return e
end

local function trim(v)
    v = tostring(v or "")
    return string.gsub(v, "^%s*(.-)%s*$", "%1")
end

local function stripColors(v)
    v = tostring(v or "")
    v = string.gsub(v, "|c%x%x%x%x%x%x%x%x", "")
    v = string.gsub(v, "|r", "")
    return v
end

local function itemIDFromLink(link)
    if type(link) ~= "string" then return nil end
    return tonumber(string.match(link, "item:(%d+)"))
end

local function spellIDFromLink(link)
    if type(link) ~= "string" then return nil end
    return tonumber(string.match(link, "enchant:(%d+)")) or tonumber(string.match(link, "spell:(%d+)"))
end

local staticItemNameCache = {}

local function getItemName(id)
    id = tonumber(id)
    if not id then return "미확인 아이템" end
    if staticItemNameCache[id] then return staticItemNameCache[id] end
    local name = GetItemInfo(id)
    if name and name ~= "" then
        staticItemNameCache[id] = name
        return name
    end
    if BlueItemInfo3 and BlueItemInfo3.GetItemName then
        local ok, value = pcall(BlueItemInfo3.GetItemName, BlueItemInfo3, id)
        if ok and value and value ~= "" and value ~= ("아이템 " .. tostring(id)) then
            staticItemNameCache[id] = value
            return value
        end
    end
    local D = BlueItemInfo3EmbeddedData
    local raw = D and D.itemName and D.itemName[id]
    if raw then
        local _, n = string.match(raw, "^(%d+)|(.+)$")
        local value = n or raw
        staticItemNameCache[id] = value
        return value
    end
    if addon.KoKRSearchData and addon.KoKRSearchData.item then
        local data = addon.KoKRSearchData.item
        local i
        for i = 1, table.getn(data) do
            if tonumber(data[i][1]) == id then
                staticItemNameCache[id] = data[i][2]
                return data[i][2]
            end
        end
    end
    return "아이템 " .. tostring(id)
end

local function getItemTexture(id)
    id = tonumber(id)
    if not id then return "Interface\\Icons\\INV_Misc_QuestionMark" end
    local _, _, _, _, _, _, _, _, _, texture = GetItemInfo(id)
    if not texture and GetItemIcon then
        local ok, value = pcall(GetItemIcon, id)
        if ok then texture = value end
    end
    return texture or "Interface\\Icons\\INV_Misc_QuestionMark"
end

local function getItemLink(id)
    id = tonumber(id)
    if not id then return nil end
    local _, link = GetItemInfo(id)
    if link then return link end
    local name = getItemName(id)
    if name and name ~= "" then
        return "|cffffffff|Hitem:" .. tostring(id) .. ":0:0:0:0:0:0:0|h[" .. name .. "]|h|r"
    end
    return nil
end

local reagentNameToItemID = nil

local function normalizeItemName(name)
    name = trim(stripColors(name))
    name = string.gsub(name, "%s+", " ")
    return string.lower(name)
end

local function ensureReagentNameIndex()
    if reagentNameToItemID then return end
    reagentNameToItemID = {}
    local data = addon.KoKRSearchData and addon.KoKRSearchData.item or nil
    if type(data) ~= "table" then return end
    local i
    for i = 1, table.getn(data) do
        local id = tonumber(data[i][1])
        local key = normalizeItemName(data[i][2])
        if id and key ~= "" and not reagentNameToItemID[key] then
            reagentNameToItemID[key] = id
        end
    end
end

local function resolveItemID(name)
    local key = normalizeItemName(name)
    if key == "" then return nil end

    ensureReagentNameIndex()
    local id = reagentNameToItemID and reagentNameToItemID[key] or nil
    if id then return tonumber(id) end

    -- Reuse the addon's exact/unique koKR resolver as a final fallback.
    if addon.FindLocaleID then
        local ok, value = pcall(addon.FindLocaleID, addon, "item", trim(stripColors(name)))
        if ok and value then return tonumber(value) end
    end
    return nil
end

local function normalizeReagents(reagents)
    if type(reagents) ~= "table" then return nil end
    local result = {}
    local i
    for i = 1, table.getn(reagents) do
        local source = reagents[i]
        if type(source) == "table" then
            local reagent = source
            reagent.id = tonumber(reagent.id) or itemIDFromLink(reagent.link) or resolveItemID(reagent.name)
            if reagent.id then
                reagent.name = (reagent.name and trim(stripColors(reagent.name)) ~= "")
                    and trim(stripColors(reagent.name)) or getItemName(reagent.id)
                reagent.link = reagent.link or getItemLink(reagent.id)
                local texture = reagent.texture
                if not texture or texture == "Interface\\Icons\\INV_Misc_QuestionMark" then
                    texture = getItemTexture(reagent.id)
                end
                reagent.texture = texture
                if reagent.have == nil and GetItemCount then reagent.have = GetItemCount(reagent.id) end
            else
                reagent.name = trim(stripColors(reagent.name or "미확인 재료"))
                reagent.texture = reagent.texture or "Interface\\Icons\\INV_Misc_QuestionMark"
            end
            reagent.needed = math.max(1, math.floor(tonumber(reagent.needed) or 1))
            table.insert(result, reagent)
        end
    end
    return result
end

local PROFESSION_IDS = {
    2550,   -- Cooking
    2259,   -- Alchemy
    3908,   -- Tailoring
    2108,   -- Leatherworking
    2018,   -- Blacksmithing
    4036,   -- Engineering
    7411,   -- Enchanting
    25229,  -- Jewelcrafting
    45363,  -- Inscription
    3273,   -- First Aid
    2656,   -- Smelting / Mining
}

local professionRecords = {}
local selectedProfession = nil
local allRecipes = {}
local filteredRecipes = {}
local page = 1
local PAGE_SIZE = 9
local selectedRecipe = nil
local refreshRows

local icon = UI:CreateTexture(nil, "ARTWORK")
icon:SetTexture("Interface\\Icons\\Trade_Engineering")
icon:SetWidth(32)
icon:SetHeight(32)
icon:SetPoint("TOPLEFT", 14, -10)

local title = makeText(UI, "전문기술 정보 · WotLK 3.3.5a", "GameFontNormalLarge")
title:SetPoint("TOPLEFT", 54, -17)
title:SetTextColor(1, 0.78, 0.25)

local close = CreateFrame("Button", nil, UI, "UIPanelCloseButton")
close:SetPoint("TOPRIGHT", -5, -5)

local hint = makeText(UI, "제작 목록 · 결과물/재료 획득 · 도안 습득 · 요구 숙련 관리", "GameFontHighlightSmall")
hint:SetPoint("TOPLEFT", 18, -47)
hint:SetTextColor(0.55, 0.88, 0.92)

local professionPanel = makePanel(UI)
professionPanel:SetPoint("TOPLEFT", 15, -72)
professionPanel:SetWidth(170)
professionPanel:SetHeight(473)

local professionTitle = makeText(professionPanel, "전문기술", "GameFontNormal")
professionTitle:SetPoint("TOPLEFT", 10, -10)
professionTitle:SetTextColor(1, 0.82, 0.18)

local recipePanel = makePanel(UI)
recipePanel:SetPoint("TOPLEFT", 194, -72)
recipePanel:SetWidth(308)
recipePanel:SetHeight(473)

local recipeTitle = makeText(recipePanel, "제작 아이템", "GameFontNormal")
recipeTitle:SetPoint("TOPLEFT", 10, -10)
recipeTitle:SetTextColor(1, 0.82, 0.18)

local searchBox = makeEdit(recipePanel, 142, 24)
searchBox:SetPoint("TOPLEFT", 10, -30)

local searchButton = makeButton(recipePanel, 55, 24, "검색")
searchButton:SetPoint("LEFT", searchBox, "RIGHT", 6, 0)

local sortMode = "skill"
local sortButton = makeButton(recipePanel, 75, 24, "숙련↓")
sortButton:SetPoint("LEFT", searchButton, "RIGHT", 5, 0)
sortButton.aaeHint = "클릭: 요구 숙련 높은순 / 희귀도 높은순 / 숙련+희귀도 순환"

local detailPanel = makePanel(UI)
detailPanel:SetPoint("TOPLEFT", 511, -72)
detailPanel:SetWidth(324)
detailPanel:SetHeight(473)

local detailTitle = makeText(detailPanel, "결과물", "GameFontNormal")
detailTitle:SetPoint("TOPLEFT", 10, -10)
detailTitle:SetTextColor(1, 0.82, 0.18)

UI.professionButtons = {}
UI.skillButtons = {}
UI.reagentButtons = {}

local outputButton = CreateFrame("Button", nil, detailPanel)
outputButton:SetPoint("TOPLEFT", 10, -30)
outputButton:SetWidth(304)
outputButton:SetHeight(76)
outputButton:RegisterForClicks("LeftButtonUp", "RightButtonUp")
outputButton:SetBackdrop({
    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 12, edgeSize = 8,
    insets = { left = 2, right = 2, top = 2, bottom = 2 },
})
outputButton:SetBackdropColor(0.020, 0.035, 0.045, 0.90)
outputButton:SetBackdropBorderColor(0.42, 0.40, 0.30, 1)
outputButton.icon = outputButton:CreateTexture(nil, "ARTWORK")
outputButton.icon:SetWidth(48)
outputButton.icon:SetHeight(48)
outputButton.icon:SetPoint("LEFT", 8, 0)
outputButton.name = makeText(outputButton, "", "GameFontNormal")
outputButton.name:SetPoint("TOPLEFT", 66, -9)
outputButton.name:SetWidth(226)
outputButton.name:SetJustifyH("LEFT")
outputButton.meta = makeText(outputButton, "", "GameFontHighlightSmall")
outputButton.meta:SetPoint("TOPLEFT", outputButton.name, "BOTTOMLEFT", 0, -5)
outputButton.meta:SetWidth(226)
outputButton.meta:SetJustifyH("LEFT")
outputButton.meta:SetTextColor(0.58, 0.82, 0.92)
outputButton.clickHint = makeText(outputButton, "클릭: 수량 선택 → 가방 추가", "GameFontHighlightSmall")
outputButton.clickHint:SetPoint("BOTTOMLEFT", 66, 8)
outputButton.clickHint:SetTextColor(0.55, 0.95, 0.75)

local spellAction = makeButton(detailPanel, 142, 22, "Spell", "CENTER")
spellAction:SetPoint("TOPLEFT", 10, -111)
local skillAction = makeButton(detailPanel, 142, 22, "요구 숙련", "CENTER")
skillAction:SetPoint("LEFT", spellAction, "RIGHT", 8, 0)
spellAction:Hide(); skillAction:Hide()

local sourceText = makeText(detailPanel, "", "GameFontHighlightSmall")
sourceText:SetPoint("TOPLEFT", 12, -139)
sourceText:SetWidth(300)
sourceText:SetHeight(34)
sourceText:SetJustifyH("LEFT")
sourceText:SetJustifyV("TOP")
sourceText:SetTextColor(0.75, 0.78, 0.82)

local reagentTitle = makeText(detailPanel, "재료", "GameFontNormal")
reagentTitle:SetPoint("TOPLEFT", 10, -171)
reagentTitle:SetTextColor(1, 0.82, 0.18)

local noReagentText = makeText(detailPanel, "", "GameFontHighlightSmall")
noReagentText:SetPoint("TOPLEFT", 12, -194)
noReagentText:SetWidth(300)
noReagentText:SetJustifyH("LEFT")
noReagentText:SetTextColor(0.75, 0.78, 0.82)
noReagentText:Hide()

for i = 1, 8 do
    local b = CreateFrame("Button", nil, detailPanel)
    local col = (i - 1) % 2
    local row = math.floor((i - 1) / 2)
    b:SetWidth(145)
    b:SetHeight(62)
    b:SetPoint("TOPLEFT", 10 + col * 151, -190 - row * 66)
    b:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    b:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 12, edgeSize = 8,
        insets = { left = 2, right = 2, top = 2, bottom = 2 },
    })
    b:SetBackdropColor(0.020, 0.035, 0.045, 0.84)
    b:SetBackdropBorderColor(0.34, 0.36, 0.34, 1)
    b.icon = b:CreateTexture(nil, "ARTWORK")
    b.icon:SetWidth(34)
    b.icon:SetHeight(34)
    b.icon:SetPoint("LEFT", 6, 5)
    b.name = makeText(b, "", "GameFontHighlightSmall")
    b.name:SetPoint("TOPLEFT", 46, -7)
    b.name:SetWidth(91)
    b.name:SetHeight(31)
    b.name:SetJustifyH("LEFT")
    b.name:SetJustifyV("TOP")
    b.count = makeText(b, "", "GameFontHighlightSmall")
    b.count:SetPoint("BOTTOMLEFT", 46, 8)
    b.count:SetWidth(91)
    b.count:SetJustifyH("LEFT")
    b.count:SetTextColor(0.55, 0.88, 0.92)
    b:Hide()
    UI.reagentButtons[i] = b
end

local recipeRows = {}
for i = 1, PAGE_SIZE do
    local row = makeButton(recipePanel, 286, 36, "", "LEFT")
    row:SetPoint("TOPLEFT", 10, -64 - (i - 1) * 39)
    row.indexText = makeText(row, "", "GameFontHighlightSmall")
    row.indexText:SetPoint("RIGHT", row, "RIGHT", -7, 0)
    row.indexText:SetTextColor(0.48, 0.70, 0.80)
    row.label:ClearAllPoints()
    row.label:SetPoint("LEFT", row, "LEFT", 7, 0)
    row.label:SetPoint("RIGHT", row, "RIGHT", -82, 0)
    row:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    row:SetScript("OnEnter", function(self)
        self:SetBackdropColor(0.055, 0.12, 0.15, 0.96)
        if self.recipe then
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            local link = self.recipe.itemID and getItemLink(self.recipe.itemID) or nil
            if link then
                GameTooltip:SetHyperlink(link)
            elseif self.recipe.spellID then
                pcall(GameTooltip.SetHyperlink, GameTooltip, "spell:" .. tostring(self.recipe.spellID))
            end
            GameTooltip:AddLine(" ")
            GameTooltip:AddLine("Spell ID: " .. tostring(self.recipe.spellID), 0.45, 0.86, 1.00)
            GameTooltip:AddLine("요구 숙련: " .. tostring(self.recipe.required or 0), 0.85, 0.85, 0.85)
            GameTooltip:AddLine("좌클릭: 상세 보기", 0.55, 0.95, 0.75)
            GameTooltip:Show()
        end
    end)
    row:SetScript("OnLeave", function(self)
        if self.recipe == selectedRecipe then
            self:SetBackdropColor(0.07, 0.11, 0.16, 0.98)
        else
            self:SetBackdropColor(0.025, 0.040, 0.055, 0.96)
        end
        GameTooltip:Hide()
    end)
    recipeRows[i] = row
    UI.skillButtons[i] = row
end

local prevButton = makeButton(recipePanel, 72, 22, "◀ 이전")
prevButton:SetPoint("BOTTOMLEFT", 10, 9)

local pageText = makeText(recipePanel, "", "GameFontHighlightSmall")
pageText:SetPoint("LEFT", prevButton, "RIGHT", 5, 0)
pageText:SetWidth(120)
pageText:SetJustifyH("CENTER")
pageText:SetTextColor(0.65, 0.82, 0.90)

local nextButton = makeButton(recipePanel, 72, 22, "다음 ▶")
nextButton:SetPoint("LEFT", pageText, "RIGHT", 5, 0)

local function isKnownSpell(spellID)
    if IsSpellKnown then
        local ok, known = pcall(IsSpellKnown, spellID)
        if ok and known then return true end
    end
    if IsPlayerSpell then
        local ok, known = pcall(IsPlayerSpell, spellID)
        if ok and known then return true end
    end
    if InvenCraftInfoData and InvenCraftInfoData.IsKnownRecipe then
        local ok, _, knownPlayer = pcall(InvenCraftInfoData.IsKnownRecipe, InvenCraftInfoData, spellID)
        if ok and knownPlayer then return true end
    end
    -- 3.3.5a fallback: scan the player spellbook by hyperlink ID. Some private
    -- client builds do not expose IsSpellKnown consistently for profession recipes.
    if GetNumSpellTabs and GetSpellTabInfo and GetSpellLink then
        local tab
        for tab = 1, (GetNumSpellTabs() or 0) do
            local _, _, offset, numSpells = GetSpellTabInfo(tab)
            offset = tonumber(offset) or 0
            numSpells = tonumber(numSpells) or 0
            local slot
            for slot = offset + 1, offset + numSpells do
                local ok, link = pcall(GetSpellLink, slot, BOOKTYPE_SPELL)
                if ok and type(link) == "string" then
                    local sid = tonumber(string.match(link, "spell:(%d+)"))
                    if sid == tonumber(spellID) then return true end
                end
            end
        end
    end
    return false
end

local PROFESSION_SKILL_LINES = {
    [2550]=185, [2259]=171, [3908]=197, [2108]=165, [2018]=164,
    [4036]=202, [7411]=333, [25229]=755, [45363]=773, [3273]=129, [2656]=186,
}
local PROFESSION_COLORS = {
    [2550]={1.00,0.62,0.18}, [2259]={0.35,0.95,0.50}, [3908]={0.80,0.55,1.00},
    [2108]={0.86,0.58,0.28}, [2018]={0.80,0.82,0.86}, [4036]={1.00,0.82,0.20},
    [7411]={0.65,0.45,1.00}, [25229]={0.35,0.85,1.00}, [45363]={0.95,0.72,0.35},
    [3273]={0.95,0.95,0.95}, [2656]={0.70,0.74,0.80},
}

local function getItemQuality(id)
    id = tonumber(id) or 0
    local _, _, q = GetItemInfo(id)
    q = tonumber(q)
    if q == nil then
        local D = BlueItemInfo3EmbeddedData
        local raw = D and D.itemName and D.itemName[id]
        if type(raw) == "string" then q = tonumber(string.match(raw, "^(%d+)|")) end
    end
    return q or 1
end

local function itemQualityColor(id)
    local q = getItemQuality(id)
    if GetItemQualityColor then
        local r,g,b = GetItemQualityColor(q)
        if r then return r,g,b end
    end
    return 0.95,0.95,0.95
end

local function sortRecipeList(list)
    table.sort(list, function(a, b)
        local ar, br = tonumber(a.required) or 0, tonumber(b.required) or 0
        local aq = a.itemID and getItemQuality(a.itemID) or 1
        local bq = b.itemID and getItemQuality(b.itemID) or 1
        if sortMode == "quality" then
            if aq ~= bq then return aq > bq end
            if ar ~= br then return ar > br end
        elseif sortMode == "skillquality" then
            if ar ~= br then return ar > br end
            if aq ~= bq then return aq > bq end
        else
            if ar ~= br then return ar > br end
            if aq ~= bq then return aq > bq end
        end
        return (a.itemID or a.spellID or 0) < (b.itemID or b.spellID or 0)
    end)
end

local function getProfessionSkillValue(rec)
    if not rec or not GetNumSkillLines or not GetSkillLineInfo then return 0,0 end
    local wanted = PROFESSION_SKILL_LINES[rec.spellID]
    if not wanted then return 0,0 end
    local i
    for i=1,(GetNumSkillLines() or 0) do
        local name, header, _, rank, _, _, maxRank = GetSkillLineInfo(i)
        if not header and name == rec.name then return tonumber(rank) or 0, tonumber(maxRank) or 0 end
    end
    return 0,0
end

local function sendSelfSelectedCommand(command)
    -- Never alter the player's target from addon Lua. Target manipulation is a
    -- protected action and can raise ADDON_ACTION_BLOCKED on the 3.3.5 client.
    addon:SendNow(command)
end

UI._pendingLearn = UI._pendingLearn or {}

local function getSelfPlayerIdentifier()
    local lowGUID = addon.GetSelfLowGUID and addon:GetSelfLowGUID() or nil
    if lowGUID then return tostring(lowGUID), true end
    local name = UnitName("player")
    if name and name ~= "" then return name, false end
    return nil, false
end

local function refreshLearnState()
    if UI:IsShown() then
        UI:RefreshDetail()
        refreshRows()
    end
end

local function requestPlayerLearn(spellID, allRanks, onFinished)
    spellID = tonumber(spellID)
    if not spellID or spellID <= 0 then return end
    if isKnownSpell(spellID) then
        UI._pendingLearn[spellID] = nil
        if onFinished then onFinished(true) end
        refreshLearnState()
        return
    end

    local identifier, usedGUID = getSelfPlayerIdentifier()
    if not identifier then
        addon:Print("현재 캐릭터 식별자를 확인하지 못했습니다.", true)
        if onFinished then onFinished(false) end
        return
    end

    UI._pendingLearn[spellID] = true
    local command = ".player learn " .. identifier .. " " .. tostring(spellID)
    if allRanks then command = command .. " all" end
    addon:SendNow(command)
    refreshLearnState()

    -- First verification. If an older core rejects the no-'all' variant, retry
    -- once with the same unambiguous low GUID and the optional all-ranks token.
    addon:RunAfter(1.0, function()
        if isKnownSpell(spellID) then
            UI._pendingLearn[spellID] = nil
            addon:Print("Spell " .. tostring(spellID) .. " 습득 완료")
            if onFinished then onFinished(true) end
            refreshLearnState()
            return
        end
        if usedGUID and not allRanks then
            addon:SendNow(".player learn " .. identifier .. " " .. tostring(spellID) .. " all")
        end

        addon:RunAfter(1.3, function()
            local known = isKnownSpell(spellID)
            UI._pendingLearn[spellID] = nil
            if known then
                addon:Print("Spell " .. tostring(spellID) .. " 습득 완료")
            else
                addon:Print("Spell " .. tostring(spellID) .. " 습득이 확인되지 않았습니다. 사용 명령: .player learn "
                    .. identifier .. " " .. tostring(spellID), true)
            end
            if onFinished then onFinished(known) end
            refreshLearnState()
        end)
    end)
end

local function buildProfessionCache()
    professionRecords = {}
    local recipeItemSet = {}
    local pi
    for pi = 1, table.getn(PROFESSION_IDS) do
        local skillSpellID = PROFESSION_IDS[pi]
        local skillName = GetSpellInfo(skillSpellID)
        if skillName then
            local skillTable = CraftData.GetSkillTable and CraftData:GetSkillTable(skillName) or nil
            local recipes = {}
            if type(skillTable) == "table" then
                local itemID, spellID
                for itemID, spellID in pairs(skillTable) do
                    itemID = tonumber(itemID)
                    spellID = tonumber(spellID)
                    if itemID and itemID > 0 and itemID <= 56806 and spellID and spellID > 0 and GetSpellInfo(spellID) then
                        recipeItemSet[itemID] = true
                        table.insert(recipes, {
                            itemID = itemID,
                            spellID = spellID,
                            required = (CraftData.GetSpellReq and CraftData:GetSpellReq(spellID)) or 0,
                        })
                    end
                end
            end
            sortRecipeList(recipes)
            table.insert(professionRecords, {
                spellID = skillSpellID,
                name = skillName,
                icon = select(3, GetSpellInfo(skillSpellID)),
                recipes = recipes,
            })
        end
    end

    -- Prime only the recipe output names in one pass instead of scanning the
    -- full koKR item list once for every visible row.
    local source = addon.KoKRSearchData and addon.KoKRSearchData.item or nil
    if source then
        local i
        for i = 1, table.getn(source) do
            local id = tonumber(source[i][1])
            if id and recipeItemSet[id] then staticItemNameCache[id] = source[i][2] end
        end
    end
end

local function getLiveReagents(spellID, outputItemID)
    if not GetNumTradeSkills or not GetTradeSkillRecipeLink then return nil end
    local count = GetNumTradeSkills() or 0
    local i
    for i = 1, count do
        local recipeLink = GetTradeSkillRecipeLink(i)
        local sid = spellIDFromLink(recipeLink)
        local outputLink = GetTradeSkillItemLink and GetTradeSkillItemLink(i) or nil
        local iid = itemIDFromLink(outputLink)
        if (sid and sid == spellID) or (iid and iid == outputItemID) then
            local result = {}
            local n = GetTradeSkillNumReagents and (GetTradeSkillNumReagents(i) or 0) or 0
            local r
            for r = 1, n do
                local name, texture, needed, have = GetTradeSkillReagentInfo(i, r)
                local link = GetTradeSkillReagentItemLink and GetTradeSkillReagentItemLink(i, r) or nil
                local id = itemIDFromLink(link) or resolveItemID(name)
                table.insert(result, {
                    id = id,
                    name = name or (id and getItemName(id)) or ("재료 " .. tostring(r)),
                    texture = texture or (id and getItemTexture(id)),
                    needed = tonumber(needed) or 1,
                    have = tonumber(have),
                    link = link,
                })
            end
            if table.getn(result) > 0 then return result end
        end
    end
    return nil
end

local function parseTooltipReagents(spellID)
    if not CraftData.GetTooltipReagents then return nil end
    local ok, text = pcall(CraftData.GetTooltipReagents, CraftData, spellID)
    if not ok or type(text) ~= "string" or text == "" then return nil end
    text = stripColors(text)
    local reagentHeader = SPELL_REAGENTS or "Reagents"
    local startPos = string.find(text, reagentHeader, 1, true)
    if startPos then text = string.sub(text, startPos + string.len(reagentHeader)) end
    text = string.gsub(text, "^%s*:%s*", "")
    text = trim(text)
    if text == "" then return nil end

    local result = {}
    for token in string.gmatch(text .. ",", "(.-),") do
        token = trim(token)
        if token ~= "" then
            local name, needed = string.match(token, "^(.-)%s*%((%d+)%)%s*$")
            if not name then
                name, needed = string.match(token, "^(.-)%s+[xX](%d+)%s*$")
            end
            if not name then
                name = token
                needed = 1
            end
            name = trim(name)
            needed = tonumber(needed) or 1
            local id = resolveItemID(name)
            table.insert(result, {
                id = id,
                name = name,
                needed = needed,
                have = id and GetItemCount and GetItemCount(id) or nil,
                texture = id and getItemTexture(id) or "Interface\\Icons\\INV_Misc_QuestionMark",
                link = id and getItemLink(id) or nil,
            })
        end
    end
    if table.getn(result) > 0 then return result end
    return nil
end

local function getRecipeReagents(recipe)
    if not recipe then return nil end
    local reagents
    if type(recipe.reagents) == "table" and table.getn(recipe.reagents) > 0 then
        reagents = recipe.reagents
    else
        reagents = getLiveReagents(recipe.spellID, recipe.itemID) or parseTooltipReagents(recipe.spellID)
    end
    reagents = normalizeReagents(reagents)
    if reagents and table.getn(reagents) > 0 then recipe.reagents = reagents end
    return reagents
end

local function setReagentButton(button, reagent)
    button.reagent = reagent
    button.aaeItemID = reagent.id
    button.aaeItemName = reagent.name
    button.aaeItemLink = reagent.link
    button.icon:SetTexture(reagent.texture or (reagent.id and getItemTexture(reagent.id)) or "Interface\\Icons\\INV_Misc_QuestionMark")
    button.name:SetText(reagent.name or (reagent.id and getItemName(reagent.id)) or "미확인 재료")
    local have = reagent.have
    if have == nil and reagent.id and GetItemCount then have = GetItemCount(reagent.id) end
    if have ~= nil then
        button.count:SetText("필요 " .. tostring(reagent.needed or 1) .. " · 보유 " .. tostring(have))
    else
        button.count:SetText("필요 " .. tostring(reagent.needed or 1))
    end
    if reagent.id then
        local r,g,b = itemQualityColor(reagent.id)
        button.name:SetTextColor(r,g,b)
        button:SetBackdropBorderColor(r*0.75,g*0.75,b*0.75,1)
    else
        button.name:SetTextColor(0.70, 0.70, 0.70)
        button:SetBackdropBorderColor(0.38, 0.32, 0.24, 1)
    end
    button:Show()
end

local function clearDetail()
    selectedRecipe = nil
    outputButton.itemID = nil
    outputButton.recipe = nil
    outputButton.icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
    outputButton.name:SetText("왼쪽 목록에서 제작 아이템을 선택하세요.")
    outputButton.name:SetTextColor(0.78, 0.78, 0.78)
    outputButton.meta:SetText("")
    outputButton.clickHint:Hide()
    sourceText:SetText("")
    spellAction.recipe=nil; skillAction.recipe=nil; spellAction:Hide(); skillAction:Hide()
    local i
    for i = 1, table.getn(UI.reagentButtons) do
        UI.reagentButtons[i].reagent = nil
        UI.reagentButtons[i].aaeItemID = nil
        UI.reagentButtons[i]:Hide()
    end
    noReagentText:Hide()
end

function UI:RefreshDetail()
    local recipe = selectedRecipe
    if not recipe then
        clearDetail()
        return
    end

    outputButton.itemID = recipe.itemID
    outputButton.recipe = recipe
    local spellName, _, spellTexture = GetSpellInfo(recipe.spellID)
    spellName = spellName or ("Spell " .. tostring(recipe.spellID))
    if recipe.itemID then
        outputButton.icon:SetTexture(getItemTexture(recipe.itemID))
        outputButton.name:SetText(getItemName(recipe.itemID))
        outputButton.meta:SetText("Item " .. tostring(recipe.itemID) .. " · Spell " .. tostring(recipe.spellID) .. " · 요구 숙련 " .. tostring(recipe.required or 0))
        outputButton.clickHint:SetText("클릭: 수량 선택 → 가방 추가")
        outputButton.clickHint:Show()
    else
        outputButton.icon:SetTexture(spellTexture or "Interface\\Icons\\INV_Misc_QuestionMark")
        outputButton.name:SetText(recipe.recipeName or spellName)
        outputButton.meta:SetText("Spell " .. tostring(recipe.spellID) .. " · 요구 숙련 " .. tostring(recipe.required or 0) .. " · 직접 아이템 결과 없음")
        outputButton.clickHint:Hide()
    end
    if recipe.itemID then local r,g,b=itemQualityColor(recipe.itemID); outputButton.name:SetTextColor(r,g,b) else outputButton.name:SetTextColor(1,0.82,0.18) end

    spellAction.recipe=recipe
    skillAction.recipe=recipe
    local known=isKnownSpell(recipe.spellID)
    if known then UI._pendingLearn[recipe.spellID] = nil end
    local pending = UI._pendingLearn[recipe.spellID]
    if known then
        spellAction:SetText("|cff55ff66습득 완료|r  Spell " .. tostring(recipe.spellID))
    elseif pending then
        spellAction:SetText("|cffffff66확인 중|r  Spell " .. tostring(recipe.spellID))
    else
        spellAction:SetText("|cffffd24a습득|r  Spell " .. tostring(recipe.spellID))
    end
    spellAction:SetBackdropBorderColor(known and 0.25 or (pending and 0.80 or 0.85), known and 0.75 or (pending and 0.75 or 0.62), known and 0.30 or 0.15, 1)
    spellAction:Show()
    local rank,maxRank=getProfessionSkillValue(selectedProfession)
    local req=tonumber(recipe.required) or 0
    local met=(req<=0 or rank>=req)
    skillAction:SetText((met and "|cff55ff66충족|r " or "|cffff6666부족|r ") .. tostring(rank) .. "/" .. tostring(req))
    skillAction:SetBackdropBorderColor(met and 0.25 or 0.85, met and 0.75 or 0.25, met and 0.30 or 0.20, 1)
    skillAction:Show()

    local source = CraftData.GetDropText and CraftData:GetDropText(recipe.spellID) or nil
    if source and source ~= "" then
        sourceText:SetText(spellName .. " · " .. stripColors(source))
    else
        sourceText:SetText(spellName)
    end

    local reagents = getRecipeReagents(recipe) or {}
    local i
    for i = 1, table.getn(UI.reagentButtons) do
        local r = reagents[i]
        if r then
            setReagentButton(UI.reagentButtons[i], r)
        else
            UI.reagentButtons[i].reagent = nil
            UI.reagentButtons[i].aaeItemID = nil
            UI.reagentButtons[i]:Hide()
        end
    end

    if table.getn(reagents) == 0 then
        noReagentText:SetText("재료 정보를 확인할 수 없습니다. 주문 툴팁/전문기술 캐시가 준비되면 자동 갱신됩니다.")
        noReagentText:Show()
    else
        noReagentText:Hide()
    end
end

local function selectRecipe(recipe)
    selectedRecipe = recipe
    UI:RefreshDetail()
    local i
    for i = 1, table.getn(recipeRows) do
        local row = recipeRows[i]
        if row.recipe == recipe then
            row:SetBackdropColor(0.07, 0.11, 0.16, 0.98)
            row:SetBackdropBorderColor(0.95, 0.58, 0.10, 1)
        else
            row:SetBackdropColor(0.025, 0.040, 0.055, 0.96)
            row:SetBackdropBorderColor(0.40, 0.38, 0.30, 1)
        end
    end
end

refreshRows = function()
    local total = table.getn(filteredRecipes)
    local maxPage = math.max(1, math.ceil(total / PAGE_SIZE))
    if page < 1 then page = 1 end
    if page > maxPage then page = maxPage end
    local first = (page - 1) * PAGE_SIZE + 1
    local i
    for i = 1, PAGE_SIZE do
        local rec = filteredRecipes[first + i - 1]
        local row = recipeRows[i]
        if rec then
            row.recipe = rec
            local name = rec.itemID and getItemName(rec.itemID) or rec.recipeName or GetSpellInfo(rec.spellID) or ("Spell " .. tostring(rec.spellID))
            row.label:SetText(name)
            if rec.itemID then
                local r,g,b=itemQualityColor(rec.itemID); row.label:SetTextColor(r,g,b)
            elseif isKnownSpell(rec.spellID) then
                row.label:SetTextColor(0.30,1.00,0.36)
            else
                row.label:SetTextColor(0.92,0.92,0.92)
            end
            if rec.itemID then
                row.indexText:SetText(tostring(rec.required or 0) .. " · " .. tostring(rec.itemID))
            else
                row.indexText:SetText(tostring(rec.required or 0) .. " · S" .. tostring(rec.spellID))
            end
            if selectedRecipe == rec then
                row:SetBackdropColor(0.07, 0.11, 0.16, 0.98)
                row:SetBackdropBorderColor(0.95, 0.58, 0.10, 1)
            else
                row:SetBackdropColor(0.025, 0.040, 0.055, 0.96)
                row:SetBackdropBorderColor(0.40, 0.38, 0.30, 1)
            end
            row:Show()
        else
            row.recipe = nil
            row:Hide()
        end
    end
    pageText:SetText(tostring(total) .. "개 · " .. tostring(page) .. " / " .. tostring(maxPage))
    if page <= 1 then prevButton:Disable() else prevButton:Enable() end
    if page >= maxPage then nextButton:Disable() else nextButton:Enable() end
end

local function applySearch()
    filteredRecipes = {}
    local query = string.lower(trim(searchBox:GetText()))
    local numeric = tonumber(query)
    local i
    for i = 1, table.getn(allRecipes) do
        local rec = allRecipes[i]
        local include = query == ""
        if not include and numeric then
            include = (rec.itemID and rec.itemID == numeric) or rec.spellID == numeric
        elseif not include then
            local itemName = rec.itemID and string.lower(getItemName(rec.itemID)) or ""
            local recipeName = string.lower(rec.recipeName or "")
            local spellName = string.lower(GetSpellInfo(rec.spellID) or "")
            include = string.find(itemName, query, 1, true) ~= nil
                or string.find(recipeName, query, 1, true) ~= nil
                or string.find(spellName, query, 1, true) ~= nil
        end
        if include then table.insert(filteredRecipes, rec) end
    end
    sortRecipeList(filteredRecipes)
    page = 1
    clearDetail()
    refreshRows()
end

local updateProfessionButtons

local function restoreTradeSkillFrame()
    if TradeSkillFrame then
        if TradeSkillFrame:IsShown() then
            if HideUIPanel then
                pcall(HideUIPanel, TradeSkillFrame)
            else
                pcall(TradeSkillFrame.Hide, TradeSkillFrame)
            end
        end
        if UI._tradeSkillOldAlpha then TradeSkillFrame:SetAlpha(UI._tradeSkillOldAlpha) end
    end
    UI._tradeSkillOldAlpha = nil
end

local function captureLinkedProfession(rec)
    if not rec or UI._loadingLive ~= rec then return false end
    local num = GetNumTradeSkills and (GetNumTradeSkills() or 0) or 0
    if num <= 0 then return false end

    local line = GetTradeSkillLine and GetTradeSkillLine() or nil
    if line and line ~= "" and line ~= "UNKNOWN" and line ~= rec.name then return false end

    local staticBySpell = {}
    local i
    for i = 1, table.getn(rec.recipes or {}) do
        local sr = rec.recipes[i]
        if sr and sr.spellID then staticBySpell[sr.spellID] = sr end
    end

    local live = {}
    for i = 1, num do
        local recipeName, skillType = GetTradeSkillInfo(i)
        if skillType ~= "header" then
            local recipeLink = GetTradeSkillRecipeLink and GetTradeSkillRecipeLink(i) or nil
            local spellID = spellIDFromLink(recipeLink)
            if spellID then
                local outputLink = GetTradeSkillItemLink and GetTradeSkillItemLink(i) or nil
                local itemID = itemIDFromLink(outputLink)
                local fallback = staticBySpell[spellID]
                if not itemID and fallback then itemID = fallback.itemID end

                local reagents = {}
                local reagentCount = GetTradeSkillNumReagents and (GetTradeSkillNumReagents(i) or 0) or 0
                local r
                for r = 1, reagentCount do
                    local reagentName, texture, needed, have = GetTradeSkillReagentInfo(i, r)
                    local reagentLink = GetTradeSkillReagentItemLink and GetTradeSkillReagentItemLink(i, r) or nil
                    local reagentID = itemIDFromLink(reagentLink) or resolveItemID(reagentName)
                    table.insert(reagents, {
                        id = reagentID,
                        name = reagentName or (reagentID and getItemName(reagentID)) or ("재료 " .. tostring(r)),
                        texture = texture or (reagentID and getItemTexture(reagentID)),
                        needed = tonumber(needed) or 1,
                        have = tonumber(have),
                        link = reagentLink,
                    })
                end

                table.insert(live, {
                    itemID = itemID,
                    spellID = spellID,
                    required = (fallback and fallback.required) or (CraftData.GetSpellReq and CraftData:GetSpellReq(spellID)) or 0,
                    recipeName = recipeName or GetSpellInfo(spellID) or ("Spell " .. tostring(spellID)),
                    reagents = reagents,
                    live = true,
                })
            end
        end
    end

    if table.getn(live) <= 0 then return false end

    sortRecipeList(live)

    local keepSpell = selectedRecipe and selectedRecipe.spellID or nil
    local keepItem = selectedRecipe and selectedRecipe.itemID or nil
    rec.recipes = live
    rec.liveLoaded = true
    UI._loadingLive = nil
    UI._liveCaptureScheduled = nil
    restoreTradeSkillFrame()

    if selectedProfession == rec then
        allRecipes = rec.recipes
        applySearch()
        updateProfessionButtons()
        if keepSpell or keepItem then
            local j
            for j=1,table.getn(rec.recipes) do
                local rr=rec.recipes[j]
                if (keepSpell and rr.spellID==keepSpell) or (keepItem and rr.itemID==keepItem) then
                    selectRecipe(rr)
                    break
                end
            end
        end
    end
    return true
end

-- Live trade-link opening intentionally removed. Embedded DB/spell-tooltip data only.

updateProfessionButtons = function()
    local i
    for i = 1, table.getn(UI.professionButtons) do
        local b = UI.professionButtons[i]
        local rec = professionRecords[i]
        if b and rec then
            b.record = rec
            b:SetText(rec.name .. "  |cff6fcfe8" .. tostring(table.getn(rec.recipes)) .. "|r")
            if rec == selectedProfession then
                b:SetBackdropColor(0.07, 0.11, 0.16, 0.98)
                b:SetBackdropBorderColor(0.95, 0.58, 0.10, 1)
                local pc = PROFESSION_COLORS[rec.spellID] or {1,0.82,0.18}
                b.label:SetTextColor(pc[1],pc[2],pc[3])
            else
                b:SetBackdropColor(0.025, 0.040, 0.055, 0.96)
                b:SetBackdropBorderColor(0.40, 0.38, 0.30, 1)
                local pc = PROFESSION_COLORS[rec.spellID] or {0.90,0.92,0.94}
                b.label:SetTextColor(pc[1],pc[2],pc[3])
            end
            b:Show()
        elseif b then
            b.record = nil
            b:Hide()
        end
    end
end

local function selectProfession(rec)
    if not rec then return end
    selectedProfession = rec
    InvenCraftInfoCharDB = InvenCraftInfoCharDB or {}
    InvenCraftInfoCharDB.openSkill = rec.name
    InvenCraftInfoCharDB.isMySkill = nil
    if InvenCraftInfoDB then InvenCraftInfoDB.selecter = rec.name end
    allRecipes = rec.recipes or {}
    searchBox:SetText("")
    filteredRecipes = {}
    local i
    for i = 1, table.getn(allRecipes) do filteredRecipes[i] = allRecipes[i] end
    sortRecipeList(filteredRecipes)
    page = 1
    clearDetail()
    updateProfessionButtons()
    refreshRows()
    -- Do not open trade links here. Opening them can invoke a standalone/original
    -- InvenCraftInfo SetItemRef hook and flash its legacy window. Reagent data is
    -- resolved from the embedded database/spell tooltip instead.
end

for i = 1, table.getn(PROFESSION_IDS) do
    local b = makeButton(professionPanel, 150, 34, "", "LEFT")
    b:SetPoint("TOPLEFT", 9, -35 - (i - 1) * 39)
    b:SetScript("OnClick", function(self)
        if self.record then selectProfession(self.record) end
    end)
    b:SetScript("OnEnter", function(self)
        if self.record ~= selectedProfession then self:SetBackdropColor(0.055, 0.12, 0.15, 0.96) end
        if self.record then
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText(self.record.name, 1, 0.82, 0.18)
            GameTooltip:AddLine("제작 항목 " .. tostring(table.getn(self.record.recipes)) .. "개", 1, 1, 1)
            GameTooltip:Show()
        end
    end)
    b:SetScript("OnLeave", function(self)
        if self.record == selectedProfession then
            self:SetBackdropColor(0.07, 0.11, 0.16, 0.98)
        else
            self:SetBackdropColor(0.025, 0.040, 0.055, 0.96)
        end
        GameTooltip:Hide()
    end)
    UI.professionButtons[i] = b
end

for i = 1, table.getn(recipeRows) do
    recipeRows[i]:SetScript("OnClick", function(self)
        if self.recipe then selectRecipe(self.recipe) end
    end)
end

outputButton:SetScript("OnEnter", function(self)
    if not self.itemID then return end
    self:SetBackdropColor(0.055, 0.12, 0.15, 0.96)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    local link = getItemLink(self.itemID)
    if link then GameTooltip:SetHyperlink(link) end
    GameTooltip:AddLine(" ")
    GameTooltip:AddLine("좌클릭: 수량 입력 후 현재 GM 캐릭터 가방에 추가", 0.55, 0.95, 0.75, true)
    GameTooltip:Show()
end)
outputButton:SetScript("OnLeave", function(self)
    self:SetBackdropColor(0.020, 0.035, 0.045, 0.90)
    GameTooltip:Hide()
end)
outputButton:SetScript("OnClick", function(self, button)
    if not self.itemID then return end
    local link = getItemLink(self.itemID)
    if link and HandleModifiedItemClick and HandleModifiedItemClick(link) then return end
    if button == "RightButton" and addon.ShowSearchContextMenu then
        addon:ShowSearchContextMenu("item", { self.itemID, getItemName(self.itemID) })
    elseif addon.ShowItemQuantityPopup then
        addon:ShowItemQuantityPopup(self.itemID, getItemName(self.itemID), 1)
    end
end)

for i = 1, table.getn(UI.reagentButtons) do
    local b = UI.reagentButtons[i]
    b:SetScript("OnEnter", function(self)
        self:SetBackdropColor(0.055, 0.12, 0.15, 0.96)
        local r = self.reagent
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        if r and r.id then
            local link = r.link or getItemLink(r.id)
            if link then GameTooltip:SetHyperlink(link) end
            GameTooltip:AddLine(" ")
            GameTooltip:AddLine("필요 수량: " .. tostring(r.needed or 1), 0.85, 0.85, 0.85)
            GameTooltip:AddLine("좌클릭: 수량 입력 후 가방에 추가", 0.55, 0.95, 0.75, true)
        else
            GameTooltip:SetText((r and r.name) or "미확인 재료", 1, 0.82, 0.18)
            GameTooltip:AddLine("Item ID를 확인하지 못해 가방 추가를 사용할 수 없습니다.", 1, 0.45, 0.35, true)
        end
        GameTooltip:Show()
    end)
    b:SetScript("OnLeave", function(self)
        self:SetBackdropColor(0.020, 0.035, 0.045, 0.84)
        GameTooltip:Hide()
    end)
    b:SetScript("OnClick", function(self, button)
        local r = self.reagent
        if not r or not r.id then
            addon:Print("재료 Item ID를 확인하지 못했습니다: " .. tostring(r and r.name or "미확인"), true)
            return
        end
        local link = r.link or getItemLink(r.id)
        if link and HandleModifiedItemClick and HandleModifiedItemClick(link) then return end
        if button == "RightButton" and addon.ShowSearchContextMenu then
            addon:ShowSearchContextMenu("item", { r.id, r.name or getItemName(r.id) })
        elseif addon.ShowItemQuantityPopup then
            addon:ShowItemQuantityPopup(r.id, r.name or getItemName(r.id), r.needed or 1)
        end
    end)
end

spellAction:SetScript("OnClick", function(self)
    local rec = self.recipe
    if not rec or not rec.spellID or isKnownSpell(rec.spellID) or UI._pendingLearn[rec.spellID] then return end

    local professionSpell = selectedProfession and tonumber(selectedProfession.spellID) or nil
    local professionRank = selectedProfession and select(1, getProfessionSkillValue(selectedProfession)) or 0

    local function learnRecipe()
        requestPlayerLearn(rec.spellID, false)
        addon:Print("전문기술 도안 습득 요청: Spell " .. tostring(rec.spellID))
    end

    -- A non-zero skill rank already proves that the base profession is present.
    -- Only learn the base spell when the profession really is absent.
    if professionSpell and professionSpell ~= rec.spellID and professionRank <= 0 and not isKnownSpell(professionSpell) then
        requestPlayerLearn(professionSpell, false, function()
            addon:RunAfter(0.25, learnRecipe)
        end)
    else
        learnRecipe()
    end
end)

skillAction:SetScript("OnClick", function(self)
    local rec=self.recipe
    local req=rec and tonumber(rec.required) or 0
    local skillID=selectedProfession and PROFESSION_SKILL_LINES[selectedProfession.spellID]
    if not skillID or req<=0 then return end
    local rank,maxRank=getProfessionSkillValue(selectedProfession)
    if rank>=req then return end
    local newMax=math.max(tonumber(maxRank) or 0, req, 450)
    sendSelfSelectedCommand(".setskill "..tostring(skillID).." "..tostring(req).." "..tostring(newMax))
    addon:RunAfter(0.8,function() if UI:IsShown() then UI:RefreshDetail(); refreshRows() end end)
end)

sortButton:SetScript("OnClick", function()
    if sortMode == "skill" then
        sortMode = "quality"
        sortButton:SetText("희귀↓")
    elseif sortMode == "quality" then
        sortMode = "skillquality"
        sortButton:SetText("숙련+희귀")
    else
        sortMode = "skill"
        sortButton:SetText("숙련↓")
    end
    applySearch()
end)

searchButton:SetScript("OnClick", applySearch)
searchBox:SetScript("OnEnterPressed", function(self) applySearch(); self:ClearFocus() end)
searchBox:SetScript("OnEscapePressed", function(self)
    if self:GetText() ~= "" then
        self:SetText("")
        applySearch()
        self:ClearFocus()
    else
        self:ClearFocus()
    end
end)
prevButton:SetScript("OnClick", function() if page > 1 then page = page - 1; clearDetail(); refreshRows() end end)
nextButton:SetScript("OnClick", function()
    local maxPage = math.max(1, math.ceil(table.getn(filteredRecipes) / PAGE_SIZE))
    if page < maxPage then page = page + 1; clearDetail(); refreshRows() end
end)

function UI:ADDON_LOADED()
    if self.enable then return end
    self.enable = true
    if InvenCraftInfoDB then
        self:SetScale(tonumber(InvenCraftInfoDB.scale) or 1)
        self:SetAlpha(tonumber(InvenCraftInfoDB.alpha) or 1)
        self:SetClampedToScreen(InvenCraftInfoDB.clamp ~= false)
    end
    buildProfessionCache()
    updateProfessionButtons()
    clearDetail()
    if table.getn(professionRecords) > 0 then
        local remembered = InvenCraftInfoCharDB and InvenCraftInfoCharDB.openSkill or nil
        local picked = nil
        local i
        for i = 1, table.getn(professionRecords) do
            if professionRecords[i].name == remembered then picked = professionRecords[i]; break end
        end
        selectProfession(picked or professionRecords[1])
    else
        pageText:SetText("0개")
    end
end

function UI:ResetGMProfessionView()
    searchBox:SetText("")
    page = 1
    clearDetail()
    if not self.enable then self:ADDON_LOADED() end
    if selectedProfession then
        allRecipes = selectedProfession.recipes or {}
        filteredRecipes = {}
        local i
        for i = 1, table.getn(allRecipes) do filteredRecipes[i] = allRecipes[i] end
        sortRecipeList(filteredRecipes)
        refreshRows()
    end
end

function UI:ClearGMTradeSkillDetail()
    clearDetail()
end

function UI:SetSelection()
    self:RefreshDetail()
end

function UI:SetSkillChecked()
    -- Compatibility no-op for the original link hook.
end

function UI:SetTradeSkillLink(skillName)
    if self._requestingTradeLink then return end
    if not self.enable then self:ADDON_LOADED() end
    local i
    for i = 1, table.getn(professionRecords) do
        if professionRecords[i].name == skillName then
            selectProfession(professionRecords[i])
            if not self:IsShown() then
                if addon.OpenManagedFrame then addon:OpenManagedFrame(self) else self:Show() end
            end
            return
        end
    end
end

function UI:RebuildProfessionData()
    local remembered = selectedProfession and selectedProfession.spellID or nil
    buildProfessionCache()
    selectedProfession = nil
    updateProfessionButtons()
    local picked = nil
    local i
    for i = 1, table.getn(professionRecords) do
        if professionRecords[i].spellID == remembered then picked = professionRecords[i]; break end
    end
    selectProfession(picked or professionRecords[1])
end

function UI:ShowRecipeByItemID(itemID)
    itemID = tonumber(itemID)
    if not itemID then return false end
    if not self.enable then self:ADDON_LOADED() end
    local pi, ri
    for pi = 1, table.getn(professionRecords) do
        local recipes = professionRecords[pi].recipes
        for ri = 1, table.getn(recipes) do
            if recipes[ri].itemID == itemID then
                selectProfession(professionRecords[pi])
                local target = recipes[ri]
                filteredRecipes = { target }
                page = 1
                refreshRows()
                selectRecipe(target)
                return true
            end
        end
    end
    return false
end

if not addon.PromptCraftLearn then
    StaticPopupDialogs["AZEROTHADMIN_CRAFT_LEARN"] = {
        text = "|cffffd24a%s|r\n\nSpell ID: |cff66ddff%d|r\n현재 GM 캐릭터에게 바로 습득시킬까요?",
        button1 = "습득",
        button2 = CANCEL,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        preferredIndex = 3,
        OnShow = function(self)
            if addon.RaisePopup then addon:RaisePopup(self) end
            if addon.SuspendManagedEscapeForPopup then addon:SuspendManagedEscapeForPopup(self) end
        end,
        OnHide = function(self)
            if addon.ResumeManagedEscapeForPopup then addon:ResumeManagedEscapeForPopup(self) end
        end,
        OnAccept = function(self, data)
            data = data or self.data
            if not data or not data.spellID then return end
            requestPlayerLearn(data.spellID, data.allRanks and true or false)
        end,
    }

    function addon:PromptCraftLearn(spellID, spellName, allRanks)
        spellID = tonumber(spellID)
        if not spellID then return end
        self:HideAddonPopups("AZEROTHADMIN_CRAFT_LEARN")
        StaticPopup_Show("AZEROTHADMIN_CRAFT_LEARN", spellName or (GetSpellInfo(spellID) or "도안/기술"), spellID, {
            spellID = spellID,
            allRanks = allRanks and true or false,
        })
    end
end

function CraftData:OnClick(button)
    -- Embedded data provider only. Never open the legacy InvenCraftInfo window.
    if addon and addon.ToggleCraftInfo then addon:ToggleCraftInfo() end
end

-- Re-fetch icons/reagent counts a few times after the client item cache warms.
UI._refreshElapsed = 0
UI._refreshCount = 0
UI:SetScript("OnShow", function(self)
    self._refreshElapsed = 0
    self._refreshCount = 5
    updateProfessionButtons()
    refreshRows()
    self:RefreshDetail()
    -- Legacy trade-link loading intentionally disabled: this window must never
    -- expose the original InvenCraftInfo UI.
end)
UI:RegisterEvent("SPELLS_CHANGED")
UI:SetScript("OnEvent", function(self, event)
    if event == "SPELLS_CHANGED" then
        if self:IsShown() then
            addon:RunAfter(0.05, function()
                if UI:IsShown() then UI:RefreshDetail(); refreshRows() end
            end)
        end
        return
    end
    return
end)

UI:SetScript("OnUpdate", function(self, elapsed)
    if not self:IsShown() or (self._refreshCount or 0) <= 0 then return end
    self._refreshElapsed = (self._refreshElapsed or 0) + (elapsed or 0)
    if self._refreshElapsed >= 0.65 then
        self._refreshElapsed = 0
        self._refreshCount = self._refreshCount - 1
        refreshRows()
        self:RefreshDetail()
    end
end)

-- Initialization is deferred until InvenCraftInfo's ADDON_LOADED handler has
-- created its tooltip/database state. AzerothAdmin:ToggleCraftInfo also calls
-- ADDON_LOADED defensively if the frame has not initialized yet.
