local MAJOR_VERSION, MINOR_VERSION = "LibRaidComm-1.0", 13
local lib = LibStub:NewLibrary(MAJOR_VERSION, MINOR_VERSION)
if not lib then return end
BluePrint = BluePrint or function() end

local _G = _G
local type = _G.type
local pairs = _G.pairs
local ipairs = _G.ipairs
local select = _G.select
local tonumber = _G.tonumber
local min = _G.math.min
local ceil = _G.math.ceil
local floor = _G.math.floor
local twipe = _G.table.wipe
local tinsert = _G.table.insert
local tremove = _G.table.remove
local UnitExists = _G.UnitExists
local UnitName = _G.UnitName
local GetRealmName = _G.GetRealmName
local UnitLevel = _G.UnitLevel
local UnitClass = _G.UnitClass
local UnitRace = _G.UnitRace
local GetNumTalents = _G.GetNumTalents
local GetTalentInfo = _G.GetTalentInfo
local GetInventoryItemLink = _G.GetInventoryItemLink
local SendAddonMessage = _G.SendAddonMessage
local IsInInstance = _G.IsInInstance
local GetNumRaidMembers = _G.GetNumRaidMembers
local GetNumPartyMembers = _G.GetNumPartyMembers

local mtype, mvalue

lib.Callbacks = LibStub("CallbackHandler-1.0"):New(lib)
lib.EventFrame = lib.EventFrame or CreateFrame("Frame")
lib.EventFrame:SetScript("OnEvent", function(self, event, ...) lib[event](lib, ...) end)
lib.EventFrame:UnregisterAllEvents()
lib.EventFrame:RegisterEvent("PLAYER_LOGIN")
lib.temp = lib.temp or {}
lib.inspectDB = lib.inspectDB or {}
lib.battleGround = lib.battleGround or { pvp = true, arena = true }
lib.castingTarget = lib.castingTarget or {}
lib.corpsePattern = lib.corpsePattern or  "^(.+)의 시체$"
lib.resurrectionSpells = lib.resurrectionSpells or {
	[GetSpellInfo(20777)] = true,
	[GetSpellInfo(25435)] = true,
	[GetSpellInfo(20773)] = true,
	[GetSpellInfo(50764)] = true,
	[GetSpellInfo(20484)] = true,
}

function lib:PLAYER_LOGIN()
	lib.playerName = UnitName("player")
	lib.playerRealmName = "-"..GetRealmName()
	lib.playerFullName = lib.playerName..lib.playerRealmName
	lib.playerClassLocale, lib.playerClass = UnitClass("player")
	lib.playerRace = UnitRace("player")
	lib.EventFrame:UnregisterEvent("PLAYER_LOGIN")
	lib.EventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
	lib.EventFrame:RegisterEvent("UNIT_SPELLCAST_SENT")
	lib.EventFrame:RegisterEvent("PARTY_MEMBERS_CHANGED")
	lib.EventFrame:RegisterEvent("CHAT_MSG_ADDON")
	lib.EventFrame:RegisterEvent("RAID_ROSTER_UPDATE")
	lib.PARTY_MEMBERS_CHANGED = lib.RAID_ROSTER_UPDATE
	if not lib.hookWorldFrame then
		lib.hookWorldFrame = true
		WorldFrame:HookScript("OnMouseDown", function(self, button)
			if GameTooltip:IsShown() and GameTooltipTextLeft1:GetText() then
				lib.playerMouseover = GameTooltipTextLeft1:GetText():match(lib.corpsePattern) or lib.playerMouseover
			end
		end)
	end
end

function lib:PLAYER_ENTERING_WORLD()
	lib.EventFrame:UnregisterEvent("PLAYER_ENTERING_WORLD")
	lib:CreateOptionFrame()
end

function lib:SendAddonMessage(info, content, whisper)
	if info and content then
		content = info.."="..content
		if whisper then
			SendAddonMessage("LibRaidComm", content, "WHISPER", whisper)
		elseif GetNumRaidMembers() > 0 then
			if lib.battleGround[select(2, IsInInstance()) or 0] then
				SendAddonMessage("LibRaidComm", content, "BATTLEGROUND")
			else
				SendAddonMessage("LibRaidComm", content, "RAID")
			end
		elseif GetNumPartyMembers() > 0 then
			if lib.battleGround[select(2, IsInInstance()) or 0] then
				SendAddonMessage("LibRaidComm", content, "BATTLEGROUND")
			else
				SendAddonMessage("LibRaidComm", content, "PARTY")
			end
		end
	end
end

function lib:UNIT_SPELLCAST_SENT(unit, spellName, spellRank, target)
	if unit == "player" then
		if lib.resurrectionSpells[spellName] then
			if (target == nil or target == COMBATLOG_UNKNOWN_UNIT) and lib.playerMouseover then
				target = lib.playerMouseover
				lib.playerMouseover = nil
			end
			if target and target ~= "" and target ~= COMBATLOG_UNKNOWN_UNIT then
				lib.castingTarget[lib.playerName] = target
				lib:SendAddonMessage("CASTING", target)
			else
				lib.castingTarget[playerName] = nil
			end
		else
			lib.castingTarget[lib.playerName] = nil
		end
	end
end

function lib:RAID_ROSTER_UPDATE()
	for name in pairs(lib.castingTarget) do
		if not UnitExists(name) then
			lib.castingTarget[name] = nil
		end
	end
end

function lib:IsDeny()
	return (Blizzard_CombatLog_Filters and Blizzard_CombatLog_Filters.InvenArmoryDenyInspect == 1) and true or nil
end

function lib:CheckInspectDelay()
	if lib.inspectDelay and lib.inspectDelay > GetTime() then
		return nil
	else
		lib.inspectDelay = GetTime() + 2
		return true
	end
end

function lib:CHAT_MSG_ADDON(prefix, msg, distribution, sender)
	if prefix == "LibRaidComm" and sender then
		sender = sender:gsub(lib.playerRealmName, "")
		mtype, mvalue = msg:match("(.+)=(.+)")
		mtype = mtype or msg
		if mtype == "CASTING" then
			if mvalue then
				lib.castingTarget[sender] = mvalue:gsub(lib.playerRealmName, "")
				lib.Callbacks:Fire("LibRaidComm_Casting", sender, lib.castingTarget[sender])
			end
		elseif distribution ~= "WHISPER" then
			-- noting
		elseif mtype == "IM" then
			if mvalue == "DENY" then
				lib.Callbacks:Fire("LibRaidComm_Deny", sender)
			elseif mvalue == "BUSY" then
				lib.Callbacks:Fire("LibRaidComm_Busy", sender)
			end
		elseif mtype == "CHECK" then
			if lib:IsDeny() then
				if mvalue == "INSPECT" and lib:CheckInspectDelay() then
					lib:SendAddonMessage("IM", "DENY", sender)
				end
			elseif mvalue == "INSPECT" then
				if lib:CheckInspectDelay() then
					for i = 1, 19 do
						lib:SendAddonMessage("INSPECT", i.."_"..(GetInventoryItemLink("player", i) or "*"), sender)
					end
				end
			elseif mvalue == "NEWTALENT" then
				lib.playerTalent = lib.playerClassLocale.."#"
				for i = 1, 3 do
					for j = 1, GetNumTalents(i) do
						lib.playerTalent = lib.playerTalent..(select(5, GetTalentInfo(i, j)) or 0)
					end
					lib.playerTalent = lib.playerTalent..(i == 3 and "" or "#")
				end
				lib:SendAddonMessage("NEWTALENT", lib.playerTalent, sender)
				lib.playerTalent = nil
			elseif mvalue == "INFO" then
				lib:SendAddonMessage("INFO", ("%d#%s#%s"):format(UnitLevel("player"), lib.playerClassLocale, lib.playerRace), sender)
			end
		elseif mtype == "INSPECT" then
			lib.temp[1], lib.temp[2] = mvalue:match("^(%d+)_(.+)$")
			lib.temp[1] = tonumber(lib.temp[1] or "")
			if lib.temp[1] then
				if lib.temp[1] == 1 then
					lib.inspectDB[sender] = lib.temp[2]
				else
					lib.inspectDB[sender] = lib.inspectDB[sender].."#"..lib.temp[2]
					if lib.temp[1] == 19 then
						lib.Callbacks:Fire("LibRaidComm_InspectCheck", sender, ("#"):split(lib.inspectDB[sender]))
						lib.inspectDB[sender] = nil
					end
				end
				twipe(lib.temp)
			end
		elseif mtype == "NEWTALENT" then
			if mvalue then
				lib.Callbacks:Fire("LibRaidComm_Talent", sender, mvalue)
			end
		elseif mtype == "INFO" then
			if mvalue then
				lib.temp[1], lib.temp[2], lib.temp[3] = ("#"):split(mvalue)
				if lib.temp[1] then
					lib.Callbacks:Fire("LibRaidComm_Info", sender, tonumber(lib.temp[1]), lib.temp[2], lib.temp[3])
				end
				twipe(lib.temp)
			end
		end
	end
end

function lib:GetCastingTarget(caster)
	return caster and lib.castingTarget[caster]
end

function lib:Inspect(name)
	if name then
		lib:SendAddonMessage("CHECK", "INSPECT", name)
	end
end

function lib:Talent(name)
	if name then
		lib:SendAddonMessage("CHECK", "NEWTALENT", name)
	end
end

function lib:Info(name)
	if name then
		lib:SendAddonMessage("CHECK", "INFO", name)
	end
end

function lib:Stat()
	-- removed r13
end

function lib:CreateOptionFrame()
	if not LibRaidCommOption then
		CreateFrame("Frame", "LibRaidCommOption", InterfaceOptionsFramePanelContainer)
		LibRaidCommOption.name = "인벤 전투정보실"
		LibRaidCommOption.title = LibRaidCommOption:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
		LibRaidCommOption.title:SetPoint("TOPLEFT", LibRaidCommOption, "TOPLEFT", 16, -16)
		LibRaidCommOption.title:SetText(LibRaidCommOption.name)
		LibRaidCommOption.subText = LibRaidCommOption:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
		LibRaidCommOption.subText:SetPoint("TOPLEFT", LibRaidCommOption.title, "TOPLEFT", 15, -40)
		LibRaidCommOption.subText:SetPoint("RIGHT", -32, 0)
		LibRaidCommOption.subText:SetHeight(32)
		LibRaidCommOption.subText:SetJustifyH("LEFT")
		LibRaidCommOption.subText:SetJustifyV("TOP")
		LibRaidCommOption.subText:SetNonSpaceWrap(true)
		LibRaidCommOption.subText:SetText("LibRaidComm-1.0 라이브러리를 사용하여 다른 사람에게 사용자의 정보를 제공해주는 기능을 합니다. 정보 수집을 허용하지 않으면 인벤 전투정보실 애드온으로 타인의 정보도 확인할 수 없습니다.")
		LibRaidCommOption.option1 = CreateFrame("CheckButton", "LibRaidCommOption1", LibRaidCommOption, "InterfaceOptionsCheckButtonTemplate")
		LibRaidCommOption1:SetPoint("TOPLEFT", LibRaidCommOption.subText, "BOTTOMLEFT", -2, -8)
		LibRaidCommOption1Text:SetText("정보 수집 허용")
		if Blizzard_CombatLog_Filters then
			Blizzard_CombatLog_Filters.InvenArmoryDenyInspect = Blizzard_CombatLog_Filters.InvenArmoryDenyInspect or 0
			if Blizzard_CombatLog_Filters.InvenArmoryDenyInspect == 0 then
				LibRaidCommOption1:SetChecked(true)
			else
				LibRaidCommOption1:SetChecked(nil)
			end
		else
			LibRaidCommOption1:SetChecked(true)
		end
		LibRaidCommOption1:SetScript("OnClick", function(self)
			if self:GetChecked() then
				PlaySound("igMainMenuOptionCheckBoxOn")
				Blizzard_CombatLog_Filters.InvenArmoryDenyInspect = 0
			else
				PlaySound("igMainMenuOptionCheckBoxOff")
				Blizzard_CombatLog_Filters.InvenArmoryDenyInspect = 1
			end
		end)
		InterfaceOptions_AddCategory(LibRaidCommOption)
	end
end

if IsLoggedIn() then lib:PLAYER_LOGIN() end