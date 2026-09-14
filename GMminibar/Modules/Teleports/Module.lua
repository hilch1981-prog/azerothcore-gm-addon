-- Canonical AzerothAdmin 3.5.0 teleport/favorites workflow with AC335 3.3.5a metadata.
local A = AzerothAdminAC335
A.UI = type(A.UI) == "table" and A.UI or {}
local UI = A.UI
local TELEPORTS_PER_PAGE = 24
-- Rows start at 180, have a 27px pitch and end 2px before the next pitch.
-- Reserve 6px before the dispatch line at height-57, followed by the pager.
local function pageSize(frame) return math.max(1,math.min(TELEPORTS_PER_PAGE,math.floor((frame:GetHeight()-241)/27))) end
local FAVORITES_PER_PAGE = 12

local BLOCKED_TELEPORT_IDS = {} -- Disabled rows are removed from the Legends catalog.

local function isTeleportUsable(row)
    if A.TeleportDestinationByID and not A.TeleportDestinationByID[tonumber(row and row.id) or 0]then return false end
    if not row then return false end
    local meta=A.Data.teleportMeta[tonumber(row.id) or 0]
    if meta and meta.disabled then return false end
    if row.disabled or BLOCKED_TELEPORT_IDS[tonumber(row.id) or 0] then return false end
    return string.lower(tostring(row.name or "")) ~= "scotttest"
end

function A:TeleportCommandFor(row)
 local id=tonumber(row and row.id)
 local target=id and self.TeleportDestinationByID and self.TeleportDestinationByID[id]
 if not target or target.disabled then return nil end
 if target.landing then
  local p=target.landing
  if not (tonumber(p.x) and tonumber(p.y) and tonumber(p.z) and tonumber(p.map)) then return nil end
  return string.format('.go xyz %.4f %.4f %.4f %d %.5f',p.x,p.y,p.z,p.map,p.orientation or 0)
 end
 if target.targetKind=='creature' then return '.go creature '..target.guid end
 if target.targetKind=='gameobject' then return (self.interface==30300 and '.go gameobject ' or '.go object ')..target.guid end
 if target.targetKind=='trigger' then return '.go trigger '..target.trigger end
end

local function teleportStatus(message,failed)
 local frame=A.teleportFrame
 if frame and frame.dispatchText then frame.dispatchText:SetText(message) end
 if failed then A:Print(message,true);A.teleportReturn=nil end
end

local function teleportDifficultyAPI(row)
 if row.type=='raid' then
  if A.interface==30300 then return GetRaidDifficulty,SetRaidDifficulty end
  return GetRaidDifficultyID,SetRaidDifficultyID
 end
 if A.interface==30300 then return GetDungeonDifficulty,SetDungeonDifficulty end
 return GetDungeonDifficultyID,SetDungeonDifficultyID
end

local function difficultyChangeBlocked()
 if IsInInstance and IsInInstance() then return '인스턴스 밖에서 난이도를 변경한 뒤 이동하세요.' end
 if InCombatLockdown and InCombatLockdown() then return '전투가 끝난 뒤 난이도를 변경할 수 있습니다.' end
 local grouped=(GetNumGroupMembers and GetNumGroupMembers()>0)
  or (GetNumRaidMembers and GetNumRaidMembers()>0)
  or (GetNumPartyMembers and GetNumPartyMembers()>0)
 if grouped then
  local leader=(UnitIsGroupLeader and UnitIsGroupLeader('player')) or (IsPartyLeader and IsPartyLeader()) or (IsRaidLeader and IsRaidLeader())
  if not leader then return '파티장 또는 공격대장만 난이도를 변경할 수 있습니다.' end
 end
end

local function dispatchTeleport(row,command)
 local ok=A:SendCommand(command)
 teleportStatus(ok and ((row.name_ko or row.name)..' · 이동 요청 · 서버 응답을 확인하세요.') or '이동 요청을 보내지 못했습니다.',not ok)
 return ok
end

function A:RunTeleportRow(row)
 self.pendingTeleportDifficulty=nil
 if self.teleportDifficultyWatch then self.teleportDifficultyWatch:SetScript('OnUpdate',nil);self.teleportDifficultyWatch:Hide() end
 local command=self:TeleportCommandFor(row)
 if not command or not self:CanRunCommand('go_xyz') then
  teleportStatus('이 목적지의 이동 정보 또는 GM 권한을 확인할 수 없습니다.',true);return false
 end
 local target=self.TeleportDestinationByID[tonumber(row.id)]
 local mode=target.clientDifficulty
 if not mode then return dispatchTeleport(target,command) end
 local getter,setter=teleportDifficultyAPI(target)
 if not getter or not setter then
  teleportStatus('현재 클라이언트에서 이 난이도 변경을 지원하지 않습니다.',true);return false
 end
 local readOK,current=pcall(getter)
 if not readOK then teleportStatus('현재 난이도를 확인하지 못했습니다.',true);return false end
 if current==mode then return dispatchTeleport(target,command) end
 local blocked=difficultyChangeBlocked()
 if blocked then teleportStatus(blocked,true);return false end
 local ok=pcall(setter,mode)
 if not ok then teleportStatus('난이도를 변경하지 못해 이동을 취소했습니다.',true);return false end
 local request={row=target,command=command,mode=mode,getter=getter,elapsed=0,tick=0}
 self.pendingTeleportDifficulty=request
 teleportStatus((target.name_ko or target.name)..' · 난이도 변경 확인 중')
 local watcher=self.teleportDifficultyWatch or CreateFrame('Frame')
 self.teleportDifficultyWatch=watcher;watcher:Show()
 watcher:SetScript('OnUpdate',function(frame,delta)
  local job=A.pendingTeleportDifficulty
  if job~=request then frame:SetScript('OnUpdate',nil);frame:Hide();return end
  job.elapsed=job.elapsed+delta;job.tick=job.tick+delta
  if job.tick<.15 then return end;job.tick=0
  local success,value=pcall(job.getter)
  if success and value==job.mode then
   A.pendingTeleportDifficulty=nil;frame:SetScript('OnUpdate',nil);frame:Hide()
   dispatchTeleport(job.row,job.command)
  elseif job.elapsed>=6 then
   A.pendingTeleportDifficulty=nil;frame:SetScript('OnUpdate',nil);frame:Hide()
   teleportStatus('난이도 변경이 확인되지 않아 이동을 취소했습니다. 레벨·파티 상태와 서버 메시지를 확인하세요.',true)
  end
 end)
 return true
end


local CATEGORY_ORDER = {
    { key = "all", label = "ALL" },
    { key = "zone", label = "ZONES" },
    { key = "city", label = "CITIES" },
    { key = "dungeon", label = "DUNGEONS" },
    { key = "raid", label = "RAIDS" },
    { key = "battleground", label = "BATTLEGROUNDS" },
}

local REGION_OPTIONS = {
    { key = "ALL", label = "ALL_REGIONS" },
    { key = "EASTERN_KINGDOMS", label = "REGION_EASTERN_KINGDOMS" },
    { key = "KALIMDOR", label = "REGION_KALIMDOR" },
    { key = "OUTLAND", label = "REGION_OUTLAND" },
    { key = "NORTHREND", label = "REGION_NORTHREND" },
    { key = "BATTLEGROUND", label = "REGION_BATTLEGROUND" },
    { key = "OTHER", label = "REGION_OTHER" },
}

local REGION_RANK = {
    EASTERN_KINGDOMS = 1, KALIMDOR = 2, OUTLAND = 3, NORTHREND = 4,
    CATACLYSM = 5, PANDARIA = 6, BATTLEGROUND = 7, OTHER = 8,
}

local ALLIANCE_WORDS = {
    "alliance", "얼라이언스", "stormwind", "스톰윈드", "ironforge", "아이언포지",
    "darnassus", "다르나서스", "exodar", "엑소다르", "sevenstars", "일곱 별",
}
local HORDE_WORDS = {
    "horde", "호드", "orgrimmar", "오그리마", "undercity", "언더시티",
    "thunderbluff", "썬더 블러프", "silvermoon", "실버문", "twomoons", "두 달",
}

local function compact(value)
    return string.lower(tostring(value or "")):gsub("[%s_%-']", "")
end

local function containsFactionWord(haystack, words)
    haystack = compact(haystack)
    for _, word in ipairs(words) do
        if string.find(haystack, compact(word), 1, true) then return true end
    end
    return false
end

local function teleportFaction(row)
    if row and row.faction then return row.faction end
    if row and row.aaeFaction then return row.aaeFaction end
    local haystack = table.concat({ tostring(row and row.name or ""), tostring(row and row.name_ko or ""), tostring(row and row.zone_ko or "") }, " ")
    local alliance = containsFactionWord(haystack, ALLIANCE_WORDS)
    local horde = containsFactionWord(haystack, HORDE_WORDS)
    local faction=alliance and not horde and "ALLIANCE" or (horde and not alliance and "HORDE" or "NEUTRAL")
    if row then row.aaeFaction=faction end
    return faction
end

local function playerFaction()
    if UnitFactionGroup then
        local faction = UnitFactionGroup("player")
        if faction == "Alliance" then return "ALLIANCE" end
        if faction == "Horde" then return "HORDE" end
    end
    return "NEUTRAL"
end

local function levelRange(row)
    local text = tostring(row and row.levelText or "")
    local first, last = text:match("(%d+)%s*[%-%~–]%s*(%d+)")
    if first and last then return tonumber(first), tonumber(last) end
    local single = text:match("(%d+)")
    if single then return tonumber(single), tonumber(single) end
    return nil, nil
end

local function matchesProgress(row, enabled)
    if not enabled then return true end
    local faction = teleportFaction(row)
    local mine = playerFaction()
    -- R10: faction-only filter. Neutral destinations remain visible for both factions;
    -- player level is deliberately not used.
    return faction == "NEUTRAL" or mine == "NEUTRAL" or faction == mine
end

local function factionLabel(faction)
    return A:L("TELEPORT_FACTION_" .. tostring(faction or "NEUTRAL"))
end

local function utf8CharLen(byte)
    if not byte then return 1 end
    if byte < 0x80 then return 1 end
    if byte < 0xE0 then return 2 end
    if byte < 0xF0 then return 3 end
    return 4
end

local function fitFontText(fontString, text, width)
    text = A:TranslateLabel(tostring(text or ""))
    fontString:SetText(text)
    if not fontString.GetStringWidth or fontString:GetStringWidth() <= width then return end
    local suffix = "..."
    local bytes, pos, pieces = string.len(text), 1, {}
    while pos <= bytes do
        local len = utf8CharLen(string.byte(text, pos))
        table.insert(pieces, string.sub(text, pos, pos + len - 1))
        pos = pos + len
    end
    local low, high, best = 0, table.getn(pieces), 0
    while low <= high do
        local mid = math.floor((low + high) / 2)
        local candidate = table.concat(pieces, "", 1, mid) .. suffix
        fontString:SetText(candidate)
        if fontString:GetStringWidth() <= width then best = mid; low = mid + 1 else high = mid - 1 end
    end
    fontString:SetText(table.concat(pieces, "", 1, best) .. suffix)
end

local SORT_KEYS = { area = true, destination = true, level = true, faction = true }
local function teleportSortValue(row, key)
    if key == "area" then
        return tostring(row.region_ko or "") .. "\001" .. tostring(row.zone_ko or "")
    elseif key == "level" then
        return tonumber(row.minLevel) or 999
    elseif key == "faction" then
        return tostring(row.faction or teleportFaction(row))
    end
    return tostring(row.name_ko or row.name or "")
end

local quickGroupByName
local function buildQuickGroupIndex()
    if quickGroupByName then return quickGroupByName end
    quickGroupByName = {}
    for _, row in ipairs(A.Data.teleports or {}) do
        quickGroupByName[string.lower(tostring(row.name or ""))] = row.group or "zone"
    end
    return quickGroupByName
end

local function normalizeFavorites()
    local db = A:GetDB()
    db.teleportFavorites = db.teleportFavorites or {}
    local favorites = db.teleportFavorites
    if table.getn(favorites) > 0 then
        local converted = {}
        for _, value in ipairs(favorites) do converted[tostring(value)] = true end
        db.teleportFavorites = converted
        favorites = converted
    end
    if not db.teleportFavorites156 and A.TeleportDestinations then
        local unique = {}
        for _, row in ipairs(A.TeleportDestinations) do
            if not row.baseID or row.id==row.baseID then
                local name = tostring(row.baseName or row.name or "")
                if unique[name] == nil then unique[name] = row.id else unique[name] = false end
            end
        end
        for name, id in pairs(unique) do
            if id and favorites[name] == true then favorites["destination:" .. tostring(id)] = true end
        end
        db.teleportFavorites156 = true
    end
    return favorites
end

local function teleportKey(row)
    if row and row.id then return "destination:" .. tostring(row.id) end
    return tostring(row and row.name or "")
end

function A:IsTeleportFavorite(row)
    local key = teleportKey(row)
    return key ~= "" and normalizeFavorites()[key] == true
end

function A:ToggleTeleportFavorite(row)
    local key = teleportKey(row)
    if key == "" then return false end
    local favorites = normalizeFavorites()
    favorites[key] = not favorites[key]
    self:Print(self:L(favorites[key] and "TELEPORT_FAVORITE_ADDED" or "TELEPORT_FAVORITE_REMOVED", self:TranslateLabel(row.name_ko or row.name)))
    if self.teleportFrame and self.teleportFrame:IsShown() then self:RefreshTeleportWindow() end
    if self.teleportFavoritesFrame and self.teleportFavoritesFrame:IsShown() then self:RefreshTeleportFavoritesWindow() end
    return favorites[key]
end

local RAID_MAPS = { [409]=true,[469]=true,[509]=true,[531]=true,[532]=true,[533]=true,[534]=true,[544]=true,[548]=true,[550]=true,[565]=true,[568]=true,[580]=true,[603]=true,[615]=true,[616]=true,[624]=true,[631]=true,[649]=true,[669]=true,[671]=true,[720]=true,[724]=true,[754]=true,[757]=true,[967]=true,[1008]=true,[1009]=true,[1098]=true,[1136]=true }
local SCENARIO_MAPS = { [974]=true,[1005]=true,[1006]=true,[1030]=true,[1031]=true,[1050]=true,[1051]=true,[1099]=true,[1102]=true,[1103]=true,[1104]=true,[1112]=true,[1126]=true,[1130]=true,[1144]=true }
local DUNGEON_MAPS = { [33]=true,[34]=true,[36]=true,[43]=true,[47]=true,[48]=true,[70]=true,[90]=true,[109]=true,[129]=true,[189]=true,[209]=true,[229]=true,[230]=true,[289]=true,[329]=true,[349]=true,[389]=true,[429]=true,[540]=true,[542]=true,[543]=true,[545]=true,[546]=true,[547]=true,[552]=true,[553]=true,[554]=true,[555]=true,[556]=true,[557]=true,[558]=true,[560]=true,[574]=true,[575]=true,[576]=true,[578]=true,[585]=true,[595]=true,[599]=true,[600]=true,[601]=true,[602]=true,[604]=true,[608]=true,[619]=true,[632]=true,[643]=true,[644]=true,[645]=true,[657]=true,[658]=true,[668]=true,[725]=true,[755]=true,[938]=true,[959]=true,[960]=true,[961]=true,[962]=true,[1001]=true,[1004]=true,[1007]=true,[1011]=true }

local CITY_WORDS = { "stormwind", "orgrimmar", "ironforge", "darnassus", "exodar", "silvermoon", "undercity", "thunderbluff", "shattrath", "dalaran", "shrineofsevenstars", "shrineoftwomoons", "city", "capital" }
local function hasWord(name, words)
    name = string.lower(tostring(name or "")):gsub("[%s_%-']", "")
    for _, word in ipairs(words) do
        local normalized = string.lower(word):gsub("[%s_%-']", "")
        if string.find(name, normalized, 1, true) then return true end
    end
    return false
end

local function classifyServerTeleport(row)
    if row and row.group and row.group ~= "server" then return row.group end
    local override = buildQuickGroupIndex()[string.lower(tostring(row and row.name or ""))]
    if override then return override end
    local map = tonumber(row and row.map) or 0
    if hasWord(row and row.name, CITY_WORDS) then return "city" end
    if RAID_MAPS[map] then return "raid" end
    if SCENARIO_MAPS[map] then return "scenario" end
    if DUNGEON_MAPS[map] then return "dungeon" end
    return "zone"
end

local function matchesCategory(row, category, serverMode)
    if category == "all" then return true end
    if category == "battleground" then return row.regionKey=="BATTLEGROUND" or row.group=="battleground" end
    local group = row.group
    if serverMode and (not group or group == "server") then group = classifyServerTeleport(row) end
    return group == category
end

local function matchesRegion(row, region)
    return region == nil or region == "ALL" or tostring(row.regionKey or "OTHER") == region
end

local function teleportLabel(row, favorite)
    local star = favorite and "|cffffd24a★|r " or ""
    local region = row.region_ko and row.region_ko ~= "" and row.region_ko or A:L("REGION_OTHER")
    local zone = row.zone_ko and row.zone_ko ~= "" and row.zone_ko or region
    local name = row.name_ko and row.name_ko ~= "" and row.name_ko or tostring(row.name or A:L("UNKNOWN"))
    local level = row.levelText and row.levelText ~= "" and row.levelText or A:L("TELEPORT_LEVEL")
    local faction = teleportFaction(row)
    local color = faction == "ALLIANCE" and "|cff69a8ff" or (faction == "HORDE" and "|cffff6666" or "|cffb8c6cc")
    return star .. "|cffffd24a" .. tostring(region) .. "|r / " .. tostring(zone)
        .. "  |cff6fcfe8→|r  " .. tostring(name) .. "  |cff8fd8e8" .. tostring(level) .. "|r  "
        .. color .. "[" .. factionLabel(faction) .. "]|r"
end

local function teleportTooltipLines(row)
    return {
        A:L("TELEPORT_TABLE_PATH", A:TranslateLabel(tostring(row.region_ko or A:L("REGION_OTHER"))), A:TranslateLabel(tostring(row.zone_ko or A:L("REGION_OTHER"))), A:TranslateLabel(tostring(row.levelText or ""))),
        A:L("TELEPORT_FACTION_LABEL") .. ": " .. factionLabel(teleportFaction(row)),
        row.clientDifficulty and (row.difficultyLabel..' · 난이도 적용 후 입구로 이동') or (row.targetKind=='creature' and '해당 NPC에게 이동' or '외부 입구로 이동'),
        row.landing and (row.targetKind=='gameobject' and '만남의 돌 옆 바닥으로 이동' or '포탈 앞 바닥으로 이동') or (row.targetKind=='gameobject' and '만남의 돌로 이동' or ''),
        A:L("TELEPORT_ROW_HINT"),
    }
end

local function regionLabel(key)
    for _, option in ipairs(REGION_OPTIONS) do
        if option.key == key then return A:L(option.label) end
    end
    return A:L("REGION_OTHER")
end

local function getTeleportMatches(frame)
    local query = A:Trim(frame.search:GetText())
    local serverMode = frame.serverCheck:GetChecked() and true or false
    local source = A.Data:SearchTeleports(query, serverMode and "server" or nil)
    local matches = {}
    local progressOnly = frame.progressCheck and frame.progressCheck:GetChecked() and true or false
    for _, row in ipairs(source) do
        if isTeleportUsable(row)
            and matchesCategory(row, frame.category or "all", serverMode)
            and matchesRegion(row, frame.regionFilter or "ALL")
            and matchesProgress(row, progressOnly)
            and (not frame.aaeFavOnly or A.Workbench:IsMapFavorite(row))
            and (not A.MatchesTeleportColumns or A:MatchesTeleportColumns(row,frame)) then
            row.faction = teleportFaction(row)
            row.minLevel, row.maxLevel = levelRange(row)
            table.insert(matches, row)
        end
    end
    local sortKey = SORT_KEYS[frame.sortKey] and frame.sortKey or "area"
    local ascending = frame.sortAscending ~= false
    local sortValues={}
    for _,row in ipairs(matches) do sortValues[row]=teleportSortValue(row,sortKey) end
    table.sort(matches, function(left, right)
        local lv, rv = sortValues[left],sortValues[right]
        if lv ~= rv then
            if ascending then return lv < rv else return lv > rv end
        end
        -- Deterministic secondary order preserves the familiar continent/zone/destination layout.
        local lr = REGION_RANK[tostring(left.regionKey or "OTHER")] or 99
        local rr = REGION_RANK[tostring(right.regionKey or "OTHER")] or 99
        if lr ~= rr then return lr < rr end
        local lz, rz = tostring(left.zone_ko or ""), tostring(right.zone_ko or "")
        if lz ~= rz then return lz < rz end
        local ln, rn = tostring(left.name_ko or left.name or ""), tostring(right.name_ko or right.name or "")
        if ln ~= rn then return ln < rn end
        return (tonumber(left.id) or 0) < (tonumber(right.id) or 0)
    end)
    if frame.rc3Sort then A.Workbench:SortMapRows(matches,frame) end
    return matches, serverMode
end

function A:RefreshTeleportRegionDropdown()
    local frame = self.teleportFrame
    if not frame or not frame.regionDropdown then return end
    local text = regionLabel(frame.regionFilter or "ALL")
    if UIDropDownMenu_SetSelectedValue then UIDropDownMenu_SetSelectedValue(frame.regionDropdown, frame.regionFilter or "ALL") end
    if UIDropDownMenu_SetText then UIDropDownMenu_SetText(frame.regionDropdown, text) end
end

function A:SetTeleportRegion(region)
    local frame = self.teleportFrame
    if not frame then return end
    frame.columnFilters={};frame.regionFilter = region or "ALL"
    frame.page = 1
    self:RefreshTeleportRegionDropdown()
    self:RefreshTeleportWindow()
end

local function availableServerTeleportCount()
    local count = 0
    for _, source in ipairs(A.Data.Teleports or {}) do
        if isTeleportUsable(A.Data:EnrichTeleport(source, true)) then count = count + 1 end
    end
    return count
end

function A:RefreshTeleportWindow()
    local frame = self.teleportFrame
    if not frame then return end
    local matches, serverMode = getTeleportMatches(frame)
    frame.matches = matches
    local count = table.getn(matches)
    local perPage=pageSize(frame);frame.perPage=perPage
    local pageCount = math.max(1, math.ceil(count / perPage))
    frame.page = math.max(1, math.min(frame.page or 1, pageCount))
    local first = ((frame.page - 1) * perPage) + 1

    for index = 1, TELEPORTS_PER_PAGE do
        local button = frame.rows[index]
        local row = index<=perPage and matches[first + index - 1] or nil
        button.aaeTeleport = row
        if row then
            local favorite = self:IsTeleportFavorite(row)
            local region = row.region_ko and row.region_ko ~= "" and row.region_ko or self:L("REGION_OTHER")
            local zone = row.zone_ko and row.zone_ko ~= "" and row.zone_ko or region
            local path = (zone == region) and region or (region .. " / " .. zone)
            local destination = (favorite and "|cffffd24a★|r " or "") .. tostring(row.name_ko or row.name or self:L("UNKNOWN"))
            local faction = teleportFaction(row)
            fitFontText(button.pathText, path, 150)
            fitFontText(button.nameText, destination, 146)
            button.levelText:SetText(tostring(row.levelText or self:L("TELEPORT_LEVEL")):gsub("^권장%s*", ""))
            button.factionText:SetText(factionLabel(faction))
            if faction == "ALLIANCE" then button.factionText:SetTextColor(0.41,0.66,1.00)
            elseif faction == "HORDE" then button.factionText:SetTextColor(1.00,0.40,0.40)
            else button.factionText:SetTextColor(0.72,0.78,0.80) end
            button:Show()
        else
            button:Hide()
        end
    end

    frame.pageText:SetText(self:L("DEST156_RESULTS",count,frame.page,pageCount))
    UI:SetEnabled(frame.previous, frame.page > 1)
    UI:SetEnabled(frame.next, frame.page < pageCount)
    for _, button in ipairs(frame.categoryButtons) do UI:SetActive(button, button.aaeCategory == frame.category) end
    if frame.sortHeaders then
        for key, header in pairs(frame.sortHeaders) do
            local base = header.aaeBaseLabel or ""
            if key == frame.sortKey then base = base .. (frame.sortAscending ~= false and " ▲" or " ▼") end
            header.aaeLabel:SetText(base)
        end
    end
    frame.modeText:SetText("분류 → 대륙 → 지역·도시 → 목적지"
        .. (frame.progressCheck and frame.progressCheck:GetChecked() and (" · " .. self:L("TELEPORT_PROGRESS_ACTIVE")) or ""))
end

function A:SetTeleportCategory(category)
    local frame = self.teleportFrame
    if not frame then return end
    frame.columnFilters={};frame.regionFilter="ALL";self:RefreshTeleportRegionDropdown()
    frame.category = category or "all"
    frame.page = 1
    self:RefreshTeleportWindow()
end

function A:CreateTeleportWindow()
    if self.teleportFrame then return end
    local frame = UI:CreateWindow("teleports", self:L("TELEPORTS"), 500, 470)
    frame.aaeClose:SetScript("OnClick",function() A.teleportReturn=nil;frame:Hide() end)
    frame.aaeTitle:ClearAllPoints()
    frame.aaeTitle:SetPoint("TOPLEFT", frame, "TOPLEFT", 56, -18)
    frame:SetBackdropBorderColor(0.72, 0.52, 0.18, 1)
    local icon = frame:CreateTexture(nil, "ARTWORK")
    icon:SetTexture("Interface\\Icons\\INV_Misc_Map_01")
    icon:SetWidth(34); icon:SetHeight(34); icon:SetPoint("TOPLEFT", frame, "TOPLEFT", 14, -8)
    frame.aaeTitleIcon = icon
    local subtitle = UI:Text(frame, self:L("TELEPORT_CANONICAL_SUBTITLE_R7"), "small")
    subtitle:SetPoint("TOPLEFT", frame, "TOPLEFT", 56, -40); subtitle:SetTextColor(0.55, 0.88, 0.92)

    local searchLabel = UI:Text(frame, self:L("SEARCH"), "normal")
    searchLabel:SetPoint("TOPLEFT", frame, "TOPLEFT", 20, -62)
    local search = UI:EditBox(frame, 245, 22, "AzerothAdminAC335TeleportSearch")
    search:SetPoint("LEFT", searchLabel, "RIGHT", 10, 0)
    frame.search = search
    local serverCheck = UI:Check(frame, 155, self:L("SERVER_ALL"), self:GetDB().teleportFullCatalog ~= false, function()
        frame.page = 1
        A:GetDB().teleportFullCatalog = frame.serverCheck:GetChecked() and true or false
        A:RefreshTeleportWindow()
    end)
    serverCheck:SetPoint("LEFT", search, "RIGHT", 7, 0)
    frame.serverCheck = serverCheck;serverCheck:Hide();serverCheck:SetChecked(true)

    local regionLabelText = UI:Text(frame, self:L("TELEPORT_REGION"), "small")
    regionLabelText:SetPoint("TOPLEFT", frame, "TOPLEFT", 20, -88); regionLabelText:SetTextColor(1, 0.78, 0.25)
    local regionDropdown = CreateFrame("Frame", "AzerothAdminAC335TeleportRegionDropdown", frame, "UIDropDownMenuTemplate")
    regionDropdown:SetPoint("LEFT", regionLabelText, "RIGHT", -6, -1)
    if UIDropDownMenu_SetWidth then UIDropDownMenu_SetWidth(regionDropdown, 150) end
    frame.regionDropdown = regionDropdown
    frame.regionFilter = "ALL"
    if UIDropDownMenu_Initialize then
        UIDropDownMenu_Initialize(regionDropdown, function(_, level)
            for _, option in ipairs(REGION_OPTIONS) do
                local selectedKey = option.key
                local selectedLabel = option.label
                local info = UIDropDownMenu_CreateInfo()
                info.text = A:L(selectedLabel)
                info.value = selectedKey
                info.checked = frame.regionFilter == selectedKey
                info.func = function() A:SetTeleportRegion(selectedKey) end
                UIDropDownMenu_AddButton(info, level)
            end
        end)
    end
    local progressCheck = UI:Check(frame, 118, self:L("TELEPORT_PROGRESS_ONLY"), self:GetDB().teleportProgressOnly == true, function(self)
        A:GetDB().teleportProgressOnly = self:GetChecked() and true or false
        frame.page = 1
        A:RefreshTeleportWindow()
    end)
    progressCheck:SetPoint("TOPLEFT", frame, "TOPLEFT", 356, -81)
    frame.progressCheck = progressCheck
    local modeText = UI:Text(frame, "", "small")
    modeText:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -22, -103); modeText:SetTextColor(0.45, 0.90, 1.00)
    frame.modeText = modeText

    search:SetScript("OnTextChanged", function() frame.page = 1; A:RefreshTeleportWindow() end)
    search:SetScript("OnEnterPressed", function(self) self:ClearFocus(); frame.page = 1; A:RefreshTeleportWindow() end)
    search:SetScript("OnEscapePressed", function(self) self:ClearFocus(); frame:Hide() end)

    local filterCaption = UI:Text(frame, self:L("TELEPORT_FILTER_CATEGORY"), "small")
    filterCaption:SetPoint("TOPLEFT", frame, "TOPLEFT", 22, -121)
    filterCaption:SetWidth(34); filterCaption:SetJustifyH("LEFT"); filterCaption:SetTextColor(1, 0.78, 0.25)
    frame.filterCaption = filterCaption

    frame.categoryButtons = {}
    for index, entry in ipairs(CATEGORY_ORDER) do
        local button = UI:Button(frame, 66, 22, self:L(entry.label), "normal")
        button:SetPoint("TOPLEFT", frame, "TOPLEFT", 58 + (index - 1) * 68, -116)
        button.aaeCategory = entry.key
        button:SetScript("OnClick", function(self) A:SetTeleportCategory(self.aaeCategory) end)
        frame.categoryButtons[index] = button
    end

    local headerY = -145
    frame.sortKey = "level"
    frame.rc3Sort = 6
    frame.rc3Ascending = true
    frame.sortAscending = true
    frame.sortHeaders = {}
    local function sortHeader(key, label, x, width, justify)
        local button = CreateFrame("Button", nil, frame)
        button:SetPoint("TOPLEFT", frame, "TOPLEFT", x, headerY + 3)
        button:SetWidth(width); button:SetHeight(18)
        local text = UI:Text(button, label, "small")
        text:SetAllPoints(button); text:SetJustifyH(justify or "LEFT"); text:SetTextColor(1,0.78,0.25)
        button.aaeLabel = text; button.aaeBaseLabel = label; button.aaeSortKey = key
        button:SetScript("OnClick", function(self)
            if frame.sortKey == self.aaeSortKey then frame.sortAscending = not frame.sortAscending
            else frame.sortKey = self.aaeSortKey; frame.sortAscending = true end
            frame.page = 1; A:RefreshTeleportWindow()
        end)
        button:SetScript("OnEnter", function(self)
            UI:ShowHint(self, self.aaeBaseLabel, A:L("TELEPORT_SORT_HINT", A:L(frame.sortAscending ~= false and "TELEPORT_SORT_DESC" or "TELEPORT_SORT_ASC")))
        end)
        button:SetScript("OnLeave", function() GameTooltip:Hide() end)
        frame.sortHeaders[key] = button
        return button
    end
    local pathHeader = sortHeader("area", self:L("TELEPORT_COL_AREA"), 28, 152, "LEFT")
    local nameHeader = sortHeader("destination", self:L("TELEPORT_COL_DESTINATION"), 184, 148, "LEFT")
    local levelHeader = sortHeader("level", self:L("LEVEL"), 338, 66, "CENTER")
    local factionHeader = sortHeader("faction", self:L("TELEPORT_FACTION_LABEL"), 410, 62, "CENTER")
    frame.tableHeaders = { pathHeader, nameHeader, levelHeader, factionHeader }

    frame.rows = {}
    for index = 1, TELEPORTS_PER_PAGE do
        local button = UI:Button(frame, 456, 21, "", "normal", "LEFT")
        button:SetPoint("TOPLEFT", frame, "TOPLEFT", 22, -157 - (index - 1) * 22)
        button.aaeLabel:SetText("")
        local pathText = UI:Text(button, "", "small"); pathText:SetPoint("LEFT", button, "LEFT", 6, 0); pathText:SetWidth(150); pathText:SetJustifyH("LEFT"); pathText:SetTextColor(1.00,0.82,0.28); button.pathText=pathText
        local nameText = UI:Text(button, "", "small"); nameText:SetPoint("LEFT", button, "LEFT", 162, 0); nameText:SetWidth(146); nameText:SetJustifyH("LEFT"); nameText:SetTextColor(0.85,0.92,0.94); button.nameText=nameText
        local levelText = UI:Text(button, "", "small"); levelText:SetPoint("LEFT", button, "LEFT", 316, 0); levelText:SetWidth(68); levelText:SetJustifyH("CENTER"); levelText:SetTextColor(0.56,0.85,0.91); button.levelText=levelText
        local factionText = UI:Text(button, "", "small"); factionText:SetPoint("LEFT", button, "LEFT", 388, 0); factionText:SetWidth(62); factionText:SetJustifyH("CENTER"); button.factionText=factionText
        button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
        button:SetScript("OnClick", function(self, mouseButton)
            local row = self.aaeTeleport
            if not row then return end
            if mouseButton == "RightButton" then A:ToggleTeleportFavorite(row)
            else A:RunTeleportRow(row) end
        end)
        button:SetScript("OnEnter", function(self)
            local row = self.aaeTeleport
            if not row then return end
            self:SetBackdropColor(0.055, 0.12, 0.15, 0.96)
            UI:ShowHint(self, A:TranslateLabel(tostring(row.name_ko or A:L("UNKNOWN"))), teleportTooltipLines(row))
        end)
        button:SetScript("OnLeave", function(self) UI:ApplyStyle(self, "normal"); GameTooltip:Hide() end)
        frame.rows[index] = button
    end

    local previous = UI:Button(frame, 85, 23, "◀ " .. self:L("PREVIOUS"), "utility")
    previous:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 22, 20)
    previous:SetScript("OnClick", function() if frame.page > 1 then frame.page = frame.page - 1; A:RefreshTeleportWindow() end end)
    frame.previous = previous
    local nextButton = UI:Button(frame, 85, 23, self:L("NEXT") .. " ▶", "utility")
    nextButton:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -22, 20)
    nextButton:SetScript("OnClick", function()
        local maxPage = math.max(1, math.ceil(table.getn(frame.matches or {}) / pageSize(frame)))
        if frame.page < maxPage then frame.page = frame.page + 1; A:RefreshTeleportWindow() end
    end)
    frame.next = nextButton
    local pageText = UI:Text(frame, "", "small")
    pageText:SetWidth(280); pageText:SetJustifyH("CENTER"); pageText:SetPoint("BOTTOM", frame, "BOTTOM", 0, 25)
    frame.pageText = pageText

    frame.page = 1
    frame.category = "all"
    frame.serverCheck:SetChecked(self:GetDB().teleportFullCatalog ~= false)
    frame.progressCheck:SetChecked(self:GetDB().teleportProgressOnly == true)
    self:RefreshTeleportRegionDropdown()
    UI:BindMouseWheel(frame, previous, nextButton)
    self.teleportFrame = frame
    self:RefreshTeleportWindow()
end

function A:IsTeleportUsable(row) return isTeleportUsable(row) end
function A:AvailableServerTeleportCount() return availableServerTeleportCount() end

function A:OpenTeleportWindow()
    if not self.teleportFrame then self:CreateTeleportWindow() end
    self.teleportFrame.page = self.teleportFrame.page or 1
    self:RefreshTeleportWindow()
    UI:ShowWindow(self.teleportFrame)
end

function A:ToggleTeleportWindow()
    if not self.teleportFrame then self:CreateTeleportWindow() end
    if self.teleportFrame:IsShown() then self.teleportReturn=nil;self.teleportFrame:Hide() else self:OpenTeleportWindow() end
end

local function favoriteMatches(frame)
    local query = string.lower(A:Trim(frame.search:GetText()))
    local favorites = normalizeFavorites()
    local rows, seen = {}, {}
    local function add(row)
        if not isTeleportUsable(row) then return end
        local key = teleportKey(row)
        if key == "" or not favorites[key] or seen[key] then return end
        local hay = string.lower(tostring(row.name or "") .. " " .. tostring(row.name_ko or "") .. " " .. tostring(row.zone_ko or "") .. " " .. tostring(row.region_ko or ""))
        if query == "" or string.find(hay, query, 1, true) then seen[key] = true; table.insert(rows, row) end
    end
    for _, row in ipairs(A.Data.teleports or {}) do add(A.Data:EnrichTeleport(row, false)) end
    for _, row in ipairs(A.Data.Teleports or {}) do add(A.Data:EnrichTeleport(row, true)) end
    table.sort(rows, function(left, right)
        local a = tostring(left.region_ko or "") .. tostring(left.zone_ko or "") .. tostring(left.name_ko or left.name)
        local b = tostring(right.region_ko or "") .. tostring(right.zone_ko or "") .. tostring(right.name_ko or right.name)
        return a < b
    end)
    return rows
end

function A:RefreshTeleportFavoritesWindow()
    local frame = self.teleportFavoritesFrame
    if not frame then return end
    local matches = favoriteMatches(frame)
    frame.matches = matches
    local count = table.getn(matches)
    local pages = math.max(1, math.ceil(count / FAVORITES_PER_PAGE))
    frame.page = math.max(1, math.min(frame.page or 1, pages))
    local first = (frame.page - 1) * FAVORITES_PER_PAGE + 1
    for index = 1, FAVORITES_PER_PAGE do
        local row = matches[first + index - 1]
        local button = frame.rows[index]
        button.aaeTeleport = row
        if row then button:SetText(teleportLabel(row, true)); button:Show() else button:Hide() end
    end
    if count == 0 then frame.empty:SetText(self:L("NO_TELEPORT_FAVORITES")); frame.empty:Show() else frame.empty:Hide() end
    frame.pageText:SetText(count .. " " .. self:L("FAVORITES") .. "   ·   " .. frame.page .. " / " .. pages)
    UI:SetEnabled(frame.previous, frame.page > 1)
    UI:SetEnabled(frame.next, frame.page < pages)
end

function A:CreateTeleportFavoritesWindow()
    if self.teleportFavoritesFrame then return end
    local frame = UI:CreateWindow("teleport_favorites", self:L("TELEPORT_FAVORITES"), 520, 500)
    frame.aaeTitle:ClearAllPoints(); frame.aaeTitle:SetPoint("TOPLEFT", frame, "TOPLEFT", 54, -17)
    local icon = frame:CreateTexture(nil, "ARTWORK")
    icon:SetTexture("Interface\\Icons\\INV_Misc_Note_01"); icon:SetWidth(32); icon:SetHeight(32); icon:SetPoint("TOPLEFT", frame, "TOPLEFT", 14, -9)
    local hint = UI:Text(frame, self:L("TELEPORT_FAVORITE_WINDOW_HINT"), "small")
    hint:SetPoint("TOPLEFT", frame, "TOPLEFT", 18, -47); hint:SetTextColor(0.55, 0.88, 0.92)
    local search = UI:EditBox(frame, 385, 23, "AzerothAdminAC335TeleportFavoriteSearch")
    search:SetPoint("TOPLEFT", frame, "TOPLEFT", 20, -70); frame.search = search
    local go = UI:Button(frame, 72, 23, self:L("SEARCH"), "utility")
    go:SetPoint("LEFT", search, "RIGHT", 8, 0); go:SetScript("OnClick", function() frame.page=1; A:RefreshTeleportFavoritesWindow() end)
    search:SetScript("OnTextChanged", function() frame.page=1; A:RefreshTeleportFavoritesWindow() end)
    search:SetScript("OnEnterPressed", function(self) self:ClearFocus(); frame.page=1; A:RefreshTeleportFavoritesWindow() end)

    frame.rows = {}
    for index = 1, FAVORITES_PER_PAGE do
        local button = UI:Button(frame, 476, 25, "", "normal", "LEFT")
        button:SetPoint("TOPLEFT", frame, "TOPLEFT", 22, -105 - (index - 1) * 28)
        button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
        button:SetScript("OnClick", function(self, mouseButton)
            if not self.aaeTeleport then return end
            if mouseButton == "RightButton" then A:ToggleTeleportFavorite(self.aaeTeleport)
            else A:RunTeleportRow(self.aaeTeleport) end
        end)
        button:SetScript("OnEnter", function(self)
            if self.aaeTeleport then UI:ShowHint(self, A:TranslateLabel(self.aaeTeleport.name_ko or A:L("UNKNOWN")), teleportTooltipLines(self.aaeTeleport)) end
        end)
        button:SetScript("OnLeave", function() GameTooltip:Hide() end)
        frame.rows[index] = button
    end
    local empty = UI:Text(frame, "", "normal")
    empty:SetWidth(470); empty:SetJustifyH("CENTER"); empty:SetPoint("CENTER", frame, "CENTER", 0, 20); empty:SetTextColor(0.65,0.72,0.76)
    frame.empty = empty

    local previous = UI:Button(frame, 85, 23, "◀ " .. self:L("PREVIOUS"), "utility")
    previous:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 22, 20); frame.previous=previous
    previous:SetScript("OnClick", function() if frame.page>1 then frame.page=frame.page-1; A:RefreshTeleportFavoritesWindow() end end)
    local nextButton = UI:Button(frame, 85, 23, self:L("NEXT") .. " ▶", "utility")
    nextButton:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -22, 20); frame.next=nextButton
    nextButton:SetScript("OnClick", function()
        local pages=math.max(1,math.ceil(table.getn(frame.matches or {})/FAVORITES_PER_PAGE))
        if frame.page<pages then frame.page=frame.page+1; A:RefreshTeleportFavoritesWindow() end
    end)
    local pageText=UI:Text(frame,"","small"); pageText:SetWidth(250); pageText:SetJustifyH("CENTER"); pageText:SetPoint("BOTTOM",frame,"BOTTOM",0,25); frame.pageText=pageText
    frame.page=1
    UI:BindMouseWheel(frame,previous,nextButton)
    self.teleportFavoritesFrame=frame
end

function A:OpenTeleportFavoritesWindow()
    if not self.teleportFavoritesFrame then self:CreateTeleportFavoritesWindow() end
    self.teleportFavoritesFrame.page=1
    self:RefreshTeleportFavoritesWindow()
    UI:ShowWindow(self.teleportFavoritesFrame)
end

function A:ToggleFavoriteWindow()
    if not self.teleportFavoritesFrame then self:CreateTeleportFavoritesWindow() end
    if self.teleportFavoritesFrame:IsShown() then self.teleportFavoritesFrame:Hide() else self:OpenTeleportFavoritesWindow() end
end

-- Exposed for R7 regression tests and other modules.
A.GetTeleportFaction = teleportFaction
A.GetTeleportLevelRange = levelRange
A.TeleportMatchesProgress = matchesProgress
