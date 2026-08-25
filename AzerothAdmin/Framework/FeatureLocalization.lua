AzerothAdminEasy = AzerothAdminEasy or {}
local addon = AzerothAdminEasy

local function hasHangul(value)
    value = tostring(value or "")
    return string.find(value, "[\234-\237][\128-\191][\128-\191]") ~= nil
end

local function fallbackCommandHint(def)
    local command = def and (def.command or def.permissionCommand) or nil
    if addon.ActiveLocale == "zhCN" then
        return command and ("AzerothCore GM命令：" .. command) or "AzerothCore GM功能"
    elseif addon.ActiveLocale == "zhTW" then
        return command and ("AzerothCore GM命令：" .. command) or "AzerothCore GM功能"
    end
    return command and ("AzerothCore GM command: " .. command) or "AzerothCore GM action"
end

local function fallbackActionLabel(action)
    local names = {
        enUS = { revive="Revive", godToggle="God Mode", visibilityToggle="Visibility", flightToggle="GM Flight", waterwalkToggle="Water Walk", speedToggle="Speed", questhelper="Quest Helper", bankToggle="Bank", craftInfo="Profession Info", itemInfo="Item Info", teleports="Teleports", favorites="Favorites", probeSecurity="Check GM Access", screenshot="Screenshot" },
        zhCN = { revive="复活", godToggle="无敌模式", visibilityToggle="隐身", flightToggle="GM飞行", waterwalkToggle="水上行走", speedToggle="移动速度", questhelper="任务助手", bankToggle="银行", craftInfo="专业技能信息", itemInfo="物品信息", teleports="传送", favorites="收藏", probeSecurity="检查GM权限", screenshot="截图" },
        zhTW = { revive="復活", godToggle="無敵模式", visibilityToggle="隱形", flightToggle="GM飛行", waterwalkToggle="水上行走", speedToggle="移動速度", questhelper="任務助手", bankToggle="銀行", craftInfo="專業技能資訊", itemInfo="物品資訊", teleports="傳送", favorites="最愛", probeSecurity="檢查GM權限", screenshot="截圖" },
    }
    local pack = names[addon.ActiveLocale] or names.enUS
    return pack[action] or action or "Action"
end

function addon:LocalizeCommandDefinitions()
    if self.ActiveLocale == "koKR" or type(self.Categories) ~= "table" then return end
    local ci, di
    for ci = 1, table.getn(self.Categories) do
        local category = self.Categories[ci]
        if category then
            local name = self:TranslateUI(category.name or "")
            if hasHangul(name) then name = "GM" .. tostring(ci) end
            category.name = name
            local short = self:TranslateUI(category.short or category.name or "")
            if hasHangul(short) then short = name end
            category.short = short
            local commands = category.commands or {}
            for di = 1, table.getn(commands) do
                local def = commands[di]
                if def then
                    local label = self:TranslateUI(def.label or "")
                    if hasHangul(label) then
                        if def.command and def.command ~= "" then label = def.command
                        else label = fallbackActionLabel(def.action) end
                    end
                    def.label = label
                    local hint = self:TranslateUI(def.hint or "")
                    if hint == "" or hasHangul(hint) then hint = fallbackCommandHint(def) end
                    def.hint = hint
                    if def.example then
                        local example = self:TranslateUI(def.example)
                        if hasHangul(example) then example = nil end
                        def.example = example
                    end
                end
            end
        end
    end
end

local function localizeTeleportEntries(entries)
    local i
    for i = 1, table.getn(entries or {}) do
        local entry = entries[i]
        if entry then
            if entry.name then
                local translated = addon:TranslateUI(entry.name)
                if translated ~= entry.name then entry.name = translated end
            end
            if entry.zone then
                local translated = addon:TranslateUI(entry.zone)
                if translated ~= entry.zone then entry.zone = translated end
            end
        end
    end
end

function addon:LocalizeTeleportDefinitions()
    if self.ActiveLocale == "koKR" then return end
    local groups = self.FavoriteTeleportGroups or {}
    local i
    for i = 1, table.getn(groups) do
        if groups[i] and groups[i].name then groups[i].name = self:TranslateUI(groups[i].name) end
    end
    localizeTeleportEntries(self.FavoriteTeleports)
    localizeTeleportEntries(self.Teleports)
end

function addon:LocalizeAddonPopups()
    if self.ActiveLocale == "koKR" or type(StaticPopupDialogs) ~= "table" then return end
    local key, dialog
    for key, dialog in pairs(StaticPopupDialogs) do
        if type(key) == "string" and string.find(key, "AZEROTHADMIN_", 1, true) == 1 and type(dialog) == "table" then
            if type(dialog.text) == "string" then dialog.text = self:TranslateUI(dialog.text) end
            if type(dialog.button1) == "string" then dialog.button1 = self:TranslateUI(dialog.button1) end
            if type(dialog.button2) == "string" then dialog.button2 = self:TranslateUI(dialog.button2) end
            if type(dialog.button3) == "string" then dialog.button3 = self:TranslateUI(dialog.button3) end
        end
    end
end

local function isDescendantOf(frame, ancestor)
    if not frame or not ancestor then return false end
    local current, guard = frame, 0
    while current and guard < 24 do
        if current == ancestor then return true end
        current = current.GetParent and current:GetParent() or nil
        guard = guard + 1
    end
    return false
end

function addon:IsLocalizationOwnedFrame(frame)
    if not frame then return false end
    local roots = {
        self.frame, self.toolbar, self.argumentFrame, self.teleportFrame, self.favoriteFrame,
        self.localeSearchFrame, self.questHelperFrame, self.questHelperSearchResultFrame,
        self.creatureBrowserFrame, _G.AzerothAdminCraftInfoFrame, _G.BlueItemInfo3,
    }
    local i
    for i = 1, table.getn(roots) do
        if roots[i] and isDescendantOf(frame, roots[i]) then return true end
    end
    return false
end

local function hookFrame(frame)
    if not frame or frame.aaeLocalizationHooked then return end
    frame.aaeLocalizationHooked = true
    local elapsedTotal = 0
    frame:HookScript("OnShow", function(self)
        addon:LocalizeFrame(self)
    end)
    frame:HookScript("OnUpdate", function(self, elapsed)
        if addon.ActiveLocale == "koKR" then return end
        elapsedTotal = elapsedTotal + (elapsed or 0)
        if elapsedTotal < 0.5 then return end
        elapsedTotal = 0
        addon:LocalizeFrame(self)
    end)
end

function addon:InstallRuntimeLocalizationHooks()
    if self.ActiveLocale == "koKR" then return end
    local frames = {
        self.frame, self.toolbar, self.argumentFrame, self.teleportFrame, self.favoriteFrame,
        self.localeSearchFrame, self.questHelperFrame, self.questHelperSearchResultFrame,
        self.creatureBrowserFrame, _G.AzerothAdminCraftInfoFrame, _G.BlueItemInfo3,
        _G.AzerothAdminTeleportFrame, _G.AzerothAdminFavoriteTeleportFrame,
        _G.AzerothAdminQuestHelperFrame, _G.AzerothAdminKoKRSearchFrame,
    }
    local i
    for i = 1, table.getn(frames) do hookFrame(frames[i]) end
    if GameTooltip and not GameTooltip.aaeLocalizationHooked then
        GameTooltip.aaeLocalizationHooked = true
        GameTooltip:HookScript("OnShow", function(self)
            local owner = self.GetOwner and self:GetOwner() or nil
            if addon.ActiveLocale ~= "koKR" and addon:IsLocalizationOwnedFrame(owner) then
                addon:LocalizeFrame(self)
            end
        end)
    end
end

local events = CreateFrame("Frame")
events:RegisterEvent("ADDON_LOADED")
events:RegisterEvent("PLAYER_LOGIN")
events:SetScript("OnEvent", function(self, event, name)
    if event == "ADDON_LOADED" then
        if name ~= "AzerothAdmin" then return end
        addon:LocalizeCommandDefinitions()
        addon:LocalizeTeleportDefinitions()
        addon:LocalizeAddonPopups()
        self:UnregisterEvent("ADDON_LOADED")
    elseif event == "PLAYER_LOGIN" then
        local driver = CreateFrame("Frame")
        local elapsedTotal = 0
        driver:SetScript("OnUpdate", function(_, elapsed)
            if addon.ActiveLocale == "koKR" then return end
            elapsedTotal = elapsedTotal + (elapsed or 0)
            if elapsedTotal < 1.0 then return end
            elapsedTotal = 0
            addon:InstallRuntimeLocalizationHooks()
            addon:LocalizeVisibleFrames()
        end)
        self:UnregisterEvent("PLAYER_LOGIN")
    end
end)
