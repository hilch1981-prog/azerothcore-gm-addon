-- AzerothAdmin 3.5.0-335a profession-info UI contract, adapted to AC335 3.3.5a.
local A = AzerothAdminAC335
A.UI = type(A.UI) == "table" and A.UI or {}
local UI = A.UI
local PAGE_SIZE = 20
local function pageSize(frame) return math.max(1,math.min(PAGE_SIZE,math.floor((frame:GetHeight()-92-109-38)/34))) end
local PROFESSION_IDS = { 129, 164, 165, 171, 185, 186, 197, 202, 333, 755, 773 }
local PROFESSION_ICONS = {
    [129] = "Interface\\Icons\\Spell_Holy_SealOfSacrifice", [164] = "Interface\\Icons\\Trade_BlackSmithing",
    [165] = "Interface\\Icons\\Trade_LeatherWorking", [171] = "Interface\\Icons\\Trade_Alchemy",
    [185] = "Interface\\Icons\\INV_Misc_Food_15", [186] = "Interface\\Icons\\Trade_Mining",
    [197] = "Interface\\Icons\\Trade_Tailoring", [202] = "Interface\\Icons\\Trade_Engineering",
    [333] = "Interface\\Icons\\Trade_Engraving", [755] = "Interface\\Icons\\INV_Misc_Gem_01",
    [773] = "Interface\\Icons\\INV_Inscription_Tradeskill01",
}


-- InvenCraftInfo2 encodes requirements as skillCodeIndex * 1000 + requiredSkill.
local REQUIRE_SKILL_INDEX = {
    [1] = 185, [2] = 171, [3] = 197, [4] = 165, [5] = 164, [6] = 202,
    [7] = 333, [8] = 755, [9] = 773, [10] = 186, [11] = 129, [12] = 182, [13] = 393,
}
local TIER_ORDER = {
    { key = "APPRENTICE", minimum = 0, maximum = 74, label = "PROF_TIER_APPRENTICE" },
    { key = "JOURNEYMAN", minimum = 75, maximum = 149, label = "PROF_TIER_JOURNEYMAN" },
    { key = "EXPERT", minimum = 150, maximum = 224, label = "PROF_TIER_EXPERT" },
    { key = "ARTISAN", minimum = 225, maximum = 299, label = "PROF_TIER_ARTISAN" },
    { key = "MASTER", minimum = 300, maximum = 374, label = "PROF_TIER_MASTER" },
    { key = "GRAND_MASTER", minimum = 375, maximum = 450, label = "PROF_TIER_GRAND_MASTER" },
}

local function professionRequirement(spellID, fallbackProfessionID)
    local detail = (A.Data and A.Data:GetProfessionDetail(spellID)) or (A.AC335ProfessionDetails and A.AC335ProfessionDetails[tonumber(spellID)])
    local code = tonumber(detail and detail.requireCode) or 0
    local requiredProfessionID = REQUIRE_SKILL_INDEX[math.floor(code / 1000)] or tonumber(fallbackProfessionID) or 0
    return requiredProfessionID, code % 1000, code
end

local function tierForSkill(skill)
    skill = math.max(0, tonumber(skill) or 0)
    for _, tier in ipairs(TIER_ORDER) do
        if skill >= tier.minimum and skill <= tier.maximum then return tier end
    end
    return TIER_ORDER[table.getn(TIER_ORDER)]
end

local function professionNameMatches(professionID, name)
    name = string.lower(tostring(name or "")):gsub("[%s%p]", "")
    if name == "" then return false end
    local info = A.Data and A.Data:GetProfession(professionID) or nil
    local commands=A.ProfessionCommandNames or {}
    for _, candidate in pairs({ info and info.name, info and info.name_ko, commands.enUS and commands.enUS[professionID], commands.koKR and commands.koKR[professionID] }) do
        candidate = string.lower(tostring(candidate or "")):gsub("[%s%p]", "")
        if candidate ~= "" and (name == candidate or string.find(name, candidate, 1, true) or string.find(candidate, name, 1, true)) then return true end
    end
    return false
end

local function playerProfessionState(professionID, force)
    professionID = tonumber(professionID) or 0
    A.professionSkillStateCache = A.professionSkillStateCache or {}
    if not force and A.professionSkillStateCache[professionID] then return A.professionSkillStateCache[professionID] end
    local state = { known = false, current = 0, maximum = 0, id = professionID }
    if GetProfessions and GetProfessionInfo then
        local p1, p2, archaeology, fishing, cooking, firstAid = GetProfessions()
        local slots = { p1, p2, archaeology, fishing, cooking, firstAid }
        for slot = 1, 6 do
            local index = slots[slot]
            if index then
                local ok, name, _, rank, maxRank, _, _, skillLine = pcall(GetProfessionInfo, index)
                if ok and (tonumber(skillLine) == professionID or professionNameMatches(professionID, name)) then
                    state.known = true; state.current = tonumber(rank) or 0; state.maximum = tonumber(maxRank) or 0
                    break
                end
            end
        end
    end
    if not state.known and GetNumSkillLines and GetSkillLineInfo then
        for index = 1, (GetNumSkillLines() or 0) do
            local ok, name, isHeader, _, rank, _, modifier, maxRank = pcall(GetSkillLineInfo, index)
            if ok and not isHeader and professionNameMatches(professionID, name) then
                state.known = true; state.current = tonumber(rank) or 0; state.maximum = tonumber(maxRank) or 0
                break
            end
        end
    end
    A.professionSkillStateCache[professionID] = state
    return state
end

function A.GetPlayerProfessionState(selfOrID,idOrForce,force)
 if type(selfOrID)=='table'then return playerProfessionState(idOrForce,force)end
 return playerProfessionState(selfOrID,idOrForce)
end
A.ProfessionTierOrder=TIER_ORDER
local function lower(value) return string.lower(tostring(value or "")) end
local function contains(value, query)
    query = lower(query)
    if query == "" then return true end
    return string.find(lower(value), query, 1, true) ~= nil
end

local function itemIDFromLink(link)
    return type(link) == "string" and tonumber(string.match(link, "item:(%d+)")) or nil
end

local function generatedItem(id)
    return A.Data and A.Data:GetGeneratedById("Items", tonumber(id)) or nil
end

local function itemName(id)
    id = tonumber(id)
    if not id then return A:L("UNKNOWN") end
    if GetItemInfo then
        local name = GetItemInfo(id)
        if name and name ~= "" then return name end
    end
    local row = generatedItem(id)
    return (row and row[2]) or (A:L("ITEM") .. " " .. tostring(id))
end

local function itemTexture(id)
    id = tonumber(id)
    if not id then return "Interface\\Icons\\INV_Misc_QuestionMark" end
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

local function itemLink(id)
    id = tonumber(id)
    if not id then return nil end
    if GetItemInfo then
        local _, link = GetItemInfo(id)
        if link then return link end
    end
    return "|cffffffff|Hitem:" .. tostring(id) .. ":0:0:0:0:0:0:0:80|h[" .. itemName(id) .. "]|h|r"
end

A.professionSpellInfoCache = A.professionSpellInfoCache or {}
A.professionKnownCache = A.professionKnownCache or {}
A.professionKnownSpellbook = A.professionKnownSpellbook or nil
A.professionRecipeCache = A.professionRecipeCache or {}
A.professionDisplayGeneration = A.professionDisplayGeneration or 1
A.professionWarmupStarted = A.professionWarmupStarted or false
A.professionWarmupComplete = A.professionWarmupComplete or false

local function configuredLocale()
    if A.GetConfiguredLocale then return A:GetConfiguredLocale() end
    return GetLocale and GetLocale() or "enUS"
end

local function persistentSpellCache()
    local db = A:GetDB()
    db.professionSpellCache = type(db.professionSpellCache) == "table" and db.professionSpellCache or {}
    local locale = configuredLocale()
    db.professionSpellCache[locale] = type(db.professionSpellCache[locale]) == "table" and db.professionSpellCache[locale] or {}
    return db.professionSpellCache[locale]
end

local function spellInfo(spellID, force)
    spellID = tonumber(spellID) or 0
    local cache = A.professionSpellInfoCache
    if not force and cache[spellID] then
        local value = cache[spellID]
        return value.name, value.rank, value.icon
    end

    local persisted = persistentSpellCache()[spellID]
    if not force and type(persisted) == "table" and persisted.name and persisted.name ~= "" then
        cache[spellID] = { name = persisted.name, rank = persisted.rank, icon = persisted.icon }
        return persisted.name, persisted.rank, persisted.icon
    end

    local name, rank, icon
    if GetSpellInfo then
        local ok, a, b, c = pcall(GetSpellInfo, spellID)
        if ok then name, rank, icon = a, b, c end
    end
    if (not icon or icon == "") and GetSpellTexture then
        local ok, texture = pcall(GetSpellTexture, spellID)
        if ok then icon = texture end
    end
    if name == "" then name = nil end
    if icon == "" then icon = nil end

    local detail = (A.Data and A.Data:GetProfessionDetail(spellID))
        or (A.AC335ProfessionDetails and A.AC335ProfessionDetails[spellID])
    if detail and detail.createdItem then
        if not name then name = itemName(detail.createdItem) end
        if not icon or icon == "Interface\\Icons\\INV_Misc_QuestionMark" then
            icon = itemTexture(detail.createdItem)
        end
    end

    local value = {
        name = name or (A:L("SPELL") .. " " .. tostring(spellID)),
        rank = rank,
        icon = icon or "Interface\\Icons\\INV_Misc_QuestionMark",
    }
    cache[spellID] = value
    persistentSpellCache()[spellID] = { name = value.name, rank = value.rank, icon = value.icon }
    return value.name, value.rank, value.icon
end

local function recipeResultIcon(recipe)
    if not recipe then return "Interface\\Icons\\INV_Misc_QuestionMark" end
    local detail = (A.Data and A.Data:GetProfessionDetail(recipe.spellID))
        or (A.AC335ProfessionDetails and A.AC335ProfessionDetails[tonumber(recipe.spellID)])
    local outputID = tonumber(detail and detail.createdItem)
    if outputID then
        local texture = itemTexture(outputID)
        if texture and texture ~= "Interface\\Icons\\INV_Misc_QuestionMark" then return texture, outputID end
    end
    local _, _, spellIcon = spellInfo(recipe.spellID)
    if spellIcon and spellIcon ~= "" then return spellIcon, outputID end
    return PROFESSION_ICONS[recipe.professionID] or "Interface\\Icons\\INV_Misc_QuestionMark", outputID
end

local function spellLink(spellID)
    if GetSpellLink then
        local link = GetSpellLink(spellID)
        if link then return link end
    end
    return "|cff71d5ff|Hspell:" .. tostring(spellID) .. "|h[" .. (select(1, spellInfo(spellID))) .. "]|h|r"
end

local function recipeSpellIDFromLink(link)
    if type(link) ~= "string" then return nil end
    return tonumber(string.match(link, "enchant:(%d+)")) or tonumber(string.match(link, "spell:(%d+)"))
end

local function buildKnownSpellbook()
    if A.professionKnownSpellbook then return A.professionKnownSpellbook end
    local known = {}
    if GetNumSpellTabs and GetSpellTabInfo and GetSpellLink then
        for tab = 1, (GetNumSpellTabs() or 0) do
            local _, _, offset, count = GetSpellTabInfo(tab)
            offset = tonumber(offset) or 0
            count = tonumber(count) or 0
            for slot = offset + 1, offset + count do
                local ok, link = pcall(GetSpellLink, slot, BOOKTYPE_SPELL)
                local id = ok and type(link) == "string" and tonumber(string.match(link, "spell:(%d+)")) or nil
                if id then known[id] = true end
            end
        end
    end
    A.professionKnownSpellbook = known
    return known
end

local function isKnownSpell(spellID)
    spellID = tonumber(spellID) or 0
    if A.PlayerActions and A.PlayerActions:Known(spellID)then return true end
    local cached = A.professionKnownCache[spellID]
    if cached ~= nil then return cached end

    local known = false
    local directCheckSucceeded = false
    if IsSpellKnown then
        local ok, value = pcall(IsSpellKnown, spellID)
        if ok then
            directCheckSucceeded = true
            known = value and true or false
        end
    end
    if not known and IsPlayerSpell then
        local ok, value = pcall(IsPlayerSpell, spellID)
        if ok then
            directCheckSucceeded = true
            known = value and true or false
        end
    end

    -- AC335's direct APIs return a definitive false for unknown recipes. The
    -- old fallback scanned the entire spellbook on the first unknown row,
    -- causing the one-time hitch seen while changing profession tabs.
    if not directCheckSucceeded then
        known = buildKnownSpellbook()[spellID] and true or false
    end
    A.professionKnownCache[spellID] = known
    return known
end

local function invalidateKnownCache()
    A.professionKnownCache = {}
    A.professionKnownSpellbook = nil
end


local function canLearnRecipe(recipe)
    if not recipe then return false, A:L("PROF_LEARN_NO_RECIPE") end
    if isKnownSpell(recipe.spellID) then return false, A:L("PROF_LEARN_ALREADY_KNOWN") end
    if not A:CanRunCommand("learn") then return false, A:L("PROF_LEARN_NO_PERMISSION") end
    local requiredProfessionID = tonumber(recipe.requiredProfessionID) or tonumber(recipe.professionID) or 0
    local requiredSkill = tonumber(recipe.requiredSkill) or 0
    local state = playerProfessionState(requiredProfessionID)
    if not state.known then return false, A:L("PROF_LEARN_PROFESSION_MISSING") end
    if state.current < requiredSkill then return false, A:L("PROF_LEARN_SKILL_LOW", state.current, requiredSkill) end
    return true, A:L("PROF_LEARN_READY", state.current, requiredSkill)
end

local function getLiveRecipe(spellID, spellName)
    if not GetNumTradeSkills or not GetTradeSkillInfo then return nil end
    local count = GetNumTradeSkills() or 0
    for index = 1, count do
        local name, skillType = GetTradeSkillInfo(index)
        if skillType ~= "header" then
            local recipeLink = GetTradeSkillRecipeLink and GetTradeSkillRecipeLink(index) or nil
            local liveSpellID = recipeSpellIDFromLink(recipeLink)
            if liveSpellID == tonumber(spellID) or (spellName and name == spellName) then
                local outputLink = GetTradeSkillItemLink and GetTradeSkillItemLink(index) or nil
                local outputID = itemIDFromLink(outputLink)
                local reagents = {}
                local reagentCount = GetTradeSkillNumReagents and (GetTradeSkillNumReagents(index) or 0) or 0
                for reagentIndex = 1, reagentCount do
                    local reagentName, texture, needed, have = GetTradeSkillReagentInfo(index, reagentIndex)
                    local reagentLink = GetTradeSkillReagentItemLink and GetTradeSkillReagentItemLink(index, reagentIndex) or nil
                    table.insert(reagents, {
                        name = reagentName or A:L("UNKNOWN"), texture = texture, needed = tonumber(needed) or 1,
                        have = tonumber(have), link = reagentLink, id = itemIDFromLink(reagentLink),
                    })
                end
                return { outputLink = outputLink, outputID = outputID, reagents = reagents, tradeSkillIndex = index }
            end
        end
    end
    return nil
end

local function getStaticRecipe(spellID)
    local detail = (A.Data and A.Data:GetProfessionDetail(spellID)) or (A.AC335ProfessionDetails and A.AC335ProfessionDetails[tonumber(spellID)])
    if type(detail) ~= "table" then return nil end
    local reagents = {}
    for _, source in ipairs(detail.reagents or {}) do
        local id = tonumber(source.id)
        if id then
            table.insert(reagents, {
                id = id,
                name = itemName(id),
                texture = itemTexture(id),
                needed = math.max(1, tonumber(source.count) or 1),
                have = GetItemCount and (GetItemCount(id) or 0) or 0,
                link = itemLink(id),
            })
        end
    end
    local outputID = tonumber(detail.createdItem)
    return {
        outputID = outputID,
        outputLink = outputID and itemLink(outputID) or nil,
        outputName = outputID and itemName(outputID) or nil,
        outputTexture = outputID and itemTexture(outputID) or nil,
        outputCount = math.max(1, tonumber(detail.createdCount) or 1),
        reagents = reagents,
        tool = detail.tool,
        requireCode = detail.requireCode,
        difficulty = detail.difficulty,
        source = "InvenCraftInfo2 v4.0 offline metadata",
    }
end


local function flattenProfession(profession)
    if type(profession) ~= "table" then return {} end
    local professionID = tonumber(profession.id) or 0
    local cached = A.professionRecipeCache[professionID]
    if cached then return cached end
    local recipes = {}
    for categoryIndex, category in ipairs(profession.categories or {}) do
        for spellIndex, spellID in ipairs(category.spells or {}) do
            local requiredProfessionID, requiredSkill, requireCode = professionRequirement(spellID, professionID)
            local tier = tierForSkill(requiredSkill)
            table.insert(recipes, {
                spellID = tonumber(spellID),
                name = nil,
                icon = PROFESSION_ICONS[professionID] or "Interface\\Icons\\INV_Misc_QuestionMark",
                category = category.name or A:L("OTHER"),
                categoryCode = tonumber(category.code) or 0,
                categoryIndex = categoryIndex,
                spellIndex = spellIndex,
                professionID = professionID,
                requiredProfessionID = requiredProfessionID, requiredSkill = requiredSkill, requireCode = requireCode,
                tierKey = tier.key, tierLabelKey = tier.label,
                profession = profession,
                displayGeneration = 0,
            })
        end
    end
    A.professionRecipeCache[professionID] = recipes
    return recipes
end

local function resolveRecipeDisplay(recipe, force)
    if not recipe then return nil end
    if not force and recipe.displayGeneration == A.professionDisplayGeneration and recipe.name then return recipe end
    local name = select(1, spellInfo(recipe.spellID, force))
    recipe.name = name
    recipe.icon = recipeResultIcon(recipe)
    recipe.displayGeneration = A.professionDisplayGeneration
    return recipe
end

function A:ResetProfessionLocaleCache()
    self.professionSpellInfoCache = {}
    self.professionDisplayGeneration = (self.professionDisplayGeneration or 1) + 1
    self.professionWarmupStarted = false
    self.professionWarmupComplete = false
    self.professionWarmupSerial = (self.professionWarmupSerial or 0) + 1
    for _, recipes in pairs(self.professionRecipeCache or {}) do
        for _, recipe in ipairs(recipes or {}) do
            recipe.name = nil
            recipe.displayGeneration = 0
        end
    end
    if self.professionFrame and self.professionFrame.selectedProfession then
        self:BuildProfessionFilter(true)
    end
    self:PrimeProfessionCaches()
end

function A:PrimeProfessionCaches()
    if self.professionWarmupStarted or self:GetDB().professionWarmup == false then return end
    self.professionWarmupStarted = true
    self.professionWarmupSerial = (self.professionWarmupSerial or 0) + 1
    local serial = self.professionWarmupSerial
    local queue = {}
    for _, professionID in ipairs(PROFESSION_IDS) do
        local profession = self.Data:GetProfession(professionID) or (self.AC335Professions and self.AC335Professions[professionID])
        if type(profession) == "table" then
            profession.id = tonumber(professionID)
            local recipes = flattenProfession(profession)
            for index = 1, math.min(PAGE_SIZE, table.getn(recipes)) do
                table.insert(queue, recipes[index])
            end
        end
    end

    local cursor = 1
    local function warmChunk()
        if serial ~= A.professionWarmupSerial then return end
        local stop = math.min(table.getn(queue), cursor + 1)
        while cursor <= stop do
            local recipe = queue[cursor]
            resolveRecipeDisplay(recipe)
            isKnownSpell(recipe.spellID)
            cursor = cursor + 1
        end
        if cursor <= table.getn(queue) then
            A:RunAfter(0.02, warmChunk)
        else
            A.professionWarmupComplete = true
            A:Debug("Profession first-page cache warmup complete: " .. tostring(table.getn(queue)))
        end
    end
    self:RunAfter(0.20, warmChunk)
end

local function sortRecipes(frame)
    table.sort(frame.filteredRecipes, function(left, right)
        if frame.sortMode == "name" then
            resolveRecipeDisplay(left)
            resolveRecipeDisplay(right)
            local a, b = lower(left.name), lower(right.name)
            if a ~= b then return a < b end
        elseif frame.sortMode == "known" then
            local ak, bk = isKnownSpell(left.spellID), isKnownSpell(right.spellID)
            if ak ~= bk then return ak end
        elseif frame.sortMode == "skill" then
            if (left.requiredSkill or 0) ~= (right.requiredSkill or 0) then return (left.requiredSkill or 0) < (right.requiredSkill or 0) end
            if left.categoryIndex ~= right.categoryIndex then return left.categoryIndex < right.categoryIndex end
        else
            local lt, rt = tierForSkill(left.requiredSkill), tierForSkill(right.requiredSkill)
            if lt.minimum ~= rt.minimum then return lt.minimum < rt.minimum end
            if left.categoryIndex ~= right.categoryIndex then return left.categoryIndex < right.categoryIndex end
            if left.spellIndex ~= right.spellIndex then return left.spellIndex < right.spellIndex end
        end
        return (left.spellID or 0) < (right.spellID or 0)
    end)
end

function A:BuildProfessionFilter(preservePage)
    local frame = self.professionFrame
    if not frame or not frame.selectedProfession then return end
    local query = self:Trim(frame.searchBox:GetText())
    local numericQuery = tonumber(query)
    local category = frame.categoryFilter or "ALL"
    local tierFilter = frame.tierFilter or "ALL"
    local knownOnly = frame.knownOnly:GetChecked() and true or false
    local savedPage = preservePage and (tonumber(frame.page) or 1) or 1
    frame.filteredRecipes = {}
    for _, recipe in ipairs(frame.allRecipes or {}) do
        local include = (category == "ALL" or recipe.category == category)
            and (tierFilter == "ALL" or recipe.tierKey == tierFilter)
        if include and query ~= "" then
            if numericQuery then
                include = numericQuery == recipe.spellID
            elseif contains(recipe.category, query) then
                include = true
            else
                resolveRecipeDisplay(recipe)
                include = contains(recipe.name, query)
            end
        end
        if include and knownOnly then include = isKnownSpell(recipe.spellID) end
        if include and frame.hideKnown and frame.hideKnown:GetChecked()then include=not isKnownSpell(recipe.spellID)end
        if include then table.insert(frame.filteredRecipes, recipe) end
    end
    sortRecipes(frame)
    frame.page = savedPage
    self:RefreshProfessionRows()
end

function A:RefreshProfessionCategoryDropdown()
    local frame = self.professionFrame
    if not frame then return end
    if UIDropDownMenu_SetText then UIDropDownMenu_SetText(frame.categoryDropdown, frame.categoryFilter == "ALL" and self:L("ALL_CATEGORIES") or frame.categoryFilter) end
end


function A:RefreshProfessionTierDropdown()
    local frame = self.professionFrame
    if not frame or not frame.tierDropdown then return end
    local label = self:L("ALL_TIERS")
    if frame.tierFilter and frame.tierFilter ~= "ALL" then
        for _, tier in ipairs(TIER_ORDER) do if tier.key == frame.tierFilter then label = self:L(tier.label) break end end
    end
    if UIDropDownMenu_SetText then UIDropDownMenu_SetText(frame.tierDropdown, label) end
end

function A:RefreshProfessionSkillButtons(force)
    local frame = self.professionFrame
    if not frame then return end
    if force then self.professionSkillStateCache = {} end
    for _, button in ipairs(frame.professionButtons or {}) do
        local state = playerProfessionState(button.professionID, force)
        local suffix = state.known and self:L("PROF_SKILL_SHORT", state.current, state.maximum) or self:L("PROF_NOT_LEARNED_SHORT")
        button:SetText(tostring(button.baseLabel or button.professionID) .. "  |cff6fcfe8" .. suffix .. "|r")
    end
end

function A:SelectProfession(professionID)
    local frame = self.professionFrame
    if not frame then return end
    local profession = self.Data:GetProfession(professionID) or (self.AC335Professions and self.AC335Professions[professionID])
    if type(profession) ~= "table" then return end
    profession.id = tonumber(professionID)
    frame.selectedProfession = profession
    frame.allRecipes = flattenProfession(profession)
    frame.categoryFilter = "ALL"
    frame.tierFilter = "ALL"
    frame.searchBox:SetText("")
    self:RefreshProfessionCategoryDropdown()
    self:RefreshProfessionTierDropdown()
    self:RefreshProfessionSkillButtons(false)
    for _, button in ipairs(frame.professionButtons) do UI:SetActive(button, button.professionID == professionID) end
    self:ClearProfessionDetail()
    self:BuildProfessionFilter()
end

function A:ClearProfessionDetail()
    local frame = self.professionFrame
    if not frame then return end
    frame.selectedRecipe = nil; frame.selectedSpellID = nil; frame.liveRecipe = nil; frame.staticRecipe = nil; frame.resolvedRecipe = nil
    frame.outputButton.icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
    frame.outputButton.name:SetText(self:L("SELECT_RECIPE")); frame.outputButton.name:SetTextColor(1, 0.82, 0.18)
    frame.outputButton.meta:SetText(""); frame.outputButton.clickHint:SetText(self:L("RECIPE_OUTPUT_HINT"))
    frame.sourceText:SetText(self:L("PROFESSION_SOURCE_NOTE"))
    frame.learnButton.recipe = nil; frame.unlearnButton.recipe = nil
    UI:SetEnabled(frame.learnButton, false); UI:SetEnabled(frame.unlearnButton, false)
    frame.noReagentText:SetText(self:L("SELECT_RECIPE_REAGENTS")); frame.noReagentText:Show()
    for _, button in ipairs(frame.reagentButtons) do button.reagent = nil; button:Hide() end
end

local function reagentVisualState(reagent)
    local have = tonumber(reagent and reagent.have)
    local needed = math.max(1, tonumber(reagent and reagent.needed) or 1)
    if have == nil then return "unknown", 0, needed, needed end
    local missing = math.max(0, needed - have)
    if missing == 0 then return "ready", have, needed, 0 end
    if have > 0 then return "partial", have, needed, missing end
    return "missing", have, needed, missing
end

function A:ApplyProfessionReagentVisual(button, hovered)
    if not button or not button.reagent then return end
    local state, have, needed, missing = reagentVisualState(button.reagent)
    button.reagentState = state
    if state == "ready" then
        button:SetBackdropBorderColor(0.20, 0.85, 0.35, 1)
        button:SetBackdropColor(0.025, hovered and 0.16 or 0.09, 0.055, hovered and 0.98 or 0.90)
        button.name:SetTextColor(0.55, 1.00, 0.62)
        button.count:SetTextColor(0.45, 1.00, 0.52)
        button.count:SetText(self:L("REAGENT_COUNT_READY", have, needed))
    elseif state == "partial" then
        button:SetBackdropBorderColor(1.00, 0.68, 0.18, 1)
        button:SetBackdropColor(0.12, 0.075, 0.015, hovered and 0.98 or 0.90)
        button.name:SetTextColor(1.00, 0.84, 0.35)
        button.count:SetTextColor(1.00, 0.66, 0.22)
        button.count:SetText(self:L("REAGENT_COUNT_SHORT", have, needed, missing))
    elseif state == "missing" then
        button:SetBackdropBorderColor(0.95, 0.24, 0.22, 1)
        button:SetBackdropColor(0.13, 0.025, 0.025, hovered and 0.98 or 0.90)
        button.name:SetTextColor(1.00, 0.55, 0.50)
        button.count:SetTextColor(1.00, 0.32, 0.28)
        button.count:SetText(self:L("REAGENT_COUNT_SHORT", have, needed, missing))
    else
        button:SetBackdropBorderColor(0.34, 0.36, 0.34, 1)
        button:SetBackdropColor(0.020, 0.035, 0.045, hovered and 0.96 or 0.84)
        button.name:SetTextColor(0.92, 0.92, 0.92)
        button.count:SetTextColor(0.55, 0.88, 0.92)
        button.count:SetText(self:L("REAGENT_COUNT", have, needed))
    end
end

function A:SelectProfessionRecipe(recipe)
    local frame = self.professionFrame
    if not frame or not recipe then return end
    frame.selectedRecipe = recipe; frame.selectedSpellID = recipe.spellID
    local spellName, _, spellIcon = spellInfo(recipe.spellID)
    local known = isKnownSpell(recipe.spellID)
    local live = getLiveRecipe(recipe.spellID, spellName)
    local static = getStaticRecipe(recipe.spellID)
    local resolved = static or { reagents = {} }
    if live then
        if live.outputID then
            resolved.outputID = live.outputID
            resolved.outputLink = live.outputLink or itemLink(live.outputID)
            resolved.outputName = itemName(live.outputID)
            resolved.outputTexture = itemTexture(live.outputID)
        end
        if type(live.reagents) == "table" and table.getn(live.reagents) > 0 then resolved.reagents = live.reagents end
        resolved.tradeSkillIndex = live.tradeSkillIndex
        resolved.source = "AC335 client trade-skill API"
    end
    frame.liveRecipe = live; frame.staticRecipe = static; frame.resolvedRecipe = resolved

    local outputID = tonumber(resolved.outputID)
    frame.outputButton.icon:SetTexture((outputID and itemTexture(outputID)) or spellIcon)
    frame.outputButton.name:SetText((outputID and itemName(outputID)) or spellName)
    if known then frame.outputButton.name:SetTextColor(0.28, 0.68, 1.00) else frame.outputButton.name:SetTextColor(1.00, 0.82, 0.25) end
    local outputCount = tonumber(resolved.outputCount) or 1
    local skillState = playerProfessionState(recipe.requiredProfessionID or recipe.professionID)
    local tier = tierForSkill(recipe.requiredSkill)
    frame.outputButton.meta:SetText(recipe.category .. " · " .. self:L(tier.label)
        .. " · " .. self:L("PROF_REQUIRED_SKILL", recipe.requiredSkill or 0)
        .. " · Spell ID " .. tostring(recipe.spellID)
        .. (outputID and (" · Item " .. tostring(outputID) .. " x" .. tostring(outputCount)) or "")
        .. " · " .. self:L(known and "KNOWN" or "UNKNOWN_RECIPE"))
    frame.outputButton.clickHint:SetText(outputID and self:L("RECIPE_OUTPUT_ADD_HINT") or self:L("RECIPE_SPELL_LINK_HINT"))
    local sourceLine = ""
    if resolved.tool and resolved.tool ~= "" then sourceLine = self:L("TOOL_LABEL") .. ": " .. resolved.tool end
    frame.sourceText:SetText(sourceLine)
    frame.learnButton.recipe = recipe; frame.unlearnButton.recipe = recipe
    local canLearn, learnReason = canLearnRecipe(recipe)
    frame.learnButton.learnReason = learnReason
    UI:SetEnabled(frame.learnButton, canLearn)
    UI:SetEnabled(frame.unlearnButton, known and self:CanRunCommand("unlearn"))
    local statusLine = self:L("PROF_CURRENT_SKILL", skillState.current, skillState.maximum) .. " · " .. learnReason
    if sourceLine ~= "" then statusLine = sourceLine .. " · " .. statusLine end
    frame.sourceText:SetText(statusLine)

    local reagents = resolved.reagents or {}
    if table.getn(reagents) > 0 then
        frame.noReagentText:Hide()
        for index = 1, table.getn(frame.reagentButtons) do
            local button = frame.reagentButtons[index]
            local reagent = reagents[index]
            button.reagent = reagent
            if reagent then
                if reagent.have == nil and reagent.id and GetItemCount then reagent.have = GetItemCount(reagent.id) or 0 end
                button.icon:SetTexture(reagent.texture or (reagent.id and itemTexture(reagent.id)) or "Interface\\Icons\\INV_Misc_QuestionMark")
                button.name:SetText(reagent.name or (reagent.id and itemName(reagent.id)) or self:L("UNKNOWN"))
                button:Show()
                self:ApplyProfessionReagentVisual(button, false)
            else
                button.reagent = nil; button:Hide()
            end
        end
    else
        for _, button in ipairs(frame.reagentButtons) do button.reagent = nil; button:Hide() end
        frame.noReagentText:SetText(self:L("REAGENT_DATA_UNAVAILABLE")); frame.noReagentText:Show()
    end

    self:RefreshProfessionRows()
end

local function applyRecipeRowVisual(row, selected)
    local recipe = row and row.recipe
    if not recipe then return end
    if selected then
        row:SetBackdropColor(0.07, 0.11, 0.16, 0.98)
        row:SetBackdropBorderColor(0.20, 0.82, 0.88, 1)
    else
        UI:ApplyStyle(row, "normal")
    end
    if isKnownSpell(recipe.spellID) then
        row.aaeLabel:SetTextColor(0.25, 0.68, 1.00)
    else
        local canLearn = canLearnRecipe(recipe)
        if canLearn then row.aaeLabel:SetTextColor(0.92, 0.92, 0.92)
        else row.aaeLabel:SetTextColor(0.58, 0.58, 0.58) end
    end
end

function A:RefreshProfessionRows()
    local frame = self.professionFrame
    if not frame then return end
    local total = table.getn(frame.filteredRecipes or {})
    local perPage=pageSize(frame);frame.perPage=perPage
    local maxPage = math.max(1, math.ceil(total / perPage))
    frame.page = math.max(1, math.min(frame.page or 1, maxPage))
    local first = (frame.page - 1) * perPage + 1
    for index = 1, PAGE_SIZE do
        local row = frame.recipeRows[index]
        local recipe = index<=perPage and frame.filteredRecipes[first + index - 1] or nil
        row.recipe = recipe
        if recipe then
            local refreshedName = select(1, spellInfo(recipe.spellID))
            if refreshedName and refreshedName ~= "" then recipe.name = refreshedName end
            recipe.icon = recipeResultIcon(recipe)
            row:SetText(tostring(recipe.name or (A:L("SPELL") .. " " .. tostring(recipe.spellID))))
            row.indexText:SetText((isKnownSpell(recipe.spellID)and "|cff55bbff습득 완료|r · "or "")..self:L(recipe.tierLabelKey or "PROF_TIER_APPRENTICE") .. " · " .. tostring(recipe.requiredSkill or 0) .. " · " .. recipe.spellID)
            row.recipeIcon:SetTexture(recipe.icon or PROFESSION_ICONS[recipe.professionID]
                or "Interface\\Icons\\INV_Misc_QuestionMark")
            row:Show()
            applyRecipeRowVisual(row, recipe == frame.selectedRecipe)
        else
            row.recipe = nil
            row:Hide()
        end
    end
    frame.pageText:SetText(self:L("PROFESSION_PAGE_STATUS", total, frame.page, maxPage))
    UI:SetEnabled(frame.previous, frame.page > 1)
    UI:SetEnabled(frame.next, frame.page < maxPage)
end

function A:CreateProfessionWindow()
    if self.professionFrame then return end
    local frame = UI:CreateWindow("profession_info", self:L("PROFESSIONS"), 850, 570, "strong")
    self.professionFrame = frame
    frame.aaeTitle:ClearAllPoints(); frame.aaeTitle:SetPoint("TOPLEFT", frame, "TOPLEFT", 54, -17)
    local icon = frame:CreateTexture(nil, "ARTWORK"); icon:SetTexture("Interface\\Icons\\Trade_Engineering"); icon:SetWidth(32); icon:SetHeight(32); icon:SetPoint("TOPLEFT", frame, "TOPLEFT", 14, -10)
    frame.aaeTitleIcon = icon
    local hint = UI:Text(frame, self:L("PROFESSION_CANONICAL_HINT"), "small"); hint:SetPoint("TOPLEFT", frame, "TOPLEFT", 18, -47); hint:SetTextColor(0.55, 0.88, 0.92)

    local professionPanel = UI:Panel(frame); professionPanel:SetPoint("TOPLEFT", frame, "TOPLEFT", 15, -72); professionPanel:SetWidth(170); professionPanel:SetHeight(473); frame.professionPanel = professionPanel
    local professionTitle = UI:Text(professionPanel, self:L("PROFESSIONS"), "normal"); professionTitle:SetPoint("TOPLEFT", professionPanel, "TOPLEFT", 10, -10); professionTitle:SetTextColor(1, 0.82, 0.18)
    local recipePanel = UI:Panel(frame); recipePanel:SetPoint("TOPLEFT", frame, "TOPLEFT", 194, -72); recipePanel:SetWidth(308); recipePanel:SetHeight(473); frame.recipePanel = recipePanel
    local recipeTitle = UI:Text(recipePanel, self:L("CRAFT_ITEMS"), "normal"); recipeTitle:SetPoint("TOPLEFT", recipePanel, "TOPLEFT", 10, -10); recipeTitle:SetTextColor(1, 0.82, 0.18)
    local detailPanel = UI:Panel(frame); detailPanel:SetPoint("TOPLEFT", frame, "TOPLEFT", 511, -72); detailPanel:SetWidth(324); detailPanel:SetHeight(473); frame.detailPanel = detailPanel
    local detailTitle = UI:Text(detailPanel, self:L("RESULT_ITEM"), "normal");frame.detailTitle=detailTitle; detailTitle:SetPoint("TOPLEFT", detailPanel, "TOPLEFT", 10, -10); detailTitle:SetTextColor(1, 0.82, 0.18)

    frame.professionButtons = {}
    for index, professionID in ipairs(PROFESSION_IDS) do
        local profession = self.Data:GetProfession(professionID) or (self.AC335Professions and self.AC335Professions[professionID])
        local label = profession and (profession.name_ko or profession.name) or tostring(professionID)
        local count = 0; for _, category in ipairs((profession and profession.categories) or {}) do count = count + table.getn(category.spells or {}) end
        local button = UI:Button(professionPanel, 148, 34, label .. "  |cff6fcfe8" .. count .. "|r", "normal", "LEFT")
        button:SetPoint("TOPLEFT", professionPanel, "TOPLEFT", 10, -34 - (index - 1) * 38); button.professionID = professionID; button.baseLabel = label; button.recipeCount = count
        local picon = button:CreateTexture(nil, "ARTWORK"); picon:SetWidth(24); picon:SetHeight(24); picon:SetPoint("RIGHT", button, "RIGHT", -5, 0); picon:SetTexture(PROFESSION_ICONS[professionID]); button.aaeProfessionIcon = picon
        button.aaeLabel:SetPoint("LEFT", button, "LEFT", 6, 0); button.aaeLabel:SetPoint("RIGHT", button, "RIGHT", -32, 0)
        button:SetScript("OnClick", function(self) A:SelectProfession(self.professionID) end)
        frame.professionButtons[index] = button
    end

    local searchBox = UI:EditBox(recipePanel, 142, 24, "AzerothAdminAC335ProfessionSearch"); searchBox:SetPoint("TOPLEFT", recipePanel, "TOPLEFT", 10, -30); frame.searchBox = searchBox
    local searchButton = UI:Button(recipePanel, 55, 24, self:L("SEARCH"), "utility"); searchButton:SetPoint("LEFT", searchBox, "RIGHT", 6, 0)
    local sortButton = UI:Button(recipePanel, 75, 24, self:L("SORT_CATEGORY"), "normal"); sortButton:SetPoint("LEFT", searchButton, "RIGHT", 5, 0); frame.sortButton = sortButton; frame.sortMode = "category"
    local categoryDrop = CreateFrame("Frame", "AzerothAdminAC335ProfessionCategoryDropdown", recipePanel, "UIDropDownMenuTemplate")
    categoryDrop:SetPoint("TOPLEFT", recipePanel, "TOPLEFT", -4, -48); if UIDropDownMenu_SetWidth then UIDropDownMenu_SetWidth(categoryDrop, 112) end; frame.categoryDropdown = categoryDrop; frame.categoryFilter = "ALL"
    if UIDropDownMenu_Initialize then
        UIDropDownMenu_Initialize(categoryDrop, function(_, level)
            local options = { "ALL" }
            for _, category in ipairs((frame.selectedProfession and frame.selectedProfession.categories) or {}) do table.insert(options, category.name) end
            for _, value in ipairs(options) do
                local categoryValue = value
                local info = UIDropDownMenu_CreateInfo(); info.text = categoryValue == "ALL" and A:L("ALL_CATEGORIES") or categoryValue; info.value = categoryValue; info.checked = frame.categoryFilter == categoryValue
                info.func = function() frame.categoryFilter = categoryValue; A:RefreshProfessionCategoryDropdown(); A:BuildProfessionFilter() end
                UIDropDownMenu_AddButton(info, level)
            end
        end)
    end
    local tierDrop = CreateFrame("Frame", "AzerothAdminAC335ProfessionTierDropdown", recipePanel, "UIDropDownMenuTemplate")
    tierDrop:SetPoint("TOPLEFT", recipePanel, "TOPLEFT", 140, -48); if UIDropDownMenu_SetWidth then UIDropDownMenu_SetWidth(tierDrop, 124) end; frame.tierDropdown = tierDrop; frame.tierFilter = "ALL"
    if UIDropDownMenu_Initialize then
        UIDropDownMenu_Initialize(tierDrop, function(_, level)
            local options = { { key = "ALL", label = "ALL_TIERS" } }
            for _, tier in ipairs(TIER_ORDER) do table.insert(options, tier) end
            for _, option in ipairs(options) do
                local selected = option
                local info = UIDropDownMenu_CreateInfo(); info.text = A:L(selected.label); info.value = selected.key; info.checked = frame.tierFilter == selected.key
                info.func = function() frame.tierFilter = selected.key; A:RefreshProfessionTierDropdown(); A:BuildProfessionFilter() end
                UIDropDownMenu_AddButton(info, level)
            end
        end)
    end
    local knownOnly = UI:Check(recipePanel, 78, self:L("KNOWN_ONLY"), false, function() if frame.hideKnown then frame.hideKnown:SetChecked(false)end;A:BuildProfessionFilter() end)
    knownOnly:SetPoint("TOPLEFT", recipePanel, "TOPLEFT", 10, -79); frame.knownOnly = knownOnly
    frame.hideKnown=UI:Check(recipePanel,200,'습득한 제작법 제외',false,function()frame.knownOnly:SetChecked(false);A:BuildProfessionFilter()end)
    frame.hideKnown:SetPoint('TOPLEFT',recipePanel,'TOPLEFT',100,-79)


    frame.recipeRows = {}
    for index = 1, PAGE_SIZE do
        local row = UI:Button(recipePanel, 286, 31, "", "normal", "LEFT"); row:SetPoint("TOPLEFT", recipePanel, "TOPLEFT", 10, -109 - (index - 1) * 34)
        local recipeIcon = row:CreateTexture(nil, "ARTWORK"); recipeIcon:SetWidth(22); recipeIcon:SetHeight(22); recipeIcon:SetPoint("LEFT", row, "LEFT", 5, 0); row.recipeIcon = recipeIcon
        local indexText = UI:Text(row, "", "small"); indexText:SetPoint("RIGHT", row, "RIGHT", -7, 0); indexText:SetWidth(128); indexText:SetJustifyH("RIGHT"); indexText:SetTextColor(0.48, 0.70, 0.80); row.indexText = indexText
        row.aaeLabel:ClearAllPoints(); row.aaeLabel:SetPoint("LEFT", row, "LEFT", 32, 0); row.aaeLabel:SetPoint("RIGHT", row, "RIGHT", -132, 0)
        row:SetScript("OnClick", function(self) if self.recipe then A:SelectProfessionRecipe(self.recipe) end end)
        row:SetScript("OnEnter", function(self)
            if self.recipe then
                self:SetBackdropColor(0.055, 0.12, 0.15, 0.96); local GameTooltip=A:BeginHintTooltip(self, "ANCHOR_RIGHT"); pcall(GameTooltip.SetHyperlink, GameTooltip, "spell:" .. self.recipe.spellID)
                GameTooltip:AddLine(" "); GameTooltip:AddLine(A:L("SPELL_ID") .. ": " .. self.recipe.spellID, 0.45, 0.86, 1.00); GameTooltip:AddLine(A:L("RECIPE_ROW_HINT"), 0.55, 0.95, 0.75, true); A:StyleHintTooltip();GameTooltip:Show()
            end
        end)
        row:SetScript("OnLeave", function(self) if self.recipe then applyRecipeRowVisual(self, self.recipe == frame.selectedRecipe) end; A:HideHintTooltip(self) end)
        frame.recipeRows[index] = row
    end
    local previous = UI:Button(recipePanel, 72, 22, "◀ " .. self:L("PREVIOUS"), "utility"); previous:SetPoint("BOTTOMLEFT", recipePanel, "BOTTOMLEFT", 10, 9); frame.previous = previous
    previous:SetScript("OnClick", function() if frame.page > 1 then frame.page = frame.page - 1; A:RefreshProfessionRows() end end)
    local pageText = UI:Text(recipePanel, "", "small"); pageText:SetPoint("LEFT", previous, "RIGHT", 5, 0); pageText:SetWidth(120); pageText:SetJustifyH("CENTER"); pageText:SetTextColor(0.65, 0.82, 0.90); frame.pageText = pageText
    local nextButton = UI:Button(recipePanel, 72, 22, self:L("NEXT") .. " ▶", "utility"); nextButton:SetPoint("LEFT", pageText, "RIGHT", 5, 0); frame.next = nextButton
    nextButton:SetScript("OnClick", function() local maxPage = math.max(1, math.ceil(table.getn(frame.filteredRecipes or {}) / pageSize(frame))); if frame.page < maxPage then frame.page = frame.page + 1; A:RefreshProfessionRows() end end)
    searchButton:SetScript("OnClick", function() A:BuildProfessionFilter() end); searchBox:SetScript("OnEnterPressed", function(self) A:BuildProfessionFilter(); self:ClearFocus() end)
    searchBox:SetScript("OnEscapePressed", function(self) if self:GetText() ~= "" then self:SetText(""); A:BuildProfessionFilter() else self:ClearFocus(); frame:Hide() end end)
    sortButton:SetScript("OnClick", function()
        if frame.sortMode == "category" then frame.sortMode = "skill"; sortButton:SetText(A:L("SORT_SKILL"))
        elseif frame.sortMode == "skill" then frame.sortMode = "name"; sortButton:SetText(A:L("SORT_NAME"))
        elseif frame.sortMode == "name" then frame.sortMode = "known"; sortButton:SetText(A:L("SORT_KNOWN"))
        else frame.sortMode = "category"; sortButton:SetText(A:L("SORT_CATEGORY")) end
        sortRecipes(frame); frame.page = 1; A:RefreshProfessionRows()
    end)

    local outputButton = CreateFrame("Button", nil, detailPanel); outputButton:SetPoint("TOPLEFT", detailPanel, "TOPLEFT", 10, -30); outputButton:SetWidth(304); outputButton:SetHeight(76)
    outputButton:RegisterForClicks("LeftButtonUp", "RightButtonUp"); outputButton:SetBackdrop(UI.buttonBackdrop); outputButton:SetBackdropColor(0.020, 0.035, 0.045, 0.90); outputButton:SetBackdropBorderColor(0.42, 0.40, 0.30, 1)
    local outIcon = outputButton:CreateTexture(nil, "ARTWORK"); outIcon:SetWidth(48); outIcon:SetHeight(48); outIcon:SetPoint("LEFT", outputButton, "LEFT", 8, 0); outputButton.icon = outIcon
    local outName = UI:Text(outputButton, "", "normal"); outName:SetPoint("TOPLEFT", outputButton, "TOPLEFT", 66, -9); outName:SetWidth(226); outName:SetJustifyH("LEFT"); outputButton.name = outName
    local outMeta = UI:Text(outputButton, "", "small"); outMeta:SetPoint("TOPLEFT", outName, "BOTTOMLEFT", 0, -5); outMeta:SetWidth(226); outMeta:SetJustifyH("LEFT"); outMeta:SetTextColor(0.58, 0.82, 0.92); outputButton.meta = outMeta
    local clickHint = UI:Text(outputButton, "", "small"); clickHint:SetPoint("BOTTOMLEFT", outputButton, "BOTTOMLEFT", 66, 8); clickHint:SetTextColor(0.55, 0.95, 0.75); outputButton.clickHint = clickHint
    outputButton:SetScript("OnClick", function(_, mouseButton)
        local recipe = frame.selectedRecipe; if not recipe then return end
        local resolved = frame.resolvedRecipe
        if resolved and resolved.outputID then
            local link = resolved.outputLink or itemLink(resolved.outputID)
            if link and HandleModifiedItemClick and HandleModifiedItemClick(link) then return end
            if mouseButton == "RightButton" then A:RunRegisteredCommand("lookup_item", tostring(resolved.outputName or itemName(resolved.outputID)), true)
            else A:ShowItemQuantityPopup(resolved.outputID, resolved.outputName or recipe.name, resolved.outputCount or 1) end
        else
            local link = spellLink(recipe.spellID); if HandleModifiedItemClick then HandleModifiedItemClick(link) end
        end
    end)
    frame.outputButton = outputButton

    local learnButton = UI:Button(detailPanel, 142, 22, self:L("LEARN"), "reward"); learnButton:SetPoint("TOPLEFT", detailPanel, "TOPLEFT", 10, -111); frame.learnButton = learnButton
    learnButton:SetScript("OnClick", function(self)
        if not self.recipe then return end
        local allowed, reason = canLearnRecipe(self.recipe)
        if not allowed then A:Print(reason, true); return end
        A:LearnOwnSpell(self.recipe.spellID); A:SelectProfessionRecipe(self.recipe)
    end)
    learnButton:SetScript("OnEnter", function(self) UI:ShowHint(self, A:L("LEARN"), self.learnReason or A:L("PROF_LEARN_NO_RECIPE")) end)
    learnButton:SetScript("OnLeave", function(self) A:HideHintTooltip(self) end)
    A.PlayerActions:Attach(learnButton,learnButton:GetScript('OnClick'))
    local unlearnButton = UI:Button(detailPanel, 142, 22, self:L("UNLEARN"), "danger"); unlearnButton:SetPoint("LEFT", learnButton, "RIGHT", 8, 0); frame.unlearnButton = unlearnButton
    unlearnButton:SetScript("OnClick", function(self) if self.recipe then A:UnlearnOwnSpell(self.recipe.spellID) end end)
    A.PlayerActions:Attach(unlearnButton,unlearnButton:GetScript('OnClick'))
    local sourceText = UI:Text(detailPanel, "", "small"); sourceText:SetPoint("TOPLEFT", detailPanel, "TOPLEFT", 12, -139); sourceText:SetWidth(300); sourceText:SetHeight(34); sourceText:SetJustifyH("LEFT"); sourceText:SetJustifyV("TOP"); sourceText:SetTextColor(0.75, 0.78, 0.82); frame.sourceText = sourceText
    local reagentTitle = UI:Text(detailPanel, self:L("REAGENTS"), "normal");frame.reagentTitle=reagentTitle; reagentTitle:SetPoint("TOPLEFT", detailPanel, "TOPLEFT", 10, -171); reagentTitle:SetTextColor(1, 0.82, 0.18)
    local noReagentText = UI:Text(detailPanel, "", "small"); noReagentText:SetPoint("TOPLEFT", detailPanel, "TOPLEFT", 12, -194); noReagentText:SetWidth(300); noReagentText:SetJustifyH("LEFT"); noReagentText:SetTextColor(0.75, 0.78, 0.82); frame.noReagentText = noReagentText
    frame.reagentButtons = {}
    for index = 1, 8 do
        local button = CreateFrame("Button", nil, detailPanel); local col = (index - 1) % 2; local line = math.floor((index - 1) / 2)
        button:SetWidth(145); button:SetHeight(62); button:SetPoint("TOPLEFT", detailPanel, "TOPLEFT", 10 + col * 151, -190 - line * 66)
        button:RegisterForClicks("LeftButtonUp", "RightButtonUp"); button:SetBackdrop(UI.buttonBackdrop); button:SetBackdropColor(0.020, 0.035, 0.045, 0.84); button:SetBackdropBorderColor(0.34, 0.36, 0.34, 1)
        local texture = button:CreateTexture(nil, "ARTWORK"); texture:SetWidth(34); texture:SetHeight(34); texture:SetPoint("LEFT", button, "LEFT", 6, 5); button.icon = texture
        local name = UI:Text(button, "", "small"); name:SetPoint("TOPLEFT", button, "TOPLEFT", 46, -7); name:SetWidth(91); name:SetHeight(31); name:SetJustifyH("LEFT"); name:SetJustifyV("TOP"); button.name = name
        local count = UI:Text(button, "", "small"); count:SetPoint("BOTTOMLEFT", button, "BOTTOMLEFT", 46, 8); count:SetWidth(91); count:SetJustifyH("LEFT"); count:SetTextColor(0.55, 0.88, 0.92); button.count = count
        button:SetScript("OnEnter", function(self)
            if self.reagent then
                A:ApplyProfessionReagentVisual(self, true); local GameTooltip=A:BeginHintTooltip(self, "ANCHOR_RIGHT")
                if self.reagent.link then GameTooltip:SetHyperlink(self.reagent.link) else GameTooltip:SetText(self.reagent.name or A:L("UNKNOWN"), 1, 0.82, 0.18) end
                local state, have, needed, missing = reagentVisualState(self.reagent)
                GameTooltip:AddLine(" ")
                if state == "ready" then
                    GameTooltip:AddLine(A:L("REAGENT_READY_TOOLTIP", have, needed), 0.45, 1.00, 0.55, true)
                elseif state == "partial" or state == "missing" then
                    GameTooltip:AddLine(A:L("REAGENT_SHORT_TOOLTIP", missing), 1.00, 0.38, 0.28, true)
                end
                GameTooltip:AddLine(A:L("REAGENT_ROW_HINT"), 0.55, 0.95, 0.75, true); A:StyleHintTooltip();GameTooltip:Show()
            end
        end)
        button:SetScript("OnLeave", function(self) if self.reagent then A:ApplyProfessionReagentVisual(self, false) end; A:HideHintTooltip(self) end)
        button:SetScript("OnClick", function(self, mouseButton)
            local reagent = self.reagent; if not reagent or not reagent.id then return end
            if reagent.link and HandleModifiedItemClick and HandleModifiedItemClick(reagent.link) then return end
            if mouseButton == "RightButton" then A:RunRegisteredCommand("lookup_item", tostring(reagent.name or itemName(reagent.id)), true)
            else A:ShowItemQuantityPopup(reagent.id, reagent.name, reagent.needed or 1) end
        end)
        button:Hide(); frame.reagentButtons[index] = button
    end

    frame.page = 1; frame.filteredRecipes = {}; frame.allRecipes = {}
    UI:BindMouseWheel(recipePanel, previous, nextButton)
    self:ClearProfessionDetail()
    self:RefreshProfessionTierDropdown()
    self:RefreshProfessionSkillButtons(true)
    self:PrimeProfessionCaches()
    self:SelectProfession(PROFESSION_IDS[1])
end

function A:RefreshProfessionInventoryData()
    local frame = self.professionFrame
    if not frame or not frame.selectedProfession then return end
    self:RefreshProfessionRows()
    if frame.selectedRecipe then self:SelectProfessionRecipe(frame.selectedRecipe) end
end

function A:RefreshProfessionDynamicData(rebuildFilter)
    local frame = self.professionFrame
    if not frame or not frame.selectedProfession then return end
    if rebuildFilter then
        self:BuildProfessionFilter(true)
    else
        self:RefreshProfessionRows()
    end
    if frame.selectedRecipe then self:SelectProfessionRecipe(frame.selectedRecipe) end
end

function A:OpenProfessionWindow()
    if not self.professionFrame then self:CreateProfessionWindow() end
    self:RefreshProfessionDynamicData(false)
    UI:ShowWindow(self.professionFrame)
end

function A:ToggleProfessionWindow()
    if not self.professionFrame then self:CreateProfessionWindow() end
    if self.professionFrame:IsShown() then self.professionFrame:Hide() else self:OpenProfessionWindow() end
end

-- Coalesce only the data that actually changed. Switching professions no longer resolves
-- hundreds of spell names/icons, and BAG_UPDATE refreshes only visible/detail data.
local professionEvents = CreateFrame("Frame")
for _, event in ipairs({
    "SPELLS_CHANGED", "LEARNED_SPELL_IN_TAB", "TRADE_SKILL_SHOW", "TRADE_SKILL_UPDATE",
    "SKILL_LINES_CHANGED", "GET_ITEM_INFO_RECEIVED", "BAG_UPDATE",
}) do
    professionEvents:RegisterEvent(event)
end
professionEvents:SetScript("OnEvent", function(_, event)
    local skillChange=event~="BAG_UPDATE" and event~="GET_ITEM_INFO_RECEIVED"
    if skillChange then
        A.professionKnownDirty=true
        invalidateKnownCache();A.professionSkillStateCache={}
    end
    local frame=A.professionFrame
    if not frame or not frame:IsShown()then return end
    if A.professionDynamicRefreshPending then return end
    A.professionDynamicRefreshPending=true
    A:RunAfter(.12,function()
        A.professionDynamicRefreshPending=false
        local selected=A.professionFrame
        if not selected or not selected:IsShown()then return end
        if A.professionKnownDirty then
            A.professionKnownDirty=nil
            invalidateKnownCache();A.professionSkillStateCache={}
            A:RefreshProfessionSkillButtons(true)
            local filtered=selected.knownOnly:GetChecked()or(selected.hideKnown and selected.hideKnown:GetChecked())or selected.sortMode=="known"
            A:RefreshProfessionDynamicData(filtered)
            if A.RefreshProfessionTraining then A:RefreshProfessionTraining()end
        else A:RefreshProfessionInventoryData()end
    end)
end)
A.professionEventFrame = professionEvents

local professionWarmupEvents = CreateFrame("Frame")
professionWarmupEvents:RegisterEvent("PLAYER_LOGIN")
professionWarmupEvents:RegisterEvent("PLAYER_ENTERING_WORLD")
professionWarmupEvents:SetScript("OnEvent", function()
    A:PrimeProfessionCaches()
end)
A.professionWarmupEventFrame = professionWarmupEvents

-- R7 requirement helpers exposed for deterministic self-tests.
A.GetProfessionRequirement = professionRequirement
A.GetProfessionRecipeResultIcon = recipeResultIcon
A.GetProfessionTierForSkill = tierForSkill
function A.GetPlayerProfessionState(selfOrID,idOrForce,force)
 if type(selfOrID)=='table'then return playerProfessionState(idOrForce,force)end
 return playerProfessionState(selfOrID,idOrForce)
end
A.CanLearnProfessionRecipe = canLearnRecipe
