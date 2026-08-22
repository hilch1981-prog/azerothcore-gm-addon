local _G = _G
local parentMod, addOnOptionFrameName, optionNum = InvenCraftInfo, "InvenCraftInfoOption", 0

if not parentMod then return end

local function cbOnClick(self)
	if self:GetChecked() then
		PlaySound("igMainMenuOptionCheckBoxOn")
		self.set(true)
	else
		PlaySound("igMainMenuOptionCheckBoxOff")
		self.set(false)
	end
end

local function cbOnEnter(self)
	if self.tooltipText then
		GameTooltip:ClearLines()
		GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT")
		GameTooltip:AddLine(self.tooltipText, nil, nil, nil, true)
		GameTooltip:Show()
	end
end

local function cbOnLeave(self)
	GameTooltip:Hide()
end

local function btOnClick(self)
	if type(self.runFunc) == "function" then
		self.runFunc()
	elseif type(self.runFunc) == "string" and type(parentMod[self.runFunc]) == "function" then
		parentMod[self.runFunc](parentMod)
	end
end

local function cbOnEnter(self)
	if self.tooltipText then
		GameTooltip:ClearLines()
		GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT")
		GameTooltip:AddLine(self.tooltipText, nil, nil, nil, true)
		GameTooltip:Show()
	end
end

local function sdOnValueChanged(self, v)
	if InCombatLockdown() then
		v = self.get()
		if self.unit == "%" then
			self.value:SetFormattedText("%d%%", v * 100)
		else
			self.value:SetFormattedText(self.renew..self.unit, v)
		end
		self:SetValue(v)
	else
		if self.unit == "%" then
			self.value:SetFormattedText("%d%%", v * 100)
		else
			self.value:SetFormattedText(self.renew..self.unit, v)
		end
		self.set(tonumber(self.renew:format(v)))
	end
end

local function sdOnShow(self)
	self:SetValue(self.get())
end

local function CreateUICheckButton(parentFrame, text, tooltipText, get, set, ...)
	optionNum = optionNum + 1
	name = addOnOptionFrameName..optionNum
	local frame = CreateFrame("CheckButton", name, parentFrame, "InterfaceOptionsCheckButtonTemplate")
	frame:SetID(optionNum)
	frame:SetPoint(...)
	frame.text = _G[name.."Text"]
	frame.text:SetText(text)
	frame.tooltipText = tooltipText
	frame.get = get
	frame.set = set
	frame:SetChecked(get())
	frame:SetScript("OnClick", cbOnClick)
	frame:SetScript("OnEnter", cbOnEnter)
	frame:SetScript("OnLeave", cbOnLeave)
	frame:SetScript("OnShow", cbOnShow)
	return frame
end

local function CreateUIButton(parentFrame, text, tooltipText, runFunc, w, h, ...)
	optionNum = optionNum + 1
	name = addOnOptionFrameName..optionNum
	local frame = CreateFrame("Button", name, parentFrame, "UIPanelButtonTemplate")
	frame:SetID(optionNum)
	frame:SetPoint(...)
	frame:SetWidth(w or 146)
	frame:SetHeight(h or 22)
	frame:SetText(text)
	frame.tooltipText = tooltipText
	frame.runFunc = runFunc
	frame:SetScript("OnClick", btOnClick)
	frame:SetScript("OnEnter", cbOnEnter)
	frame:SetScript("OnLeave", cbOnLeave)
	return frame
end

local function CreateUISlider(parentFrame, text, tooltipText, minv, maxv, step, unit, get, set, ...)
	optionNum = optionNum + 1
	name = addOnOptionFrameName..optionNum
	local frame = CreateFrame("Slider", name, parentFrame, "OptionsSliderTemplate")
	frame:SetID(optionNum)
	frame.text = _G[name.."Text"]
	frame.low = _G[name.."Low"]
	frame.high = _G[name.."High"]
	frame:SetPoint(...)
	frame:SetMinMaxValues(minv, maxv)
	frame:SetValueStep(step)
	frame:SetValue(get())
	frame.text:SetText(text)
	frame.low:SetText(minv)
	frame.high:SetText(maxv)
	frame.unit = unit or ""
	frame.step = step
	frame.value = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	frame.value:SetPoint("TOP", frame, "BOTTOM")
	frame.value:SetText(get()..frame.unit)
	frame.tooltipText = tooltipText
	frame.get = get
	frame.set = set
	if unit == "%" then
		if step < 1 then
			frame.renew = "%.2f"
			frame.low:SetFormattedText("%d", minv * 100)
			frame.high:SetFormattedText("%d", maxv * 100)
			frame.value:SetFormattedText("%d%%", get() * 100)
		else
			frame.renew = "%d"
			frame.unit = "%%"
		end
	elseif floor(step) == step then
		frame.renew = "%d"
	elseif step >= 0.1 then
		frame.renew = "%.1f"
	else
		frame.renew = "%.2f"
	end
	frame:SetScript("OnValueChanged", sdOnValueChanged)
	frame:SetScript("OnShow", sdOnShow)
	return frame
end

function InvenCraftInfo:CreateOptionFrame()
	local f = CreateFrame("Frame", "InvenCraftInfoOptionFrame", InterfaceOptionsFramePanelContainer)
	f.name = "인벤 전문기술 정보"
	f.title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
	f.title:SetPoint("TOPLEFT", f, "TOPLEFT", 16, -16)
	f.title:SetText(f.name)
	f.subText = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	f.subText:SetPoint("TOPLEFT", f.title, "TOPLEFT", 15, -40)
	f.subText:SetHeight(32)
	f.subText:SetJustifyH("LEFT")
	f.subText:SetJustifyV("TOP")
	f.subText:SetNonSpaceWrap(true)
	f.subText:SetPoint("TOPLEFT", f.title, "BOTTOMLEFT", 0, -8)
	f.subText:SetPoint("RIGHT", -32, 0)
	f.subText:SetText("전문기술 창의 기능을 향상시켜줍니다. 전문기술 창의 아래쪽 텝은 자신의 전문기술을 보여주며, 오른쪽 아이콘으로 되어있는 텝은 해당 전문길술의 모든 조제법을 보여줍니다.")

	f.showReagent = CreateUICheckButton(f, "툴팁에 재료 표시", "전문기술로 제작된 아이템의 툴팁에 재료 목록을 보여줍니다.",
		function() return InvenCraftInfoDB.showReagent end,
		function(v) InvenCraftInfoDB.showReagent = v end,
	"TOPLEFT", f.subText, "BOTTOMLEFT", -2, -8)

	f.showUse = CreateUICheckButton(f, "툴팁에 사용처 표시", "아이템의 툴팁에 사용되는 전문기술의 이름을 보여줍니다.",
		function() return InvenCraftInfoDB.showUse end,
		function(v) InvenCraftInfoDB.showUse = v end,
	"LEFT", f.showReagent, "LEFT", 160, 0)

	f.showDrop = CreateUICheckButton(f, "툴팁에 도안 획득처 표시", "아이템의 툴팁에 사용되는 전문기술 도안의 획득처를 보여줍니다.",
		function() return InvenCraftInfoDB.showDrop end,
		function(v) InvenCraftInfoDB.showDrop = v end,
	"TOPLEFT", f.showReagent, "BOTTOMLEFT", 0, -8)

	f.showKnown = CreateUICheckButton(f, "툴팁에 제작 가능자 표시", "아이템의 툴팁에 해당 전문기술을 배운 캐릭터의 목록을 보여줍니다.",
		function() return not InvenCraftInfoDB.hideKnownRecipe end,
		function(v) InvenCraftInfoDB.hideKnownRecipe = not v end,
	"TOPLEFT", f.showUse, "BOTTOMLEFT", 0, -8)

	f.scale = CreateUISlider(f, "전문기술 창 크기", "전문기술 창의 크기를 조절합니다.", 0.5, 1.5, 0.01, "%",
		function() return InvenCraftInfoDB.scale end,
		function(v)
			InvenCraftInfoDB.scale = v
			if InvenCraftInfoUI then
				InvenCraftInfoUI:SetScale(v)
			end
		end,
	"TOPLEFT", f.showDrop, "BOTTOMLEFT", 0, -16)

	f.alpha = CreateUISlider(f, "전문기술 창 투명도", "전문기술 창의 투명도를 조절합니다.", 0.25, 1.0, 0.01, "%",
		function() return InvenCraftInfoDB.alpha end,
		function(v)
			InvenCraftInfoDB.alpha = v
			if InvenCraftInfoUI then
				InvenCraftInfoUI:SetAlpha(v)
			end
		end,
	"LEFT", f.scale, "RIGHT", 20, 0)

	f.reagentCountSize = CreateUISlider(f, "재료 수량 글꼴 크기", "전문기술 창의 재료 수량 글꼴의 크기를 조절합니다.", 8, 16, 1, "포인트",
		function() return InvenCraftInfoDB.reagentCountSize end,
		function(v)
			InvenCraftInfoDB.reagentCountSize = v
			if InvenCraftInfoUI then
				for i = 1, 8 do
					InvenCraftInfoUI.reagentButtons[i].count:SetFont(STANDARD_TEXT_FONT, v, "OUTLINE")
				end
			end
		end,
	"TOPLEFT", f.scale, "BOTTOMLEFT", 0, -24)

	f.clamp = CreateUICheckButton(f, "전문기술 창 화면 내 유지", "전문기술 창을 화면에서 벗어나지 못하게 합니다.",
		function() return InvenCraftInfoDB.clamp end,
		function(v)
			InvenCraftInfoDB.clamp = v
			if InvenCraftInfoUI then
				InvenCraftInfoUI:SetClampedToScreen(v)
			end
		end,
	"TOPLEFT", f.reagentCountSize, "BOTTOMLEFT", 0, -16)

	f.rarityBorder = CreateUICheckButton(f, "등급에 따른 색상 테두리 표시", "전문기술 창 내에 있는 완성품 및  재료 아이템의 등급에 따른 테두리를 표시합니다.",
		function() return not InvenCraftInfoDB.hideRarityBorder end,
		function(v)
			InvenCraftInfoDB.hideRarityBorder = not v
			if InvenCraftInfoUI and InvenCraftInfoUI:IsShown() then
				InvenCraftInfoUI:SetSelection()
			end
		end,
	"LEFT", f.clamp, "LEFT", 160, 0)

	f.bankCount = CreateUICheckButton(f, "은행에 있는 재료 표시", "전문기술 창 내에 재료 아이템에 은행에 보유중인 아이템 갯수를 표시해줍니다.",
		function() return InvenCraftInfoDB.bankCount end,
		function(v)
			InvenCraftInfoDB.bankCount = v
			if InvenCraftInfoUI and InvenCraftInfoUI:IsShown() then
				InvenCraftInfoUI:SetSelection()
			end
		end,
	"TOPLEFT", f.clamp, "BOTTOMLEFT", 0, -8)

	f.showListTootip = CreateUICheckButton(f, "목록에서 툴팁 표시하기", "전문기술 창 내의 목록에 툴팁을 표시합니다.",
		function() return InvenCraftInfoDB.listTootip end,
		function(v) InvenCraftInfoDB.listTootip = v end,
	"TOPLEFT", f.rarityBorder, "BOTTOMLEFT", 0, -8)

	f.reset = CreateUIButton(f, "창 위치 초기화", "전문기술 창의 위치를 초기화합니다.", function()
		InvenCraftInfoDB.pos = { "CENTER", 0, 0 }
		if InvenCraftInfoUI then
			InvenCraftInfoUI:ClearAllPoints()
			InvenCraftInfoUI:SetPoint("CENTER", 0, 0)
		end
	end, nil, nil, "TOPLEFT", f.bankCount, "BOTTOMLEFT", -2, -8)

	f.mapbuttonShow = CreateUICheckButton(f, "미니맵 버튼 보이기", "미니맵 버튼을 보이거나 숨깁니다.",
		function() return InvenCraftInfoDB.mapbuttonShow end,
		function(v)
			InvenCraftInfoDB.mapbuttonShow = v
			InvenCraftInfo:HandleMapButton()
		end,
	"TOPLEFT", f.reset, "BOTTOMLEFT", 0, -8)

	f.mapbuttonLock = CreateUICheckButton(f, "미니맵 버튼 고정", "미니맵 버튼을 잠가 움직이지 못하게 합니다.",
		function() return InvenCraftInfoDB.mapbuttonLock end,
		function(v)
			InvenCraftInfoDB.mapbuttonLock = v
			InvenCraftInfo:HandleMapButton()
		end,
	"LEFT", f.mapbuttonShow, "LEFT", 160, 0)

	InterfaceOptions_AddCategory(f)
end