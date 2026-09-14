-- Canonical AzerothAdmin 3.5.0-335a shell layout, AC335 command/data adapter.
local A = AzerothAdminAC335
A.UI = type(A.UI) == "table" and A.UI or {}
local UI = A.UI

-- Bootstrap fallback.  The previous package could capture A.UI as nil when an
-- older AC335 addon or a partially overwritten TOC replaced/skipped the shared UI
-- component file.  Keep the shell independently bootable so the minibar, minimap
-- button, /aaac and /aaac test always have a recovery path.
if type(UI.CreateWindow) ~= "function" then

    UI.styles = {
        normal   = { 0.025, 0.040, 0.055, 1.00, 0.48, 0.43, 0.31, 1.00, 0.92, 0.78, 0.28 },
        utility  = { 0.025, 0.090, 0.110, 1.00, 0.12, 0.63, 0.68, 1.00, 0.43, 0.92, 0.95 },
        reward   = { 0.035, 0.105, 0.055, 1.00, 0.30, 0.67, 0.30, 1.00, 0.66, 0.95, 0.45 },
        danger   = { 0.130, 0.045, 0.025, 1.00, 0.72, 0.25, 0.12, 1.00, 1.00, 0.48, 0.25 },
        active   = { 0.035, 0.160, 0.180, 1.00, 0.18, 0.88, 0.92, 1.00, 1.00, 0.82, 0.24 },
        disabled = { 0.025, 0.030, 0.035, 0.94, 0.14, 0.16, 0.18, 0.80, 0.40, 0.42, 0.43 },
    }

    UI.windowBackdrop = {
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 14,
        insets = { left = 4, right = 4, top = 4, bottom = 4 },
    }

    UI.buttonBackdrop = {
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 12, edgeSize = 8,
        insets = { left = 2, right = 2, top = 2, bottom = 2 },
    }

    function UI:ApplyStyle(button, name)
        if not button then return end
        local style = self.styles[name] or self.styles.normal
        button.aaeStyle = name or "normal"
        if button.SetBackdropColor then
            button:SetBackdropColor(style[1], style[2], style[3], style[4])
            button:SetBackdropBorderColor(style[5], style[6], style[7], style[8])
        end
        if button.aaeLabel then button.aaeLabel:SetTextColor(style[9], style[10], style[11]) end
    end

    function UI:SetEnabled(button, enabled)
        if not button then return end
        if enabled then
            button:Enable()
            if button.aaeIconButton then
                self:SetIconActive(button, button.aaeToggleActive)
            else
                self:ApplyStyle(button, button.aaeEnabledStyle or "normal")
            end
            if button.aaeIcon then button.aaeIcon:SetVertexColor(1, 1, 1, 1) end
        else
            button:Disable()
            if button.aaeIconButton then
                button:SetBackdropColor(0.025, 0.030, 0.035, 0.94)
                button:SetBackdropBorderColor(0.14, 0.16, 0.18, 0.80)
            else
                self:ApplyStyle(button, "disabled")
            end
            if button.aaeIcon then button.aaeIcon:SetVertexColor(0.35, 0.35, 0.35, 1) end
        end
    end

    function UI:SetActive(button, active)
        if not button then return end
        if active then
            button:Disable()
            self:ApplyStyle(button, "active")
        else
            button:Enable()
            self:ApplyStyle(button, button.aaeEnabledStyle or "normal")
        end
    end

    function UI:SetIconActive(button, active)
        if not button then return end
        button.aaeToggleActive = active and true or false
        if active then
            button:SetBackdropColor(0.035, 0.24, 0.12, 1)
            button:SetBackdropBorderColor(0.30, 1.00, 0.58, 1)
        else
            button:SetBackdropColor(0.13, 0.085, 0.025, 1)
            button:SetBackdropBorderColor(0.95, 0.63, 0.12, 1)
        end
    end

    function UI:Text(parent, text, size)
        local value = parent:CreateFontString(nil, "OVERLAY")
        value:SetFontObject(A:GetFontObject(size))
        value:SetText(text or "")
        return value
    end

    function UI:Button(parent, width, height, text, style, justify)
        local button = CreateFrame("Button", nil, parent)
        button:SetWidth(width)
        button:SetHeight(height)
        button:SetBackdrop(self.buttonBackdrop)

        local label = button:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        label:SetPoint("LEFT", button, "LEFT", 6, 0)
        label:SetPoint("RIGHT", button, "RIGHT", -6, 0)
        label:SetJustifyH(justify or "CENTER")
        button.aaeLabel = label
        button.SetText = function(self, value)
            self.aaeText = value or ""
            self.aaeLabel:SetText(self.aaeText)
        end
        button.GetText = function(self) return self.aaeText or "" end
        button:SetText(text or "")
        button.aaeEnabledStyle = style or "normal"
        self:ApplyStyle(button, style or "normal")

        button:SetScript("OnMouseDown", function(self)
            if self:IsEnabled() then self:SetBackdropColor(0.025, 0.26, 0.30, 1) end
        end)
        button:SetScript("OnMouseUp", function(self)
            if self:IsEnabled() then UI:ApplyStyle(self, self.aaeStyle) end
        end)
        return button
    end

    function UI:IconButton(parent, size, icon, hint)
        local button = CreateFrame("Button", nil, parent)
        button.aaeIconButton = true
        button:SetWidth(size)
        button:SetHeight(size == 28 and 24 or size)
        button:SetBackdrop({
            bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true, tileSize = 8, edgeSize = 8,
            insets = { left = 2, right = 2, top = 2, bottom = 2 },
        })
        button:SetBackdropColor(0.13, 0.085, 0.025, 1)
        button:SetBackdropBorderColor(0.95, 0.63, 0.12, 1)
        local texture = button:CreateTexture(nil, "ARTWORK")
        texture:SetPoint("TOPLEFT", button, "TOPLEFT", 3, -3)
        texture:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -3, 3)
        texture:SetTexture(icon)
        button.aaeIcon = texture
        button.aaeHint = hint
        button:SetScript("OnEnter", function(self)
            self:SetBackdropColor(0.11, 0.31, 0.39, 1)
            self:SetBackdropBorderColor(1, 0.78, 0.18, 1)
            if self.aaeHint then
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:SetText(self.aaeTitle or "AzerothAdmin", 1, 0.82, 0.18)
                GameTooltip:AddLine(self.aaeHint, 1, 1, 1, true)
                GameTooltip:Show()
            end
        end)
        button:SetScript("OnLeave", function(self)
            UI:SetIconActive(self, self.aaeToggleActive)
            GameTooltip:Hide()
        end)
        return button
    end

    function UI:EditBox(parent, width, height, name)
        local edit = CreateFrame("EditBox", name, parent)
        edit:SetWidth(width)
        edit:SetHeight(height)
        edit:SetAutoFocus(false)
        edit:SetFontObject(ChatFontNormal)
        edit:SetTextInsets(7, 7, 1, 1)
        edit:SetBackdrop(self.buttonBackdrop)
        edit:SetBackdropColor(0.025, 0.035, 0.045, 0.98)
        edit:SetBackdropBorderColor(0.20, 0.33, 0.38, 0.95)
        edit:SetScript("OnEditFocusGained", function(self) self:SetBackdropBorderColor(0.15, 0.72, 0.78, 1) end)
        edit:SetScript("OnEditFocusLost", function(self) self:SetBackdropBorderColor(0.20, 0.33, 0.38, 0.95) end)
        edit:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
        return edit
    end

    function UI:Panel(parent)
        local frame = CreateFrame("Frame", nil, parent)
        frame:SetBackdrop(self.buttonBackdrop)
        frame:SetBackdropColor(0.012, 0.020, 0.028, 0.92)
        frame:SetBackdropBorderColor(0.34, 0.31, 0.23, 1)
        return frame
    end

    function UI:Check(parent, width, text, checked, onClick)
        local button = CreateFrame("CheckButton", nil, parent)
        local hitWidth = math.max(24, tonumber(width) or 130)
        button:SetWidth(20); button:SetHeight(20)
        button:SetNormalTexture("Interface\\Buttons\\UI-CheckBox-Up")
        button:SetPushedTexture("Interface\\Buttons\\UI-CheckBox-Down")
        button:SetHighlightTexture("Interface\\Buttons\\UI-CheckBox-Highlight", "ADD")
        button:SetCheckedTexture("Interface\\Buttons\\UI-CheckBox-Check")
        button:SetDisabledCheckedTexture("Interface\\Buttons\\UI-CheckBox-Check-Disabled")
        if button.SetHitRectInsets then button:SetHitRectInsets(0, -(hitWidth - 20), 0, 0) end
        button:SetChecked(checked and true or false)
        local label = self:Text(button, text or "", "small")
        label:SetPoint("LEFT", button, "RIGHT", 4, 0)
        label:SetWidth(hitWidth - 24); label:SetJustifyH("LEFT")
        label:SetTextColor(0.82, 0.90, 0.92)
        button.aaeLabel = label; button.aaeHitWidth = hitWidth
        if onClick then button:SetScript("OnClick", onClick) end
        return button
    end

    function UI:RowLabel(parent, width, height)
        local button = self:Button(parent, width, height, "", "normal", "LEFT")
        return button
    end

    function UI:SavePoint(frame, key)
        if not frame or not frame.GetPoint then return end
        local point, _, relativePoint, x, y = frame:GetPoint()
        A:GetDB().windowPoints[key] = { point = point, relativePoint = relativePoint, x = x, y = y }
    end

    function UI:RestorePoint(frame, key, dx, dy)
        local data = A:GetDB().windowPoints[key]
        frame:ClearAllPoints()
        if data then
            frame:SetPoint(data.point or "CENTER", UIParent, data.relativePoint or data.point or "CENTER", data.x or 0, data.y or 0)
        else
            frame:SetPoint("CENTER", UIParent, "CENTER", dx or 0, dy or 0)
        end
    end

    function UI:CreateWindow(key, title, width, height, borderStrength)
        if A.windows[key] then return A.windows[key] end
        local frame = CreateFrame("Frame", "AzerothAdminAC335_" .. key, UIParent)
        frame:SetWidth(width)
        frame:SetHeight(height)
        frame:SetFrameStrata("FULLSCREEN_DIALOG")
        frame:SetMovable(true)
        frame:EnableMouse(true)
        frame:SetClampedToScreen(true)
        frame:RegisterForDrag("LeftButton")
        frame:SetBackdrop(self.windowBackdrop)
        frame:SetBackdropColor(0.018, 0.025, 0.035, 0.985)
        if borderStrength == "strong" then
            frame:SetBackdropBorderColor(0.95, 0.58, 0.10, 1)
        else
            frame:SetBackdropBorderColor(0.72, 0.52, 0.18, 1)
        end
        frame:Hide()
        self:RestorePoint(frame, key)
        frame:SetScript("OnDragStart", function(self) self:StartMoving() end)
        frame:SetScript("OnDragStop", function(self) self:StopMovingOrSizing(); UI:SavePoint(self, key) end)

        local heading = self:Text(frame, title or "", "large")
        heading:SetPoint("TOPLEFT", frame, "TOPLEFT", 14, -12)
        heading:SetTextColor(1, 0.78, 0.25)
        frame.aaeTitle = heading
        frame.aaeWindowKey = key
        if key ~= "main" and key ~= "argument" and key ~= "confirm" then
            local back = self:Button(frame, 72, 20, "← " .. A:L("BACK"), "utility")
            back:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -78, -8)
            back:SetScript("OnClick", function() UI:GoBack(frame) end)
            frame.aaeBack = back
        end
        local close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
        close:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -5, -5)
        frame.aaeClose = close

        A:RegisterWindow(key, frame)
        table.insert(UISpecialFrames, frame:GetName())
        return frame
    end

    function UI:AddAccent(frame, y)
        local line = frame:CreateTexture(nil, "ARTWORK")
        line:SetTexture(0.72, 0.52, 0.18, 0.85)
        line:SetPoint("TOPLEFT", frame, "TOPLEFT", 12, y or -53)
        line:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -12, y or -53)
        line:SetHeight(1)
        return line
    end

    function UI:GetShownWindow(except)
        for _, key in ipairs(A.windowOrder or {}) do
            local candidate = A.windows[key]
            if candidate and candidate ~= except and candidate.IsShown and candidate:IsShown() then return candidate end
        end
        return nil
    end

    function UI:ShowWindow(frame, skipHistory)
        if not frame then return end
        local current = self:GetShownWindow(frame)
        if current and not skipHistory and current.aaeWindowKey then
            A.windowHistory = A.windowHistory or {}
            local last = A.windowHistory[table.getn(A.windowHistory)]
            if last ~= current.aaeWindowKey then table.insert(A.windowHistory, current.aaeWindowKey) end
            while table.getn(A.windowHistory) > 20 do table.remove(A.windowHistory, 1) end
        end
        A:HideAddonWindows(frame)
        frame:Show()
        frame:Raise()
    end

    function UI:GoBack(frame)
        A.windowHistory = A.windowHistory or {}
        while table.getn(A.windowHistory) > 0 do
            local key = table.remove(A.windowHistory)
            local previous = A.windows[key]
            if previous and previous ~= frame then self:ShowWindow(previous, true); return true end
        end
        if A.ShowMainWindow then A:ShowMainWindow(); return true end
        return false
    end

    function UI:BindMouseWheel(frame, previous, nextButton)
        if not frame then return end
        frame:EnableMouseWheel(true)
        frame:SetScript("OnMouseWheel", function(_, delta)
            local button = delta > 0 and previous or nextButton
            if button and button:IsEnabled() then
                local handler = button:GetScript("OnClick")
                if handler then handler(button) end
            end
        end)
    end

    function UI:ShowHint(owner, title, lines, anchor)
        GameTooltip:SetOwner(owner, anchor or "ANCHOR_RIGHT")
        GameTooltip:SetText(title or "AzerothAdmin", 1, 0.82, 0.18)
        if type(lines) == "table" then
            for _, line in ipairs(lines) do GameTooltip:AddLine(tostring(line), 1, 1, 1, true) end
        elseif lines then
            GameTooltip:AddLine(tostring(lines), 1, 1, 1, true)
        end
        GameTooltip:Show()
    end

    UI.__source = "Modules/Shell/UI.lua fallback"
    UI.__ready = true
end

local COMMANDS_PER_PAGE = 20

local function sortCategories()
    table.sort(A.CategoryOrder, function(left, right)
        return (A.Categories[left].order or 100) < (A.Categories[right].order or 100)
    end)
end

local function commandStyle(definition)
    if not definition then return "normal" end
    if definition.style then return definition.style end
    if definition.dangerous then return "danger" end
    local command = string.lower(definition.command or "")
    if string.find(command, ".additem", 1, true)
        or string.find(command, ".learn", 1, true)
        or string.find(command, ".revive", 1, true)
        or string.find(command, ".quest complete", 1, true) then
        return "reward"
    end
    if definition.action
        or string.find(command, ".lookup", 1, true)
        or string.find(command, ".gm ", 1, true)
        or string.find(command, ".cheat", 1, true)
        or string.find(command, ".modify speed", 1, true) then
        return "utility"
    end
    return "normal"
end

local function commandIcon(definition)
    local command = string.lower((definition and definition.command) or "")
    local action = (definition and definition.action) or ""
    if action == "OpenTeleportWindow" then return "Interface\\Icons\\INV_Misc_Map_01" end
    if action == "OpenQuestHelper" then return "Interface\\Icons\\INV_Misc_Book_07" end
    if action == "OpenItemBrowser" then return "Interface\\AddOns\\GMminibar\\Embedded\\BlueItemInfo3\\ItemInfoR3" end
    if action == "OpenProfessionWindow" then return "Interface\\Icons\\Trade_Engineering" end
    if action == "OpenDatabaseWindow" then return "Interface\\Icons\\INV_Misc_Book_11" end
    if action == "OpenSearchWindow" then return "Interface\\Icons\\INV_Misc_Spyglass_02" end
    if action == "OpenLanguageWindow" then return "Interface\\Icons\\INV_Misc_Note_05" end
    if action == "OpenIntegrationsWindow" then return "Interface\\Icons\\INV_Misc_Gear_01" end
    if string.find(command, ".die", 1, true) then return "Interface\\Icons\\Ability_Creature_Cursed_02" end
    if string.find(command, ".revive", 1, true) then return "Interface\\Icons\\Spell_Holy_Resurrection" end
    if string.find(command, "visible", 1, true) then return "Interface\\Icons\\Ability_Stealth" end
    if string.find(command, "fly", 1, true) then return "Interface\\Icons\\Ability_Druid_FlightForm" end
    if string.find(command, "speed", 1, true) then return "Interface\\Icons\\Ability_Rogue_Sprint" end
    if string.find(command, ".additem", 1, true) then return "Interface\\Icons\\INV_Misc_Bag_10_Blue" end
    if string.find(command, "money", 1, true) then return "Interface\\Icons\\INV_Misc_Coin_01" end
    if string.find(command, ".levelup", 1, true) then return "Interface\\Icons\\Spell_Holy_DivineSpirit" end
    if string.find(command, ".learn", 1, true) then return "Interface\\Icons\\INV_Misc_Book_09" end
    if string.find(command, ".lookup", 1, true) then return "Interface\\Icons\\INV_Misc_Spyglass_02" end
    if string.find(command, ".quest", 1, true) then return "Interface\\Icons\\INV_Misc_Note_02" end
    if string.find(command, ".npc", 1, true) or string.find(command, ".creature", 1, true) then return "Interface\\Icons\\INV_Misc_Head_Dragon_01" end
    if string.find(command, ".server", 1, true) then return "Interface\\Icons\\INV_Misc_Gear_01" end
    return "Interface\\Icons\\INV_Misc_Gear_01"
end

local function showButtonTooltip(self)
    if not self.aaeHint then return end
    UI:ShowHint(self, self:GetText(), self.aaeHint, "ANCHOR_RIGHT")
end

function A:BuildMainInfoLine()
    return self:L("MAIN_INFO_LINE", self:GetAccountSecurity(), self.releaseDate or "2026-09-04")
end

function A:RefreshSecurityDisplays()
    local level = self:GetAccountSecurity()
    if self.subtitle then self.subtitle:SetText(self:BuildMainInfoLine()) end
    if self.argumentFrame and self.argumentFrame.securityText then self.argumentFrame.securityText:SetText(tostring(level)) end
    if self.currentCategory then self:ShowCategory(self.currentCategory, self.currentCommandPage or 1, true) end
    self:RefreshToolbarPermissions()
end

function A:ShowCategory(categoryID, page, refreshOnly)
    local category = self.Categories[categoryID]
    if not category then
        categoryID = self.CategoryOrder[1]
        category = self.Categories[categoryID]
    end
    if not category then return end

    if category.action and not refreshOnly then
        local action = self[category.action]
        if type(action) == "function" then action(self); return end
    end

    self.currentCategory = categoryID
    self.currentCommandPage = math.max(1, tonumber(page) or 1)
    local db = self:GetDB()
    db.lastCategory = categoryID
    db.lastCommandPage = self.currentCommandPage

    local definitions = self:GetCategoryCommands(categoryID)
    local pageCount = math.max(1, math.ceil(table.getn(definitions) / COMMANDS_PER_PAGE))
    if self.currentCommandPage > pageCount then self.currentCommandPage = pageCount end
    local first = ((self.currentCommandPage - 1) * COMMANDS_PER_PAGE) + 1

    for index = 1, COMMANDS_PER_PAGE do
        local button = self.commandButtons[index]
        local definition = definitions[first + index - 1]
        button.aaeDefinition = definition
        if definition then
            local favorite = self:IsCommandFavorite(definition.id) and "★ " or ""
            button:SetText(favorite .. self:L(definition.labelKey))
            button.aaeHint = ((definition.command and definition.command ~= "") and definition.command or "[UI action]")
                .. "\n" .. (definition.notes or self:L("TOOLTIP_RIGHTCLICK"))
            button.aaeEnabledStyle = commandStyle(definition)
            button.aaeCommandIcon:SetTexture(commandIcon(definition))
            button.aaeResultText:SetText(definition.verified == false and "?" or tostring(definition.security or 0))
            button:Show()
            UI:SetEnabled(button, self:CanRunCommand(definition))
        else
            button.aaeDefinition = nil
            button:Hide()
        end
    end

    self.commandPageText:SetText(self:L("PAGE", self.currentCommandPage, pageCount))
    UI:SetEnabled(self.commandPrev, self.currentCommandPage > 1)
    UI:SetEnabled(self.commandNext, self.currentCommandPage < pageCount)

    for _, button in ipairs(self.tabButtons or {}) do
        UI:SetActive(button, button.aaeCategory == categoryID)
    end
end

function A:ChangeCommandPage(delta)
    self:ShowCategory(self.currentCategory, (self.currentCommandPage or 1) + delta, true)
end

function A:RefreshMainWindow()
    if not self.frame then return end
    self.frame.aaeTitle:SetText(self:L("TITLE"))
    self.subtitle:SetText(self:BuildMainInfoLine())
    self:RefreshSecurityDisplays()
    for _, button in ipairs(self.tabButtons or {}) do
        local category = self.Categories[button.aaeCategory]
        if category then button:SetText(self:L(category.labelKey)) end
    end
end

function A:EnsureLaunchers()
    local allReady = true
    if not self.toolbar and type(self.CreateToolbar) == "function" then
        if not self:SafeCall("CreateToolbar", self.CreateToolbar, self) then allReady = false end
    end
    if self.toolbar and type(self.CreateLanguageMinibarButton) == "function" and not self.languageMinibarButton then
        if not self:SafeCall("CreateLanguageMinibarButton", self.CreateLanguageMinibarButton, self) then allReady = false end
    end
    if not self.minimapButton and type(self.CreateMinimapButton) == "function" then
        if not self:SafeCall("CreateMinimapButton", self.CreateMinimapButton, self) then allReady = false end
    end
    local db = self:GetDB()
    if self.toolbar and not db.toolbarHidden then self.toolbar:Show() end
    if self.minimapButton and not (db.minimap and db.minimap.hidden) then self.minimapButton:Show() end
    return allReady and self.toolbar ~= nil and self.minimapButton ~= nil
end

function A:CreateUI()
    if self.frame then
        self:EnsureLaunchers()
        return self.frame
    end
    sortCategories()

    -- Build both launchers first.  Even if a category or the main window later
    -- fails, the user keeps a visible recovery entry point.
    self:EnsureLaunchers()

    local frame = UI:CreateWindow("main", self:L("TITLE"), 520, 405)
    frame:SetFrameStrata("DIALOG")
    frame.aaeTitle:ClearAllPoints()
    frame.aaeTitle:SetPoint("TOPLEFT", frame, "TOPLEFT", 48, -12)
    self.frame = frame

    local creatorIcon = frame:CreateTexture(nil, "ARTWORK")
    creatorIcon:SetTexture("Interface\\AddOns\\GMminibar\\Textures\\HobbyistCreatorR3")
    creatorIcon:SetWidth(28)
    creatorIcon:SetHeight(28)
    creatorIcon:SetPoint("TOPLEFT", frame, "TOPLEFT", 14, -7)
    frame.aaeCreatorIcon = creatorIcon

    local subtitle = UI:Text(frame, self:BuildMainInfoLine(), "small")
    subtitle:SetPoint("TOPLEFT", frame, "TOPLEFT", 48, -34)
    subtitle:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -42, -34)
    subtitle:SetJustifyH("LEFT")
    subtitle:SetTextColor(0.30, 0.86, 0.86)
    self.subtitle = subtitle
    self.securityText = nil
    UI:AddAccent(frame, -53)

    self.tabButtons = {}
    for index, categoryID in ipairs(self.CategoryOrder) do
        local category = self.Categories[categoryID]
        local tab = UI:Button(frame, 78, 21, self:L(category.labelKey), "normal")
        local column = (index - 1) % 6
        local row = math.floor((index - 1) / 6)
        tab:SetPoint("TOPLEFT", frame, "TOPLEFT", 15 + column * 82, -64 - row * 24)
        tab.aaeCategory = categoryID
        tab:SetScript("OnClick", function(self) A:ShowCategory(self.aaeCategory, 1, false) end)
        self.tabButtons[index] = tab
    end

    local commandArea = CreateFrame("Frame", nil, frame)
    commandArea:SetWidth(484)
    commandArea:SetHeight(250)
    commandArea:SetPoint("TOPLEFT", frame, "TOPLEFT", 18, -116)
    self.commandButtons = {}
    for index = 1, COMMANDS_PER_PAGE do
        local button = UI:Button(commandArea, 231, 22, "", "normal")
        local column = (index - 1) % 2
        local row = math.floor((index - 1) / 2)
        button:SetPoint("TOPLEFT", commandArea, "TOPLEFT", column * 247, -row * 25)
        local icon = button:CreateTexture(nil, "ARTWORK")
        icon:SetWidth(15); icon:SetHeight(15); icon:SetPoint("LEFT", button, "LEFT", 7, 0)
        button.aaeCommandIcon = icon
        button.aaeLabel:ClearAllPoints()
        button.aaeLabel:SetPoint("LEFT", button, "LEFT", 26, 0)
        button.aaeLabel:SetPoint("RIGHT", button, "RIGHT", -48, 0)
        button.aaeLabel:SetJustifyH("LEFT")
        local result = button:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        result:SetWidth(40); result:SetJustifyH("RIGHT"); result:SetPoint("RIGHT", button, "RIGHT", -7, 0)
        result:SetTextColor(0.48, 0.70, 0.80)
        button.aaeResultText = result
        button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
        button:SetScript("OnEnter", showButtonTooltip)
        button:SetScript("OnLeave", function() GameTooltip:Hide() end)
        button:SetScript("OnClick", function(self, mouseButton)
            local definition = self.aaeDefinition
            if not definition then return end
            if mouseButton == "RightButton" then
                A:ToggleCommandFavorite(definition.id)
                A:ShowCategory(A.currentCategory, A.currentCommandPage, true)
                A:RefreshToolbarQuickSlots()
            else
                A:RunRegisteredCommand(definition.id)
            end
        end)
        self.commandButtons[index] = button
    end

    local previous = UI:Button(frame, 54, 18, "◀", "utility")
    previous:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -130, 14)
    previous:SetScript("OnClick", function() A:ChangeCommandPage(-1) end)
    self.commandPrev = previous
    local pageText = UI:Text(frame, "", "small")
    pageText:SetWidth(66); pageText:SetJustifyH("CENTER"); pageText:SetPoint("LEFT", previous, "RIGHT", 2, 0)
    self.commandPageText = pageText
    local nextButton = UI:Button(frame, 54, 18, "▶", "utility")
    nextButton:SetPoint("LEFT", pageText, "RIGHT", 2, 0)
    nextButton:SetScript("OnClick", function() A:ChangeCommandPage(1) end)
    self.commandNext = nextButton

    self:EnsureLaunchers()
    self:ShowCategory(self:GetDB().lastCategory or "gm", self:GetDB().lastCommandPage or 1, true)
    if self:GetDB().toolbarHidden then self.toolbar:Hide() end
end

function A:RefreshToolbarStates()
    if not self.toolbar then return end
    local db = self:GetDB()
    UI:SetIconActive(self.flightButton, db.gmFlight)
    UI:SetIconActive(self.godButton, db.godMode)
    UI:SetIconActive(self.gmModeButton, db.gmMode)
    UI:SetIconActive(self.visibilityButton, db.gmInvisible)
    UI:SetIconActive(self.speedButton, db.speedBoosted)
end

function A:RefreshToolbarPermissions()
    if not self.toolbar then return end
    local checks = {
        { self.flightButton, "gm_fly_on" },
        { self.killButton, "die" },
        { self.godButton, "cheat_god_on" },
        { self.visibilityButton, "gm_visible_off" },
        { self.speedButton, "speed_3" },
        { self.bankButton, "bank" },
    }
    for _, row in ipairs(checks) do
        local definition = self:GetCommand(row[2])
        if row[1] and definition then UI:SetEnabled(row[1], self:CanRunCommand(definition)) end
    end
end

function A:RefreshToolbarQuickSlots()
    if not self.commandQuickSlots or #self.commandQuickSlots==0 then return end
    local favorites = {}
    for _, id in ipairs(self.CommandOrder) do
        if self:IsCommandFavorite(id) then table.insert(favorites, id) end
    end
    local configured = self:GetDB().quickSlots or {}
    for index = 1, 2 do
        local id = favorites[index] or configured[index]
        local definition = self:GetCommand(id)
        local button = self.commandQuickSlots[index]
        button.aaeDefinition = definition
        button.aaeTitle = definition and self:L(definition.labelKey) or self:L("QUICK_SLOT")
        button.aaeHint = definition and ((definition.command ~= "" and definition.command) or "[UI action]") or self:L("QUICK_SLOT_HINT")
        button.aaeIcon:SetTexture(definition and commandIcon(definition) or "Interface\\Icons\\INV_Misc_QuestionMark")
        UI:SetEnabled(button, definition ~= nil and self:CanRunCommand(definition))
    end
end

function A:CreateToolbar()
    if self.toolbar then return end
    local toolbar = CreateFrame("Frame", "AzerothAdminAC335CanonicalToolbar", UIParent)
    toolbar:SetWidth(500); toolbar:SetHeight(32)
    toolbar:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, 92)
    toolbar:SetFrameStrata("HIGH")
    toolbar:SetMovable(true); toolbar:EnableMouse(true); toolbar:SetClampedToScreen(true)
    toolbar:RegisterForDrag("LeftButton")
    toolbar:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 },
    })
    toolbar:SetBackdropColor(0.005, 0.008, 0.012, 0.98)
    toolbar:SetBackdropBorderColor(0.95, 0.58, 0.10, 1)
    toolbar:SetScript("OnDragStart", function(self) self:StartMoving() end)
    toolbar:SetScript("OnDragStop", function(self) self:StopMovingOrSizing(); UI:SavePoint(self, "toolbar") end)
    UI:RestorePoint(toolbar, "toolbar", 0, -220)
    self.toolbar = toolbar

    local function addIcon(x, texture, title, hint, click)
        local button = UI:IconButton(toolbar, 28, texture, hint)
        button:SetPoint("LEFT", toolbar, "LEFT", x, 0)
        button.aaeTitle = title
        button:SetScript("OnClick", click)
        return button
    end

    self.flightButton = addIcon(5, "Interface\\Icons\\Ability_Druid_FlightForm", self:L("CMD_FLY_ON"), ".gm fly on/off", function() A:ToggleFlight() end)
    self.killButton = addIcon(35, "Interface\\Icons\\Ability_Rogue_Eviscerate", self:L("CMD_DIE"), ".die", function() A:RunRegisteredCommand("die") end)
    self.gmModeButton = addIcon(65, "Interface\\Icons\\INV_Misc_Food_54", self:L("GM_MODE_TOGGLE"), ".gm on/off", function() A:ToggleGMMode() end)
    self.godButton = addIcon(65, "Interface\\Icons\\Spell_Holy_PowerWordShield", self:L("CMD_GOD_ON"), ".cheat god on/off", function() A:ToggleGod() end)
    self.visibilityButton = addIcon(95, "Interface\\Icons\\Ability_Stealth", self:L("CMD_VISIBLE_OFF"), ".gm visible on/off", function() A:ToggleVisibility() end)
    self.speedButton = addIcon(125, "Interface\\Icons\\Ability_Rogue_Sprint", self:L("CMD_SPEED_3"), ".modify speed all 1/3", function() A:ToggleSpeed() end)
    self.teleportButton = addIcon(155, "Interface\\Icons\\INV_Misc_Map_01", self:L("TELEPORTS"), self:L("TELEPORT_HINT"), function() A:ToggleTeleportWindow() end)
    self.favoriteButton = addIcon(185, "Interface\\Icons\\INV_Misc_Note_01", self:L("TELEPORT_FAVORITES"), self:L("TELEPORT_FAVORITE_HINT"), function() A:ToggleFavoriteWindow() end)
    self.questHelperButton = addIcon(215, "Interface\\Icons\\INV_Misc_Book_07", self:L("QUEST_HELPER"), self:L("QUEST_HELPER_HINT"), function() A:ToggleQuestHelper() end)
    self.bankButton = addIcon(245, "Interface\\Icons\\INV_Misc_Bag_10_Blue", self:L("BANK"), self:L("BANK_NOTE"), function() A:OpenBank() end)
    self.craftInfoButton = addIcon(275, "Interface\\Icons\\INV_Misc_Gear_01", self:L("PROFESSIONS"), self:L("PROFESSION_HINT"), function() A:ToggleProfessionWindow() end)
    self.itemInfoButton = addIcon(305, "Interface\\AddOns\\GMminibar\\Embedded\\BlueItemInfo3\\ItemInfoR3", self:L("ITEM_BROWSER"), self:L("ITEM_BROWSER_HINT"), function() A:ToggleItemBrowser() end)

    local gmMenu = UI:Button(toolbar, 84, 22, self:L("MAIN_MENU"), "active")
    gmMenu:SetPoint("LEFT", toolbar, "LEFT", 338, 0)
    gmMenu.aaeHint = self:L("MAIN_MENU_HINT")
    gmMenu:SetScript("OnEnter", showButtonTooltip)
    gmMenu:SetScript("OnLeave", function() GameTooltip:Hide() end)
    gmMenu:SetScript("OnClick", function() A:ToggleMainWindow() end)
    self.gmMenuButton = gmMenu

    self.commandQuickSlots = {}
    for index = 1, 2 do
        local slot = UI:IconButton(toolbar, 28, "Interface\\Icons\\INV_Misc_QuestionMark", self:L("QUICK_SLOT_HINT"))
        slot:SetPoint("LEFT", toolbar, "LEFT", 430 + (index - 1) * 30, 0)
        slot.aaeSlotIndex = index
        slot:RegisterForClicks("LeftButtonUp", "RightButtonUp")
        slot:SetScript("OnClick", function(self, mouseButton)
            local definition = self.aaeDefinition
            if not definition then return end
            if mouseButton == "RightButton" then
                A:ToggleCommandFavorite(definition.id)
                A:RefreshToolbarQuickSlots()
                if A.currentCategory then A:ShowCategory(A.currentCategory, A.currentCommandPage, true) end
            else
                A:RunRegisteredCommand(definition.id)
            end
        end)
        self.commandQuickSlots[index] = slot
    end

    self:RefreshToolbarQuickSlots()
    self:RefreshToolbarStates()
    self:RefreshToolbarPermissions()
end

function A:CreateMinimapButton()
    if self.minimapButton or not Minimap then return end
    local button = CreateFrame("Button", "AzerothAdminAC335CanonicalMinimapButton", UIParent)
    button:SetWidth(34); button:SetHeight(34)
    button:SetFrameStrata("MEDIUM")
    if Minimap.GetFrameLevel then button:SetFrameLevel(Minimap:GetFrameLevel() + 8) end
    button:SetMovable(true); button:SetClampedToScreen(true)
    button:RegisterForClicks("LeftButtonUp", "RightButtonUp", "MiddleButtonUp")
    button:RegisterForDrag("LeftButton")

    local saved = self:GetDB().minimap or {}
    if saved.x and saved.y then
        button:SetPoint("CENTER", UIParent, "CENTER", saved.x, saved.y)
    else
        button:SetPoint("TOPRIGHT", Minimap, "TOPRIGHT", 7, -38)
    end

    local icon = button:CreateTexture(nil, "ARTWORK")
    icon:SetTexture("Interface\\AddOns\\GMminibar\\Textures\\HobbyistCreatorR3")
    icon:SetWidth(23); icon:SetHeight(23); icon:SetPoint("CENTER", button, "CENTER", 0, 0)
    button.aaeIcon = icon
    local ring = button:CreateTexture(nil, "OVERLAY")
    ring:SetTexture("Interface\\AddOns\\GMminibar\\Textures\\MinimapRingR3")
    ring:SetWidth(34); ring:SetHeight(34); ring:SetPoint("CENTER", button, "CENTER", 0, 0)
    button.aaeRing = ring

    button:SetScript("OnEnter", function(self)
        self.aaeRing:SetVertexColor(0.35, 1, 1, 1)
        UI:ShowHint(self, "AzerothAdmin AC335 3.3.5a", {
            A:L("MINIMAP_LEFT"), A:L("MINIMAP_RIGHT"), A:L("MINIMAP_MIDDLE"), A:L("MINIMAP_DRAG"),
        }, "ANCHOR_LEFT")
    end)
    button:SetScript("OnLeave", function(self) self.aaeRing:SetVertexColor(1, 1, 1, 1); GameTooltip:Hide() end)
    button:SetScript("OnClick", function(_, mouseButton)
        if mouseButton == "RightButton" then A:OpenTeleportWindow()
        elseif mouseButton == "MiddleButton" then A:OpenTeleportFavoritesWindow()
        else A:ToggleMainWindow() end
    end)
    button:SetScript("OnDragStart", function(self) self:StartMoving() end)
    button:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local x, y = self:GetCenter()
        local cx, cy = UIParent:GetCenter()
        if x and y and cx and cy then
            x = x - cx; y = y - cy
            self:ClearAllPoints(); self:SetPoint("CENTER", UIParent, "CENTER", x, y)
            local db = A:GetDB(); db.minimap.x = x; db.minimap.y = y
        end
    end)
    self.minimapButton = button
    if saved.hidden then button:Hide() end
end

function A:Toggle()
    self:ToggleMainWindow()
end
