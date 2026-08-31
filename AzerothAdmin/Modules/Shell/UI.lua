AzerothAdminEasy = AzerothAdminEasy or {}
local addon = AzerothAdminEasy
local L = addon.L

local COMMANDS_PER_PAGE = 20
local TELEPORTS_PER_PAGE = 12
local FAVORITES_PER_PAGE = 12

local BUTTON_STYLES = {
    normal   = { 0.025, 0.04, 0.055, 1, 0.48, 0.43, 0.31, 1, 0.92, 0.78, 0.28 },
    utility  = { 0.025, 0.09, 0.11, 1, 0.12, 0.63, 0.68, 1, 0.43, 0.92, 0.95 },
    reward   = { 0.035, 0.105, 0.055, 1, 0.30, 0.67, 0.30, 1, 0.66, 0.95, 0.45 },
    danger   = { 0.13, 0.045, 0.025, 1, 0.72, 0.25, 0.12, 1, 1, 0.48, 0.25 },
    active   = { 0.035, 0.16, 0.18, 1, 0.18, 0.88, 0.92, 1, 1, 0.82, 0.24 },
    disabled = { 0.025, 0.03, 0.035, 0.94, 0.14, 0.16, 0.18, 0.8, 0.40, 0.42, 0.43 },
}

local function applyButtonStyle(button, styleName)
    local style = BUTTON_STYLES[styleName] or BUTTON_STYLES.normal
    button.aaeStyle = styleName or "normal"
    button:SetBackdropColor(style[1], style[2], style[3], style[4])
    button:SetBackdropBorderColor(style[5], style[6], style[7], style[8])
    if button.aaeLabel then
        button.aaeLabel:SetTextColor(style[9], style[10], style[11])
    end
end

local function makeText(parent, text, size)
    local value = parent:CreateFontString(nil, "OVERLAY")
    if size == "large" then
        value:SetFontObject(GameFontNormalLarge)
    elseif size == "small" then
        value:SetFontObject(GameFontHighlightSmall)
    else
        value:SetFontObject(GameFontNormal)
    end
    value:SetText(text or "")
    return value
end

local function makeButton(parent, width, height, text)
    local button = CreateFrame("Button", nil, parent)
    button:SetWidth(width)
    button:SetHeight(height)
    button:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 12, edgeSize = 9,
        insets = { left = 2, right = 2, top = 2, bottom = 2 },
    })
    local label = button:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    label:SetPoint("LEFT", button, "LEFT", 6, 0)
    label:SetPoint("RIGHT", button, "RIGHT", -6, 0)
    label:SetJustifyH("CENTER")
    button.aaeLabel = label
    button.SetText = function(self, value)
        self.aaeText = value or ""
        self.aaeLabel:SetText(self.aaeText)
    end
    button.GetText = function(self)
        return self.aaeText or ""
    end
    button:SetText(text or "")
    button.aaeModern = true
    applyButtonStyle(button, "normal")
    button:SetScript("OnMouseDown", function(self)
        if self:IsEnabled() then
            self:SetBackdropColor(0.025, 0.26, 0.30, 1)
        end
    end)
    button:SetScript("OnMouseUp", function(self)
        if self:IsEnabled() then
            applyButtonStyle(self, self.aaeStyle)
        end
    end)
    return button
end

local function makeEditBox(parent, name, width, height)
    local edit = CreateFrame("EditBox", name, parent)
    edit:SetWidth(width)
    edit:SetHeight(height)
    edit:SetAutoFocus(false)
    edit:SetFontObject(ChatFontNormal)
    edit:SetTextInsets(7, 7, 1, 1)
    edit:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 12, edgeSize = 8,
        insets = { left = 2, right = 2, top = 2, bottom = 2 },
    })
    edit:SetBackdropColor(0.025, 0.035, 0.045, 0.98)
    edit:SetBackdropBorderColor(0.20, 0.33, 0.38, 0.95)
    edit:SetScript("OnEditFocusGained", function(self)
        self:SetBackdropBorderColor(0.15, 0.72, 0.78, 1)
    end)
    edit:SetScript("OnEditFocusLost", function(self)
        self:SetBackdropBorderColor(0.20, 0.33, 0.38, 0.95)
    end)
    edit:SetScript("OnEscapePressed", function(self)
        self:ClearFocus()
    end)
    return edit
end

local function makeIconButton(parent, icon, hint)
    local button = CreateFrame("Button", nil, parent)
    button:SetWidth(28)
    button:SetHeight(24)
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
    return button
end

local function setIconActive(button, active)
    if not button then return end
    button.aaeToggleActive = active and true or false
    if active then
        button:SetBackdropColor(0.035, 0.24, 0.12, 1)
        button:SetBackdropBorderColor(0.30, 1, 0.58, 1)
    else
        button:SetBackdropColor(0.13, 0.085, 0.025, 1)
        button:SetBackdropBorderColor(0.95, 0.63, 0.12, 1)
    end
end

local function setButtonEnabled(button, enabled)
    if enabled then
        button:Enable()
        applyButtonStyle(button, button.aaeEnabledStyle or "normal")
    else
        button:Disable()
        applyButtonStyle(button, "disabled")
    end
end

local function setTabActive(button, active)
    if active then
        button:Disable()
        applyButtonStyle(button, "active")
    else
        button:Enable()
        applyButtonStyle(button, "normal")
    end
end

local function commandSemantic(definition)
    local command = string.lower((definition and definition.command) or "")
    if definition and definition.danger then return "danger" end
    if string.find(command, ".die", 1, true)
        or string.find(command, "delete", 1, true)
        or string.find(command, "shutdown", 1, true)
        or string.find(command, "restart", 1, true)
        or string.find(command, ".ban", 1, true)
        or string.find(command, ".kick", 1, true) then
        return "danger"
    end
    if (definition and definition.action == "revive")
        or string.find(command, ".revive", 1, true)
        or string.find(command, ".modify money", 1, true)
        or string.find(command, ".levelup", 1, true)
        or string.find(command, ".additem", 1, true)
        or string.find(command, ".learn", 1, true) then
        return "reward"
    end
    if string.find(command, ".gm ", 1, true)
        or string.find(command, ".cheat", 1, true)
        or string.find(command, ".modify speed", 1, true)
        or (definition and (definition.action == "teleports" or definition.action == "favorites" or definition.action == "questhelper" or definition.action == "kr_item_search" or definition.action == "kr_quest_search" or definition.action == "kr_creature_search" or definition.action == "godToggle" or definition.action == "waterwalkToggle" or definition.action == "bankToggle" or definition.action == "craftInfo" or definition.action == "itemInfo")) then
        return "utility"
    end
    return "normal"
end

local function commandIcon(definition)
    local command = string.lower((definition and definition.command) or "")
    local action = (definition and definition.action) or ""
    if action == "teleports" then return "Interface\\Icons\\INV_Misc_Map_01" end
    if action == "favorites" then return "Interface\\Icons\\INV_Misc_Note_01" end
    if action == "questhelper" then return "Interface\\Icons\\INV_Misc_Book_07" end
    if action == "kr_item_search" then return "Interface\\Icons\\INV_Misc_Bag_10_Blue" end
    if action == "kr_creature_search" then return "Interface\\Icons\\INV_Misc_Head_Dragon_01" end
    if action == "bankToggle" then return "Interface\\Icons\\INV_Misc_Bag_10_Blue" end
    if action == "craftInfo" then return "Interface\\Icons\\Trade_Engineering" end
    if action == "itemInfo" then return "Interface\\AddOns\\AzerothAdmin\\Embedded\\BlueItemInfo3\\Icon" end
    if action == "waterwalkToggle" then return "Interface\\Icons\\Spell_Frost_WindWalkOn" end
    if action == "screenshot" then return "Interface\\Icons\\INV_Misc_Spyglass_03" end
    if string.find(command, ".die", 1, true) then return "Interface\\Icons\\Ability_Creature_Cursed_02" end
    if action == "revive" or string.find(command, ".revive", 1, true) then return "Interface\\Icons\\Spell_Holy_Resurrection" end
    if string.find(command, "visible", 1, true) then return "Interface\\Icons\\Ability_Stealth" end
    if string.find(command, "fly", 1, true) then return "Interface\\Icons\\Ability_Druid_FlightForm" end
    if string.find(command, "speed", 1, true) then return "Interface\\Icons\\Ability_Rogue_Sprint" end
    if string.find(command, ".additem", 1, true) then return "Interface\\Icons\\INV_Misc_Bag_10_Blue" end
    if string.find(command, "money", 1, true) then return "Interface\\Icons\\INV_Misc_Coin_01" end
    if string.find(command, ".levelup", 1, true) then return "Interface\\Icons\\Spell_Holy_DivineSpirit" end
    if string.find(command, ".learn", 1, true) then return "Interface\\Icons\\INV_Misc_Book_09" end
    if string.find(command, ".lookup", 1, true) then return "Interface\\Icons\\INV_Misc_Spyglass_02" end
    if string.find(command, ".quest", 1, true) then return "Interface\\Icons\\INV_Misc_Note_02" end
    if string.find(command, ".gobject", 1, true) then return "Interface\\Icons\\INV_Crate_03" end
    if string.find(command, ".npc", 1, true) then return "Interface\\Icons\\INV_Misc_Head_Dragon_01" end
    if string.find(command, ".server", 1, true) then return "Interface\\Icons\\INV_Misc_Gear_01" end
    return "Interface\\Icons\\INV_Misc_Gear_01"
end

local function showHint(self)
    if self.aaeModern and self:IsEnabled() then
        self:SetBackdropColor(0.07, 0.22, 0.28, 1)
        self:SetBackdropBorderColor(0.22, 0.88, 0.95, 1)
    elseif self.aaeIcon then
        self:SetBackdropColor(0.11, 0.31, 0.39, 1)
        self:SetBackdropBorderColor(1, 0.78, 0.18, 1)
    end
    if self.aaeHint then
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(self.aaeTitle or self:GetText() or "", 1, 0.82, 0)
        GameTooltip:AddLine(self.aaeHint, 1, 1, 1, true)
        GameTooltip:Show()
    end
end

local function hideHint(self)
    if self.aaeModern and self:IsEnabled() then
        applyButtonStyle(self, self.aaeStyle)
    elseif self.aaeIcon then
        setIconActive(self, self.aaeToggleActive)
    end
    GameTooltip:Hide()
end

function addon:CreateUI()
    if self.frame then return end

    local frame = CreateFrame("Frame", "AzerothAdminTurtleStyleFrame", UIParent)
    frame:SetWidth(520)
    frame:SetHeight(405)
    frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    frame:SetFrameStrata("DIALOG")
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:SetClampedToScreen(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", function(self) self:StartMoving() end)
    frame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local point, _, relativePoint, x, y = self:GetPoint()
        AzerothAdminEasyDB.point = point
        AzerothAdminEasyDB.relativePoint = relativePoint
        AzerothAdminEasyDB.x = x
        AzerothAdminEasyDB.y = y
    end)
    frame:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 14,
        insets = { left = 4, right = 4, top = 4, bottom = 4 },
    })
    frame:SetBackdropColor(0.018, 0.025, 0.035, 0.97)
    frame:SetBackdropBorderColor(0.95, 0.58, 0.10, 1)
    frame:Hide()
    self.frame = frame
    if self.RegisterEscapeFrame then self:RegisterEscapeFrame(frame) end

    if AzerothAdminEasyDB and AzerothAdminEasyDB.point then
        frame:ClearAllPoints()
        frame:SetPoint(AzerothAdminEasyDB.point, UIParent,
            AzerothAdminEasyDB.relativePoint or AzerothAdminEasyDB.point,
            AzerothAdminEasyDB.x or 0, AzerothAdminEasyDB.y or 0)
    end

    local creatorIcon = frame:CreateTexture(nil, "ARTWORK")
    creatorIcon:SetTexture("Interface\\AddOns\\AzerothAdmin\\Textures\\HobbyistIcon")
    creatorIcon:SetWidth(28)
    creatorIcon:SetHeight(28)
    creatorIcon:SetPoint("TOPLEFT", frame, "TOPLEFT", 14, -7)

    local title = makeText(frame, "GM에드온[3.3.5a 아제로스코어 전용]", "large")
    title:SetPoint("TOPLEFT", frame, "TOPLEFT", 48, -12)
    title:SetTextColor(1, 0.78, 0.25)
    local subtitle = makeText(frame, "아제로스코어 전용버전 · 제작자: 취미연구가", "small")
    subtitle:SetPoint("TOPLEFT", frame, "TOPLEFT", 48, -34)
    subtitle:SetTextColor(0.30, 0.86, 0.86)
    local securityText = makeText(frame, "권한: 확인 중", "small")
    securityText:SetWidth(110)
    securityText:SetJustifyH("RIGHT")
    securityText:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -42, -34)
    securityText:SetTextColor(0.75, 0.75, 0.75)
    self.securityText = securityText
    local accent = frame:CreateTexture(nil, "ARTWORK")
    accent:SetTexture(0.95, 0.58, 0.10, 0.85)
    accent:SetPoint("TOPLEFT", frame, "TOPLEFT", 12, -53)
    accent:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -12, -53)
    accent:SetHeight(1)
    local close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -5, -5)

    self.tabButtons = {}
    local index
    for index = 1, table.getn(self.Categories) do
        local category = self.Categories[index]
        local tab = makeButton(frame, 78, 21, category.name)
        local column = ((index - 1) % 6)
        local row = math.floor((index - 1) / 6)
        tab:SetPoint("TOPLEFT", frame, "TOPLEFT", 15 + (column * 82), -64 - (row * 24))
        tab.aaeIndex = index
        tab:SetScript("OnClick", function(self)
            local cat = addon.Categories[self.aaeIndex]
            if cat and cat.action then
                addon:ExecuteDefinition({ action = cat.action, label = cat.name })
            else
                addon:ShowCategory(self.aaeIndex, 1)
            end
        end)
        self.tabButtons[index] = tab
    end

    local commandArea = CreateFrame("Frame", nil, frame)
    commandArea:SetWidth(484)
    commandArea:SetHeight(250)
    commandArea:SetPoint("TOPLEFT", frame, "TOPLEFT", 18, -116)
    self.commandButtons = {}
    for index = 1, COMMANDS_PER_PAGE do
        local button = makeButton(commandArea, 231, 22, "")
        local column = ((index - 1) % 2)
        local row = math.floor((index - 1) / 2)
        button:SetPoint("TOPLEFT", commandArea, "TOPLEFT", column * 247, -(row * 25))
        local commandTexture = button:CreateTexture(nil, "ARTWORK")
        commandTexture:SetWidth(15)
        commandTexture:SetHeight(15)
        commandTexture:SetPoint("LEFT", button, "LEFT", 7, 0)
        button.aaeCommandIcon = commandTexture
        button.aaeLabel:ClearAllPoints()
        button.aaeLabel:SetPoint("LEFT", button, "LEFT", 26, 0)
        button.aaeLabel:SetPoint("RIGHT", button, "RIGHT", -48, 0)
        local resultText = button:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        resultText:SetWidth(40)
        resultText:SetJustifyH("RIGHT")
        resultText:SetPoint("RIGHT", button, "RIGHT", -7, 0)
        button.aaeResultText = resultText
        button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
        button:SetScript("OnEnter", showHint)
        button:SetScript("OnLeave", hideHint)
        button:SetScript("OnClick", function(self, mouseButton)
            local definition = self.aaeDefinition
            if not definition then return end
            if mouseButton == "RightButton" then
                addon:ToggleCommandFavorite(definition)
            else
                addon:ExecuteDefinition(definition)
            end
        end)
        self.commandButtons[index] = button
    end

    -- Reference-style compact pager: only visible on categories with multiple pages.
    local previous = makeButton(frame, 54, 18, "◀")
    previous:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -130, 14)
    previous:SetScript("OnClick", function() addon:ChangeCommandPage(-1) end)
    self.commandPrev = previous
    local pageText = makeText(frame, "", "small")
    pageText:SetWidth(58)
    pageText:SetJustifyH("CENTER")
    pageText:SetPoint("LEFT", previous, "RIGHT", 2, 0)
    self.commandPageText = pageText
    local nextButton = makeButton(frame, 54, 18, "▶")
    nextButton:SetPoint("LEFT", pageText, "RIGHT", 2, 0)
    nextButton:SetScript("OnClick", function() addon:ChangeCommandPage(1) end)
    self.commandNext = nextButton

    local status = makeText(frame, "", "small")
    status:SetWidth(1); status:SetHeight(1)
    status:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 4, 4)
    status:Hide()
    self.statusText = status

    self:CreateToolbar()
    self:CreateMinimapButton()
    self:CreateArgumentPrompt()
    self:CreateTeleportWindow()
    self:CreateFavoriteWindow()
    self:ShowCategory((AzerothAdminEasyDB and AzerothAdminEasyDB.lastCategory) or 1,
        (AzerothAdminEasyDB and AzerothAdminEasyDB.lastPage) or 1)
end

function addon:CreateToolbar()
    if self.toolbar then return end
    local toolbar = CreateFrame("Frame", "AzerothAdminTurtleStyleToolbar", UIParent)
    toolbar:SetWidth(500)
    toolbar:SetHeight(32)
    toolbar:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, 92)
    toolbar:SetFrameStrata("HIGH")
    toolbar:SetMovable(true)
    toolbar:EnableMouse(true)
    toolbar:SetClampedToScreen(true)
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
    toolbar:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local point, _, relativePoint, x, y = self:GetPoint()
        AzerothAdminEasyDB.toolbarPoint = point
        AzerothAdminEasyDB.toolbarRelativePoint = relativePoint
        AzerothAdminEasyDB.toolbarX = x
        AzerothAdminEasyDB.toolbarY = y
    end)
    if AzerothAdminEasyDB and AzerothAdminEasyDB.toolbarPoint then
        toolbar:ClearAllPoints()
        toolbar:SetPoint(AzerothAdminEasyDB.toolbarPoint, UIParent,
            AzerothAdminEasyDB.toolbarRelativePoint or AzerothAdminEasyDB.toolbarPoint,
            AzerothAdminEasyDB.toolbarX or 0, AzerothAdminEasyDB.toolbarY or 0)
    end

    local function addIcon(x, icon, titleText, hint, click)
        local button = makeIconButton(toolbar, icon, hint)
        button.aaeTitle = titleText
        button:SetPoint("LEFT", toolbar, "LEFT", x, 0)
        button:SetScript("OnEnter", showHint)
        button:SetScript("OnLeave", hideHint)
        button:SetScript("OnClick", click)
        return button
    end

    self.flightButton = addIcon(5, "Interface\\Icons\\Ability_Druid_FlightForm", "GM 비행 전환",
        "GM 비행 모드를 켜고 끕니다.", function() addon:ToggleFlight() end)
    self.killButton = addIcon(35, "Interface\\Icons\\Ability_Rogue_Eviscerate", "즉시 처치",
        "선택한 대상을 즉시 처치합니다. 확인창 없이 바로 실행됩니다.", function()
            addon:SendNow(".die")
        end)
    self.godButton = addIcon(65, "Interface\\Icons\\Spell_Holy_PowerWordShield", "무적 모드 전환",
        "AzerothCore God 치트를 켜고 끕니다.", function() addon:ToggleGod() end)
    self.visibilityButton = addIcon(95, "Interface\\Icons\\Ability_Stealth", "투명화 전환",
        "GM 투명화를 켜고 끕니다.", function() addon:ToggleVisibility() end)
    self.speedButton = addIcon(125, "Interface\\Icons\\Ability_Rogue_Sprint", "이동속도 3배 전환",
        "전체 이동속도를 정상/3배로 전환합니다.", function() addon:ToggleSpeed() end)
    self.teleportButton = addIcon(155, "Interface\\Icons\\INV_Misc_Map_01", "순간이동 목록",
        "기존 1,761개 한글 순간이동 좌표를 엽니다.", function() addon:ToggleTeleportWindow() end)
    self.favoriteButton = addIcon(185, "Interface\\Icons\\INV_Misc_Note_01", "즐겨찾기 순간이동",
        "불사조 NPC SQL에서 추출한 텍스트 순간이동 목록을 엽니다.", function() addon:ToggleFavoriteWindow() end)
    self.questHelperButton = addIcon(215, "Interface\\Icons\\INV_Misc_Book_07", "퀘스트 도우미",
        "진행 중 퀘스트를 표로 보고 완료, 시작/종료 위치, 목표와 아이템 생성을 관리합니다.", function() addon:ToggleQuestHelper() end)
    self.bankButton = addIcon(245, "Interface\\Icons\\INV_Misc_Bag_10_Blue", "은행 가방 열기/닫기",
        "AzerothCore 원격 은행 세션을 요청해 실제 기본 은행 UI를 중앙에 엽니다. 원격 확인창은 표시하지 않습니다.", function() addon:ToggleBankWindow() end)
    self.craftInfoButton = addIcon(275, "Interface\\Icons\\INV_Misc_Gear_01", "전문기술 정보",
        "전문기술 제작 목록과 결과물/재료 정보를 엽니다. 클릭으로 습득 상태와 숙련도를 관리할 수 있습니다.", function() addon:ToggleCraftInfo() end)
    self.itemInfoButton = addIcon(305, "Interface\\AddOns\\AzerothAdmin\\Embedded\\BlueItemInfo3\\Icon", "아이템 정보",
        "아이템 분류와 검색 정보 창을 엽니다.", function() addon:ToggleItemInfo() end)

    local gmMenu = makeButton(toolbar, 84, 22, "GM 메뉴")
    gmMenu:SetPoint("LEFT", toolbar, "LEFT", 338, 0)
    gmMenu.aaeHint = "메인 GM 명령 창을 열고 닫습니다."
    gmMenu:SetScript("OnEnter", showHint)
    gmMenu:SetScript("OnLeave", hideHint)
    gmMenu:SetScript("OnClick", function()
        if addon.frame:IsShown() and addon.currentCategory == 1 then
            addon.frame:Hide()
        else
            addon:HideAddonWindows(addon.frame)
            addon:HideAddonPopups(nil)
            addon:ShowCategory(1, 1)
            addon.frame:Show()
        end
    end)
    self.gmMenuButton = gmMenu

    self.commandQuickSlots = {}
    local qi
    for qi = 1, 2 do
        local slot = makeIconButton(toolbar, "Interface\\Icons\\INV_Misc_QuestionMark", "")
        slot:SetPoint("LEFT", toolbar, "LEFT", 430 + ((qi - 1) * 30), 0)
        slot.aaeSlotIndex = qi
        slot:RegisterForClicks("LeftButtonUp", "RightButtonUp")
        slot:SetScript("OnEnter", showHint)
        slot:SetScript("OnLeave", hideHint)
        slot:SetScript("OnClick", function(self, mouseButton)
            local def = self.aaeDefinition
            if not def then return end
            if mouseButton == "RightButton" then
                addon:ToggleCommandFavorite(def)
            else
                addon:ExecuteDefinition(def)
            end
        end)
        self.commandQuickSlots[qi] = slot
    end
    self:RefreshCommandQuickSlots()

    setIconActive(self.flightButton, AzerothAdminEasyDB and AzerothAdminEasyDB.gmFlight)
    setIconActive(self.godButton, AzerothAdminEasyDB and AzerothAdminEasyDB.godMode)
    setIconActive(self.visibilityButton, AzerothAdminEasyDB and AzerothAdminEasyDB.gmInvisible)
    setIconActive(self.speedButton, AzerothAdminEasyDB and AzerothAdminEasyDB.speedBoosted)
    self.toolbar = toolbar
    self:RefreshToolbarPermissions()
end


function addon:RefreshToolbarPermissions()
    local checks = {
        { self.flightButton, ".gm fly on" },
        { self.killButton, ".die" },
        { self.godButton, ".cheat god on" },
        { self.visibilityButton, ".gm visible off" },
        { self.speedButton, ".modify speed all 3" },
        { self.teleportButton, ".go xyz 0 0 0 0" },
        { self.favoriteButton, ".go xyz 0 0 0 0" },
    }
    local current = self:GetDetectedSecurity()
    local i
    for i = 1, table.getn(checks) do
        local button = checks[i][1]
        local command = checks[i][2]
        if button then
            local name = self:GetCommandName(command)
            local required = name and self.CommandSecurity and self.CommandSecurity[name] or nil
            local locked = (required == 4) or (current and required and required > current)
            if name and self.sessionDeniedCommands and self.sessionDeniedCommands[name] then locked = true end
            if locked then
                button:Disable()
                if button.aaeIcon then button.aaeIcon:SetVertexColor(0.35, 0.35, 0.35) end
            else
                button:Enable()
                if button.aaeIcon then button.aaeIcon:SetVertexColor(1, 1, 1) end
            end
        end
    end
end

function addon:CreateMinimapButton()
    if self.minimapButton or not Minimap then return end
    local button = CreateFrame("Button", "AzerothAdminTurtleStyleMinimapButton", UIParent)
    button:SetWidth(34)
    button:SetHeight(34)
    button:SetFrameStrata("MEDIUM")
    button:SetMovable(true)
    button:SetClampedToScreen(true)
    button:RegisterForClicks("LeftButtonUp", "RightButtonUp", "MiddleButtonUp")
    button:RegisterForDrag("LeftButton")
    if AzerothAdminEasyDB and AzerothAdminEasyDB.minimapX then
        button:SetPoint("CENTER", UIParent, "CENTER", AzerothAdminEasyDB.minimapX, AzerothAdminEasyDB.minimapY)
    else
        button:SetPoint("TOPRIGHT", Minimap, "TOPRIGHT", 7, -38)
    end
    local icon = button:CreateTexture(nil, "ARTWORK")
    icon:SetTexture("Interface\\AddOns\\AzerothAdmin\\Textures\\HobbyistIcon")
    icon:SetWidth(23)
    icon:SetHeight(23)
    icon:SetPoint("CENTER", button, "CENTER", 0, 0)
    local border = button:CreateTexture(nil, "OVERLAY")
    border:SetTexture("Interface\\AddOns\\AzerothAdmin\\Textures\\MinimapRing")
    border:SetWidth(34)
    border:SetHeight(34)
    border:SetPoint("CENTER", button, "CENTER", 0, 0)
    button.aaeRing = border
    button:SetScript("OnEnter", function(self)
        self.aaeRing:SetVertexColor(0.35, 1, 1, 1)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:SetText("AzerothAdmin 3.3.5a", 1, 0.82, 0.18)
        GameTooltip:AddLine("왼쪽 클릭: GM 패널", 1, 1, 1)
        GameTooltip:AddLine("오른쪽 클릭: 순간이동 목록", 1, 1, 1)
        GameTooltip:AddLine("가운데 클릭: 즐겨찾기 순간이동", 1, 1, 1)
        GameTooltip:AddLine("드래그: 아이콘 이동", 0.72, 0.72, 0.72)
        GameTooltip:Show()
    end)
    button:SetScript("OnLeave", function(self)
        self.aaeRing:SetVertexColor(1, 1, 1, 1)
        GameTooltip:Hide()
    end)
    button:SetScript("OnClick", function(self, mouseButton)
        if mouseButton == "RightButton" then
            addon:ToggleTeleportWindow()
        elseif mouseButton == "MiddleButton" then
            addon:ToggleFavoriteWindow()
        else
            addon:Toggle()
        end
    end)
    button:SetScript("OnDragStart", function(self) self:StartMoving() end)
    button:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local x, y = self:GetCenter()
        local cx, cy = UIParent:GetCenter()
        x = x - cx
        y = y - cy
        self:ClearAllPoints()
        self:SetPoint("CENTER", UIParent, "CENTER", x, y)
        AzerothAdminEasyDB.minimapX = x
        AzerothAdminEasyDB.minimapY = y
    end)
    self.minimapButton = button
end

function addon:ShowCategory(categoryIndex, page)
    if not self.Categories[categoryIndex] then categoryIndex = 1 end
    self.currentCategory = categoryIndex
    self.currentPage = page or 1
    AzerothAdminEasyDB.lastCategory = categoryIndex
    AzerothAdminEasyDB.lastPage = self.currentPage
    self:RefreshCommands()
end

function addon:ChangeCommandPage(delta)
    local category = self.Categories[self.currentCategory]
    if not category then return end
    local maxPage = math.max(1, math.ceil(table.getn(category.commands) / COMMANDS_PER_PAGE))
    local newPage = (self.currentPage or 1) + delta
    if newPage < 1 then newPage = 1 end
    if newPage > maxPage then newPage = maxPage end
    self.currentPage = newPage
    AzerothAdminEasyDB.lastPage = newPage
    self:RefreshCommands()
end

function addon:RefreshSecurityLabel()
    if not self.securityText then return end
    local level = self:GetDetectedSecurity()
    if level then
        self.securityText:SetText("권한: GM Lv." .. tostring(level))
        self.securityText:SetTextColor(0.45, 0.95, 0.65)
    else
        self.securityText:SetText("권한: 확인 중")
        self.securityText:SetTextColor(0.75, 0.75, 0.75)
    end
end

function addon:RefreshCommands()
    self:RefreshSecurityLabel()
    local category = self.Categories[self.currentCategory]
    if not category then return end
    local count = table.getn(category.commands)
    local maxPage = math.max(1, math.ceil(count / COMMANDS_PER_PAGE))
    if self.currentPage > maxPage then self.currentPage = maxPage end
    local first = ((self.currentPage - 1) * COMMANDS_PER_PAGE) + 1
    local index
    for index = 1, COMMANDS_PER_PAGE do
        local button = self.commandButtons[index]
        local definition = category.commands[first + index - 1]
        if definition then
            button.aaeDefinition = definition
            local favorite = addon:IsCommandFavorite(definition)
            button:SetText((favorite and "★ " or "") .. (definition.label or ""))
            local detail = definition.command or definition.action or ""
            local hint = definition.hint or ""
            if definition.officialSyntax and definition.officialSyntax ~= "" then
                hint = hint .. "\n|cff66ccff공식 구문:|r " .. definition.officialSyntax
            end
            if definition.requiredSecurity ~= nil then
                hint = hint .. "\n|cffaaaaaa필요 GM 레벨: " .. tostring(definition.requiredSecurity) .. "|r"
            end
            if addon:GetDefinitionKey(definition) then
                hint = hint .. "\n|cffffff88우클릭: 기능 퀵슬롯 등록/해제|r"
            end
            if definition._resultMessage and definition._resultMessage ~= "" then
                hint = hint .. "\n|cffbbbbbb최근 결과:|r " .. definition._resultMessage
            end
            hint = hint .. "\n" .. detail
            button.aaeHint = hint
            button.aaeEnabledStyle = commandSemantic(definition)
            button.aaeCommandIcon:SetTexture(commandIcon(definition))
            button.aaeCommandIcon:Show()

            local allowed, reason = addon:IsDefinitionAllowed(definition)
            if not allowed then
                setButtonEnabled(button, false)
                button.aaeHint = button.aaeHint .. "\n|cffff6666잠금: " .. tostring(reason or "권한 부족") .. "|r"
                button.aaeResultText:SetText("잠금")
                button.aaeResultText:SetTextColor(0.65, 0.65, 0.65)
                button.aaeCommandIcon:SetVertexColor(0.45, 0.45, 0.45)
            else
                setButtonEnabled(button, true)
                button.aaeCommandIcon:SetVertexColor(1, 1, 1)
                local state = definition._resultState
                if state == "pending" then
                    button.aaeResultText:SetText("...")
                    button.aaeResultText:SetTextColor(1, 0.82, 0.20)
                elseif state == "success" then
                    button.aaeResultText:SetText("OK")
                    button.aaeResultText:SetTextColor(0.35, 1, 0.45)
                elseif state == "failure" then
                    button.aaeResultText:SetText("실패")
                    button.aaeResultText:SetTextColor(1, 0.30, 0.25)
                elseif state == "sent" then
                    button.aaeResultText:SetText("전송")
                    button.aaeResultText:SetTextColor(0.45, 0.82, 0.95)
                else
                    button.aaeResultText:SetText("")
                end
            end
            button:Show()
        else
            button.aaeDefinition = nil
            button.aaeCommandIcon:Hide()
            if button.aaeResultText then button.aaeResultText:SetText("") end
            button:Hide()
        end
    end
    for index = 1, table.getn(self.tabButtons) do
        setTabActive(self.tabButtons[index], index == self.currentCategory)
    end
    if maxPage > 1 then
        self.commandPageText:SetText(self.currentPage .. "/" .. maxPage)
        self.commandPrev:Show(); self.commandPageText:Show(); self.commandNext:Show()
        setButtonEnabled(self.commandPrev, self.currentPage > 1)
        setButtonEnabled(self.commandNext, self.currentPage < maxPage)
    else
        self.commandPrev:Hide(); self.commandPageText:Hide(); self.commandNext:Hide()
    end
end

function addon:RefreshCommandQuickSlots()
    if not self.commandQuickSlots then return end
    local favs = self:GetCommandFavorites()
    local i
    for i = 1, 2 do
        local slot = self.commandQuickSlots[i]
        local key = favs[i]
        local def = key and self:FindDefinitionByKey(key) or nil
        slot.aaeDefinition = def
        if def then
            slot.aaeIcon:SetTexture(commandIcon(def))
            local allowed, reason = self:IsDefinitionAllowed(def)
            slot.aaeTitle = "퀵 " .. tostring(i) .. ": " .. tostring(def.label or key)
            slot.aaeHint = (def.hint or "") .. "\n" .. tostring(def.command or def.action or "") .. "\n우클릭: 퀵슬롯 해제"
            if allowed then
                slot:Enable()
                slot.aaeIcon:SetVertexColor(1, 1, 1)
                slot:SetBackdropBorderColor(0.95, 0.63, 0.12, 1)
            else
                slot:Disable()
                slot.aaeIcon:SetVertexColor(0.35, 0.35, 0.35)
                slot.aaeHint = slot.aaeHint .. "\n잠금: " .. tostring(reason or "권한 부족")
                slot:SetBackdropBorderColor(0.35, 0.35, 0.35, 1)
            end
        else
            slot:Enable()
            slot.aaeIcon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
            slot.aaeIcon:SetVertexColor(0.45, 0.45, 0.45)
            slot.aaeTitle = "기능 퀵슬롯 " .. tostring(i)
            slot.aaeHint = "메인 메뉴의 명령·검색·창 열기·토글 기능을 우클릭하면 최대 2개까지 등록됩니다."
            slot:SetBackdropBorderColor(0.35, 0.35, 0.35, 1)
        end
    end
end

function addon:RefreshHistory()
    if not self.historyButtons then return end
    local history = (AzerothAdminEasyDB and AzerothAdminEasyDB.history) or {}
    local index
    for index = 1, 3 do
        local button = self.historyButtons[index]
        local command = history[index]
        if command then
            button.aaeCommand = command
            button:SetText(command)
            applyButtonStyle(button, "normal")
            button:Show()
        else
            button.aaeCommand = nil
            button:Hide()
        end
    end
end

function addon:Toggle()
    if not self.frame then self:CreateUI() end
    if self.frame:IsShown() then
        self.frame:Hide()
    else
        -- GM메뉴는 루트 창입니다. 현재 세부창이 있으면 닫고 루트로 돌아옵니다.
        self:HideAddonPopups(nil)
        self:HideAddonWindows(self.frame)
        self.frame.aaeReturnFrame = nil
        self.frame:Show()
        self.currentManagedFrame = self.frame
        self:UpdateEscapeProxy()
    end
end

function addon:ToggleFlight(definition)
    AzerothAdminEasyDB.gmFlight = not AzerothAdminEasyDB.gmFlight
    if AzerothAdminEasyDB.gmFlight then
        self:SendNow(".gm fly on", definition)
    else
        self:SendNow(".gm fly off", definition)
    end
    setIconActive(self.flightButton, AzerothAdminEasyDB.gmFlight)
end

function addon:ToggleGod(definition)
    AzerothAdminEasyDB.godMode = not AzerothAdminEasyDB.godMode
    if AzerothAdminEasyDB.godMode then
        self:SendNow(".cheat god on", definition)
    else
        self:SendNow(".cheat god off", definition)
    end
    setIconActive(self.godButton, AzerothAdminEasyDB.godMode)
end

function addon:ToggleVisibility(definition)
    AzerothAdminEasyDB.gmInvisible = not AzerothAdminEasyDB.gmInvisible
    if AzerothAdminEasyDB.gmInvisible then
        self:SendNow(".gm visible off", definition)
    else
        self:SendNow(".gm visible on", definition)
    end
    setIconActive(self.visibilityButton, AzerothAdminEasyDB.gmInvisible)
end

function addon:ToggleSpeed(definition)
    AzerothAdminEasyDB.speedBoosted = not AzerothAdminEasyDB.speedBoosted
    if AzerothAdminEasyDB.speedBoosted then
        self:SendNow(".modify speed all 3", definition)
    else
        self:SendNow(".modify speed all 1", definition)
    end
    setIconActive(self.speedButton, AzerothAdminEasyDB.speedBoosted)
end

function addon:ToggleWaterwalk(definition)
    AzerothAdminEasyDB.waterwalk = not AzerothAdminEasyDB.waterwalk
    if AzerothAdminEasyDB.waterwalk then
        self:SendNow(".cheat waterwalk on", definition)
    else
        self:SendNow(".cheat waterwalk off", definition)
    end
end

local ARGUMENT_HELP = {
    account = "계정명(로그인 ID)", accountname = "계정명(로그인 ID)",
    player = "플레이어 이름", playername = "플레이어 이름", charactername = "캐릭터 이름", name = "이름/대상명",
    level = "레벨 또는 권한 레벨", realmid = "Realm ID (-1 = 모든 Realm)", realm = "Realm ID",
    itemid = "아이템 Entry ID", itemcount = "아이템 수량", count = "수량/표시 개수", itemsetid = "아이템 세트 ID",
    spellid = "주문/기술 Spell ID", achievement = "업적 ID 또는 링크", quest = "퀘스트 ID", questid = "퀘스트 ID",
    creature_id = "크리쳐 Entry ID", creature_guid = "크리쳐 DB Spawn GUID", guid = "DB Spawn GUID 또는 캐릭터 GUID",
    object_guid = "게임오브젝트 DB Spawn GUID", groupid = "Spawn Group ID", entry = "Entry ID",
    distance = "검색 거리", mapid = "Map ID", areaid = "Area/Zone ID", phase = "PhaseMask", phasemask = "PhaseMask",
    x = "X 좌표", y = "Y 좌표", z = "Z 좌표", orientation = "방향(Orientation)",
    amount = "변경할 수치", money = "Copper 단위 금액", copper = "Copper 단위 금액",
    reason = "사유", bantime = "기간 예: 1d2h / 음수=영구", message = "메시지 내용", text = "본문/텍스트",
    subject = "우편 제목(따옴표 권장)", password = "비밀번호", email = "이메일 주소",
    ranknumber = "길드 등급 번호(0=길드장)", teamid = "팀 ID", type = "종류/타입 값", state = "상태 값",
    addon = "확장팩 단계 0=Classic, 1=TBC, 2=WotLK", gmlevel = "GM 권한 레벨 0~3",
}

function addon:BuildArgumentGuide(definition)
    if definition and definition.argGuide and definition.argGuide ~= "" then return definition.argGuide end
    local syntax = (definition and definition.officialSyntax) or ""
    local seen, rows = {}, {}
    local function addToken(token)
        if not token then return end
        token = string.gsub(token, "[^%w_]", "")
        if token == "" then return end
        local key = string.lower(token)
        if seen[key] then return end
        seen[key] = true
        local desc = ARGUMENT_HELP[key]
        if desc then table.insert(rows, "• " .. token .. " : " .. desc) end
    end
    for token in string.gmatch(syntax, "[$#]([%w_]+)") do addToken(token) end
    for token in string.gmatch(syntax, "<([%w_]+)>") do addToken(token) end
    local lowerSyntax = string.lower(syntax or "")
    if string.find(lowerSyntax, "on/off", 1, true) or string.find(lowerSyntax, "on|off", 1, true) then
        table.insert(rows, "• on / off : 기능 활성화 / 비활성화")
    end
    if definition and definition.commandName == "account set gmlevel" then
        table.insert(rows, "• level : 0=일반, 1=Moderator, 2=GM, 3=Administrator")
        table.insert(rows, "• realmID : 현재 Realm ID, -1=모든 Realm")
    elseif definition and (definition.commandName == "account set addon" or definition.commandName == "account addon") then
        table.insert(rows, "• addon : 0=Classic, 1=TBC, 2=WotLK")
    end
    if table.getn(rows) == 0 and definition and definition.hint then
        local hint = string.gsub(definition.hint, "^인수:%s*", "")
        if hint ~= definition.hint and hint ~= "" then table.insert(rows, "• 입력 형식 : " .. hint) end
    end
    if table.getn(rows) == 0 then return "인수 설명: 위 입력 형식과 예시를 참고하세요." end
    while table.getn(rows) > 5 do table.remove(rows) end
    return "인수 설명\n" .. table.concat(rows, "\n")
end

function addon:CreateArgumentPrompt()
    if self.argumentFrame then return end
    local frame = CreateFrame("Frame", "AzerothAdminArgumentFrame", UIParent)
    frame:SetWidth(380)
    frame:SetHeight(310)
    frame:SetPoint("CENTER", UIParent, "CENTER", 0, 80)
    frame:SetFrameStrata("FULLSCREEN_DIALOG")
    frame:EnableMouse(true)
    frame:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 14,
        insets = { left = 4, right = 4, top = 4, bottom = 4 },
    })
    frame:SetBackdropColor(0.018, 0.025, 0.035, 0.99)
    frame:SetBackdropBorderColor(0.95, 0.58, 0.10, 1)
    frame:Hide()
    self.argumentFrame = frame
    if self.RegisterEscapeFrame then self:RegisterEscapeFrame(frame) end

    local title = makeText(frame, "인수값 입력", "large")
    title:SetPoint("TOPLEFT", frame, "TOPLEFT", 18, -16)
    title:SetTextColor(1, 0.82, 0.18)
    self.argumentTitle = title
    local description = makeText(frame, "필요한 인수값을 입력하세요.", "small")
    description:SetWidth(344)
    description:SetHeight(46)
    description:SetJustifyH("LEFT")
    description:SetJustifyV("TOP")
    description:SetPoint("TOPLEFT", frame, "TOPLEFT", 18, -45)
    self.argumentDescription = description
    local guide = makeText(frame, "", "small")
    guide:SetWidth(344)
    guide:SetHeight(92)
    guide:SetJustifyH("LEFT")
    guide:SetJustifyV("TOP")
    guide:SetTextColor(0.92, 0.88, 0.68)
    guide:SetPoint("TOPLEFT", frame, "TOPLEFT", 18, -91)
    self.argumentGuide = guide
    local example = makeText(frame, "", "small")
    example:SetWidth(344)
    example:SetHeight(54)
    example:SetJustifyH("LEFT")
    example:SetJustifyV("TOP")
    example:SetTextColor(0.35, 0.88, 0.95)
    example:SetPoint("TOPLEFT", frame, "TOPLEFT", 18, -181)
    self.argumentExample = example
    local edit = makeEditBox(frame, "AzerothAdminArgumentEdit", 344, 24)
    edit:SetPoint("TOPLEFT", frame, "TOPLEFT", 18, -237)
    self.argumentEdit = edit
    local run = makeButton(frame, 164, 24, "실행")
    run:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 18, 16)
    run:SetScript("OnClick", function() addon:SubmitArgumentPrompt() end)
    local cancel = makeButton(frame, 164, 24, "취소")
    cancel:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -18, 16)
    cancel:SetScript("OnClick", function() addon.argumentFrame:Hide() end)
    edit:SetScript("OnEnterPressed", function() addon:SubmitArgumentPrompt() end)
    edit:SetScript("OnEscapePressed", function() addon.argumentFrame:Hide() end)
end

function addon:PromptArguments(definition)
    if not self.argumentFrame then self:CreateArgumentPrompt() end
    self.argumentPendingDefinition = definition
    self.argumentPromptMode = "args"
    self.argumentTitle:SetText(definition.label or "인수값 입력")
    self.argumentDescription:SetText(definition.hint or "필요한 인수값을 입력하세요.")
    if self.argumentGuide then self.argumentGuide:SetText(self:BuildArgumentGuide(definition)) end
    local preview = definition.command and string.gsub(definition.command, "{args}", "<인수>") or ""
    local ex = definition.example or ""
    if preview ~= "" then preview = "명령: " .. preview end
    if definition.officialSyntax and definition.officialSyntax ~= "" then
        if preview ~= "" then preview = preview .. "\n" end
        preview = preview .. "공식: " .. definition.officialSyntax
    end
    if ex ~= "" and preview ~= "" then preview = preview .. "\n" .. ex elseif ex ~= "" then preview = ex end
    self.argumentExample:SetText(preview)
    self.argumentEdit:SetText("")
    self:HideAddonPopups(nil)
    self:OpenManagedFrame(self.argumentFrame)
    self.argumentEdit:SetFocus()
end

function addon:PromptTarget(definition)
    if not self.argumentFrame then self:CreateArgumentPrompt() end
    self.argumentPendingDefinition = definition
    self.argumentPromptMode = "target"
    self.argumentTitle:SetText((definition.label or "명령") .. " - 플레이어 이름")
    self.argumentDescription:SetText("선택한 플레이어가 없습니다. 대상 플레이어 이름을 입력하세요.")
    if self.argumentGuide then self.argumentGuide:SetText("인수 설명\n• playerName : 온라인/오프라인 대상 캐릭터 이름 (명령 지원 범위에 따름)") end
    self.argumentExample:SetText((definition.command or "") .. "\n예: Mychar")
    self.argumentEdit:SetText("")
    self:HideAddonPopups(nil)
    self:OpenManagedFrame(self.argumentFrame)
    self.argumentEdit:SetFocus()
end

function addon:SubmitArgumentPrompt()
    local definition = self.argumentPendingDefinition
    if not definition then
        self.argumentFrame:Hide()
        return
    end
    local value = addon.Trim(self.argumentEdit:GetText() or "")
    if value == "" then
        self.argumentDescription:SetText("값을 입력해야 합니다.")
        self.argumentEdit:SetFocus()
        return
    end
    if self.argumentPromptMode == "target" then
        self.pendingTargetName = value
    else
        self.pendingArgumentValue = value
    end
    self.argumentFrame:Hide()
    self.argumentPendingDefinition = nil
    self.argumentPromptMode = nil
    self:ExecuteDefinition(definition)
end

local function teleportCategory(tp)
    if tp.group == "EK_N" or tp.group == "EK_S" then return "eastern" end
    if tp.group == "K" then return "kalimdor" end
    if tp.group == "Ou" then return "outland" end
    if tp.group == "N_A" or tp.group == "N_H" then return "northrend" end
    return "instance"
end

function addon:CreateTeleportWindow()
    if self.teleportFrame then return end
    local frame = CreateFrame("Frame", "AzerothAdminTeleportFrame", UIParent)
    frame:SetWidth(500)
    frame:SetHeight(470)
    frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    frame:SetFrameStrata("FULLSCREEN_DIALOG")
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:SetClampedToScreen(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", function(self) self:StartMoving() end)
    frame:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
    frame:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 14,
        insets = { left = 4, right = 4, top = 4, bottom = 4 },
    })
    frame:SetBackdropColor(0.018, 0.025, 0.035, 0.98)
    frame:SetBackdropBorderColor(0.95, 0.58, 0.10, 1)
    frame:Hide()
    self.teleportFrame = frame
    if self.RegisterEscapeFrame then self:RegisterEscapeFrame(frame) end

    local titleIcon = frame:CreateTexture(nil, "ARTWORK")
    titleIcon:SetTexture("Interface\\AddOns\\AzerothAdmin\\Textures\\icon")
    titleIcon:SetWidth(34)
    titleIcon:SetHeight(34)
    titleIcon:SetPoint("TOPLEFT", frame, "TOPLEFT", 14, -8)
    local title = makeText(frame, "한글 순간이동 목록 · 1,761 좌표", "large")
    title:SetPoint("TOPLEFT", frame, "TOPLEFT", 56, -18)
    title:SetTextColor(1, 0.78, 0.25)
    local close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -5, -5)

    local searchLabel = makeText(frame, "검색")
    searchLabel:SetPoint("TOPLEFT", frame, "TOPLEFT", 20, -50)
    local search = makeEditBox(frame, "AzerothAdminTeleportSearch", 360, 22)
    search:SetPoint("LEFT", searchLabel, "RIGHT", 10, 0)
    search:SetScript("OnTextChanged", function()
        addon.teleportPage = 1
        addon:RefreshTeleportList()
    end)
    search:SetScript("OnEscapePressed", function(self) self:ClearFocus(); frame:Hide() end)
    self.teleportSearch = search

    local groups = {
        { key = "all", label = "전체" },
        { key = "eastern", label = "동부왕국" },
        { key = "kalimdor", label = "칼림도어" },
        { key = "outland", label = "아웃랜드" },
        { key = "northrend", label = "노스렌드" },
        { key = "instance", label = "인던·전장" },
    }
    self.teleportCategoryButtons = {}
    local i
    for i = 1, table.getn(groups) do
        local button = makeButton(frame, 72, 22, groups[i].label)
        button:SetPoint("TOPLEFT", frame, "TOPLEFT", 22 + ((i - 1) * 76), -78)
        button.aaeTeleportGroup = groups[i].key
        button:SetScript("OnClick", function(self)
            addon:SetTeleportCategory(self.aaeTeleportGroup)
        end)
        self.teleportCategoryButtons[i] = button
    end
    self.teleportCategory = "all"

    self.teleportButtons = {}
    for i = 1, TELEPORTS_PER_PAGE do
        local button = makeButton(frame, 456, 23, "")
        button:SetPoint("TOPLEFT", frame, "TOPLEFT", 22, -108 - ((i - 1) * 25))
        button.aaeLabel:SetJustifyH("LEFT")
        button:RegisterForClicks("LeftButtonUp")
        button:SetScript("OnClick", function(self)
            if self.aaeTeleport then addon:SendNow(self.aaeTeleport.command) end
        end)
        button:SetScript("OnEnter", function(self)
            if not self.aaeTeleport then return end
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText(self.aaeTeleport.zone .. " > " .. self.aaeTeleport.name, 1, 0.82, 0.18)
            GameTooltip:AddLine(self.aaeTeleport.command, 0.35, 0.85, 1, true)
            GameTooltip:Show()
        end)
        button:SetScript("OnLeave", function() GameTooltip:Hide() end)
        self.teleportButtons[i] = button
    end

    local previous = makeButton(frame, 85, 23, "◀ 이전")
    previous:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 22, 20)
    previous:SetScript("OnClick", function()
        if addon.teleportPage > 1 then
            addon.teleportPage = addon.teleportPage - 1
            addon:RefreshTeleportList()
        end
    end)
    local nextButton = makeButton(frame, 85, 23, "다음 ▶")
    nextButton:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -22, 20)
    nextButton:SetScript("OnClick", function()
        if addon.teleportPage < addon.teleportPageCount then
            addon.teleportPage = addon.teleportPage + 1
            addon:RefreshTeleportList()
        end
    end)
    local pageText = makeText(frame, "", "small")
    pageText:SetWidth(190)
    pageText:SetJustifyH("CENTER")
    pageText:SetPoint("BOTTOM", frame, "BOTTOM", 0, 25)
    self.teleportPageText = pageText
    self.teleportPrevious = previous
    self.teleportNext = nextButton
    self.teleportPage = 1
    self:SetTeleportCategory("all")
end

function addon:SetTeleportCategory(group)
    self.teleportCategory = group or "all"
    self.teleportPage = 1
    local i
    for i = 1, table.getn(self.teleportCategoryButtons or {}) do
        local button = self.teleportCategoryButtons[i]
        setTabActive(button, button.aaeTeleportGroup == self.teleportCategory)
    end
    self:RefreshTeleportList()
end

function addon:RefreshTeleportList()
    if not self.teleportButtons then return end
    local query = ""
    if self.teleportSearch then query = string.lower(self.teleportSearch:GetText() or "") end
    local matches = {}
    local i
    for i = 1, table.getn(self.Teleports) do
        local tp = self.Teleports[i]
        local categoryMatch = self.teleportCategory == "all" or teleportCategory(tp) == self.teleportCategory
        local hay = string.lower((tp.zone or "") .. " " .. (tp.name or "") .. " " .. (tp.command or ""))
        local searchMatch = query == "" or string.find(hay, query, 1, true)
        if categoryMatch and searchMatch then table.insert(matches, tp) end
    end
    local count = table.getn(matches)
    self.teleportPageCount = math.max(1, math.ceil(count / TELEPORTS_PER_PAGE))
    if self.teleportPage > self.teleportPageCount then self.teleportPage = self.teleportPageCount end
    local first = ((self.teleportPage - 1) * TELEPORTS_PER_PAGE) + 1
    for i = 1, TELEPORTS_PER_PAGE do
        local tp = matches[first + i - 1]
        local button = self.teleportButtons[i]
        if tp then
            button.aaeTeleport = tp
            button:SetText(tp.zone .. "  >  " .. tp.name)
            button:Show()
        else
            button.aaeTeleport = nil
            button:Hide()
        end
    end
    self.teleportPageText:SetText("검색 " .. count .. "개   ·   " .. self.teleportPage .. " / " .. self.teleportPageCount)
    setButtonEnabled(self.teleportPrevious, self.teleportPage > 1)
    setButtonEnabled(self.teleportNext, self.teleportPage < self.teleportPageCount)
end

function addon:ToggleTeleportWindow()
    if not self.teleportFrame then self:CreateTeleportWindow() end
    if self.teleportFrame:IsShown() then
        self.teleportFrame:Hide()
    else
        self:HideAddonPopups(nil)
        if self.teleportSearch then self.teleportSearch:SetText("") end
        self.teleportPage = 1
        self:SetTeleportCategory("all")
        self:RefreshTeleportList()
        self:OpenManagedFrame(self.teleportFrame)
    end
end

function addon:CreateFavoriteWindow()
    if self.favoriteFrame then return end
    local frame = CreateFrame("Frame", "AzerothAdminFavoriteTeleportFrame", UIParent)
    frame:SetWidth(520)
    frame:SetHeight(500)
    frame:SetPoint("CENTER", UIParent, "CENTER", 30, 0)
    frame:SetFrameStrata("FULLSCREEN_DIALOG")
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:SetClampedToScreen(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", function(self) self:StartMoving() end)
    frame:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
    frame:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 14,
        insets = { left = 4, right = 4, top = 4, bottom = 4 },
    })
    frame:SetBackdropColor(0.018, 0.025, 0.035, 0.985)
    frame:SetBackdropBorderColor(0.95, 0.58, 0.10, 1)
    frame:Hide()
    self.favoriteFrame = frame
    if self.RegisterEscapeFrame then self:RegisterEscapeFrame(frame) end

    local titleIcon = frame:CreateTexture(nil, "ARTWORK")
    titleIcon:SetTexture("Interface\\Icons\\INV_Misc_Note_01")
    titleIcon:SetWidth(32)
    titleIcon:SetHeight(32)
    titleIcon:SetPoint("TOPLEFT", frame, "TOPLEFT", 14, -9)
    local title = makeText(frame, "즐겨찾기 순간이동 · 불사조 NPC 좌표 232개", "large")
    title:SetPoint("TOPLEFT", frame, "TOPLEFT", 54, -17)
    title:SetTextColor(1, 0.78, 0.25)
    local close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -5, -5)

    local searchLabel = makeText(frame, "검색")
    searchLabel:SetPoint("TOPLEFT", frame, "TOPLEFT", 20, -51)
    local search = makeEditBox(frame, "AzerothAdminFavoriteSearch", 375, 22)
    search:SetPoint("LEFT", searchLabel, "RIGHT", 10, 0)
    search:SetScript("OnTextChanged", function()
        addon.favoritePage = 1
        addon:RefreshFavoriteList()
    end)
    search:SetScript("OnEscapePressed", function(self) self:ClearFocus(); frame:Hide() end)
    self.favoriteSearch = search

    self.favoriteCategoryButtons = {}
    local groups = self.FavoriteTeleportGroups or {}
    local i
    for i = 1, table.getn(groups) do
        local button = makeButton(frame, 115, 21, groups[i].name)
        local col = ((i - 1) % 4)
        local row = math.floor((i - 1) / 4)
        button:SetPoint("TOPLEFT", frame, "TOPLEFT", 22 + col * 119, -80 - row * 23)
        button.aaeFavoriteGroup = groups[i].code
        button:SetScript("OnClick", function(self)
            addon:SetFavoriteCategory(self.aaeFavoriteGroup)
        end)
        self.favoriteCategoryButtons[i] = button
    end
    self.favoriteCategory = "all"

    self.favoriteButtons = {}
    for i = 1, FAVORITES_PER_PAGE do
        local button = makeButton(frame, 476, 23, "")
        button:SetPoint("TOPLEFT", frame, "TOPLEFT", 22, -137 - ((i - 1) * 25))
        button.aaeLabel:SetJustifyH("LEFT")
        button:RegisterForClicks("LeftButtonUp")
        button:SetScript("OnClick", function(self)
            if self.aaeFavorite then addon:SendNow(self.aaeFavorite.command) end
        end)
        button:SetScript("OnEnter", function(self)
            if not self.aaeFavorite then return end
            self:SetBackdropColor(0.07, 0.22, 0.28, 1)
            self:SetBackdropBorderColor(0.22, 0.88, 0.95, 1)
            local fav = self.aaeFavorite
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText(fav.name, 1, 0.82, 0.18)
            GameTooltip:AddLine("맵 " .. fav.map .. "  |  Menu " .. fav.menu .. ":" .. fav.option, 0.65, 0.95, 0.75)
            GameTooltip:AddLine(fav.command, 0.35, 0.85, 1, true)
            GameTooltip:AddLine("클릭: 즉시 이동", 1, 1, 1)
            GameTooltip:Show()
        end)
        button:SetScript("OnLeave", function(self)
            applyButtonStyle(self, "normal")
            GameTooltip:Hide()
        end)
        self.favoriteButtons[i] = button
    end

    local previous = makeButton(frame, 85, 23, "◀ 이전")
    previous:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 22, 20)
    previous:SetScript("OnClick", function()
        if addon.favoritePage > 1 then
            addon.favoritePage = addon.favoritePage - 1
            addon:RefreshFavoriteList()
        end
    end)
    local nextButton = makeButton(frame, 85, 23, "다음 ▶")
    nextButton:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -22, 20)
    nextButton:SetScript("OnClick", function()
        if addon.favoritePage < addon.favoritePageCount then
            addon.favoritePage = addon.favoritePage + 1
            addon:RefreshFavoriteList()
        end
    end)
    local pageText = makeText(frame, "", "small")
    pageText:SetWidth(220)
    pageText:SetJustifyH("CENTER")
    pageText:SetPoint("BOTTOM", frame, "BOTTOM", 0, 25)
    self.favoritePageText = pageText
    self.favoritePrevious = previous
    self.favoriteNext = nextButton
    self.favoritePage = 1
    self:SetFavoriteCategory("all")
end

function addon:SetFavoriteCategory(group)
    self.favoriteCategory = group or "all"
    self.favoritePage = 1
    local i
    for i = 1, table.getn(self.favoriteCategoryButtons or {}) do
        local button = self.favoriteCategoryButtons[i]
        setTabActive(button, button.aaeFavoriteGroup == self.favoriteCategory)
    end
    self:RefreshFavoriteList()
end

function addon:RefreshFavoriteList()
    if not self.favoriteButtons then return end
    local query = ""
    if self.favoriteSearch then query = string.lower(self.favoriteSearch:GetText() or "") end
    local matches = {}
    local data = self.FavoriteTeleports or {}
    local i
    for i = 1, table.getn(data) do
        local fav = data[i]
        local groupMatch = self.favoriteCategory == "all" or fav.group == self.favoriteCategory
        local hay = string.lower((fav.name or "") .. " " .. (fav.group or "") .. " " .. tostring(fav.map or ""))
        local searchMatch = query == "" or string.find(hay, query, 1, true)
        if groupMatch and searchMatch then table.insert(matches, fav) end
    end
    local count = table.getn(matches)
    self.favoritePageCount = math.max(1, math.ceil(count / FAVORITES_PER_PAGE))
    if self.favoritePage > self.favoritePageCount then self.favoritePage = self.favoritePageCount end
    local first = ((self.favoritePage - 1) * FAVORITES_PER_PAGE) + 1
    for i = 1, FAVORITES_PER_PAGE do
        local fav = matches[first + i - 1]
        local button = self.favoriteButtons[i]
        if fav then
            button.aaeFavorite = fav
            button:SetText("[" .. fav.id .. "]  " .. fav.name .. "    |    Map " .. fav.map)
            button:Show()
        else
            button.aaeFavorite = nil
            button:Hide()
        end
    end
    self.favoritePageText:SetText("검색 " .. count .. "개   ·   " .. self.favoritePage .. " / " .. self.favoritePageCount)
    setButtonEnabled(self.favoritePrevious, self.favoritePage > 1)
    setButtonEnabled(self.favoriteNext, self.favoritePage < self.favoritePageCount)
end

function addon:ToggleFavoriteWindow()
    if not self.favoriteFrame then self:CreateFavoriteWindow() end
    if self.favoriteFrame:IsShown() then
        self.favoriteFrame:Hide()
    else
        self:HideAddonPopups(nil)
        if self.favoriteSearch then self.favoriteSearch:SetText("") end
        self.favoritePage = 1
        self:SetFavoriteCategory("all")
        self:RefreshFavoriteList()
        self:OpenManagedFrame(self.favoriteFrame)
    end
end
