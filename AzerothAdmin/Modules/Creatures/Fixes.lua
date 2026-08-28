AzerothAdminEasy = AzerothAdminEasy or {}
local addon = AzerothAdminEasy

-- WotLK 3.3.5a / AzerothCore compatibility fixes that do NOT own keyboard or
-- PlayerModel state. Keyboard/model handling lives only in RuntimeFixes.lua so
-- the two layers cannot fight each other.

-- Safe instance positions from the pinned AzerothCore WotLK game_tele table.
-- The command syntax is `.go xyz x y z [mapId [orientation]]`.
local INSTANCE_SAFE_TELEPORTS = {
    ["용사의 시험장"] = ".go xyz 804.065 618.033 412.393 650 3.1456",
    ["사론의 구덩이"] = ".go xyz 435.743 212.413 528.709 658 6.25646",
    ["영혼의 제련소"] = ".go xyz 4922.86 2175.63 638.734 632 2.00355",
    ["낙스라마스"] = ".go xyz 3019.34 -3434.36 293.99 533 6.27",
    ["흑요석 성소"] = ".go xyz 3228.58 385.86 65.5484 615 1.578",
    ["영원의 눈"] = ".go xyz 728.055 1329.03 267.235 616 5.51524",
    ["울두아르"] = ".go xyz -914.041 -148.98 463.137 603 6.28",
    ["십자군의 시험장"] = ".go xyz 563.61 80.6815 395.2 649 1.59",
    ["오닉시아의 둥지"] = ".go xyz 29.1607 -71.3372 -8.18032 249 4.58",
    ["얼음왕관 성채"] = ".go xyz 65.7692 2211.28 30 631 3.14651",
    ["루비 성소"] = ".go xyz 3274 533.531 87.665 724 3.16",
}

-- Dire Maul has three wings but the creature catalog intentionally uses one
-- Korean place label. Resolve those bosses by entry so the teleport goes to the
-- correct wing instead of whichever Teleports.lua row happens to come first.
local ENTRY_SAFE_TELEPORTS = {
    -- East
    [11490] = ".go xyz 47.629997 -155.270004 -2.714379 429",
    [13280] = ".go xyz 47.629997 -155.270004 -2.714379 429",
    [14327] = ".go xyz 47.629997 -155.270004 -2.714379 429",
    [11492] = ".go xyz 47.629997 -155.270004 -2.714379 429",
    -- West
    [11488] = ".go xyz 34.35 160.70 -3.47 429",
    [11487] = ".go xyz 34.35 160.70 -3.47 429",
    [11496] = ".go xyz 34.35 160.70 -3.47 429",
    [11489] = ".go xyz 34.35 160.70 -3.47 429",
    [11486] = ".go xyz 34.35 160.70 -3.47 429",
    -- North
    [14326] = ".go xyz 254.588248 -24.739523 -2.560616 429",
    [14322] = ".go xyz 254.588248 -24.739523 -2.560616 429",
    [14321] = ".go xyz 254.588248 -24.739523 -2.560616 429",
    [14323] = ".go xyz 254.588248 -24.739523 -2.560616 429",
    [14325] = ".go xyz 254.588248 -24.739523 -2.560616 429",
    [14324] = ".go xyz 254.588248 -24.739523 -2.560616 429",
    [11501] = ".go xyz 254.588248 -24.739523 -2.560616 429",
}

-- The featured catalog and the legacy teleport database use a few different
-- Korean labels. Map only the reviewed differences; generic matching below
-- handles spacing and punctuation differences without rewriting Teleports.lua.
local INSTANCE_LABEL_ALIASES = {
    ["검은늪"] = "검은 늪 - 어둠의 문",
    ["검은심연 나락"] = "검은심연의 나락",
    ["안카헤트: 고대 왕국"] = "안카헤트",
    ["안퀴라즈 사원"] = "안퀴라즈",
    ["옛 힐스브래드 구릉지"] = "옛 힐스브래드 구릉지 - 던홀드 요새",
    ["하이잘 산 전투"] = "하이잘 정상 - 얼라이언스 주둔지",
    ["혈투의 전장"] = "동쪽 - 굽이나무 지구",
}

local function normalizeTeleportLabel(value)
    local label = tostring(value or "")
    label = string.gsub(label, "[%s:%-·_/()%[%]]", "")
    return label
end

local function sourceName(row)
    return row and (row._aaeSourceName or row.name) or nil
end

local function sourceZone(row)
    return row and (row._aaeSourceZone or row.zone) or nil
end

local function findTeleportByLabel(label)
    if not label or label == "" then return nil end
    local wanted = normalizeTeleportLabel(label)
    local list = addon.Teleports or {}
    local firstZoneMatch = nil
    local i

    -- Route from canonical source labels so UI translation can never change
    -- instance lookup behavior.
    for i = 1, table.getn(list) do
        local row = list[i]
        if row and row.command and normalizeTeleportLabel(sourceName(row)) == wanted then
            return row.command
        end
    end

    for i = 1, table.getn(list) do
        local row = list[i]
        if row and row.command and normalizeTeleportLabel(sourceZone(row)) == wanted then
            firstZoneMatch = row.command
            break
        end
    end
    return firstZoneMatch
end

local function findInstanceTeleport(record)
    if not record then return nil end
    local entry = tonumber(record[1])
    local place = tostring(record[5] or "")
    if place == "" then return nil end

    if entry and ENTRY_SAFE_TELEPORTS[entry] then
        return ENTRY_SAFE_TELEPORTS[entry]
    end
    if INSTANCE_SAFE_TELEPORTS[place] then
        return INSTANCE_SAFE_TELEPORTS[place]
    end

    local alias = INSTANCE_LABEL_ALIASES[place]
    local command = alias and findTeleportByLabel(alias) or nil
    if command then return command end
    return findTeleportByLabel(place)
end

local originalRunFeaturedCreatureAction = addon.RunFeaturedCreatureAction
if originalRunFeaturedCreatureAction then
    addon.RunFeaturedCreatureAction = function(self, action, ...)
        local record = self.creatureBrowserSelected
        if action == "go" and record then
            local group = tostring(record[3] or "")
            if group == "raid" or group == "dungeon" then
                local command = findInstanceTeleport(record)
                if command then
                    self:SendNow(command)
                    if self.Print then
                        self:Print(tostring(record[5] or record[2] or "인스턴스") .. " 안전 위치로 이동합니다.")
                    end
                    return
                end
            end
        end
        return originalRunFeaturedCreatureAction(self, action, ...)
    end
end

-- Remove the repeated dragon icon from every creature row while preserving the
-- existing row, click handlers, text, category behavior and dimensions.
local function removeRepeatedCreatureRowIcons()
    local rows = addon.creatureBrowserRows or {}
    local i
    for i = 1, table.getn(rows) do
        local row = rows[i]
        if row then
            local regions = { row:GetRegions() }
            local r
            for r = 1, table.getn(regions) do
                local region = regions[r]
                if region and region.GetObjectType and region:GetObjectType() == "Texture" and region.GetTexture then
                    local texture = region:GetTexture()
                    if texture == "Interface\\Icons\\INV_Misc_Head_Dragon_01" then
                        region:Hide()
                    end
                end
            end
            if row.name then
                row.name:ClearAllPoints()
                row.name:SetWidth(366)
                row.name:SetPoint("TOPLEFT", row, "TOPLEFT", 10, -6)
            end
            if row.meta then
                row.meta:ClearAllPoints()
                row.meta:SetWidth(366)
                row.meta:SetPoint("BOTTOMLEFT", row, "BOTTOMLEFT", 10, 6)
            end
        end
    end
end

local originalCreateCreatureBrowser = addon.CreateCreatureBrowser
if originalCreateCreatureBrowser then
    addon.CreateCreatureBrowser = function(self, ...)
        local result = originalCreateCreatureBrowser(self, ...)
        removeRepeatedCreatureRowIcons()
        return result
    end
end
