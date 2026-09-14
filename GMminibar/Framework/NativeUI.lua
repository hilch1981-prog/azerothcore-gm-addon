-- Shared visual rules only. This file never sends commands or changes game UI.
local A = AzerothAdminAC335
local N = {}
A.NativeUI = N
N.window = {
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true, tileSize = 32, edgeSize = 24,
    insets = { left = 7, right = 7, top = 7, bottom = 7 },
}
N.inset = {
    bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 16, edgeSize = 12,
    insets = { left = 3, right = 3, top = 3, bottom = 3 },
}
function N:Panel(frame, inset)
    frame:SetBackdrop(inset and self.inset or self.window)
    frame:SetBackdropColor(inset and 0.06 or 1, inset and 0.05 or 1, inset and 0.035 or 1, 1)
    frame:SetBackdropBorderColor(1, 1, 1, 1)
end
function N:Text(parent, text, width, small)
    local label = parent:CreateFontString(nil, "OVERLAY", small and "GameFontHighlightSmall" or "GameFontNormal")
    A:LocalizeWidget(label);label:SetText(text or "")
    if width then label:SetWidth(width) end
    label:SetJustifyH("LEFT")
    return label
end
function N:Button(parent, text, width, height, onClick)
    local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    button:SetWidth(width or 90); button:SetHeight(height or 24)
    A:LocalizeWidget(button);button:SetText(text or "")
    if onClick then button:SetScript("OnClick", onClick) end
    return button
end
-- Clear only this addon's frame subtree, including editors created after mounting.
function N:ClearInputFocus(frame)
    if not frame then return end
    if frame.IsObjectType and frame:IsObjectType("EditBox") then frame:ClearFocus() end
    if frame.GetChildren then
        for _, child in ipairs({ frame:GetChildren() }) do self:ClearInputFocus(child) end
    end
end
function N:Edit(parent, width)
    local edit = CreateFrame("EditBox", nil, parent)
    edit:SetWidth(width); edit:SetHeight(26); edit:SetAutoFocus(false)
    edit:SetFontObject(ChatFontNormal); A:ApplyLocaleFont(edit); edit:SetTextInsets(7, 7, 1, 1)
    self:Panel(edit, true)
    edit:SetMaxLetters(255)
    edit:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    edit:SetScript("OnEditFocusGained", function(self) self:SetBackdropBorderColor(1, 0.82, 0.35, 1) end)
    edit:SetScript("OnEditFocusLost", function(self) self:SetBackdropBorderColor(1, 1, 1, 1) end)
    return edit
end
function N:Hint(button, title, body)
    button:SetScript("OnEnter", function(self)
        local GameTooltip=A:BeginHintTooltip(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(A:T(title), 1, 0.82, 0)
        if body and body ~= "" then GameTooltip:AddLine(A:T(body), 1, 1, 1, true) end
        A:StyleHintTooltip();GameTooltip:Show()
    end)
    button:SetScript("OnLeave", function(self) A:HideHintTooltip(self) end)
end
function N:SkinContent(frame)
    if not frame or not frame.SetBackdrop then return end
    self:Panel(frame, true)
    -- Preserve rows, item icons, checkboxes and the modules' independent logic.
    -- Only text buttons created by AzerothAdmin receive the native button art.
    local function visit(parent, depth)
        if depth > 7 or not parent.GetChildren then return end
        for _, child in ipairs({ parent:GetChildren() }) do
            if child.aaeLabel and child.IsObjectType and child:IsObjectType("Button")
                and not child:IsObjectType("CheckButton") and not child.aaeIconButton and not child.gmQuietButton
                and child:GetHeight() <= 32 and child:GetWidth() <= 250 then
                child:SetNormalTexture("Interface\\Buttons\\UI-Panel-Button-Up")
                child:SetPushedTexture("Interface\\Buttons\\UI-Panel-Button-Down")
                child:SetHighlightTexture("Interface\\Buttons\\UI-Panel-Button-Highlight", "ADD")
                child:SetDisabledTexture("Interface\\Buttons\\UI-Panel-Button-Disabled")
                for _, texture in ipairs({ child:GetNormalTexture(), child:GetPushedTexture(), child:GetDisabledTexture() }) do
                    if texture then texture:SetTexCoord(0, 0.625, 0, 0.6875) end
                end
            end
            visit(child, depth + 1)
        end
    end
    visit(frame, 0)
end
function N:Fit(frame, width, height, preference)
    local availableW, availableH = UIParent:GetWidth() - 28, UIParent:GetHeight() - 28
    local scale = math.min(preference or 1, availableW / width, availableH / height)
    frame:SetScale(math.max(0.25, scale))
end
function N:OnViewportChanged(callback)
    self.viewportCallbacks = self.viewportCallbacks or {}
    self.viewportCallbacks[#self.viewportCallbacks + 1] = callback
    if self.viewportHooked then return end
    self.viewportHooked = true
    UIParent:HookScript("OnSizeChanged", function()
        for _, fn in ipairs(N.viewportCallbacks) do fn() end
    end)
end
