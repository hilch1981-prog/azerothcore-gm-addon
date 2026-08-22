-- Embedded Blue Item Info 3 browser for AzerothAdmin / WoW 3.3.5a.
local D = BlueItemInfo3EmbeddedData or { category = {}, itemName = {}, info = {} }
local addon = AzerothAdminEasy

local BII3 = CreateFrame("Frame", "BlueItemInfo3", UIParent)
_G.BlueItemInfo3 = BII3
BII3:Hide()
BII3:SetToplevel(true)
BII3.isHorde = UnitFactionGroup("player") == "Horde"

local function split(text, delimiter)
    local out = {}
    text = tostring(text or "")
    delimiter = delimiter or "|"
    local start = 1
    while true do
        local pos = string.find(text, delimiter, start, true)
        if not pos then
            table.insert(out, string.sub(text, start))
            break
        end
        table.insert(out, string.sub(text, start, pos - 1))
        start = pos + string.len(delimiter)
    end
    return out
end

local function cleanColors(text)
    text = tostring(text or "")
    if BII3.ReplaceFactionText then text = BII3:ReplaceFactionText(text) end
    text = string.gsub(text, "|c%x%x%x%x%x%x%x%x", "")
    text = string.gsub(text, "|r", "")
    return text
end

function BII3:GetCategory(code)
    if not code then return nil end
    return D.category[tostring(code)]
end

function BII3:GetCategoryName(code)
    local category = self:GetCategory(code)
    if not category then return nil end
    local parts = split(category, "_")
    if string.find(tostring(code), "0$") then
        return parts[1], parts[2], parts[3]
    end
    local c = tostring(code)
    local parent = string.sub(c, 1, 2) .. "0"
    local p = self:GetCategory(parent)
    if p then
        local pp = split(p, "_")
        return pp[1], pp[2], category
    end
    return category, category, nil
end

function BII3:ReplaceFactionText(text)
    text = tostring(text or "")
    local function pick(hordeText, allianceText)
        return self.isHorde and (hordeText or "") or (allianceText or "")
    end
    -- Original BII3 data contains several historical variants, including a few
    -- malformed bracket pairs.  Resolve all of them instead of leaking "$f".
    text = string.gsub(text, "%$f{([^{}]-)/([^{}]-)}", pick)
    text = string.gsub(text, "%$f%(([^(){}]-)/([^(){}]-)%)", pick)
    text = string.gsub(text, "%$f{([^{}()]-)/([^{}()]-)%)", pick)
    text = string.gsub(text, "%$f%(([^{}()]-)/([^{}()]-)}", pick)
    text = string.gsub(text, "@f{([^{}]-)/([^{}]-)}", pick)
    text = string.gsub(text, "@f%(([^(){}]-)/([^(){}]-)%)", pick)
    -- Never expose an unresolved formatter token to the user.
    text = string.gsub(text, "%$f", "")
    text = string.gsub(text, "@f", "")
    return text
end

function BII3:GetItemName(id)
    id = tonumber(id)
    if not id then return "미확인 아이템" end
    if id < 0 then return GetSpellInfo(-id) or "미확인 주문" end
    local raw = D.itemName[id]
    if raw then
        local _, name = string.match(raw, "^(%d+)|(.+)$")
        return name or raw
    end
    if addon and addon.KoKRSearchData and addon.KoKRSearchData.item then
        local data = addon.KoKRSearchData.item
        local i
        for i = 1, table.getn(data) do
            if data[i][1] == id then return data[i][2] end
        end
    end
    local name = GetItemInfo(id)
    return name or ("아이템 " .. id)
end

function BII3:GetItemLink(id)
    id = tonumber(id)
    if not id then return nil end
    if id < 0 then
        local sid = -id
        local name = GetSpellInfo(sid)
        if not name then return nil end
        return "|cff71d5ff|Hspell:" .. sid .. "|h[" .. name .. "]|h|r"
    end
    local name, link = GetItemInfo(id)
    if link then return link end
    name = self:GetItemName(id)
    return "|cffffffff|Hitem:" .. id .. ":0:0:0:0:0:0:0:0|h[" .. name .. "]|h|r"
end

local function replaceVars(text)
    text = BII3:ReplaceFactionText(text)
    -- Item placeholders.
    local guard = 0
    while string.find(text, "$i%d+") and guard < 12 do
        guard = guard + 1
        local id = string.match(text, "%$i(%d+)")
        if not id then break end
        text = string.gsub(text, "%$i" .. id, "[" .. id .. "] " .. BII3:GetItemName(tonumber(id)), 1)
    end
    -- Secondary category placeholders.
    guard = 0
    while string.find(text, "$C") and guard < 12 do
        guard = guard + 1
        local code = string.match(text, "%$C([A-Z0-9a-z][0-9a-z][0-9a-z])")
        if not code then break end
        local name = select(2, BII3:GetCategoryName(code)) or code
        text = string.gsub(text, "%$C" .. code, cleanColors(name), 1)
    end
    guard = 0
    while string.find(text, "$c") and guard < 12 do
        guard = guard + 1
        local code = string.match(text, "%$c([A-Z0-9a-z][0-9a-z][0-9a-z])")
        if not code then break end
        local name = select(3, BII3:GetCategoryName(code)) or code
        text = string.gsub(text, "%$c" .. code, cleanColors(name), 1)
    end
    text = string.gsub(text, "<으로>", "(으)로")
    text = string.gsub(text, "<이가>", "이/가")
    text = string.gsub(text, "<을를>", "을/를")
    return cleanColors(text)
end

local infoCache = {}
local function decodeInfo(id, visiting)
    id = tonumber(id)
    if not id then return nil end
    if infoCache[id] ~= nil then return infoCache[id] or nil end
    visiting = visiting or {}
    if visiting[id] then return nil end
    visiting[id] = true
    local raw = D.info[id]
    if type(raw) == "number" then
        local result = decodeInfo(raw, visiting)
        infoCache[id] = result or false
        visiting[id] = nil
        return result
    end
    if type(raw) ~= "string" or raw == "" then
        infoCache[id] = false
        visiting[id] = nil
        return nil
    end

    if string.sub(raw, 1, 1) == "a" then
        if BII3.isHorde then infoCache[id] = "진영 제한: 얼라이언스"; visiting[id] = nil; return infoCache[id] end
        raw = string.gsub(string.sub(raw, 2), "^|", "")
    elseif string.sub(raw, 1, 1) == "h" then
        if not BII3.isHorde then infoCache[id] = "진영 제한: 호드"; visiting[id] = nil; return infoCache[id] end
        raw = string.gsub(string.sub(raw, 2), "^|", "")
    end

    local output = {}
    local setRef = string.match(raw, "s_(%d+)")
    if setRef then
        local base = decodeInfo(tonumber(setRef), visiting)
        if base and base ~= "" then table.insert(output, base) end
    end
    local tokens = split(raw, "|")
    local i
    for i = 1, table.getn(tokens) do
        local kind, body = string.match(tokens[i], "^([A-Za-z])_(.+)$")
        if kind and body then
            if kind == "X" or kind == "C" or kind == "c" then
                table.insert(output, "▶ " .. replaceVars(body))
            elseif kind == "A" then
                local parts = split(body, "@")
                local c = parts[1] and select(2, BII3:GetCategoryName(parts[1])) or nil
                local desc = parts[2] and replaceVars(parts[2]) or nil
                if c and desc then table.insert(output, "▶ " .. cleanColors(c) .. " " .. desc)
                elseif c then table.insert(output, "▶ " .. cleanColors(c))
                elseif desc then table.insert(output, "▶ " .. desc) end
            elseif kind == "R" or kind == "D" or kind == "r" or kind == "d" then
                local c = select(2, BII3:GetCategoryName(body)) or body
                local suffix = (kind == "r" and " (하드)") or (kind == "d" and " (영웅)") or ""
                table.insert(output, "▶ " .. cleanColors(c) .. suffix)
            elseif kind == "S" then
                local c = select(2, BII3:GetCategoryName(body)) or body
                table.insert(output, "▷ " .. cleanColors(c))
            elseif kind == "s" then
                local parts = split(body, "@")
                local rid = tonumber(parts[1])
                if rid and rid ~= tonumber(setRef) then
                    local ref = decodeInfo(rid, visiting)
                    if ref and ref ~= "" then table.insert(output, ref) end
                end
                if rid then
                    local line = "세트/교환: [" .. rid .. "] " .. BII3:GetItemName(rid)
                    if parts[2] and parts[2] ~= "" then line = line .. " + " .. replaceVars(parts[2]) end
                    table.insert(output, "▷ " .. line)
                end
            elseif kind == "Q" then
                local parts = split(body, "@")
                local code, zone, level, name = parts[1], parts[2], parts[3], parts[4]
                local cat = code and select(3, BII3:GetCategoryName(code)) or nil
                local line = "퀘스트: "
                if cat then line = line .. cleanColors(cat) .. " / " end
                if zone then line = line .. replaceVars(zone) .. " / " end
                if level then line = line .. "[" .. replaceVars(level) .. "] " end
                if name then line = line .. replaceVars(name) end
                table.insert(output, "▶ " .. line)
            end
        end
    end
    visiting[id] = nil
    if table.getn(output) == 0 then
        infoCache[id] = false
        return nil
    end
    local result = table.concat(output, "\n")
    infoCache[id] = result
    return result
end

function BII3:GetAcquisitionText(id)
    return decodeInfo(id, {})
end

local function sortedKeys(tbl)
    local t = {}
    for k in pairs(tbl or {}) do table.insert(t, k) end
    table.sort(t, function(a, b) return tostring(a) < tostring(b) end)
    return t
end

local IDX = BlueItemInfo3CategoryIndex or { roots = {}, seconds = {}, thirds = {}, items = {} }
local QUEST_REWARDS_335 = BlueItemInfo3QuestRewards335 or {}
local ROWS_PER_PAGE = 14
local results, page, maxPage = {}, 1, 1
local selectedCategory = nil
local searchMode = false

-- 3.3.5a only: later-expansion branches are
-- intentionally hidden.  Current WOW32 koKR item IDs are also used as a
-- whitelist so entries not present in the 3.3.5a server DB do not appear.
local BLOCKED_ROOT = { ["5"] = true, ["6"] = true, ["f"] = true, ["n"] = true }
local BLOCKED_SECOND = {
    ["k0"] = true, ["ko"] = true, ["kp"] = true, -- Cataclysm PvP season 9
    ["j0"] = true, ["j1"] = true,                 -- Valor / Justice points
    ["r0"] = true,                                  -- 1-85 heirlooms
    ["t8"] = true,                                  -- Archaeology
    ["z0"] = true,                                  -- Maelstrom/Cataclysm quest rewards
}
-- The original data set has no WotLK fishing-book branch.  Add a dedicated
-- 3.3.5a secondary category under Professions and populate it from the local
-- koKR item index below.
IDX.seconds["t"] = IDX.seconds["t"] or {}
-- Restore the original profession branches first.  t7 is Inscription in the
-- embedded database, so fishing must use its own non-colliding key.
IDX.seconds["t"]["t4"] = IDX.seconds["t"]["t4"] or "연금술"
IDX.seconds["t"]["t7"] = IDX.seconds["t"]["t7"] or "주문각인"
IDX.seconds["t"]["t9"] = "요리"
IDX.seconds["t"]["ta"] = "응급치료"
IDX.seconds["t"]["tf"] = "낚시 도안/교본/학습 아이템"

-- WotLK-only aggregate enhancement branches.  These are intentionally separate
-- from the original slot branches so profession-only enhancements never vanish
-- when later-expansion rows are filtered out.
IDX.seconds["v"] = IDX.seconds["v"] or {}
IDX.seconds["v"]["vp"] = "마법부여 전용 강화"
IDX.seconds["v"]["vq"] = "가죽세공 전용 강화"
IDX.seconds["v"]["vr"] = "기계공학 전용 강화"
IDX.seconds["v"]["vs"] = "재봉술 전용 강화"
IDX.seconds["v"]["vt"] = "대장기술 관련 강화"
IDX.seconds["v"]["vu"] = "한손 무기"
-- These WotLK profession-only slot branches exist in the embedded source data,
-- but were missing from the generated category index.
IDX.seconds["v"]["v7"] = "망토(기계공학 전용)"
IDX.seconds["v"]["vb"] = "손목(대장기술 전용)"
IDX.seconds["v"]["vd"] = "장갑(대장기술 전용)"
IDX.seconds["v"]["vl"] = "장화(기계공학 전용)"

local ROOT_LABEL = {
    ["7"] = "공격대 · 리치 왕의 분노",
    ["8"] = "5인 던전 · 리치 왕의 분노",
    ["9"] = "공격대 · 불타는 성전",
    ["a"] = "5인 던전 · 불타는 성전",
    ["b"] = "공격대 · 오리지널",
    ["c"] = "5인 던전 · 오리지널",
    ["g"] = "세트 아이템 · 리치 왕의 분노",
    ["h"] = "세트 아이템 · 불타는 성전",
    ["i"] = "세트 아이템 · 오리지널",
    ["j"] = "화폐 / 교환",
    ["k"] = "PvP 아이템",
    ["o"] = "평판 · 리치 왕의 분노",
    ["p"] = "평판 · 불타는 성전",
    ["q"] = "평판 · 오리지널",
    ["r"] = "계승 아이템",
    ["s"] = "보석",
    ["t"] = "전문기술",
    ["v"] = "아이템 강화",
    ["z"] = "퀘스트 보상",
}

local validItemIDs = {}
local validItemCount = 0
if addon and addon.KoKRSearchData and addon.KoKRSearchData.item then
    local source = addon.KoKRSearchData.item
    local i
    for i = 1, table.getn(source) do
        local id = tonumber(source[i][1])
        if id and id > 0 and not validItemIDs[id] then
            validItemIDs[id] = true
            validItemCount = validItemCount + 1
        end
    end
end

local WOTLK_CATEGORY_MAX_ITEM_ID = 56806
local function isValid335Item(id, root)
    id = tonumber(id)
    if not id or id == 0 then return false end
    if id < 0 then return GetSpellInfo(-id) ~= nil end
    -- Blue Item Info was originally built from a later data set.  Category rows
    -- are therefore additionally capped to the 3.3.5a/WotLK item range.  Direct
    -- koKR/ID search may still expose server-custom items because those are
    -- explicitly present in this repack's locale index.
    if root and id > WOTLK_CATEGORY_MAX_ITEM_ID then return false end
    if validItemCount > 0 then return validItemIDs[id] == true end
    return id <= WOTLK_CATEGORY_MAX_ITEM_ID
end

local function makeText(parent, text, font)
    local fs = parent:CreateFontString(nil, "OVERLAY", font or "GameFontNormal")
    fs:SetText(text or "")
    return fs
end

local function makeButton(parent, w, h, text)
    local b = CreateFrame("Button", nil, parent)
    b:SetWidth(w); b:SetHeight(h)
    b:SetBackdrop({bgFile="Interface\\Tooltips\\UI-Tooltip-Background",edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",tile=true,tileSize=12,edgeSize=8,insets={left=2,right=2,top=2,bottom=2}})
    b:SetBackdropColor(0.025,0.04,0.055,0.96); b:SetBackdropBorderColor(0.48,0.43,0.31,1)
    local fs = makeText(b, text, "GameFontHighlightSmall")
    fs:SetPoint("LEFT",6,0); fs:SetPoint("RIGHT",-6,0); fs:SetJustifyH("CENTER")
    b.label=fs; b.SetText=function(self,v) self.label:SetText(v or "") end
    return b
end

local function makeEdit(parent,w,h)
    local e=CreateFrame("EditBox",nil,parent); e:SetWidth(w); e:SetHeight(h); e:SetAutoFocus(false); e:SetFontObject(ChatFontNormal); e:SetTextInsets(6,6,0,0)
    e:SetBackdrop({bgFile="Interface\\Tooltips\\UI-Tooltip-Background",edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",tile=true,tileSize=12,edgeSize=8,insets={left=2,right=2,top=2,bottom=2}})
    e:SetBackdropColor(0.01,0.02,0.025,1); e:SetBackdropBorderColor(0.48,0.43,0.31,1)
    return e
end

local function stripColor(text)
    return cleanColors(text)
end

local QUALITY_NAMES = {
    [0] = "하급", [1] = "일반", [2] = "고급", [3] = "희귀", [4] = "영웅", [5] = "전설", [6] = "유물", [7] = "계승",
}
local QUALITY_FALLBACK = {
    [0] = {0.62,0.62,0.62,"ff9d9d9d"}, [1] = {1,1,1,"ffffffff"}, [2] = {0.12,1,0,"ff1eff00"},
    [3] = {0,0.44,0.87,"ff0070dd"}, [4] = {0.64,0.21,0.93,"ffa335ee"}, [5] = {1,0.5,0,"ffff8000"},
    [6] = {0.9,0.8,0.5,"ffe6cc80"}, [7] = {0,0.8,1,"ff00ccff"},
}

function BII3:GetEmbeddedQuality(id)
    local raw = D.itemName[tonumber(id)]
    if raw then
        local q = tonumber(string.match(raw, "^(%d+)|"))
        if q then return q end
    end
    return 1
end

function BII3:GetItemDisplayInfo(id)
    id = tonumber(id)
    if id and id < 0 then
        local spellID = -id
        local name = GetSpellInfo(spellID) or ("주문/도안 " .. spellID)
        local texture = (GetSpellTexture and GetSpellTexture(spellID)) or "Interface\\Icons\\INV_Scroll_03"
        local q = 3; local c = QUALITY_FALLBACK[q]
        return name, self:GetItemLink(id), q, 0, 0, texture, c[1],c[2],c[3],c[4], "도안/주문 · Spell ID " .. spellID, true
    end
    local fallbackQ = self:GetEmbeddedQuality(id)
    local name, link, quality, itemLevel, minLevel, itemType, itemSubType, stackCount, equipLoc, texture = GetItemInfo(id)
    quality = quality or fallbackQ or 1
    name = name or self:GetItemName(id)
    texture = texture or GetItemIcon(id) or "Interface\\Icons\\INV_Misc_QuestionMark"
    local r,g,b,hex
    if GetItemQualityColor then r,g,b,hex = GetItemQualityColor(quality) end
    if not r then local c=QUALITY_FALLBACK[quality] or QUALITY_FALLBACK[1]; r,g,b,hex=c[1],c[2],c[3],c[4] end
    local levelText
    if equipLoc == "INVTYPE_BAG" then
        levelText = "가방 1칸=1개 · 아이콘 숫자=iLv." .. tostring(itemLevel or 0)
    else
        levelText = ((minLevel and minLevel > 0) or (itemLevel and itemLevel > 0))
            and ("Lv." .. tostring(minLevel or 0) .. " / iLv." .. tostring(itemLevel or 0)) or "레벨 정보 미로딩"
    end
    return name, link, quality, itemLevel or 0, minLevel or 0, texture, r,g,b,hex, levelText, false, itemType, itemSubType
end

local TYPE_LABELS = {
    recipe = "도안/주문", weapon = "무기", armor = "방어구", material = "재료/보석", consumable = "소비품", other = "기타",
}
local typeFilter = { recipe=true, weapon=true, armor=true, material=true, consumable=true, other=true }
local qualityFilter = { [0]=true,[1]=true,[2]=true,[3]=true,[4]=true,[5]=true,[6]=false,[7]=true }
local typeCache = {}

local CLASS_OPTIONS = {
    { key=nil, ko="전체", en="All" },
    { key="WARRIOR", ko="전사", en="Warrior" },
    { key="PALADIN", ko="성기사", en="Paladin" },
    { key="HUNTER", ko="사냥꾼", en="Hunter" },
    { key="ROGUE", ko="도적", en="Rogue" },
    { key="PRIEST", ko="사제", en="Priest" },
    { key="DEATHKNIGHT", ko="죽음의 기사", en="Death Knight" },
    { key="SHAMAN", ko="주술사", en="Shaman" },
    { key="MAGE", ko="마법사", en="Mage" },
    { key="WARLOCK", ko="흑마법사", en="Warlock" },
    { key="DRUID", ko="드루이드", en="Druid" },
}
local selectedClass = nil
local classTooltip = CreateFrame("GameTooltip", "AzerothAdminItemClassFilterTooltip", UIParent, "GameTooltipTemplate")
local classRestrictionCache = {}

local function selectedClassInfo()
    local i
    for i=1,table.getn(CLASS_OPTIONS) do
        if CLASS_OPTIONS[i].key == selectedClass then return CLASS_OPTIONS[i] end
    end
    return CLASS_OPTIONS[1]
end

local function itemAllowsSelectedClass(id)
    if not selectedClass or not id or id < 0 then return true end
    classRestrictionCache[id] = classRestrictionCache[id] or {}
    if classRestrictionCache[id][selectedClass] ~= nil then return classRestrictionCache[id][selectedClass] end
    local info = selectedClassInfo()
    classTooltip:SetOwner(UIParent, "ANCHOR_NONE")
    classTooltip:ClearLines()
    pcall(classTooltip.SetHyperlink, classTooltip, "item:" .. tostring(id))
    local restricted, allowed = false, false
    local i
    for i=1,(classTooltip:NumLines() or 0) do
        local line = _G["AzerothAdminItemClassFilterTooltipTextLeft" .. i]
        local text = line and line:GetText() or ""
        if string.find(text, "직업:", 1, true) or string.find(text, "Classes:", 1, true) then
            restricted = true
            if string.find(text, info.ko, 1, true) or string.find(string.lower(text), string.lower(info.en), 1, true) then allowed = true end
            break
        end
    end
    classTooltip:Hide()
    -- If the item cache has not supplied restriction text yet, do not hide it.
    local result = (not restricted) or allowed
    classRestrictionCache[id][selectedClass] = result
    return result
end

local function looksLikeRecipe(name)
    name = tostring(name or "")
    local pats = {"도안","디자인","설계도","조제법","제조법","기법","문양","주문식","조리법","처방전","도면","책:"}
    local i
    for i=1,table.getn(pats) do if string.find(name,pats[i],1,true) then return true end end
    return false
end

local function classifyItem(id, name, root)
    id = tonumber(id)
    if not id then return "other" end
    if id < 0 then return "recipe" end
    if typeCache[id] then return typeCache[id] end
    local _,_,_,_,_,itemType,itemSubType = GetItemInfo(id)
    local t = nil
    local blob = tostring(itemType or "") .. " " .. tostring(itemSubType or "")
    if looksLikeRecipe(name) or string.find(blob,"제조법",1,true) or string.find(blob,"Recipe",1,true) then t="recipe"
    elseif string.find(blob,"무기",1,true) or string.find(blob,"Weapon",1,true) then t="weapon"
    elseif string.find(blob,"방어구",1,true) or string.find(blob,"Armor",1,true) then t="armor"
    elseif string.find(blob,"소비",1,true) or string.find(blob,"Consumable",1,true) then t="consumable"
    elseif string.find(blob,"재료",1,true) or string.find(blob,"거래",1,true) or string.find(blob,"직업용품",1,true) or string.find(blob,"보석",1,true) or string.find(blob,"Trade Goods",1,true) or root=="s" then t="material"
    elseif root=="t" and looksLikeRecipe(name) then t="recipe"
    else t="other" end
    if itemType then typeCache[id]=t end
    return t
end

local function allTypesEnabled()
    for k in pairs(TYPE_LABELS) do if not typeFilter[k] then return false end end
    return true
end

local function passesFilters(rec)
    local id = tonumber(rec[1])
    if not isValid335Item(id, rec.root) then return false end
    local q = id < 0 and 3 or BII3:GetEmbeddedQuality(id)
    if qualityFilter[q] == false then return false end
    if not itemAllowsSelectedClass(id) then return false end
    if not allTypesEnabled() then
        local t = classifyItem(id, rec[2], rec.root)
        if not typeFilter[t] then return false end
    end
    return true
end

local function addUniqueResult(out, seen, id, root)
    id = tonumber(id)
    if not id or seen[id] or not isValid335Item(id, root) then return end
    seen[id] = true
    local rec = {id, BII3:GetItemName(id)}
    rec.root = root
    if passesFilters(rec) then table.insert(out, rec) end
end

local special335Items = nil
local function specialAdd(bucket, key, id)
    bucket[key] = bucket[key] or {}
    local i
    for i=1,table.getn(bucket[key]) do
        if bucket[key][i] == id then return end
    end
    table.insert(bucket[key], id)
end

local function is335GemItem(id, name)
    name = tostring(name or "")
    if not id or id < 23094 or id > WOTLK_CATEGORY_MAX_ITEM_ID or looksLikeRecipe(name) then return false end
    local excludes = {"마법봉","목걸이","펜던트","왕관","티아라","반지","고리","장신구","조각","가루","렌즈","수정구","아뮬렛","옥수수","NPC 장비","[시험용]"}
    local ei
    for ei=1,table.getn(excludes) do if string.find(name,excludes[ei],1,true) then return false end end
    local gems = {
        "혈석","태양 수정","옥수","암흑 수정","거대 황수정","단홍빛 루비","단풍석","하늘 사파이어","황혼 오팔","암색 비취",
        "숲 에메랄드","선홍빛 루비","왕의 호박석","귀족 지르콘","공포석","자황수정","줄의 눈","혈류석","불꽃석류석",
        "황금 드레나이트","하늘월장석","암흑 드레나이트","여명석","생명의 루비","귀황옥","탈라사이트","엘룬의 별","야안석",
        "용의 눈","악몽의 눈물","하늘섬광 다이아몬드","대지울림 다이아몬드","하늘불꽃 다이아몬드","대지폭풍 다이아몬드"
    }
    local gi
    for gi=1,table.getn(gems) do if string.find(name,gems[gi],1,true) then return true end end
    return false
end

local function gemSecondKey(id, name)
    name = tostring(name or "")
    if string.find(name,"다이아몬드",1,true) then return "s1" end
    if string.find(name,"혈석",1,true) or string.find(name,"루비",1,true) or string.find(name,"혈류석",1,true) then return "s2" end
    if string.find(name,"호박석",1,true) or string.find(name,"태양 수정",1,true) or string.find(name,"여명석",1,true) or string.find(name,"황금 드레나이트",1,true) then return "s3" end
    if string.find(name,"사파이어",1,true) or string.find(name,"옥수",1,true) or string.find(name,"엘룬의 별",1,true) or string.find(name,"월장석",1,true) then return "s4" end
    if string.find(name,"토파즈",1,true) or string.find(name,"황수정",1,true) or string.find(name,"불꽃석류석",1,true) or string.find(name,"귀황옥",1,true) then return "s5" end
    if string.find(name,"오팔",1,true) or string.find(name,"공포석",1,true) or string.find(name,"야안석",1,true) or string.find(name,"암흑 수정",1,true) or string.find(name,"암흑 드레나이트",1,true) then return "s6" end
    if string.find(name,"에메랄드",1,true) or string.find(name,"줄의 눈",1,true) or string.find(name,"암색 비취",1,true) or string.find(name,"탈라사이트",1,true) then return "s7" end
    return nil
end

local FISHING_GUIDE_IDS = {
    [11152]=true, [16082]=true, [16083]=true, [18229]=true, [27532]=true,
    [46054]=true, [46055]=true, [50406]=true,
}

local function is335FishingGuide(id, name)
    id = tonumber(id)
    name = tostring(name or "")
    if not id or id <= 0 then return false end
    if FISHING_GUIDE_IDS[id] then return true end
    if not string.find(name, "낚시", 1, true) then return false end
    if string.find(name, "사본입니다", 1, true) then return false end
    if looksLikeRecipe(name) then return true end
    local terms = { "낚시정보", "낚시법", "낚시 완전정복", "낚시의 거장" }
    local i
    for i=1,table.getn(terms) do
        if string.find(name, terms[i], 1, true) then return true end
    end
    return false
end

local function buildSpecial335Items()
    if special335Items then return special335Items end
    special335Items = { s={}, v={}, t={} }
    local source=(addon and addon.KoKRSearchData and addon.KoKRSearchData.item) or {}
    local i
    for i=1,table.getn(source) do
        local id,name=tonumber(source[i][1]),tostring(source[i][2] or "")
        if id and id > 0 and id <= WOTLK_CATEGORY_MAX_ITEM_ID then
            if is335GemItem(id,name) then
                specialAdd(special335Items.s,"s0",id)
                local colorKey=gemSecondKey(id,name)
                if colorKey then specialAdd(special335Items.s,colorKey,id) end
            end

            if is335FishingGuide(id, name) then
                specialAdd(special335Items.t, "tf", id)
            end

            -- Enhancement consumables/scrolls that physically exist in 3.3.5a.
            -- Recipes/formulas are excluded; this list is grouped by the equipment
            -- slot named in the localized item itself.
            if not looksLikeRecipe(name) and not string.find(name,"QA ",1,true) and not string.find(name,"[시험용]",1,true) then
                local keys={}
                if string.find(name,"양손 무기 마법부여 -",1,true) then table.insert(keys,"v0")
                elseif string.find(name,"무기 마법부여 -",1,true) then table.insert(keys,"v1") end
                if string.find(name,"의 영석",1,true) then table.insert(keys,"v2") end
                if string.match(name,"새김무늬$") then table.insert(keys,"v3") end
                if string.find(name,"망토 마법부여 -",1,true) then table.insert(keys,"v5") end
                if string.find(name,"가슴보호구 마법부여 -",1,true) or string.find(name,"가슴 마법부여 -",1,true) then table.insert(keys,"v8") end
                if string.find(name,"손목보호구 마법부여 -",1,true) then table.insert(keys,"v9") end
                if string.find(name,"장갑 마법부여 -",1,true) then table.insert(keys,"vc") end
                if string.find(name,"영원의 허리 죔쇠",1,true) then table.insert(keys,"vf") end
                if string.find(name,"마법실타래",1,true) then table.insert(keys,"vh") end
                if string.find(name,"다리 방어구 강화",1,true) then table.insert(keys,"vh"); table.insert(keys,"vi") end
                if string.find(name,"장화 마법부여 -",1,true) then table.insert(keys,"vk") end
                if string.find(name,"방패 마법부여 -",1,true) then table.insert(keys,"vm") end
                if string.find(name,"반지 마법부여 -",1,true) then table.insert(keys,"vo") end
                if string.find(name,"조준경",1,true) and not looksLikeRecipe(name) and not string.find(name,"소총",1,true) then table.insert(keys,"v1") end
                local k
                for k=1,table.getn(keys) do specialAdd(special335Items.v,keys[k],id) end

                -- Profession aggregate views.  The localized item index contains
                -- the actual 3.3.5 enchant scrolls and profession-made upgrades.
                if string.find(name,"마법부여 -",1,true) then
                    specialAdd(special335Items.v,"vp",id)
                    if string.find(name,"양손 무기 마법부여 -",1,true) then
                        -- dedicated two-hand branch already handled above
                    elseif string.find(name,"무기 마법부여 -",1,true) then
                        specialAdd(special335Items.v,"vu",id)
                    end
                end
                if string.find(name,"다리 방어구 강화가죽",1,true) then specialAdd(special335Items.v,"vq",id) end
                if string.find(name,"마법실타래",1,true) then specialAdd(special335Items.v,"vs",id) end
                if string.find(name,"조준경",1,true) and not string.find(name,"소총",1,true) then specialAdd(special335Items.v,"vr",id) end
                if string.find(name,"니트로 추진기",1,true) then specialAdd(special335Items.v,"vr",id) end
                if string.find(name,"영원의 허리 죔쇠",1,true) then specialAdd(special335Items.v,"vt",id) end
            end
        end
    end

    -- Rebuild profession recipe categories from the embedded WotLK
    -- InvenCraftInfo database.  RecipeDB gives recipe item -> spell and SpellDB
    -- tells which profession owns that spell, avoiding the leather/tailoring
    -- ambiguity of the shared Korean "도안:" prefix.
    local recipeSpellToProfession = {}
    local craftData = AzerothAdminCraftData or InvenCraftInfo
    if craftData and craftData.GetSkillTable and craftData.GetRecipeID2SpellID then
        local professionDefs = {
            {"t0",7411}, {"t1",2018}, {"t2",2108}, {"t3",3908},
            {"t4",2259}, {"t5",4036}, {"t6",25229}, {"t7",45363},
            {"t9",2550}, {"ta",3273},
        }
        local pi
        for pi=1,table.getn(professionDefs) do
            local key, spell = professionDefs[pi][1], professionDefs[pi][2]
            local skillName = GetSpellInfo(spell)
            local skillTable = skillName and craftData:GetSkillTable(skillName) or nil
            if skillTable then
                local outputID, craftSpellID
                for outputID, craftSpellID in pairs(skillTable) do
                    if tonumber(craftSpellID) then recipeSpellToProfession[tonumber(craftSpellID)] = key end
                end
            end
        end
        local src=(addon and addon.KoKRSearchData and addon.KoKRSearchData.item) or {}
        local ri
        for ri=1,table.getn(src) do
            local rid,rname=tonumber(src[ri][1]),tostring(src[ri][2] or "")
            if rid and rid > 0 and rid <= WOTLK_CATEGORY_MAX_ITEM_ID and looksLikeRecipe(rname) then
                local recipeSpell = craftData:GetRecipeID2SpellID(rid)
                local pkey = recipeSpell and recipeSpellToProfession[tonumber(recipeSpell)] or nil
                if not pkey then
                    if string.find(rname,"주문식:",1,true) then pkey="t0"
                    elseif string.find(rname,"도면:",1,true) then pkey="t1"
                    elseif string.find(rname,"조제법:",1,true) then pkey="t4"
                    elseif string.find(rname,"설계도:",1,true) then pkey="t5"
                    elseif string.find(rname,"디자인:",1,true) then pkey="t6"
                    elseif string.find(rname,"기법:",1,true) then pkey="t7"
                    elseif string.find(rname,"조리법:",1,true) then pkey="t9" end
                end
                if pkey then specialAdd(special335Items.t,pkey,rid) end
            end
        end
    end

    -- WotLK profession-only / profession-made enhancements.  The source index was
    -- generated from a later expansion, so these 3.3.5a entries must be restored
    -- explicitly.  Spell rows are added only when the 3.3.5 client knows the spell.
    local function addSpell(key, spellID)
        if GetSpellInfo and GetSpellInfo(spellID) then
            specialAdd(special335Items.v, key, -spellID)
        end
    end
    local function addItem(key, itemID)
        if isValid335Item(itemID, "v") then specialAdd(special335Items.v, key, itemID) end
    end

    -- Inscription: Master's shoulder inscriptions.
    addSpell("v4", 61117); addSpell("v4", 61118); addSpell("v4", 61119); addSpell("v4", 61120)
    -- Tailoring cloak embroideries.
    addSpell("v6", 55642); addSpell("v6", 55769); addSpell("v6", 55777)
    -- Leatherworking self-only Fur Linings for bracers.
    local furLining = {57683,57690,57691,57692,57694,57696,57699,57701}
    for i=1,table.getn(furLining) do addSpell("va", furLining[i]) end
    -- Engineering glove tinkers (physical items plus the armor-webbing spell).
    addItem("ve", 41091); addItem("ve", 41093); addSpell("ve", 54998); addSpell("ve", 54999); addSpell("ve", 63770)
    -- Engineering belt tinker.
    addSpell("vg", 54793)
    -- Engineering cloak / boot modifications belong in both the normal slot
    -- lists and their profession-only branches.
    addItem("v5", 41111); addSpell("v5", 55002)
    addItem("v7", 41111); addSpell("v7", 55002)
    addItem("vk", 41118); addSpell("vk", 55016)
    addItem("vl", 41118); addSpell("vl", 55016)
    -- Blacksmith-only extra sockets.
    addSpell("vb", 55628); addSpell("vd", 55641)
    -- Leatherworking leg armor kits (profession-made WotLK enhancements).
    local legKits = {38371,38372,38373,38374,38375,38376,38377,38378}
    for i=1,table.getn(legKits) do addItem("vi", legKits[i]) end
    addSpell("vi", 60581); addSpell("vi", 60582)
    -- Enchanter-only ring enchants.  Physical scroll entries, when present, remain too.
    addSpell("vo", 44636); addSpell("vo", 44645); addSpell("vo", 59636)

    -- Also expose profession-only spell enhancements through the aggregate tabs.
    local function copyBucket(fromKey, toKey)
        local src = special335Items.v[fromKey] or {}
        local ci
        for ci=1,table.getn(src) do specialAdd(special335Items.v, toKey, src[ci]) end
    end
    copyBucket("v4", "vp")
    copyBucket("vo", "vp")
    copyBucket("va", "vq"); copyBucket("vi", "vq")
    copyBucket("v7", "vr"); copyBucket("ve", "vr"); copyBucket("vg", "vr"); copyBucket("vl", "vr")
    copyBucket("v6", "vs")
    copyBucket("vb", "vt"); copyBucket("vd", "vt")

    -- WotLK has very few off-hand-only enchants; expose the shield/off-hand set in
    -- the 보조장비 branch instead of leaving the branch empty.
    if special335Items.v.vm then
        for i=1,table.getn(special335Items.v.vm) do specialAdd(special335Items.v, "vn", special335Items.v.vm[i]) end
    end

    return special335Items
end

-- The original embedded quest-reward index was produced after the Cataclysm
-- old-world revamp.  Its z3/z4 rows therefore mostly point at item IDs that do not
-- exist in 3.3.5a.  Rebuild a useful 3.3.5a baseline from the classic dungeon
-- quest-reward groups that are already present in the same database.
local LEGACY_REGION_QUEST_KEYS = {
    z3 = { "c02", "c1b", "c47", "c67", "c98", "cb9", "cc9", "cf8", "cg8", "ch9", "z35" },
    z4 = { "c27", "c39", "c51", "c77", "c8c", "cab", "cd9", "cev", "cii", "cjc", "cki", "cla" },
}

local function addLegacyRegionQuestRewards(out, seen, secondKey)
    local keys = LEGACY_REGION_QUEST_KEYS[secondKey]
    if not keys then return false end
    local before = table.getn(out)
    local i,j
    for i=1,table.getn(keys) do
        local list = IDX.items[keys[i]] or {}
        for j=1,table.getn(list) do addUniqueResult(out, seen, list[j], "z") end
    end
    return table.getn(out) > before
end

local function addOfficialQuestRewards(out, seen, secondKey)
    local bucket = QUEST_REWARDS_335[secondKey]
    if not bucket then return false end
    local before = table.getn(out)
    local kinds = { "fixed", "choice" }
    local ki,ii
    for ki=1,table.getn(kinds) do
        local list = bucket[kinds[ki]] or {}
        for ii=1,table.getn(list) do addUniqueResult(out, seen, list[ii], "z") end
    end
    return table.getn(out) > before
end

local function collectSecond(out, seen, secondKey, root)
    if BLOCKED_SECOND[secondKey] then return end
    if root == "z" then addOfficialQuestRewards(out, seen, secondKey) end
    if root == "z" and (secondKey == "z3" or secondKey == "z4") then
        addLegacyRegionQuestRewards(out, seen, secondKey)
        -- Also merge any surviving direct 3.3.5a entries from the original branch.
        local directLegacy = IDX.items[secondKey] or {}
        local li
        for li=1,table.getn(directLegacy) do addUniqueResult(out, seen, directLegacy[li], root) end
        local legacyThirds = IDX.thirds[secondKey] or {}
        local legacyCodes = sortedKeys(legacyThirds)
        local ci,cj
        for ci=1,table.getn(legacyCodes) do
            local legacyList = IDX.items[legacyCodes[ci]] or {}
            for cj=1,table.getn(legacyList) do addUniqueResult(out, seen, legacyList[cj], root) end
        end
        return
    end
    if root == "s" or root == "v" or root == "t" then
        local special = buildSpecial335Items()
        local list = special[root] and special[root][secondKey] or nil
        if list then
            local si
            for si=1,table.getn(list) do addUniqueResult(out,seen,list[si],root) end
        end
        return
    end
    local direct = IDX.items[secondKey]
    if direct then
        local i; for i=1,table.getn(direct) do addUniqueResult(out,seen,direct[i],root) end
    end
    local thirds = IDX.thirds[secondKey] or {}
    local codes = sortedKeys(thirds)
    local i,j
    for i=1,table.getn(codes) do
        local list = IDX.items[codes[i]] or {}
        for j=1,table.getn(list) do addUniqueResult(out,seen,list[j],root) end
    end
end

local categoryEntries = {}
local roots = sortedKeys(IDX.roots)
local ri,si
for ri=1,table.getn(roots) do
    local root = roots[ri]
    if not BLOCKED_ROOT[root] then
        table.insert(categoryEntries,{kind="root",key=root,root=root,label=ROOT_LABEL[root] or stripColor(IDX.roots[root] or root)})
        local seconds = IDX.seconds[root] or {}
        local skeys = sortedKeys(seconds)
        for si=1,table.getn(skeys) do
            local sec = skeys[si]
            if not BLOCKED_SECOND[sec] then
                table.insert(categoryEntries,{kind="second",key=sec,root=root,label="   └ " .. stripColor(seconds[sec] or sec)})
            end
        end
    end
end

BII3:SetWidth(900); BII3:SetHeight(610); BII3:SetPoint("CENTER",UIParent,"CENTER",0,0)
BII3:SetFrameStrata("FULLSCREEN_DIALOG"); BII3:SetMovable(true); BII3:EnableMouse(true); BII3:SetClampedToScreen(true); BII3:RegisterForDrag("LeftButton")
BII3:SetBackdrop({bgFile="Interface\\Tooltips\\UI-Tooltip-Background",edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",tile=true,tileSize=16,edgeSize=14,insets={left=4,right=4,top=4,bottom=4}})
BII3:SetBackdropColor(0.018,0.025,0.035,0.985); BII3:SetBackdropBorderColor(0.95,0.58,0.10,1)
BII3:SetScript("OnDragStart",function(self) self:StartMoving() end)
BII3:SetScript("OnDragStop",function(self) self:StopMovingOrSizing() end)
if addon and addon.RegisterEscapeFrame then addon:RegisterEscapeFrame(BII3) end

local icon=BII3:CreateTexture(nil,"ARTWORK"); icon:SetTexture("Interface\\AddOns\\AzerothAdmin\\Embedded\\BlueItemInfo3\\Icon"); icon:SetWidth(32); icon:SetHeight(32); icon:SetPoint("TOPLEFT",14,-10)
local title=makeText(BII3,"아이템 정보 · WotLK 3.3.5a","GameFontNormalLarge"); title:SetPoint("TOPLEFT",54,-17); title:SetTextColor(1,0.78,0.25)
local close=CreateFrame("Button",nil,BII3,"UIPanelCloseButton"); close:SetPoint("TOPRIGHT",-5,-5)
local hint=makeText(BII3,"왼쪽 분류 선택 → 상단 종류/등급 필터 → 아이템 클릭 시 수량 입력 후 가방 추가","GameFontHighlightSmall"); hint:SetPoint("TOPLEFT",18,-47); hint:SetTextColor(0.55,0.88,0.92)

-- Left classification list is visible immediately; no Cataclysm roots are built.
local catTitle=makeText(BII3,"분류","GameFontNormal"); catTitle:SetPoint("TOPLEFT",18,-78); catTitle:SetTextColor(1,0.82,0.18)
local catScroll=CreateFrame("ScrollFrame","AzerothAdminBlueInfoCategoryScroll",BII3,"UIPanelScrollFrameTemplate")
catScroll:SetPoint("TOPLEFT",16,-96); catScroll:SetWidth(205); catScroll:SetHeight(460)
local catChild=CreateFrame("Frame",nil,catScroll); catChild:SetWidth(178); catChild:SetHeight(math.max(460,table.getn(categoryEntries)*23+4)); catScroll:SetScrollChild(catChild)
BII3.categoryButtons={}
for ri=1,table.getn(categoryEntries) do
    local entry=categoryEntries[ri]
    local b=makeButton(catChild,174,21,entry.label)
    b:SetPoint("TOPLEFT",2,-(ri-1)*23)
    b.label:SetJustifyH("LEFT")
    if entry.kind=="root" then b.label:SetTextColor(1,0.78,0.22) else b.label:SetTextColor(0.83,0.88,0.92) end
    b.aaeCategory=entry
    BII3.categoryButtons[ri]=b
end

local filterX=245
local typeTitle=makeText(BII3,"종류","GameFontNormal"); typeTitle:SetPoint("TOPLEFT",filterX,-72); typeTitle:SetTextColor(1,0.82,0.18)
local qualityTitle=makeText(BII3,"등급","GameFontNormal"); qualityTitle:SetPoint("TOPLEFT",filterX,-101); qualityTitle:SetTextColor(1,0.82,0.18)
local filterChecks={}
local qualityChecks={}
local function makeCheck(parent,x,y,label,checked,onClick)
    local c=CreateFrame("CheckButton",nil,parent,"UICheckButtonTemplate")
    c:SetWidth(22); c:SetHeight(22); c:SetPoint("TOPLEFT",x,y); c:SetChecked(checked)
    local t=makeText(parent,label,"GameFontHighlightSmall"); t:SetPoint("LEFT",c,"RIGHT",1,0)
    c.aaeLabel=t; c:SetScript("OnClick",onClick)
    return c
end
local types={"recipe","weapon","armor","material","consumable","other"}
for ri=1,table.getn(types) do
    local key=types[ri]
    local x=filterX+48+(ri-1)*96
    filterChecks[key]=makeCheck(BII3,x,-68,TYPE_LABELS[key],true,function(self) typeFilter[key]=self:GetChecked() and true or false; BII3.filterDirty=true end)
end
local qualities={{1,"일반"},{2,"고급"},{3,"희귀"},{4,"영웅"},{5,"전설"},{7,"계승"},{0,"하급"}}
for ri=1,table.getn(qualities) do
    local q,label=qualities[ri][1],qualities[ri][2]
    local x=filterX+48+(ri-1)*78
    qualityChecks[q]=makeCheck(BII3,x,-97,label,true,function(self) qualityFilter[q]=self:GetChecked() and true or false; BII3.filterDirty=true end)
end

local classLabel=makeText(BII3,"클래스","GameFontNormal"); classLabel:SetPoint("TOPLEFT",filterX,-132); classLabel:SetTextColor(1,0.82,0.18)
local classDrop=CreateFrame("Frame","AzerothAdminItemClassDropdown",BII3,"UIDropDownMenuTemplate")
classDrop:SetPoint("TOPLEFT",BII3,"TOPLEFT",filterX+38,-116)
if UIDropDownMenu_SetWidth then UIDropDownMenu_SetWidth(classDrop,150) end
if UIDropDownMenu_SetText then UIDropDownMenu_SetText(classDrop,"전체") end
if UIDropDownMenu_Initialize then
    UIDropDownMenu_Initialize(classDrop,function(self,level)
        local i
        for i=1,table.getn(CLASS_OPTIONS) do
            local opt=CLASS_OPTIONS[i]
            local info=UIDropDownMenu_CreateInfo()
            info.text=opt.ko
            info.value=opt.key or "ALL"
            info.checked=(selectedClass==opt.key)
            info.func=function()
                selectedClass=opt.key
                if UIDropDownMenu_SetSelectedValue then UIDropDownMenu_SetSelectedValue(classDrop,opt.key or "ALL") end
                if UIDropDownMenu_SetText then UIDropDownMenu_SetText(classDrop,opt.ko) end
                BII3.filterDirty=true
            end
            UIDropDownMenu_AddButton(info,level)
        end
    end)
end
BII3.classDropdown=classDrop

local searchLabel=makeText(BII3,"한글/ID","GameFontNormal"); searchLabel:SetPoint("TOPLEFT",filterX,-164); searchLabel:SetTextColor(1,0.82,0.18)
local edit=makeEdit(BII3,340,24); edit:SetPoint("TOPLEFT",filterX+60,-158); BII3.searchEdit=edit
local searchButton=makeButton(BII3,60,24,"검색"); searchButton:SetPoint("LEFT",edit,"RIGHT",7,0)
local clearButton=makeButton(BII3,72,24,"분류"); clearButton:SetPoint("LEFT",searchButton,"RIGHT",7,0)
local filterApply=makeButton(BII3,72,24,"필터 적용"); filterApply:SetPoint("LEFT",clearButton,"RIGHT",7,0)
local currentLabel=makeText(BII3,"분류를 선택하세요.  |cffaaaaaa※ 종류/등급/클래스 선택 후 '필터 적용'|r","GameFontHighlightSmall"); currentLabel:SetPoint("TOPLEFT",filterX,-190); currentLabel:SetTextColor(0.45,0.9,1)

BII3.rows={}
local function createItemRow(index)
    local row=CreateFrame("Button",nil,BII3)
    row:SetWidth(316); row:SetHeight(44)
    local col=(index-1)%2; local r=math.floor((index-1)/2)
    row:SetPoint("TOPLEFT",BII3,"TOPLEFT",filterX+col*326,-214-r*48)
    row:SetBackdrop({bgFile="Interface\\Tooltips\\UI-Tooltip-Background",edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",tile=true,tileSize=12,edgeSize=8,insets={left=2,right=2,top=2,bottom=2}})
    row:SetBackdropColor(0.02,0.035,0.045,0.78); row:SetBackdropBorderColor(0.30,0.34,0.37,1)
    row:RegisterForClicks("LeftButtonUp","RightButtonUp")
    local tex=row:CreateTexture(nil,"ARTWORK"); tex:SetWidth(34); tex:SetHeight(34); tex:SetPoint("LEFT",6,0); row.icon=tex
    local name=makeText(row,"","GameFontHighlightSmall"); name:SetWidth(262); name:SetJustifyH("LEFT"); name:SetPoint("TOPLEFT",46,-6); row.name=name
    local meta=makeText(row,"","GameFontHighlightSmall"); meta:SetWidth(262); meta:SetJustifyH("LEFT"); meta:SetPoint("BOTTOMLEFT",46,6); meta:SetTextColor(0.65,0.82,0.90); row.meta=meta
    row:SetScript("OnEnter",function(self)
        if not self.itemID then return end
        self:SetBackdropColor(0.055,0.12,0.15,0.96)
        GameTooltip:SetOwner(self,"ANCHOR_RIGHT")
        if self.itemID < 0 then
            pcall(GameTooltip.SetHyperlink, GameTooltip, "spell:"..(-self.itemID))
        else
            pcall(GameTooltip.SetHyperlink, GameTooltip, "item:"..self.itemID)
        end
        local source=BII3:GetAcquisitionText(self.itemID)
        if source then GameTooltip:AddLine(" "); GameTooltip:AddLine("|cffffd24a획득 정보|r"); GameTooltip:AddLine(source,1,1,1,true) end
        GameTooltip:AddLine(" ")
        if self.itemID < 0 then
            GameTooltip:AddLine("좌클릭: GM 습득 / 우클릭: GM 습득",0.55,0.95,0.80,true)
        else
            local _, _, _, itemLevel, _, _, _, _, equipLoc = GetItemInfo(self.itemID)
            GameTooltip:AddLine("좌클릭: 수량 입력 후 가방 추가 / Shift+클릭: 링크 / 우클릭: 추가 메뉴",0.55,0.95,0.80,true)
            if equipLoc == "INVTYPE_BAG" then
                GameTooltip:AddLine("가방 아이콘의 " .. tostring(tonumber(itemLevel) or 0) .. "은 수량이 아니라 iLv입니다. 각 가방 칸은 1개입니다.",0.35,0.85,1,true)
            end
        end
        GameTooltip:Show()
    end)
    row:SetScript("OnLeave",function(self) self:SetBackdropColor(0.02,0.035,0.045,0.78); GameTooltip:Hide() end)
    row:SetScript("OnClick",function(self,button)
        if not self.itemID then return end
        local link=BII3:GetItemLink(self.itemID)
        if link and HandleModifiedItemClick and HandleModifiedItemClick(link) then return end
        if self.itemID < 0 then
            local sid=-self.itemID
            if addon and addon.PromptCraftLearn then addon:PromptCraftLearn(sid,GetSpellInfo(sid) or ("Spell "..sid),false) end
        elseif button=="RightButton" and addon and addon.ShowSearchContextMenu then
            addon:ShowSearchContextMenu("item", {self.itemID,BII3:GetItemName(self.itemID)})
        elseif addon and addon.ShowItemQuantityPopup then
            addon:ShowItemQuantityPopup(self.itemID,BII3:GetItemName(self.itemID))
        end
    end)
    return row
end
for ri=1,ROWS_PER_PAGE do BII3.rows[ri]=createItemRow(ri) end

local prev=makeButton(BII3,82,22,"◀ 이전"); prev:SetPoint("BOTTOMLEFT",filterX,22)
local pageText=makeText(BII3,"","GameFontHighlightSmall"); pageText:SetWidth(420); pageText:SetJustifyH("CENTER"); pageText:SetPoint("LEFT",prev,"RIGHT",14,0)
local nextb=makeButton(BII3,82,22,"다음 ▶"); nextb:SetPoint("LEFT",pageText,"RIGHT",14,0)

local function refresh()
    local count=table.getn(results); maxPage=math.max(1,math.ceil(count/ROWS_PER_PAGE)); if page<1 then page=1 end; if page>maxPage then page=maxPage end
    local first=(page-1)*ROWS_PER_PAGE+1
    local i
    for i=1,ROWS_PER_PAGE do
        local rec=results[first+i-1]; local row=BII3.rows[i]
        if rec then
            row.itemID=rec[1]
            local name,link,quality,itemLevel,minLevel,texture,r,g,b,hex,levelText,isSpell,itemType,itemSubType=BII3:GetItemDisplayInfo(rec[1])
            row.icon:SetTexture(texture)
            row.name:SetText("["..rec[1].."]  "..(name or rec[2] or "미확인 아이템")); row.name:SetTextColor(r,g,b)
            local t = classifyItem(rec[1],name,rec.root)
            row.meta:SetText((TYPE_LABELS[t] or "기타") .. " · " .. (QUALITY_NAMES[quality] or ("등급 "..tostring(quality))) .. " · " .. levelText)
            row:Show()
        else row.itemID=nil; row:Hide() end
    end
    pageText:SetText((searchMode and "검색" or "분류") .. " " .. count .. "개 · " .. page .. " / " .. maxPage)
    if page<=1 then prev:Disable() else prev:Enable() end; if page>=maxPage then nextb:Disable() else nextb:Enable() end
end

local function buildCategory(entry)
    results={}; page=1; searchMode=false; selectedCategory=entry; BII3.filterDirty=nil
    local seen={}
    if entry then
        if entry.kind=="root" then
            local seconds=IDX.seconds[entry.key] or {}; local keys=sortedKeys(seconds); local i
            for i=1,table.getn(keys) do collectSecond(results,seen,keys[i],entry.root) end
        else
            collectSecond(results,seen,entry.key,entry.root)
        end
        table.sort(results,function(a,b) return tonumber(a[1]) < tonumber(b[1]) end)
        currentLabel:SetText("선택 분류: " .. entry.label)
    else
        currentLabel:SetText("분류를 선택하세요.")
    end
    BII3._itemRefreshCount = 4; BII3._itemRefreshElapsed = 0
    refresh()
end

local function runSearch()
    BII3.filterDirty=nil
    local query=string.gsub(edit:GetText() or "","^%s*(.-)%s*$","%1")
    if query=="" then buildCategory(selectedCategory); return end
    results={}; page=1; searchMode=true
    local numeric=tonumber(query); local needle=string.lower(query)
    local source=(addon and addon.KoKRSearchData and addon.KoKRSearchData.item) or {}
    local i
    for i=1,table.getn(source) do
        local id,name=tonumber(source[i][1]),source[i][2] or ""
        if id and ((numeric and id==numeric) or string.find(string.lower(name),needle,1,true)) then
            local rec={id,name}; rec.root=nil
            if passesFilters(rec) then table.insert(results,rec) end
            if table.getn(results)>=1000 then break end
        end
    end
    currentLabel:SetText("검색: " .. query)
    BII3._itemRefreshCount = 4; BII3._itemRefreshElapsed = 0
    refresh()
end

function BII3:RebuildCurrent()
    if searchMode and (edit:GetText() or "")~="" then runSearch() else buildCategory(selectedCategory) end
end

for ri=1,table.getn(BII3.categoryButtons) do
    local b=BII3.categoryButtons[ri]
    b:SetScript("OnClick",function(self)
        edit:SetText("")
        buildCategory(self.aaeCategory)
    end)
end

searchButton:SetScript("OnClick",runSearch)
clearButton:SetScript("OnClick",function() edit:SetText(""); buildCategory(selectedCategory) end)
filterApply:SetScript("OnClick",function()
    BII3.filterDirty=nil
    if searchMode and (edit:GetText() or "") ~= "" then runSearch() else buildCategory(selectedCategory) end
end)
edit:SetScript("OnEnterPressed",function(self) runSearch(); self:ClearFocus() end)
edit:SetScript("OnEscapePressed",function(self) self:ClearFocus(); if addon and addon.HandleManagedEscape then addon:HandleManagedEscape() else BII3:Hide() end end)
prev:SetScript("OnClick",function() if page>1 then page=page-1; refresh() end end)
nextb:SetScript("OnClick",function() if page<maxPage then page=page+1; refresh() end end)

function BII3:OnClick()
    if self:IsShown() then self:Hide(); return end
    if addon and addon.HideAddonPopups then addon:HideAddonPopups(nil) end
    results={}; page=1; searchMode=false; edit:SetText(""); selectedCategory=nil
    currentLabel:SetText("분류를 선택하세요.  |cffaaaaaa※ 종류/등급/클래스 선택 후 '필터 적용'|r")
    refresh()
    if addon and addon.OpenManagedFrame then addon:OpenManagedFrame(self) else self:Show() end
end

function BII3:Search(query)
    query=tostring(query or "")
    edit:SetText(query)
    if not self:IsShown() then if addon and addon.OpenManagedFrame then addon:OpenManagedFrame(self) else self:Show() end end
    runSearch(); edit:SetFocus(); edit:HighlightText()
end

function BII3:SimpleRefresh() self:RebuildCurrent() end

-- 3.3.5a has no reliable item-cache event used by modern clients.  Refresh only
-- the visible page a few times after category/search changes so level/type data
-- appears as the server item cache arrives, without scanning the full database.
BII3._itemRefreshElapsed = 0
BII3._itemRefreshCount = 0
BII3:SetScript("OnUpdate", function(self, elapsed)
    if not self:IsShown() or (self._itemRefreshCount or 0) <= 0 then return end
    self._itemRefreshElapsed = (self._itemRefreshElapsed or 0) + (elapsed or 0)
    if self._itemRefreshElapsed >= 0.55 then
        self._itemRefreshElapsed = 0
        self._itemRefreshCount = self._itemRefreshCount - 1
        refresh()
    end
end)

refresh(); BII3:Hide()
