InvenCraftInfo = CreateFrame("Frame")
AzerothAdminCraftData = InvenCraftInfo
InvenCraftInfo:SetScript("OnEvent", function(self, event, ...) self[event](self, ...) end)
InvenCraftInfo:RegisterEvent("ADDON_LOADED")

local _G = getfenv(0)
local type = _G.type
local tonumber = _G.tonumber
local strchar = _G.string.char
local strmatch = _G.string.match
local strsub = _G.string.sub
local gsub = _G.string.gsub
local GetSpellLink = _G.GetSpellLink
local GetSpellInfo = _G.GetSpellInfo

local baseLinkString = "trade:%d:%d:%d:%s:%s"
local getSpellName = function(v) return GetSpellInfo(v) or "*" end
local L = {
	["요리"] = getSpellName(2550),		["연금술"] = getSpellName(2259),	["재봉술"] = getSpellName(3908),
	["가죽세공"] = getSpellName(2108),	["대장기술"] = getSpellName(2018),	["기계공학"] = getSpellName(4036),
	["마법부여"] = getSpellName(7411),	["보석세공"] = getSpellName(25229),	["주문각인"] = getSpellName(45363),
	["응급치료"] = getSpellName(3273),	["제련술"] = getSpellName(2656),	["채광"] = getSpellName(2575),
	[getSpellName(2550)] = "요리",		[getSpellName(2259)] = "연금술",	[getSpellName(3908)] = "재봉술",
	[getSpellName(2108)] = "가죽세공",	[getSpellName(2018)] = "대장기술",	[getSpellName(4036)] = "기계공학",
	[getSpellName(7411)] = "마법부여",	[getSpellName(25229)] = "보석세공",	[getSpellName(45363)] = "주문각인",
	[getSpellName(3273)] = "응급치료",	[getSpellName(2656)] = "제련술",	[getSpellName(2575)] = "채광",
}

local tradeSkillIDs = { 2550, 2259, 3908, 2108, 2018, 4036, 7411, 25229, 45363, 3273, 2656, 53424 }

local tradeSkillLinkData = {
	[L["요리"]] = { 2550, "///////////////////////////////", 168 },
	[L["연금술"]] = { 2259, "////////////////////////////////////////////", 250 },
	[L["재봉술"]] = { 3908, "//////////////////////////////////////////////////////////////////////////", 408 },
	[L["가죽세공"]] = { 2108, "////////////////////////////////////////////////////////////////////////////////////////////", 527 },
	[L["대장기술"]] = { 2018, "////////////////////////////////////////////////////////////////////////////////////////", 498 },
	[L["기계공학"]] = { 4036, "//////////////////////////////////////////////////////", 296 },
	[L["마법부여"]] = { 7411, "///////////////////////////////////////////////////", 296 },
	[L["보석세공"]] = { 25229, "///////////////////////////////////////////////////////////////////////////////////////////////", 554 },
	[L["주문각인"]] = { 45363, "///////////////////////////////////////////////////////////////////////////", 440 },
	[L["응급치료"]] = { nil, nil, 17 },
	[L["제련술"]] = { nil, nil, 25 },
	[L["채광"]] = { nil, nil, 25 },
}

InvenCraftInfo.maxSkillLevel = 450
InvenCraftInfo.tradeSkillLinks = {}
InvenCraftInfo.tradeSkillFullLinks = {}
InvenCraftInfo.tradeSkillLocale = L
InvenCraftInfo.tradeSkillIDs = tradeSkillIDs
InvenCraftInfo.tradeSkillNameList = {}
for i = 1, 9 do
	InvenCraftInfo.tradeSkillNameList[i] = getSpellName(tradeSkillIDs[i])
end

BluePrint = BluePrint or function() end

BINDING_HEADER_INVENCRAFTINFO = "전문기술 정보"
BINDING_NAME_INVENCRAFTINFO_TOGGLE = "전문기술창 열기/닫기"
BINDING_NAME_INVENCRAFTINFO_OPTION = "설정창 열기"
SLASH_INVENCRAFTINFO1 = "/ici"
SLASH_INVENCRAFTINFO2 = "/인벤전문기술"
SLASH_INVENCRAFTINFO3 = "/invencraftinfo"

local ItemTooltip = LibStub("LibItemTooltip-1.0")
local Broker = LibStub("LibDataBroker-1.1")
local MapButton = LibStub("LibMapButton-1.1")

local reagentTitle = SPELL_REAGENTS
local colorStarter = strchar(124).."cff(%x%x%x%x%x%x)"
local colorCloser = strchar(124).."r"
local tradeSkillLinkText = strchar(124).."cffffd000"..strchar(124).."H%s"..strchar(124).."h[%s]"..strchar(124).."h"..strchar(124).."r"
local tradeSkillLinkParser = strchar(124).."H(.+)"..strchar(124).."h%["
local v1, v2, v3, v4, v5, drop, reagent, spellTable, known
local cache = {}
local cacheUse = {}
local cacheDrop = {}

function InvenCraftInfo:ADDON_LOADED()
	self:UnregisterEvent("ADDON_LOADED")
	if self.enable then return end
	self.enable = true
	InvenCraftInfoDB = InvenCraftInfoDB or {
		selecter = "요리", showReagent = true, showDrop = true, showUse = true, showMake = true, scale = 1.0, alpha = 1.0, clamp = true,
		mapbuttonShow = true, mapbuttonLock = false, minimapButton = {}, hideRarityBorder = false, reagentCountSize = 10,
	}
	InvenCraftInfoDB.reagentCountSize = InvenCraftInfoDB.reagentCountSize or 10
	InvenCraftInfoCharDB = InvenCraftInfoCharDB or { openSkill = GetSpellInfo(2550), isMySkill = nil }
	if InvenCraftInfoCharDB.openSkill == nil then
		InvenCraftInfoCharDB.openSkill = GetSpellInfo(2550)
		InvenCraftInfoCharDB.isMySkill = nil
	end
	self.tradeSkillLocale = L
	self.playerName = UnitName("player")
	self.realmName = GetRealmName()
	self.faction = UnitFactionGroup("player")
	CreateFrame("GameTooltip", "AzerothAdminCraftDataTooltip", UIParent, "GameTooltipTemplate")
	self.title = "전문기술 데이터"
	self.version = "3.2.8"
	self.website = "AzerothAdmin"
	self.icon = "Interface\\AddOns\\AzerothAdmin\\Embedded\\InvenCraftInfo\\icon.tga"
	-- Embedded data provider: never hook SetItemRef. A trade-link hook can invoke
	-- a standalone/original InvenCraftInfo UI and cause the legacy window to flash.
	self.prev_SetItemRef = nil
	-- Data provider only: no broker launcher, minimap button, slash UI, option panel,
	-- SetItemRef hook, or legacy profession frame is registered by the embedded copy.
	InvenCraftInfoDB.minimapButton = InvenCraftInfoDB.minimapButton or { show = false }
	-- No original profession UI/secure trade-skill buttons are created here.
	-- AzerothAdminCraftInfoFrame is the only visible profession browser.
end

function InvenCraftInfo:CreateTradeSkillButton()
	if self.myTradeSkills then return end
	local function buttonPostClick(self)
		if GetSpellTexture(self.skill) then
			InvenCraftInfoCharDB.openSkill, InvenCraftInfoCharDB.isMySkill = self.skill, true
		end
	end
	self.myTradeSkills = {}
	self.tradeSkillList = {}
	for icon, skill in ipairs(tradeSkillIDs) do
		skill, _, icon = GetSpellInfo(skill)
		if skill then
			tinsert(self.tradeSkillList, skill)
			self.myTradeSkills[skill] = CreateFrame("Button", nil, self, "SecureActionButtonTemplate")
			self.myTradeSkills[skill]:SetAttribute("type", "spell")
			self.myTradeSkills[skill]:SetAttribute("spell", skill)
			self.myTradeSkills[skill]:SetScript("PostClick", buttonPostClick)
			self.myTradeSkills[skill]:RegisterForClicks("AnyUp")
			self.myTradeSkills[skill].iconTexture = icon
			self.myTradeSkills[skill].skill = skill
		end
	end
end

function InvenCraftInfo:CreateLinks()
	if UnitGUID("player") and UnitName("player") ~= UNKNOWNOBJECT then
		local playerCode = UnitGUID("player"):gsub("0x0+", "")
		for skill, data in pairs(tradeSkillLinkData) do
			if type(data[1]) == "number" and type(data[2]) == "string" then
				self.tradeSkillLinks[skill] = baseLinkString:format(data[1], self.maxSkillLevel, self.maxSkillLevel, playerCode, data[2])
				self.tradeSkillFullLinks[skill] = "|cffffd000|H"..self.tradeSkillLinks[skill].."|h["..skill.."]|h|r"
			end
		end
	end
end

function InvenCraftInfo:GetNumTotalTradeSkills(skill)
	if skill and tradeSkillLinkData[skill] then
		return tradeSkillLinkData[skill][3]
	end
	return nil
end

function InvenCraftInfo:UpdateNumTotalTradeSkills(skill, num)
	if skill and tradeSkillLinkData[skill] and type(num) == "number" then
		tradeSkillLinkData[skill][3] = num
	end
end

function InvenCraftInfo:GetTooltipReagents(spell)
	spell = spell and GetSpellLink(spell)
	if spell then
		AzerothAdminCraftDataTooltip:SetOwner(UIParent, "ANCHOR_NONE")
		AzerothAdminCraftDataTooltip:ClearLines()
		AzerothAdminCraftDataTooltip:SetHyperlink(spell)
		AzerothAdminCraftDataTooltip:Show()
		for i = 1, 4 do
			spell = _G["AzerothAdminCraftDataTooltipTextLeft"..i]
			if spell then
				reagent = spell:IsShown() and spell:GetText() or nil
				if type(reagent) == "string" and reagent:find(SPELL_REAGENTS) then
					return reagent
				end
			else
				return nil
			end
		end
	end
	return nil
end

function InvenCraftInfo:SetTooltip(tooltip, name, link, id)
	if self:LoadData() then return end
	if id > 0 then
		if InvenCraftInfoDB.showReagent then
			v1, v2 = self:GetRecipeID(link)
			if v1 then
				if cache[id] and cache[id] ~= "" and type(cache[id]) == "string" then
					tooltip:AddLine("|cff33ccff"..cache[id], 1, 1, 1, 1)
				else
					v3 = InvenCraftInfo:GetSpellReq(v1)
					v1 = InvenCraftInfo:GetTooltipReagents(v1)
					if v1 then
						v1 = self:ClearColorText(v1)
						if v3 > 0 then
							v1 = gsub(v1, reagentTitle, v2.."("..v3..")|r: ")
						else
							v1 = gsub(v1, reagentTitle, v2.."|r: ")
						end
						tooltip:AddLine("|cff33ccff"..v1, 1, 1, 1, 1)
						if cache[id] == 3 then
							cache[id] = v1
						elseif cache[id] == 1 or cache[id] == 2 then
							cache[id] = cache[id] + 1
						else
							cache[id] = 0
						end
					end
				end
			end
		end
		if InvenCraftInfoDB.showUse then
			if cacheUse[id] then
				if cacheUse[id] ~= "" then
					tooltip:AddLine("|cff1e90ff사용: |r"..cacheUse[id], nil, nil, nil, 1)
				end
			else
				cacheUse[id] = self:GetUseSkill(link) or ""
				if cacheUse[id] ~= "" then
					tooltip:AddLine("|cff1e90ff사용: |r"..cacheUse[id], nil, nil, nil, 1)
				end
			end
		end
		if InvenCraftInfoDB.showDrop then
			drop = self:GetDropText(self:GetSpellID(id) or self:GetRecipeID2SpellID(id))
			if drop then
				tooltip:AddLine("|cffffaaff도안 획득처:|r\n"..drop, 1, 1, 1)
			end
		end
		if not InvenCraftInfoDB.hideKnownRecipe then
			known = InvenCraftInfoData:IsKnownRecipe(self:GetSpellID(id) or self:GetRecipeID2SpellID(id))
			if known then
				tooltip:AddLine("|cff20ff20제조 가능: |r"..known, 1, 1, 1, 1)
			end
		end
	elseif id < 0 then
		id = abs(id)
		if InvenCraftInfoDB.showReagent then
			v1 = InvenCraftInfo:GetSpellReq(id)
			if v1 and v1 > 0 then
				v2 = _G[tooltip:GetName().."TextLeft1"]:GetText()
				if v2 and v2 ~= "" then
					for skill in pairs(tradeSkillLinkData) do
						if v2:find("^"..skill..": ") then
							tooltip:AddLine("|cff33ccff"..skill.."("..v1..")")
							break
						end
					end
				end
			end
		end
		if InvenCraftInfoDB.showDrop then
			drop = self:GetDropText(id)
			if drop then
				tooltip:AddLine("|cffffaaff도안 획득처:|r\n"..drop, 1, 1, 1)
			end
		end
		if not InvenCraftInfoDB.hideKnownRecipe then
			known = InvenCraftInfoData:IsKnownRecipe(id)
			if known then
				tooltip:AddLine("|cff20ff20제조 가능: |r"..known, 1, 1, 1, 1)
			end
		end
	end
end

function InvenCraftInfo:LoadData()
	return InvenCraftInfoData and false or true
end

function InvenCraftInfo:GetLinkID(link, linkType)
	if type(link) == "string" then
		if linkType then
			return tonumber(strmatch(link, linkType..":(%d+)") or "")
		else
			return tonumber(strmatch(link, "item:(%d+)") or strmatch(link, "enchant:(%d+)") or strmatch(link, "spell:(%d+)") or "")
		end
	elseif type(link) == "number" then
		return link
	end
end

function InvenCraftInfo:GetDropText(id)
	if id then
		if cacheDrop[id] then
			if cacheDrop[id] ~= "" then
				return cacheDrop[id]
			end
		else
			cacheDrop[id] = self:GetDrop(id) or ""
			return cacheDrop[id] ~= "" and cacheDrop[id] or nil
		end
	end
	return nil
end

function InvenCraftInfo:ClearColorText(text)
	text = gsub(text, colorStarter, "")
	text = gsub(text, colorCloser, "")
	return text
end

function InvenCraftInfo:HookSetItemRef(link, fullLink)
    -- Disabled in the AzerothAdmin embedded build. Data access only.
end

function InvenCraftInfo:OnClick(button)
    if AzerothAdminEasy and AzerothAdminEasy.ToggleCraftInfo then
        AzerothAdminEasy:ToggleCraftInfo()
    end
end

function InvenCraftInfo:OnTooltip(tooltip)
	tooltip = tooltip or GameTooltip
	tooltip:AddLine(InvenCraftInfo.title.." v"..InvenCraftInfo.version)
	tooltip:AddLine(InvenCraftInfo.website, 1, 1, 1)
	tooltip:AddLine("좌클릭: GUI 열기", 1, 1, 0)
	tooltip:AddLine("우클릭: 옵션창 열기", 1, 1, 0)
end

function InvenCraftInfo:HandleMapButton(nopt)
	if InvenCraftInfoMapButton then
		if nopt then
			InvenCraftInfoDB.mapbuttonShow = InvenCraftInfoDB.minimapButton.show
			InvenCraftInfoDB.mapbuttonLock = not InvenCraftInfoDB.minimapButton.dragable
		end
		if InvenCraftInfoDB.mapbuttonShow then
			InvenCraftInfoDB.minimapButton.show = true
			InvenCraftInfoMapButton:Show()
		else
			InvenCraftInfoDB.minimapButton.show = false
			InvenCraftInfoMapButton:Hide()
		end
		if InvenCraftInfoDB.mapbuttonLock then
			InvenCraftInfoDB.minimapButton.dragable = false
		else
			InvenCraftInfoDB.minimapButton.dragable = true
		end
	end
end