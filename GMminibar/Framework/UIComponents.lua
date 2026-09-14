-- Canonical AzerothAdmin 3.5.0-335a visual primitives adapted for AC335 3.3.5a.
-- Layout, colors, borders, hover behavior, and typography intentionally mirror
-- the verified user-supplied AzerothAdmin_3.5.0-335a.zip reference.
local A = AzerothAdminAC335
A.UI = type(A.UI) == "table" and A.UI or {}
local UI = A.UI
UI.__source = "Framework/UIComponents.lua"

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
    A:LocalizeWidget(value);value:SetText(text or "")
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
    A:LocalizeWidget(label)
    button.SetText = function(self, value)
        self.aaeText = value or ""
        self.aaeLabel:SetText(self.aaeText)
    end
    button.GetText = function(self) return self.aaeText or "" end
    A:LocalizeWidget(button)
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
            UI:ShowHint(self,self.aaeTitle or "AzerothAdmin",self.aaeHint,"ANCHOR_RIGHT")
        end
    end)
    button:SetScript("OnLeave", function(self)
        UI:SetIconActive(self, self.aaeToggleActive)
        A:HideHintTooltip(self)
    end)
    return button
end

function UI:EditBox(parent, width, height, name)
    local edit = CreateFrame("EditBox", name, parent)
    edit:SetWidth(width)
    edit:SetHeight(height)
    edit:SetAutoFocus(false)
    edit:SetFontObject(ChatFontNormal)
    A:ApplyLocaleFont(edit)
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
    -- Do not stretch UICheckButtonTemplate to the full label width. On the 3.3.5a
    -- client its normal/checked textures inherit the button size, which produced
    -- the long diagonal gold slash seen in R8. Keep the actual check glyph 20x20
    -- and extend only the mouse hit rectangle across the label.
    local button = CreateFrame("CheckButton", nil, parent)
    local hitWidth = math.max(24, tonumber(width) or 130)
    button:SetWidth(20)
    button:SetHeight(20)
    button:SetNormalTexture("Interface\\Buttons\\UI-CheckBox-Up")
    button:SetPushedTexture("Interface\\Buttons\\UI-CheckBox-Down")
    button:SetHighlightTexture("Interface\\Buttons\\UI-CheckBox-Highlight", "ADD")
    button:SetCheckedTexture("Interface\\Buttons\\UI-CheckBox-Check")
    button:SetDisabledCheckedTexture("Interface\\Buttons\\UI-CheckBox-Check-Disabled")
    if button.SetHitRectInsets then button:SetHitRectInsets(0, -(hitWidth - 20), 0, 0) end
    button:SetChecked(checked and true or false)
    local label = self:Text(button, text or "", "small")
    label:SetPoint("LEFT", button, "RIGHT", 4, 0)
    label:SetWidth(hitWidth - 24)
    label:SetJustifyH("LEFT")
    label:SetTextColor(0.82, 0.90, 0.92)
    button.aaeLabel = label
    button.aaeHitWidth = hitWidth
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
    if A.Workbench then A.Workbench:CanMount(frame) end
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
    if A.Workbench and A.Workbench:CanMount(frame) then return A.Workbench:Mount(frame) end
    if A.Workbench and (frame.aaeWindowKey == "argument" or frame.aaeWindowKey == "confirm") then
        if A.NativeUI then A.NativeUI:Panel(frame) end
        A.Workbench:SuspendForPopup(frame)
        frame:SetFrameStrata("FULLSCREEN_DIALOG"); frame:Show(); frame:Raise(); return
    end
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
    local GameTooltip=A:BeginHintTooltip(owner, anchor or "ANCHOR_RIGHT")
    GameTooltip:SetText(A:T(title) or "AzerothAdmin", 1, 0.82, 0.18)
    if type(lines) == "table" then
        for _, line in ipairs(lines) do GameTooltip:AddLine(A:T(tostring(line)), 1, 1, 1, true) end
    elseif lines then
        GameTooltip:AddLine(A:T(tostring(lines)), 1, 1, 1, true)
    end
    A:StyleHintTooltip();GameTooltip:Show()
end

UI.__ready = true
