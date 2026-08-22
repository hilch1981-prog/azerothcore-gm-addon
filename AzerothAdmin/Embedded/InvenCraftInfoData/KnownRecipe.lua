InvenCraftInfoData = CreateFrame("Frame")
InvenCraftInfoData:SetScript("OnEvent", function(self, event, ...) self[event](self, ...) end)
InvenCraftInfoData:RegisterEvent("ADDON_LOADED")

local _G = _G
local type = _G.type
local pairs = _G.pairs
local unpack = _G.unpack
local tinsert = _G.table.insert
local GetSpellInfo = _G.GetSpellInfo
local GetTradeSkillLine = _G.GetTradeSkillLine
local GetNumTradeSkills = _G.GetNumTradeSkills
local GetTradeSkillRecipeLink = _G.GetTradeSkillRecipeLink

local realmName = GetRealmName()
local playerName = UnitName("player")
local knownCache = {}
local skills = {
	-- 요리
	[2550] = 2550, [3102] = 2550, [3413] = 2550, [18260] = 2550, [33359] = 2550, [51296] = 2550,
	-- 연금술
	[2259] = 2259, [3101] = 2259, [3464] = 2259, [11611] = 2259, [28596] = 2259, [28672] = 2259, [28675] = 2259, [28677] = 2259, [51304] = 2259,
	-- 재봉술
	[3908] = 3908, [3909] = 3908, [3910] = 3908, [12180] = 3908, [26790] = 3908, [26797] = 3908, [26798] = 3908, [26801] = 3908, [51309] = 3908,
	-- 가죽세공
	[2108] = 2108, [3104] = 2108, [3811] = 2108, [10656] = 2108, [10658] = 2108, [10660] = 2108,  [10662] = 2108, [32549] = 2108, [51302] = 2108,
	-- 대장기술
	[2018] = 2018, [3100] = 2018, [3538] = 2018, [9785] = 2018, [9787] = 2018, [9788] = 2018, [17039] = 2018, [17040] = 2018, [17041] = 2018, [29844] = 2018, [51300] = 2018,
	-- 기계공학
	[4036] = 4036, [4037] = 4036, [4038] = 4036, [12656] = 4036, [20219] = 4036, [20222] = 4036, [30350] = 4036, [51306] = 4036,
	-- 마법부여
	[7411] = 7411, [7412] = 7411, [7413] = 7411, [13920] = 7411, [28029] = 7411, [51313] = 7411,
	-- 보석세공
	[25229] = 25229, [25230] = 25229, [28894] = 25229, [28895] = 25229, [28897] = 25229, [51311] = 25229,
	-- 주문각인
	[45357] = 45357, [45358] = 45357, [45359] = 45357, [45360] = 45357, [45361] = 45357, [45363] = 45357,
	-- 응급치료
	[3273] = 3273, [3274] = 3273, [7924] = 3273, [10846] = 3273, [27028] = 3273, [45542] = 3273,
	-- 채광
	[2575] = 2656, [2576] = 2656, [2656] = 2656, [3564] = 2656, [10248] = 2656, [29354] = 2656, [50310] = 2656,
}
local unlearn1, unlearn2 = ERR_SPELL_UNLEARNED_S:gsub("%%s", "(.+)"), ERR_SPELL_UNLEARNED_S:gsub("%%s", "(.+) %((.+)%)")

function InvenCraftInfoData:ADDON_LOADED()
	self:UnregisterEvent("ADDON_LOADED")
	self:RegisterEvent("CHAT_MSG_SYSTEM")
	self:ConvertOldKnownRecipeDB()
	for p, v in pairs(skills) do
		if type(p) == "number" then
			skills[GetSpellInfo(p) or "*"] = v
		end
	end
	skills["*"] = nil
end

function InvenCraftInfoData:ConvertOldKnownRecipeDB()
	if AzerothAdminCraftInfoFrame and type(InvenCraftInfoUIDB) == "table" and not InvenCraftInfoUIDB.isNew then
		for realm, chartable in pairs(InvenCraftInfoUIDB) do
			InvenCraftInfoDataDB[realm] = InvenCraftInfoDataDB[realm] or {}
			for char, skilltable in pairs(chartable) do
				InvenCraftInfoDataDB[realm][char] = InvenCraftInfoDataDB[realm][char] or {}
				for skill, recipetable in pairs(skilltable) do
					skill = skills[skill]
					if skill then
						InvenCraftInfoDataDB[realm][char][skill] = InvenCraftInfoDataDB[realm][char][skill] or {}
						for spell in pairs(recipetable) do
							knownCache[spell] = nil
							InvenCraftInfoDataDB[realm][char][skill][spell] = true
						end
					end
				end
			end
		end
		InvenCraftInfoUIDB = nil
	else
		InvenCraftInfoDataDB = InvenCraftInfoDataDB or {}
	end
	InvenCraftInfoDataDB[realmName] = InvenCraftInfoDataDB[realmName] or {}
	InvenCraftInfoDataDB[realmName][playerName] = InvenCraftInfoDataDB[realmName][playerName] or {}
	self.realmdb = InvenCraftInfoDataDB[realmName]
	self.chardb = InvenCraftInfoDataDB[realmName][playerName]
end

function InvenCraftInfoData:SaveKnownRecipe()
	local skill = skills[GetTradeSkillLine() or "*"]
	if skill then
		if self.chardb[skill] then
			for p in pairs(self.chardb[skill]) do
				knownCache[p] = nil
				self.chardb[skill][p] = nil
			end
		else
			self.chardb[skill] = {}
		end
		for i = 1, GetNumTradeSkills() do
			self.chardb[skill][AzerothAdminCraftData:GetLinkID(GetTradeSkillRecipeLink(i), "enchant") or "*"] = true
		end
		self.chardb[skill]["*"] = nil
	end
end

function InvenCraftInfoData:ClearKnownRecipe(skill)
	skill = skills[skill or "*"]
	if skill and self.chardb[skill] then
		for p in pairs(self.chardb[skill]) do
			knownCache[p] = nil
			self.chardb[skill][p] = nil
		end
		self.chardb[skill] = nil
	end
end

local returnTable, spellset, knownPlayer = {}

function InvenCraftInfoData:IsKnownRecipe(spell)
	if type(spell) == "number" then
		if knownCache[spell] then
			if type(knownCache[spell]) == "string" then
				return knownCache[spell], knownCache[spell]:find(FONT_COLOR_CODE_CLOSE) and true or nil
			end
			return nil, nil
		else
			spellset, knownPlayer = nil, nil
			for name, skilltable in pairs(self.realmdb) do
				if spellset then
					if skilltable[spellset] and skilltable[spellset][spell] then
						if name == playerName then
							knownPlayer = true
							tinsert(returnTable, 1, NORMAL_FONT_COLOR_CODE..name..FONT_COLOR_CODE_CLOSE)
						else
							tinsert(returnTable, name)
						end
					end
				else
					for skill, spelltable in pairs(skilltable) do
						if spelltable[spell] then
							spellset = skill
							if name == playerName then
								knownPlayer = true
								tinsert(returnTable, 1, NORMAL_FONT_COLOR_CODE..name..FONT_COLOR_CODE_CLOSE)
							else
								tinsert(returnTable, name)
							end
							break
						end
					end
				end
			end
			if spellset then
				spellset = (", "):join(unpack(returnTable))
				for p in pairs(returnTable) do
					returnTable[p] = nil
				end
				knownCache[spell] = spellset
				return spellset, knownPlayer
			else
				knownCache[spell] = true
			end
		end
	end
	return nil, nil
end

function InvenCraftInfoData:CHAT_MSG_SYSTEM(msg)
	if msg then
		self:ClearKnownRecipe(msg:match(unlearn1) or msg:match(unlearn2))
	end
end