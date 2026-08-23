AzerothAdminEasy = AzerothAdminEasy or {}
local addon = AzerothAdminEasy

-- WotLK 3.3.5a / AzerothCore compatibility fixes for the creature browser.
-- This file is loaded after the original browser and embedded item browser so
-- the existing implementation can stay intact while the known runtime issues
-- are corrected in one place.

local EXTRA_WOTLK_DUNGEON_BOSSES = {
    { 23953, "공작 켈레세스", "dungeon", "wotlk", "우트가드 성채", true },
    { 24200, "스카발드", "dungeon", "wotlk", "우트가드 성채", true },
    { 24201, "달론", "dungeon", "wotlk", "우트가드 성채", true },

    { 26731, "대학자 텔레스트라", "dungeon", "wotlk", "마력의 탑", true },
    { 26763, "아노말루스", "dungeon", "wotlk", "마력의 탑", true },
    { 26794, "정원사 오르모로크", "dungeon", "wotlk", "마력의 탑", true },

    { 28684, "문지기 크릭시르", "dungeon", "wotlk", "아졸네룹", true },
    { 28921, "하드로녹스", "dungeon", "wotlk", "아졸네룹", true },

    { 29309, "장로 나독스", "dungeon", "wotlk", "안카헤트", true },
    { 29308, "공작 탈다람", "dungeon", "wotlk", "안카헤트", true },
    { 29310, "어둠추적자 제도가", "dungeon", "wotlk", "안카헤트", true },

    { 26630, "송곳아귀", "dungeon", "wotlk", "드락타론 성채", true },
    { 26631, "소환사 노보스", "dungeon", "wotlk", "드락타론 성채", true },
    { 27483, "왕 드레드", "dungeon", "wotlk", "드락타론 성채", true },

    { 29315, "에레켐", "dungeon", "wotlk", "보랏빛 요새", true },
    { 29316, "모라그", "dungeon", "wotlk", "보랏빛 요새", true },
    { 29313, "이코론", "dungeon", "wotlk", "보랏빛 요새", true },
    { 29266, "제보즈", "dungeon", "wotlk", "보랏빛 요새", true },
    { 29312, "라반토르", "dungeon", "wotlk", "보랏빛 요새", true },
    { 29314, "파멸자 주라마트", "dungeon", "wotlk", "보랏빛 요새", true },

    { 29304, "슬라드란", "dungeon", "wotlk", "군드락", true },
    { 29307, "드라카리 거대골렘", "dungeon", "wotlk", "군드락", true },
    { 29305, "무라비", "dungeon", "wotlk", "군드락", true },
    { 29932, "사나운 엑크", "dungeon", "wotlk", "군드락", true },

    { 27977, "무쇠구체자 크리스탈루스", "dungeon", "wotlk", "돌의 전당", true },
    { 27975, "고뇌의 마녀", "dungeon", "wotlk", "돌의 전당", true },

    { 28586, "장군 비야른그림", "dungeon", "wotlk", "번개의 전당", true },
    { 28587, "볼칸", "dungeon", "wotlk", "번개의 전당", true },
    { 28546, "아이오나", "dungeon", "wotlk", "번개의 전당", true },

    { 26668, "스발라 소로우그레이브", "dungeon", "wotlk", "우트가드 첨탑", true },
    { 26687, "고르톡 페일후프", "dungeon", "wotlk", "우트가드 첨탑", true },
    { 26693, "학살자 스카디", "dungeon", "wotlk", "우트가드 첨탑", true },

    { 26529, "갈고리", "dungeon", "wotlk", "옛 스트라솔름", true },
    { 26530, "살람", "dungeon", "wotlk", "옛 스트라솔름", true },
    { 26532, "시간의 군주 에포크", "dungeon", "wotlk", "옛 스트라솔름", true },

    { 27654, "심문관 드라코스", "dungeon", "wotlk", "마력의 눈", true },
    { 27447, "바로스 클라우드스트라이더", "dungeon", "wotlk", "마력의 눈", true },
    { 27655, "마법사 군주 우롬", "dungeon", "wotlk", "마력의 눈", true },

    { 35119, "성기사 에드릭", "dungeon", "wotlk", "용사의 시험장", true },
    { 34928, "성기사 고해사제 페일트리스", "dungeon", "wotlk", "용사의 시험장", true },

    { 36497, "브론잠", "dungeon", "wotlk", "영혼의 제련소", true },
    { 36494, "제련장인 가프로스트", "dungeon", "wotlk", "사론의 구덩이", true },
    { 36476, "이크", "dungeon", "wotlk", "사론의 구덩이", true },
    { 38112, "팔릭", "dungeon", "wotlk", "투영의 전당", true },
    { 38113, "마윈", "dungeon", "wotlk", "투영의 전당", true },
}

local function appendMissingFeaturedCreatures()
    addon.FeaturedCreatures = addon.FeaturedCreatures or {}
    local known = {}
    local i
    for i = 1, table.getn(addon.FeaturedCreatures) do
        local entry = tonumber(addon.FeaturedCreatures[i] and addon.FeaturedCreatures[i][1])
        if entry then known[entry] = true end
    end
    for i = 1, table.getn(EXTRA_WOTLK_DUNGEON_BOSSES) do
        local record = EXTRA_WOTLK_DUNGEON_BOSSES[i]
        local entry = tonumber(record[1])
        if entry and not known[entry] then
            table.insert(addon.FeaturedCreatures, record)
            known[entry] = true
        end
    end
end
appendMissingFeaturedCreatures()

-- Safe raid-map positions from AzerothCore WotLK game_tele data.  Using the
-- instance map directly avoids .go creature id selecting an unusable spawn on
-- another map/phase for raid bosses.
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

local function findInstanceTeleport(record)
    if not record then return nil end
    local place = tostring(record[5] or "")
    if place == "" then return nil end

    if RAID_SAFE_TELEPORTS[place] then
        return RAID_SAFE_TELEPORTS[place]
    end

    local firstZoneMatch = nil
    local list = addon.Teleports or {}
    local i
    for i = 1, table.getn(list) do
        local row = list[i]
        if row and tostring(row.zone or "") == place then
            if tostring(row.name or "") == place and row.command then
                return row.command
            end
            if not firstZoneMatch and row.command then firstZoneMatch = row.command end
        end
    end
    return firstZoneMatch
end

local originalRunFeaturedCreatureAction = addon.RunFeaturedCreatureAction
if originalRunFeaturedCreatureAction then
    addon.RunFeaturedCreatureAction = function(self, action, record)
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
        return originalRunFeaturedCreatureAction(self, action, record)
    end
end

local function reloadCreatureModel(record)
    local model = addon.creatureBrowserModel
    local entry = tonumber(record and record[1])
    if not model or not entry or not model.SetCreature then return end

    if model.Hide then model:Hide() end
    if model.ClearModel then pcall(model.ClearModel, model) end
    local ok = pcall(model.SetCreature, model, entry)
    if ok then
        if model.SetCamDistanceScale then pcall(model.SetCamDistanceScale, model, 1.05) end
        if model.SetRotation then
            pcall(model.SetRotation, model, addon.creatureBrowserModelRotation or 0)
        end
        model:Show()
        if addon.creatureBrowserModelFallback then addon.creatureBrowserModelFallback:Hide() end
    else
        model:Hide()
        if addon.creatureBrowserModelFallback then addon.creatureBrowserModelFallback:Show() end
    end
end

local originalSelectFeaturedCreature = addon.SelectFeaturedCreature
if originalSelectFeaturedCreature then
    addon.SelectFeaturedCreature = function(self, record)
        originalSelectFeaturedCreature(self, record)
        reloadCreatureModel(record)

        -- Some 3.3.5a clients keep the previous PlayerModel until the next UI
        -- update.  Re-apply once on the next short timer, but only if selection
        -- has not changed in the meantime.
        local entry = tonumber(record and record[1])
        self._creatureModelReloadSerial = (self._creatureModelReloadSerial or 0) + 1
        local serial = self._creatureModelReloadSerial
        if entry and self.RunAfter then
            self:RunAfter(0.05, function()
                local selected = addon.creatureBrowserSelected
                if serial == addon._creatureModelReloadSerial and selected and tonumber(selected[1]) == entry then
                    reloadCreatureModel(selected)
                end
            end)
        end
    end
end

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
    addon.CreateCreatureBrowser = function(self)
        local result = originalCreateCreatureBrowser(self)
        removeRepeatedCreatureRowIcons()
        return result
    end
end

local function clearEditBoxFocus(edit)
    if edit and edit.ClearFocus then edit:ClearFocus() end
end

-- Creature browser: clicking Search used to leave the Korean IME EditBox
-- focused.  Refresh is only called by explicit browser controls, so releasing
-- this EditBox after the refresh restores normal WASD/key movement immediately.
local originalRefreshCreatureBrowser = addon.RefreshCreatureBrowser
if originalRefreshCreatureBrowser then
    addon.RefreshCreatureBrowser = function(self, ...)
        local result = originalRefreshCreatureBrowser(self, ...)
        clearEditBoxFocus(self.creatureBrowserSearch)
        return result
    end
end

local originalOpenLocaleSearch = addon.OpenLocaleSearch
if originalOpenLocaleSearch then
    addon.OpenLocaleSearch = function(self, ...)
        clearEditBoxFocus(self.creatureBrowserSearch)
        return originalOpenLocaleSearch(self, ...)
    end
end

local originalRunLocaleSearch = addon.RunLocaleSearch
if originalRunLocaleSearch then
    addon.RunLocaleSearch = function(self, ...)
        local result = originalRunLocaleSearch(self, ...)
        clearEditBoxFocus(self.localeSearchEdit)
        return result
    end
end

-- BlueItemInfo3 exposes its search EditBox, but its local search function is not
-- externally replaceable.  Hook only the three submission buttons and release
-- focus after their original OnClick code has run.  This avoids Retail-only
-- keyboard propagation APIs and works with the 3.3.5a EditBox implementation.
local BII3 = _G.BlueItemInfo3
if BII3 and BII3.searchEdit then
    local function shouldReleaseForButton(button)
        local label = button and button.label
        local text = label and label.GetText and label:GetText() or ""
        return text == "검색" or text == "분류" or text == "필터 적용"
    end

    local function hookChildButtons(parent)
        if not parent or not parent.GetChildren then return end
        local children = { parent:GetChildren() }
        local i
        for i = 1, table.getn(children) do
            local child = children[i]
            if child and child.GetObjectType and child:GetObjectType() == "Button" and shouldReleaseForButton(child) then
                local oldClick = child:GetScript("OnClick")
                if oldClick and not child.aaeSearchFocusHooked then
                    child.aaeSearchFocusHooked = true
                    child:SetScript("OnClick", function(self, ...)
                        oldClick(self, ...)
                        clearEditBoxFocus(BII3.searchEdit)
                    end)
                end
            end
            hookChildButtons(child)
        end
    end
    hookChildButtons(BII3)

    local originalBII3Search = BII3.Search
    if originalBII3Search then
        BII3.Search = function(self, ...)
            local result = originalBII3Search(self, ...)
            clearEditBoxFocus(self.searchEdit)
            return result
        end
    end
end
