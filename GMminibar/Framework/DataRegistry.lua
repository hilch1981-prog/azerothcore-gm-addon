local A = AzerothAdminAC335
A.Data = A.Data or {}
local D = A.Data
D.itemSources = D.itemSources or {}
D.professions = D.professions or {}
D.teleports = D.teleports or {}
D.teleportMeta = D.teleportMeta or {}
D.teleportDbNames = D.teleportDbNames or {}
D.questLocations = D.questLocations or {}
D.databaseCatalog = D.databaseCatalog or {}
D.professionDetails = D.professionDetails or {}
D.legacyItemCategories = D.legacyItemCategories or { entries = {}, categories = {} }
D.provenance = D.provenance or {}
D._generatedIdIndex = D._generatedIdIndex or {}

local function lower(value)
    return string.lower(tostring(value or ""))
end

local function contains(value, query)
    return string.find(lower(value), lower(query), 1, true) ~= nil
end

function D:RegisterItemSources(values, provenance)
    self.itemSources = values or {}
    self.provenance.items = provenance
end

function D:RegisterProfessions(values, provenance)
    self.professions = values or {}
    self.provenance.professions = provenance
end

function D:RegisterTeleports(values, provenance)
    self.teleports = values or {}
    self.provenance.teleports = provenance
end

function D:RegisterTeleportMeta(values, provenance)
    self.teleportMeta = values or {}
    self.provenance.teleportMeta = provenance
end

function D:RegisterTeleportDbNames(values, provenance)
    self.teleportDbNames = values or {}
    self.provenance.teleportDbNames = provenance
end

function D:RegisterQuestLocations(values, provenance)
    self.questLocations = values or {}
    self.provenance.questLocations = provenance
end

function D:RegisterDatabaseCatalog(values, provenance)
    self.databaseCatalog = values or {}
    self.provenance.database = provenance
end

function D:RegisterProfessionDetails(values, provenance)
    self.professionDetails = values or {}
    self.provenance.professionDetails = provenance
end

function D:RegisterLegacyItemCategories(values, provenance)
    self.legacyItemCategories = values or { entries = {}, categories = {} }
    self.provenance.legacyItemCategories = provenance
end

function D:GetItemSource(id)
    return self.itemSources[tonumber(id)]
end

function D:GetProfession(id)
    return self.professions[tonumber(id)]
end

function D:GetProfessionDetail(spellID)
    return self.professionDetails[tonumber(spellID)]
end

function D:GetQuestLocation(questID)
    return self.questLocations[tonumber(questID)]
end

function D:GetTeleportMeta(id)
    return self.teleportMeta[tonumber(id)]
end

function D:GetLegacyItemCategory(key)
    local categories = self.legacyItemCategories and self.legacyItemCategories.categories or nil
    return categories and categories[tostring(key)] or nil
end

function D:CountTable(value)
    local count = 0
    for _ in pairs(value or {}) do count = count + 1 end
    return count
end

function D:CountItemSources()
    return self:CountTable(self.itemSources)
end

function D:CountProfessions()
    return self:CountTable(self.professions)
end

function D:CountQuestLocations()
    return self.questLocationCount or self:CountTable(self.questLocations)
end

function D:CountTeleportMeta()
    return self:CountTable(self.teleportMeta)
end

function D:GeneratedCount(kind)
    local source = self[kind]
    return type(source) == "table" and table.getn(source) or 0
end

function D:SearchItemSources(query, limit, offset)
    query = tostring(query or "")
    limit = math.max(1, tonumber(limit) or 12)
    offset = math.max(0, tonumber(offset) or 0)
    local numeric = tonumber(query)
    local ids = {}
    for id, info in pairs(self.itemSources) do
        local hit = (numeric and id == numeric) or query == ""
            or contains(info.category, query)
            or contains(info.section, query)
            or contains(info.raw, query)
        if hit then table.insert(ids, id) end
    end
    table.sort(ids)
    local out = {}
    for index = offset + 1, math.min(table.getn(ids), offset + limit) do
        local id = ids[index]
        table.insert(out, { id = id, info = self.itemSources[id] })
    end
    return out, table.getn(ids)
end

function D:SearchGenerated(kind, query, limit, offset)
    local source = self[kind]
    if type(source) ~= "table" then return {}, 0 end
    query = tostring(query or "")
    limit = math.max(1, tonumber(limit) or 12)
    offset = math.max(0, tonumber(offset) or 0)
    if kind == "Teleports" then
        local out, matched = {}, 0
        for _, row in ipairs(self:SearchTeleports(query, "server")) do
            if not row.disabled and (not A.IsTeleportUsable or A:IsTeleportUsable(row)) then
                matched = matched + 1
                if matched > offset and #out < limit then out[#out+1] = {row.id,row.name_ko or row.name,row.map,row.x,row.y,row.z} end
            end
        end
        return out, matched
    end
    local numeric = tonumber(query)
    local out = {}
    local matched = 0
    for _, row in ipairs(source) do
        local id = tonumber(row[1]) or 0
        local name = tostring(row[2] or "")
        if query == "" or (numeric and id == numeric) or contains(name, query) then
            matched = matched + 1
            if matched > offset and table.getn(out) < limit then table.insert(out, row) end
        end
    end
    return out, matched
end

function D:GetGeneratedIndex(kind)
    if self._generatedIdIndex[kind] then return self._generatedIdIndex[kind] end
    local index = {}
    local rows = self[kind]
    if type(rows) == "table" then
        for _, row in ipairs(rows) do
            local id = tonumber(row[1])
            if id then index[id] = row end
        end
    end
    self._generatedIdIndex[kind] = index
    return index
end

function D:GetGeneratedById(kind, id)
    id = tonumber(id)
    if not id then return nil end
    return self:GetGeneratedIndex(kind)[id]
end

function D:EnrichTeleport(row, fullCatalog)
    if row and row.targetKind then return row end
    if not row then return nil end
    self._teleportEnriched=self._teleportEnriched or {}
    local cached=self._teleportEnriched[row]
    local sourceMeta=self.teleportMeta[tonumber(row.id or row[1]) or 0]
    if cached and cached.meta==sourceMeta and cached.full==fullCatalog then return cached.value end
    local id, name, map, x, y, z, group, nameKo
    if row.id ~= nil then
        id, name, map, x, y, z = row.id, row.name, row.map, row.x, row.y, row.z
        group, nameKo = row.group, row.name_ko
    else
        id, name, map, x, y, z = row[1], row[2], row[3], row[4], row[5], row[6]
    end
    id = tonumber(id) or 0
    local meta = self.teleportMeta[id] or {}
    local value = {
        id = id,
        name = tostring(name or self.teleportDbNames[id] or ""),
        map = tonumber(map) or 0,
        x = tonumber(x) or 0,
        y = tonumber(y) or 0,
        z = tonumber(z) or 0,
        group = meta.group or group or "zone",
        name_ko = meta.name_ko or nameKo,
        zone_ko = meta.zone_ko,
        regionKey = meta.regionKey or "OTHER",
        faction = meta.faction,
        region_ko = meta.region_ko or "기타",
        levelText = meta.levelText or "권장 레벨 정보 없음",
        disabled = meta.disabled or self.teleportMeta[id] == nil,
        disableReason = meta.disableReason,
        fullCatalog = fullCatalog and true or false,
    }
    self._teleportEnriched[row]={meta=sourceMeta,full=fullCatalog,value=value}
    return value
end

function D:SearchTeleports(query, group)
    local out = {}
    query = tostring(query or "")
    local numeric = tonumber(query)
    if group == "server" and type(self.Teleports) == "table" then
        for _, source in ipairs(self.Teleports) do
            local row = self:EnrichTeleport(source, true)
            if query == "" or (numeric and numeric == row.id)
                or contains(row.name, query)
                or contains(row.name_ko, query)
                or contains(row.zone_ko, query)
                or contains(row.region_ko, query)
                or contains(row.levelText, query) then
                table.insert(out, row)
            end
        end
    else
        for _, source in ipairs(self.teleports) do
            local row = self:EnrichTeleport(source, false)
            if (not group or group == "all" or row.group == group)
                and (query == "" or (numeric and numeric == row.id)
                    or contains(row.name, query)
                    or contains(row.name_ko, query)
                    or contains(row.zone_ko, query)
                    or contains(row.region_ko, query)
                    or contains(row.levelText, query)) then
                table.insert(out, row)
            end
        end
    end
    table.sort(out, function(left, right)
        local a = tostring(left.region_ko or "") .. "\001" .. tostring(left.zone_ko or "") .. "\001" .. tostring(left.name_ko or left.name)
        local b = tostring(right.region_ko or "") .. "\001" .. tostring(right.zone_ko or "") .. "\001" .. tostring(right.name_ko or right.name)
        if a == b then return (tonumber(left.id) or 0) < (tonumber(right.id) or 0) end
        return a < b
    end)
    return out
end

function D:SearchDatabase(query, database)
    local out = {}
    query = tostring(query or "")
    for _, row in ipairs(self.databaseCatalog) do
        if (not database or database == "all" or row.database == database)
            and (query == "" or contains(row.name, query) or contains(row.description, query) or contains(row.database, query)) then
            table.insert(out, row)
        end
    end
    table.sort(out, function(left, right)
        if left.database == right.database then return left.name < right.name end
        return left.database < right.database
    end)
    return out
end
