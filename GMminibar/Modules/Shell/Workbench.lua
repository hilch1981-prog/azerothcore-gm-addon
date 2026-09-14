-- Common navigation and layout; WorkbenchAdapter owns every core-dependent action.
local A = AzerothAdminAC335
local N, D, C = A.NativeUI, A.WorkbenchAdapter, A.WorkbenchCatalog
local W = { page = 1, group = "all", panels = {}, history = {}, width = 1120, height = 762 }
A.Workbench = W
local PAGE_SIZE = 8
local function L(key) return A:WL(key) end
local function trim(value) return (tostring(value or ""):gsub("^%s*(.-)%s*$", "%1")) end
local legacyFavorite = D.IsFavorite
function D:IsFavorite(entry)
    local saved = W:DB().favorites[entry.key]
    if saved ~= nil then return saved end
    return legacyFavorite(self, entry)
end
function D:Favorite(entry)
    W:DB().favorites[entry.key] = not self:IsFavorite(entry)
end
function W:DB()
    local db = D:DB()
    if type(db.nativeUX) ~= "table" then db.nativeUX = {} end
    local ux = db.nativeUX
    if type(ux.quick) ~= "table" then ux.quick = {} end
    if type(ux.favorites) ~= "table" then ux.favorites = {} end
    if ux.questCompanion == nil then ux.questCompanion = true end
    if ux.schema ~= 2 then ux.scale = math.min(tonumber(ux.scale) or .85, .85); ux.schema = 2 end
    return ux
end
function W:CanMount(frame)
    if not frame then return false end
    if self.panels[frame] then return true end
    for _, item in ipairs(D:Frames()) do
        if item[1] == frame then self:Watch(frame, item[2]); return true end
    end
    return false
end
function W:Watch(frame, key)
    if not frame or self.panels[frame] then return end
    self.panels[frame] = key; frame.aaeWorkbenchManaged = true
    frame:HookScript("OnShow", function(f)
        if not W.switching then W:Mount(f, key) end
    end)
    frame:HookScript("OnHide", function(f)
        N:ClearInputFocus(f)
        if W.active == f and not W.switching then W:Close() end
    end)
end
function W:RemoveSpecial(frame)
    local name = frame and frame:GetName()
    if not name then return end
    for i = #UISpecialFrames, 1, -1 do if UISpecialFrames[i] == name then UISpecialFrames[i] = "GMminibarUnusedEscapeSlot" end end
end
function W:EscapeEnabled(enabled)
    if not self.frame then return end
    self:RemoveSpecial(self.frame)
    if enabled then table.insert(UISpecialFrames, self.frame:GetName()) end
end
function W:SuspendForPopup(frame)
    if not frame or frame.aaeUXEscapeSuspended then return end
    frame.aaeUXEscapeSuspended = true
    self.popupDepth = (self.popupDepth or 0) + 1; self:EscapeEnabled(false)
    if not frame.aaeUXPopupHooked then
        frame.aaeUXPopupHooked = true
        frame:HookScript("OnHide", function(f)
            if not f.aaeUXEscapeSuspended then return end
            f.aaeUXEscapeSuspended = nil; W.popupDepth = math.max(0, (W.popupDepth or 1) - 1)
            A:RunAfter(0.02, function() W:EscapeEnabled((W.popupDepth or 0) == 0) end)
        end)
    end
end
function W:Mount(frame, key, showFunc)
    if self.switching then return true end
    self:Create()
    self:Watch(frame, key or self.panels[frame] or "commands")
    if self.LayoutModule then self:LayoutModule(frame, key or self.panels[frame]) end
    self.switching = true
    local previous = self.active
    if previous and previous ~= frame then
        self.history[#self.history + 1] = { previous, self.key }
        if #self.history > 20 then table.remove(self.history, 1) end
        previous.aaeReturnFrame = nil; previous.aaeSuppressRestore = true; previous:Hide()
    end
    self.active, self.key = frame, self.panels[frame]
    N:Fit(self.frame, self.width, self.height, self:DB().scale)
    frame.aaeReturnFrame = nil
    self:RemoveSpecial(frame)
    if frame:GetParent() ~= self.content then frame:SetParent(self.content) end
    frame:SetMovable(false); frame:SetClampedToScreen(false)
    frame:RegisterForDrag()
    frame:SetFrameStrata("DIALOG"); frame:SetFrameLevel(self.frame:GetFrameLevel() + 3)
    frame:ClearAllPoints(); frame:SetPoint("TOPLEFT", self.content, "TOPLEFT", 0, 0)
    local scale = math.min(1, 914 / math.max(1, frame:GetWidth()), 610 / math.max(1, frame:GetHeight()))
    frame:SetScale(scale)
    if frame.aaeBack then frame.aaeBack:SetScript("OnClick", function() W:Back() end) end
    N:SkinContent(frame)
    self.frame:Show()
    if showFunc then
        local ok = pcall(showFunc, frame)
        if not ok then
            self.switching = false; self.active = nil; self:Close()
            if previous then self:Mount(previous, self.panels[previous]) end
            return false
        end
    else frame:Show() end
    frame.aaeSuppressRestore = nil
    self.switching = false
    self:RefreshHeader(); self:RefreshNavigation()
    return true
end
function W:Close()
    if not self.frame or self.closing or self.captureHidden then return end
    self.closing, self.switching = true, true
    if self.active then self.active.aaeReturnFrame = nil; self.active.aaeSuppressRestore = true; self.active:Hide(); self.active.aaeSuppressRestore = nil end
    self.frame:Hide()
    self.switching, self.closing = false, false
end
function W:TakeScreenshot()
    if self.captureHidden then return end
    local shown = self.frame and self.frame:IsShown()
    self.captureHidden = true
    if shown then self.frame:Hide() end
    A:RunAfter(0.1, function()
        if Screenshot then Screenshot() end
        A:RunAfter(0.5, function()
            if shown then W.frame:Show() end
            W.captureHidden = nil
        end)
    end)
end
function W:Back()
    local previous = table.remove(self.history)
    if previous then self:Mount(previous[1], previous[2]); table.remove(self.history)
    else self:Navigate("commands") end
end
function W:Navigate(key)
    self:Create(); self:ClearFocus()
    if key == "commands" or key == "favorites" or key == "history" then
        self.mode = key; self.page = 1
        self:Mount(self.commandPanel, key)
        self.key = key; self:RefreshNavigation(); self:RefreshCommands()
    elseif self.key == key and self.frame:IsShown() then
        return
    else
        D:Open(key)
    end
end
function W:Show() self:Navigate("commands") end
function W:Toggle()
    if self.frame and self.frame:IsShown() then self:Close() else self:Show() end
end
function W:ClearFocus()
    N:ClearInputFocus(self.frame)
    N:ClearInputFocus(self.active)
    N:ClearInputFocus(self.settings)
    N:ClearInputFocus(self.picker)
end
function W:RefreshHeader()
    if not self.frame then return end
    local target = UnitExists("target") and (UnitName("target") or "") or ""
    if not self.target:HasFocus() then self.target:SetText(target) end
    self.security:SetText(D.client .. "  |  " .. L(D.configuredSecurity and "SECURITY_CONFIG" or "SECURITY") .. ": " .. tostring(D:Security() or L("UNKNOWN")))
    self:RefreshQuick()
end
function W:Choose(entry)
    self.selected = entry; self.rawMode = false
    self.args:SetText(""); self:UpdatePreview()
    self.detail:SetText(D:Label(entry.definition) .. "\n" .. (entry.definition.hint or entry.definition.notes or "") .. "\n" .. L("SELECT_HINT"))
    self:RefreshCommands()
end
function W:UpdatePreview()
    if not self.raw or self.rawMode then return end
    self.updatingPreview = true
    self.raw:SetText(self.selected and D:Preview(self.selected, trim(self.args:GetText()), trim(self.target:GetText())) or "")
    self.updatingPreview = false
end
function W:Run(entry)
    self:Create()
    entry = entry or (not self.rawMode and self.selected)
    self:ClearFocus()
    if entry then
        local allowed = D:Allowed(entry)
        if not allowed then self.status:SetText(L("LOCKED")); return end
        D:Execute(entry, trim(self.args:GetText()), trim(self.target:GetText()))
    elseif trim(self.raw:GetText()) ~= "" then D:Raw(trim(self.raw:GetText()))
    else self.status:SetText(L("SELECT_HINT")); return end
    self.status:SetText(L("DISPATCH_HINT"))
    self:RefreshQuick()
end
function W:RefreshQuick()
    if not self.quickButtons then return end
    local slots = self:DB().quick
    for i, button in ipairs(self.quickButtons) do
        local entry = C.byKey and C.byKey[slots[i]]
        button.entry = entry
        button:SetText(tostring(i) .. ": " .. (entry and entry.label or L("EMPTY_SLOT")))
        N:Hint(button, entry and entry.label or L("EMPTY_SLOT"), A:XL("QUICK_HINT2"))
    end
end
function W:RefreshNavigation()
    for key, button in pairs(self.nav or {}) do
        button:SetButtonState(key == self.key and "PUSHED" or "NORMAL", key == self.key)
        if button:GetFontString() then button:GetFontString():SetTextColor(key == self.key and 1 or 0.8, key == self.key and 0.82 or 0.75, key == self.key and 0 or 0.6) end
    end
end
function W:RefreshCommands()
    if not self.commandPanel then return end
    local results = {}
    if self.mode == "history" then
        for i, command in ipairs(D:History()) do
            if type(command) == "string" then results[#results + 1] = { raw = command, label = command, key = "history:" .. i } end
        end
    else results = C:Filter(self.search:GetText(), self.group, self.mode == "favorites", D) end
    self.results = results
    for key, button in pairs(self.groupButtons or {}) do button:SetButtonState(key == self.group and "PUSHED" or "NORMAL", key == self.group) end
    if self.selected and not self.rawMode and self.mode ~= "history" then
        local found = false
        for _, entry in ipairs(results) do
            if entry == self.selected or (entry.variants and entry.variants[2] == self.selected) then found = true; break end
        end
        if not found then
            self.selected = nil; self.args:SetText(""); self:UpdatePreview()
            self.detail:SetText(L("SELECT_HINT"))
        end
    end
    self.pageCount = math.max(1, math.ceil(#results / PAGE_SIZE))
    self.page = math.max(1, math.min(self.page, self.pageCount))
    for i, row in ipairs(self.rows) do
        local entry = results[(self.page - 1) * PAGE_SIZE + i]
        row.entry = entry
        if entry then
            local allowed = entry.raw or D:Allowed(entry)
            row.label:SetText(entry.label)
            row.label:SetTextColor(allowed and 1 or 0.5, allowed and 0.82 or 0.5, allowed and 0.35 or 0.5)
            row.command:SetText(entry.raw or entry.definition.command or entry.category)
            row.favorite:SetText(not entry.raw and D:IsFavorite(entry) and "*" or "+")
            row.pairOn:Hide(); row.pairOff:Hide()
            if entry.variants then row.pairOn:Show(); row.pairOff:Show() end
            local selected = self.selected == entry or (entry.variants and entry.variants[2] == self.selected)
            row:SetBackdropColor(selected and 0.23 or 0.05, selected and 0.17 or 0.045, 0.025, 1)
            row:Show()
        else row:Hide() end
    end
    self.empty:SetText(#results == 0 and L(self.mode == "favorites" and "NO_FAVORITES" or "NO_RESULTS") or "")
    self.pageText:SetText(self.page .. " / " .. self.pageCount .. "  |  " .. #results .. " " .. L("RESULTS"))
    if self.page > 1 then self.prev:Enable() else self.prev:Disable() end
    if self.page < self.pageCount then self.next:Enable() else self.next:Disable() end
end
function W:Create()
    if self.frame then return end
    C:Build(D)
    local db = self:DB()
    if not db.quickInitialized then
        local count = 0
        for _, entry in ipairs(C.entries) do
            if legacyFavorite(D, entry) then count = count + 1; db.quick[count] = entry.key; if count == 4 then break end end
        end
        for _, key in ipairs(D.InitialQuickKeys and D:InitialQuickKeys() or {}) do
            local exists = false
            for _, current in ipairs(db.quick) do if current == key then exists = true end end
            if not exists and C.byKey[key] and count < 4 then count = count + 1; db.quick[count] = key end
        end
        db.quickInitialized = true
    end
    local root = CreateFrame("Frame", D.namespace, UIParent)
    self.frame = root
    root:SetWidth(self.width); root:SetHeight(self.height); root:SetFrameStrata("DIALOG")
    root:EnableMouse(true); root:SetMovable(true); root:SetClampedToScreen(true); root:Hide()
    N:Panel(root); N:Fit(root, self.width, self.height, db.scale)
    root:SetPoint("CENTER", UIParent, "CENTER", (tonumber(db.x) or 0) / root:GetScale(), (tonumber(db.y) or 0) / root:GetScale())
    root:SetScript("OnHide", function()
        if W.captureHidden then return end
        if not W.closing then W:Close() end
        if W.restoreToolbar and A.toolbar then A.toolbar:Show() end
        W.restoreToolbar = nil
    end)
    root:SetScript("OnShow", function()
        if W.captureHidden then return end
        W.restoreToolbar = A.toolbar and A.toolbar:IsShown()
        if W.restoreToolbar then A.toolbar:Hide() end
    end)
     table.insert(UISpecialFrames, root:GetName())
    local drag = CreateFrame("Frame", nil, root)
    drag:SetPoint("TOPLEFT", root, "TOPLEFT", 12, -8); drag:SetWidth(540); drag:SetHeight(30)
    drag:EnableMouse(true); drag:RegisterForDrag("LeftButton")
    drag:SetScript("OnDragStart", function() root:StartMoving() end)
    drag:SetScript("OnDragStop", function()
        root:StopMovingOrSizing()
        local x, y = root:GetCenter(); local px, py = UIParent:GetCenter()
        local ratio = root:GetEffectiveScale() / UIParent:GetEffectiveScale()
        local ux = W:DB(); ux.x, ux.y = x * ratio - px, y * ratio - py
        root:ClearAllPoints(); root:SetPoint("CENTER", UIParent, "CENTER", ux.x / root:GetScale(), ux.y / root:GetScale())
    end)
    local title = N:Text(drag, "AzerothAdmin 3.6 RC2", 160)
    title:SetPoint("LEFT", drag, "LEFT", 8, 0)
    self.security = N:Text(drag, "", 360, true); self.security:SetPoint("LEFT", title, "RIGHT", 8, 0)
    local locales = { "koKR", "enUS", "zhCN", "zhTW", "ruRU" }
    local labels = { "KO", "EN", "CN", "TW", "RU" }
    for i, locale in ipairs(locales) do
        local chosenLocale = locale
        local language = N:Button(root, labels[i], 34, 22, function() D:Language(chosenLocale) end)
        language:SetButtonState(D:Locale() == locale and "PUSHED" or "NORMAL", D:Locale() == locale)
        language:SetPoint("TOPRIGHT", root, "TOPRIGHT", -198 + (i - 1) * 36, -12)
        N:Hint(language, L("LANGUAGE"), L("RELOAD_LANGUAGE"))
    end
    local close = CreateFrame("Button", nil, root, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", root, "TOPRIGHT", -4, -4); close:SetScript("OnClick", function() W:Close() end)
    local bar = CreateFrame("Frame", nil, root); N:Panel(bar, true)
    bar:SetPoint("TOPLEFT", root, "TOPLEFT", 14, -43); bar:SetWidth(1092); bar:SetHeight(58)
    local targetLabel = N:Text(bar, L("TARGET"), 190, true); targetLabel:SetPoint("TOPLEFT", bar, "TOPLEFT", 10, -6)
    self.target = N:Edit(bar, 190); self.target:SetPoint("TOPLEFT", bar, "TOPLEFT", 10, -24)
    N:Hint(self.target, L("TARGET"), L("TARGET_HINT"))
    local argsLabel = N:Text(bar, L("ARGS"), 295, true); argsLabel:SetPoint("TOPLEFT", bar, "TOPLEFT", 212, -6)
    self.args = N:Edit(bar, 295); self.args:SetPoint("TOPLEFT", bar, "TOPLEFT", 212, -24)
    local rawLabel = N:Text(bar, L("RAW"), 480, true); rawLabel:SetPoint("TOPLEFT", bar, "TOPLEFT", 519, -6)
    self.raw = N:Edit(bar, 469); self.raw:SetPoint("TOPLEFT", bar, "TOPLEFT", 519, -24)
    self.target:SetScript("OnTextChanged", function() W:UpdatePreview() end)
    self.args:SetScript("OnTextChanged", function() W:UpdatePreview() end)
    self.raw:SetScript("OnTextChanged", function(_, userInput) if userInput and not W.updatingPreview then W.rawMode = true end end)
    for _, edit in ipairs({ self.target, self.args, self.raw }) do edit:SetScript("OnEnterPressed", function() W:Run() end) end
    local run = N:Button(bar, L("RUN"), 82, 28, function() W:Run() end); run:SetPoint("LEFT", self.raw, "RIGHT", 10, 0)
    self.nav = {}
    local menus = { "commands", "favorites", "history", "search", "teleports", "quests", "creatures", "items", "professions", "bank" }
    if D.hasDatabase then menus[#menus + 1] = "database" end
    for i, key in ipairs(menus) do
        local route = key
        local button = N:Button(root, L(string.upper(key)), 163, 35, function() W:Navigate(route) end)
        button:SetPoint("TOPLEFT", root, "TOPLEFT", 14, -110 - (i - 1) * 41); self.nav[key] = button
    end
    local back = N:Button(root, L("BACK"), 78, 24, function() W:Back() end); back:SetPoint("BOTTOMLEFT", root, "BOTTOMLEFT", 14, 52)
    local reset = N:Button(root, L("CENTER"), 78, 24, function()
        W:DB().x = 0; W:DB().y = 0; root:ClearAllPoints(); root:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    end); reset:SetPoint("LEFT", back, "RIGHT", 6, 0)
    local function resize(delta)
        local ux = W:DB(); ux.scale = math.max(0.65, math.min(1.15, (tonumber(ux.scale) or 1) + delta))
        N:Fit(root, W.width, W.height, ux.scale)
    end
    local smaller = N:Button(root, "-", 28, 22, function() resize(-0.05) end); smaller:SetPoint("BOTTOMLEFT", root, "BOTTOMLEFT", 14, 83)
    local larger = N:Button(root, "+", 28, 22, function() resize(0.05) end); larger:SetPoint("LEFT", smaller, "RIGHT", 5, 0)
    local scaleLabel = N:Text(root, L("UI_SCALE"), 90, true); scaleLabel:SetPoint("LEFT", larger, "RIGHT", 6, 0)
    local companion = CreateFrame("CheckButton", nil, root, "UICheckButtonTemplate")
    companion:SetWidth(24); companion:SetHeight(24); companion:SetPoint("BOTTOMLEFT", root, "BOTTOMLEFT", 14, 117)
    companion:SetChecked(db.questCompanion)
    local companionLabel = N:Text(root, L("QUEST_AUTO"), 135, true); companionLabel:SetPoint("LEFT", companion, "RIGHT", 2, 0)
    companion:SetScript("OnClick", function(self)
        W:DB().questCompanion = self:GetChecked() and true or false
        if A.QuestLogBridge then A.QuestLogBridge:UpdateVisibility() end
    end)
    self.content = CreateFrame("Frame", nil, root)
    self.content:SetWidth(914); self.content:SetHeight(610); self.content:SetPoint("TOPLEFT", root, "TOPLEFT", 190, -108)
    self:CreateCommands()
    self.quickButtons = {}
    for i = 1, 4 do
        local slot = i
        local button = N:Button(root, "", 214, 25)
        button:SetPoint("BOTTOMLEFT", root, "BOTTOMLEFT", 190 + (i - 1) * 224, 10)
        button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
        button:SetScript("OnClick", function(self, mouse)
            if mouse == "RightButton" then
                W:OpenSlotPicker(slot, self)
            elseif self.entry then
                W:Choose(self.entry); W:Run(self.entry)
            end
        end)
        self.quickButtons[i] = button
    end
    self.status = N:Text(root, L("READY"), 900, true); self.status:SetHeight(14); self.status:SetPoint("BOTTOMLEFT", root, "BOTTOMLEFT", 194, 39)
    local esc = N:Text(root, L("ESC_HINT"), 163, true); esc:SetPoint("BOTTOMLEFT", root, "BOTTOMLEFT", 14, 15)
    self:RefreshHeader()
    root:RegisterEvent("PLAYER_TARGET_CHANGED")
    root:RegisterEvent("CHAT_MSG_SYSTEM")
    root:SetScript("OnEvent", function(_, event, message)
        W:RefreshHeader()
        if event == "CHAT_MSG_SYSTEM" and root:IsShown() and type(message) == "string" then
            W.status:SetText((message:gsub("[\r\n]", " ")))
        end
    end)
    N:OnViewportChanged(function() N:Fit(root, W.width, W.height, W:DB().scale) end)
end
function W:CreateCommands()
    local panel = CreateFrame("Frame", nil, self.content)
    panel:SetWidth(712); panel:SetHeight(460); panel:Hide(); self.commandPanel = panel
    self:Watch(panel, "commands")
    local heading = N:Text(panel, L("COMMANDS_TITLE"), 600); heading:SetPoint("TOPLEFT", panel, "TOPLEFT", 14, -14)
    self.search = N:Edit(panel, 570); self.search:SetPoint("TOPLEFT", panel, "TOPLEFT", 14, -42)
    self.search:SetScript("OnTextChanged", function() W.page = 1; W:RefreshCommands() end)
    N:Hint(self.search, L("SEARCH"), L("SEARCH_HINT"))
    local clear = N:Button(panel, L("CLEAR"), 74, 26, function() W.search:SetText("") end); clear:SetPoint("LEFT", self.search, "RIGHT", 8, 0)
    local groups = { "all", "gm", "character", "movement", "world", "content", "server" }
    self.groupButtons = {}
    for i, key in ipairs(groups) do
        local group = key
        local button = N:Button(panel, L("GROUP_" .. string.upper(key)), 92, 25, function() W.group = group; W.page = 1; W:RefreshCommands() end)
        button:SetPoint("TOPLEFT", panel, "TOPLEFT", 14 + (i - 1) * 96, -78)
        self.groupButtons[key] = button
    end
    self.rows = {}
    for i = 1, PAGE_SIZE do
        local row = CreateFrame("Button", nil, panel); row:SetWidth(684); row:SetHeight(29); N:Panel(row, true)
        row:SetPoint("TOPLEFT", panel, "TOPLEFT", 14, -113 - (i - 1) * 32)
        row.label = N:Text(row, "", 240, true); row.label:SetPoint("LEFT", row, "LEFT", 10, 0)
        row.command = N:Text(row, "", 240, true); row.command:SetPoint("LEFT", row, "LEFT", 260, 0)
        row:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")
        row:SetScript("OnClick", function(self)
            if not self.entry then return end
            if self.entry.raw then W.selected = nil; W.rawMode = true; W.raw:SetText(self.entry.raw)
            else W:Choose(self.entry) end
        end)
        row.favorite = N:Button(row, "+", 26, 25, function()
            if row.entry and not row.entry.raw then D:Favorite(row.entry); W:RefreshCommands(); W:RefreshQuick() end
        end); row.favorite:SetPoint("RIGHT", row, "RIGHT", -6, 0)
        row.pairOn = N:Button(row, L("ON"), 55, 24, function() if row.entry and row.entry.variants then W:Choose(row.entry.variants[1]); W:Run(row.entry.variants[1]) end end)
        row.pairOn:SetPoint("RIGHT", row.favorite, "LEFT", -66, 0)
        row.pairOff = N:Button(row, L("OFF"), 55, 24, function() if row.entry and row.entry.variants then W:Choose(row.entry.variants[2]); W:Run(row.entry.variants[2]) end end)
        row.pairOff:SetPoint("RIGHT", row.favorite, "LEFT", -6, 0)
        row:Hide(); self.rows[i] = row
    end
    self.empty = N:Text(panel, "", 820); self.empty:SetPoint("TOPLEFT", panel, "TOPLEFT", 28, -146)
    self.prev = N:Button(panel, "<", 50, 24, function() W.page = W.page - 1; W:RefreshCommands() end)
    self.prev:SetPoint("TOPLEFT", panel, "TOPLEFT", 14, -376)
    self.pageText = N:Text(panel, "", 220, true); self.pageText:SetPoint("LEFT", self.prev, "RIGHT", 14, 0)
    self.next = N:Button(panel, ">", 50, 24, function() W.page = W.page + 1; W:RefreshCommands() end); self.next:SetPoint("LEFT", self.pageText, "RIGHT", 8, 0)
    self.detail = N:Text(panel, L("SELECT_HINT"), 860, true); self.detail:SetHeight(42); self.detail:SetJustifyV("TOP"); self.detail:SetPoint("TOPLEFT", panel, "TOPLEFT", 14, -413)
    panel:EnableMouseWheel(true)
    panel:SetScript("OnMouseWheel", function(_, delta) W.page = W.page + (delta > 0 and -1 or 1); W:RefreshCommands() end)
    self:RefreshCommands()
end

local events = CreateFrame("Frame")
events:RegisterEvent("PLAYER_LOGIN")
events:SetScript("OnEvent", function()
    W:DB()
    for _, item in ipairs(D:Frames()) do if item[1] then W:Watch(item[1], item[2]) end end
end)
