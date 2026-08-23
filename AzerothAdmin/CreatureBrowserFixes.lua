AzerothAdminEasy = AzerothAdminEasy or {}
local addon = AzerothAdminEasy

-- WotLK 3.3.5a / AzerothCore compatibility fixes that do NOT own keyboard or
-- PlayerModel state.  Keyboard/model handling lives only in
-- CreatureBrowserRuntimeFixes.lua so the two layers cannot fight each other.

-- Safe raid-map positions from AzerothCore WotLK game_tele data.  Direct map
-- coordinates avoid `.go creature id` selecting a spawn on the wrong map/phase.
local RAID_SAFE_TELEPORTS = {
    ["오닉시아의 둥지"] = ".go xyz 29.1607 -71.3372 -8.18032 249 4.58",
    ["낙스라마스"] = ".go xyz 3005.68 -3447.77 293.93 533",
    ["영원의 눈"] = ".go xyz 728.055 1329.03 267.235 616 5.51524",
    ["흑요석 성소"] = ".go xyz 3228.58 385.86 65.5484 615 1.578",
    ["울두아르"] = ".go xyz -914.041 -148.98 463.137 603 6.28",
    ["십자군의 시험장"] = ".go xyz 563.61 80.6815 395.2 649 1.59",
    ["얼음왕관 성채"] = ".go xyz 65.7692 2211.28 30 631 3.14651",
    ["루비 성소"] = ".go xyz 3274 533.531 87.665 724 3.16",
}

local ZONE_ALIASES = {
    ["안카헤트: 고대 왕국"] = "안카헤트",
    ["마력의 탑"] = "마력의 탑",
    ["마력의 눈"] = "마력의 눈",
    ["옛 스트라솔름"] = "옛 스트라솔름",
}

local function findInstanceTeleport(record)
    if not record then return nil end
    local place = tostring(record[5] or "")
    if place == "" then return nil end

    if RAID_SAFE_TELEPORTS[place] then
        return RAID_SAFE_TELEPORTS[place]
    end

    local zone = ZONE_ALIASES[place] or place
    local firstZoneMatch = nil
    local list = addon.Teleports or {}
    local i
    for i = 1, table.getn(list) do
        local row = list[i]
        if row and tostring(row.zone or "") == zone then
            if tostring(row.name or "") == place and row.command then
                return row.command
            end
            if not firstZoneMatch and row.command then
                firstZoneMatch = row.command
            end
        end
    end
    return firstZoneMatch
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

-- AzerothCore's Gundrak encounter uses entry 29573 for Drakkari Colossus.
-- Remove the old wrong 29307 row if it exists and add the correct entry once.
local function correctGundrakEntry()
    local list = addon.FeaturedCreatures or {}
    local hasCorrect = false
    local i
    for i = table.getn(list), 1, -1 do
        local record = list[i]
        local entry = tonumber(record and record[1])
        if entry == 29573 then
            hasCorrect = true
        elseif entry == 29307 and tostring(record and record[5] or "") == "군드락" then
            table.remove(list, i)
        end
    end
    if not hasCorrect then
        table.insert(list, { 29573, "드라카리 거대골렘", "dungeon", "wotlk", "군드락", true })
    end
end
correctGundrakEntry()
