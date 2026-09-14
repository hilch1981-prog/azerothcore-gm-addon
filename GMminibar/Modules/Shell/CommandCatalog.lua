-- Presentation-only catalog: definitions stay owned by each core's modules.
local A = AzerothAdminAC335
local C = {}
A.WorkbenchCatalog = C
local function identity(d)
    return table.concat({ d.command or "", d.action or "", d.lookupKind or "",
        d.requires or "", tostring(d.security or ""), tostring(d.requiredSecurity or ""), d.permissionCommand or "",
        tostring(d.confirm or d.dangerous or false), tostring(d.danger or false),
        d.afterCommand or "", d.promptKey or "" }, "\031")
end
function C:Identity(d) return identity(d) end
function C:Group(command, action)
    command = tostring(command or ""):gsub("^%.", "")
    local first = command:match("^(%S+)") or ""
    if first == "go" or first == "tele" or first == "appear" or first == "summon" or first == "recall" or first == "gps" then return "movement" end
    if first == "quest" or first == "additem" or first == "additemset" or first == "learn" or first == "unlearn" or first == "lookup" then return "content" end
    if first == "npc" or first == "gobject" or first == "gameobject" or first == "wp" or first == "event" or first == "pool" then return "world" end
    if first == "server" or first == "reload" or first == "ticket" or first == "ban" or first == "unban" or first == "account" then return "server" end
    if first == "modify" or first == "character" or first == "levelup" or first == "pinfo" or first == "group" or first == "reset" then return "character" end
    return "gm"
end
function C:Build(adapter)
    local entries, byIdentity = {}, {}
    for _, source in ipairs(adapter:Definitions()) do
        local d = source.definition
        local key = identity(d)
        local entry = byIdentity[key]
        if entry then
            entry.aliases = entry.aliases .. " " .. source.label .. " " .. source.category
            entry.originals[#entry.originals + 1] = d
            entry.aliasKeys[#entry.aliasKeys + 1] = source.key
        else
            entry = { definition = d, key = source.key, label = source.label,
                category = source.category, group = source.group,
                aliases = source.label .. " " .. source.category,
                originals = { d }, aliasKeys = { source.key } }
            entries[#entries + 1] = entry; byIdentity[key] = entry
        end
    end
    self.entries = entries
    self.byKey = {}
    for _, entry in ipairs(entries) do
        for _, key in ipairs(entry.aliasKeys) do self.byKey[key] = entry end
    end
    local pairsByBase = {}
    for _, entry in ipairs(entries) do
        local d = entry.definition
        local base, state = (d.command or ""):match("^(.-) (o[nf]+)$")
        if base and (state == "on" or state == "off") and not d.action then
            local pairKey = table.concat({ base, d.requires or "", tostring(d.security or ""), tostring(d.requiredSecurity or ""),
                tostring(d.confirm or d.dangerous or false), d.promptKey or "" }, "\031")
            local pair = pairsByBase[pairKey] or {}; pairsByBase[pairKey] = pair
            pair[state] = entry
        end
    end
    for _, pair in pairs(pairsByBase) do
        if pair.on and pair.off then
            pair.on.variants = { pair.on, pair.off }; pair.off.paired = pair.on
            pair.on.aliases = pair.on.aliases .. " " .. pair.off.aliases .. " " .. pair.off.definition.command
        end
    end
    return entries
end
function C:Filter(query, group, favorites, adapter)
    local result = {}
    query = string.lower(tostring(query or ""))
    for _, entry in ipairs(self.entries or {}) do
        local d = entry.definition
        local haystack = string.lower(entry.aliases .. " " .. (d.command or "") .. " " .. (d.hint or ""))
        local matches = true
        for word in string.gmatch(query, "%S+") do
            if not string.find(haystack, word, 1, true) then matches = false; break end
        end
        local isFavorite = adapter:IsFavorite(entry) or (entry.variants and adapter:IsFavorite(entry.variants[2]))
        if not entry.paired and matches and (not group or group == "all" or entry.group == group)
            and (not favorites or isFavorite) then result[#result + 1] = entry end
    end
    return result
end
