AzerothAdminAC335 = type(AzerothAdminAC335) == "table" and AzerothAdminAC335 or {}
local A = AzerothAdminAC335

-- Stable AC335 3.3.5a namespace.  Older test builds used the generic
-- `AzerothAdminAC` global and could replace it during addon load.  All R4
-- runtime files use AzerothAdminAC335; the old name is only a compatibility
-- alias for macros/debug commands.
AzerothAdminAC = A
A.UI = type(A.UI) == "table" and A.UI or {}
A.bootstrapVersion = 6
A.bootstrapReady = true

A.name = "GMminibar"
A.version = "1.0.0"
A.releaseDate = "2026-09-14"
A.interface = 30300
A.operatorSecurity = 3
A.serverSecurity = { PLAYER = 0, MODERATOR = 1, GAMEMASTER = 2, ADMINISTRATOR = 3, CONSOLE = 4 }
A.windows = A.windows or {}
A.windowOrder = A.windowOrder or {}
A.windowHistory = A.windowHistory or {}
A.debugLog = A.debugLog or {}
A.defaults = {
    schemaVersion = 7,
    locale = nil,
    securityLevel = 3,
    debug = false,
    commandHistory = {},
    commandFavorites = {},
    teleportFavorites = {},
    quickSlots = { "gm_on", "teleport_window" },
    windowPoints = {},
    minimap = { angle = 225, hidden = false },
    toolbarHidden = false,
    teleportFullCatalog = true,
    professionSpellCacheVersion = 1,
    professionSpellCache = {},
    professionWarmup = true,
    itemAdvancedFilters = false,
    showServerLifecycleCommands = false,
    lastCategory = "gm",
    lastCommandPage = 1,
}

local function applyDefaults(target, defaults)
    for key, value in pairs(defaults) do
        if target[key] == nil then
            if type(value) == "table" then
                target[key] = {}
                applyDefaults(target[key], value)
            else
                target[key] = value
            end
        elseif type(value) == "table" and type(target[key]) == "table" then
            applyDefaults(target[key], value)
        end
    end
end

function A:GetDB()
    if GMminibarAC335DB ~= nil and type(GMminibarAC335DB) ~= "table" then
        local damaged = GMminibarAC335DB
        GMminibarAC335DB = { recovery = { invalidRoot = damaged } }
    end
    GMminibarAC335DB = GMminibarAC335DB or {}
    local previousSchema = tonumber(GMminibarAC335DB.schemaVersion) or 0
    applyDefaults(GMminibarAC335DB, self.defaults)
    if previousSchema < 2 then
        local legacy = tonumber(GMminibarAC335DB.securityLevel)
        if legacy == 3 or legacy == 6 or legacy == 8 then GMminibarAC335DB.securityLevel = self.operatorSecurity end
    end
    if previousSchema < 4 then
        -- Upgrade old quick-list-only installs to the full server game_tele catalog.
        GMminibarAC335DB.teleportFullCatalog = true
    end
    if previousSchema < 5 then
        -- R4 bootstrap recovery: never inherit a hidden/off-screen launcher from an
        -- RC build that failed before its UI could be repaired.
        GMminibarAC335DB.toolbarHidden = false
        GMminibarAC335DB.minimap = GMminibarAC335DB.minimap or {}
        GMminibarAC335DB.minimap.hidden = false
        GMminibarAC335DB.minimap.x = nil
        GMminibarAC335DB.minimap.y = nil
        GMminibarAC335DB.windowPoints = GMminibarAC335DB.windowPoints or {}
        GMminibarAC335DB.windowPoints.toolbar = nil
    end
    if previousSchema < 6 then
        -- R6 profession cache: preserve names/icons across normal WoW Cache-folder clears
        -- while keeping the cache versioned and locale-scoped.
        GMminibarAC335DB.professionSpellCacheVersion = 1
        GMminibarAC335DB.professionSpellCache = GMminibarAC335DB.professionSpellCache or {}
        if GMminibarAC335DB.professionWarmup == nil then GMminibarAC335DB.professionWarmup = true end
    end
    if tonumber(GMminibarAC335DB.professionSpellCacheVersion) ~= 1 then
        GMminibarAC335DB.professionSpellCacheVersion = 1
        GMminibarAC335DB.professionSpellCache = {}
    end
    if previousSchema < 7 then
        -- R8 UX defaults: search-first item browser and safe server-command surface.
        if GMminibarAC335DB.itemAdvancedFilters == nil then GMminibarAC335DB.itemAdvancedFilters = false end
        if GMminibarAC335DB.showServerLifecycleCommands == nil then GMminibarAC335DB.showServerLifecycleCommands = false end
    end
    GMminibarAC335DB.schemaVersion = 7
    return GMminibarAC335DB
end

function A:Trim(value)
    return tostring(value or ""):match("^%s*(.-)%s*$") or ""
end

function A:Print(message, isError)
    local prefix = isError and "|cffff5b45GM MINI BAR[WotLK-아제로스코어]:|r " or "|cffffd24aGM MINI BAR[WotLK-아제로스코어]:|r "
    if DEFAULT_CHAT_FRAME then
        DEFAULT_CHAT_FRAME:AddMessage(prefix .. tostring(message or ""))
    end
end

function A:Debug(message)
    local db = self:GetDB()
    if not db.debug then return end
    local value = tostring(message or "")
    table.insert(self.debugLog, value)
    while table.getn(self.debugLog) > 100 do table.remove(self.debugLog, 1) end
    self:Print("DEBUG: " .. value)
end

function A:SafeCall(context, callback, ...)
    if type(callback) ~= "function" then return false end
    local ok, result = pcall(callback, ...)
    if not ok then
        self:Print((context or "callback") .. ": " .. tostring(result), true)
        self:Debug(tostring(result))
        return false
    end
    return true, result
end

function A:GetAccountSecurity()
    return tonumber(self:GetDB().securityLevel) or self.operatorSecurity
end

function A:SetAccountSecurity(level)
    level = math.floor(tonumber(level) or self.operatorSecurity)
    if level < 0 then level = 0 end
    if level > 255 then level = 255 end
    self:GetDB().securityLevel = level
    if self.RefreshSecurityDisplays then self:RefreshSecurityDisplays() end
    self:Print(self:L("SECURITY_SET", level))
end

function A:RecordCommand(command)
    local history = self:GetDB().commandHistory
    if history[1] == command then return end
    table.insert(history, 1, command)
    while table.getn(history) > 50 do table.remove(history) end
end

function A:RunAfter(delay, callback)
    delay = math.max(0, tonumber(delay) or 0)
    if type(callback) ~= "function" then return nil end
    local timer = CreateFrame("Frame")
    local elapsed = 0
    timer:SetScript("OnUpdate", function(self, delta)
        elapsed = elapsed + (tonumber(delta) or 0)
        if elapsed < delay then return end
        self:SetScript("OnUpdate", nil)
        self:Hide()
        A:SafeCall("RunAfter", callback)
    end)
    return timer
end

function A:IsPlayerDeadOrGhost()
    if UnitIsDeadOrGhost then
        local ok, value = pcall(UnitIsDeadOrGhost, "player")
        if ok and value then return true end
    end
    if UnitIsDead then
        local ok, value = pcall(UnitIsDead, "player")
        if ok and value then return true end
    end
    if UnitIsGhost then
        local ok, value = pcall(UnitIsGhost, "player")
        if ok and value then return true end
    end
    return false
end

function A:SendCommand(command, chatType, chatTarget)
    command = self:Trim(command):gsub("[\r\n]", " ")
    if command == "" then return false end
    if string.sub(command, 1, 1) ~= "." then command = "." .. command end
    self:RecordCommand(command)

    local resolvedType = chatType
    local resolvedTarget = chatTarget
    if not resolvedType and self:IsPlayerDeadOrGhost() then
        resolvedType = "WHISPER"
        resolvedTarget = UnitName and UnitName("player") or nil
    end
    resolvedType = resolvedType or "SAY"
    if resolvedType == "WHISPER" and (not resolvedTarget or resolvedTarget == "") then
        resolvedTarget = UnitName and UnitName("player") or nil
    end

    self:Debug("SEND[" .. tostring(resolvedType) .. "] " .. command)
    local ok, err = pcall(SendChatMessage, command, resolvedType, nil, resolvedTarget)
    if not ok then
        self:Print(self:L("COMMAND_SEND_FAILED", tostring(err)), true)
        return false
    end
    return true
end

function A:RegisterWindow(key, frame)
    if not key or not frame then return end
    self.windows[key] = frame
    for _, existing in ipairs(self.windowOrder) do if existing == key then return end end
    table.insert(self.windowOrder, key)
end

function A:HideAddonWindows(except)
    for _, key in ipairs(self.windowOrder) do
        local frame = self.windows[key]
        if frame and frame ~= except and frame.IsShown and frame:IsShown() then frame:Hide() end
    end
end

function A:ResetWindowPositions()
    self:GetDB().windowPoints = {}
    for _, key in ipairs(self.windowOrder) do
        local frame = self.windows[key]
        if frame then frame:ClearAllPoints(); frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0) end
    end
    self:Print(self:L("POSITIONS_RESET"))
end

local function ensureRuntime(context)
    if type(A.Initialize) ~= "function" then
        A:Print("UI core is not loaded (" .. tostring(context or "slash") .. "). Reinstall the complete R8 folder.", true)
        return false
    end
    local ok = A:SafeCall(context or "Initialize", A.Initialize, A)
    return ok and true or false
end

local function slashAaac(message)
    local text=A:Trim(message)
    local cmd,arg=text:match("^(%S+)%s*(.-)$")
    cmd=string.lower(cmd or "")
    if cmd == "repair" then
        local db=A:GetDB()
        db.toolbarHidden=false
        db.minimap=db.minimap or {}
        db.minimap.hidden=false
        db.minimap.x=nil
        db.minimap.y=nil
        db.windowPoints=db.windowPoints or {}
        db.windowPoints.toolbar=nil
        A.initialized=false
        ensureRuntime("/aaac repair")
        if A.toolbar then A.toolbar:Show() end
        if A.minimapButton then A.minimapButton:Show() end
        A:Print("UI launchers repaired.")
        return
    end
    if cmd == "test" then
        ensureRuntime("/aaac test")
        if A.RunRuntimeSelfTest then A:RunRuntimeSelfTest() else A:Print("Runtime self-test module is missing.", true) end
        return
    end
    if cmd == "" or cmd == "toggle" then
        if ensureRuntime("/aaac") and A.ToggleMainWindow then A:ToggleMainWindow() end
        return
    end
    if cmd == "show" then
        if ensureRuntime("/aaac show") and A.ShowMainWindow then A:ShowMainWindow() end
        return
    end
    if cmd == "hide" then A:HideAddonWindows(nil); return end
    if cmd == "reset" then A:ResetWindowPositions(); return end
    if cmd == "security" then A:SetAccountSecurity(arg); return end
    if cmd == "locale" then A:SetLocale(arg); return end
    if cmd == "debug" then
        local db=A:GetDB(); db.debug = not db.debug; A:Print(A:L(db.debug and "DEBUG_ON" or "DEBUG_OFF")); return
    end
    if cmd == "probe" then A:RunRegisteredCommand("server_info"); return end
    A:Print(A:L("SLASH_HELP"))
end

SLASH_AZEROTHADMINAC3351 = "/aaac"
SlashCmdList["AZEROTHADMINAC335"] = slashAaac
SLASH_MOPGM1 = "/mopgm"
SlashCmdList["MOPGM"] = function(message)
    local text=A:Trim(message)
    if text == "" then A:Print(A:L("RAW_HELP")); return end
    A:SendCommand(text)
end

local events=CreateFrame("Frame")
A.eventFrame = events
events:RegisterEvent("ADDON_LOADED")
events:RegisterEvent("PLAYER_LOGIN")
events:RegisterEvent("PLAYER_ENTERING_WORLD")
events:SetScript("OnEvent", function(_, event, name)
    if event == "ADDON_LOADED" and name == A.name then
        A:GetDB()
    elseif event == "PLAYER_LOGIN" or event == "PLAYER_ENTERING_WORLD" then
        ensureRuntime(event)
        -- A second idempotent pass catches late Blizzard UI initialization and also
        -- recovers from one transient frame-construction error without reloading.
        A:RunAfter(event == "PLAYER_LOGIN" and 0.25 or 0.05, function() ensureRuntime(event .. " retry") end)
    end
end)
