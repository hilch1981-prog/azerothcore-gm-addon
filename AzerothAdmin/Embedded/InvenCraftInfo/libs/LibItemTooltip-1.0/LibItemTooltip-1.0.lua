---------------------------------
-- 아이템 툴팁 후킹 라이브러리 --
--       제작자: intheblue     --
---------------------------------

local MAJOR_VERSION = "LibItemTooltip-1.0"
local MINOR_VERSION = 4

local lib = LibStub:NewLibrary(MAJOR_VERSION, MINOR_VERSION)
if not lib then return end

local _G = getfenv(0)
local pairs = _G.pairs
local ipairs = _G.ipairs
local tremove = _G.table.remove
local strfind = _G.string.find
local strmatch = _G.string.match
local tonumber = _G.tonumber
local EnumerateFrames = _G.EnumerateFrames

local item, link, id, spell, rank

lib.eventFrame = lib.eventFrame or CreateFrame("Frame")
lib.eventFrame:UnregisterAllEvents()
lib.eventFrame:SetScript("OnEvent", function(self, event, ...) lib.eventFrame[event](lib, ...) end)
lib.eventFrame:RegisterEvent("ADDON_LOADED")

local tooltips = {
	"GameTooltip",
	"ItemRefTooltip",
	"ShoppingTooltip",
	"LH_",
	"LinkWrangler",
	"LinksTooltip",
	"AtlasLootTooltip",
}
local hookWidget = {
	"SetAction",
	"SetHyperlink",
	"SetBagItem",
	"SetInventoryItem",
	"SetAuctionItem",
	"SetAuctionSellItem",
	"SetLootItem",
	"SetLootRollItem",
	"SetCraftSpell",
	"SetCraftItem",
	"SetTradeSkillItem",
	"SetTrainerService",
	"SetInboxItem",
	"SetSendMailItem",
	"SetQuestItem",
	"SetQuestLogItem",
	"SetTradePlayerItem",
	"SetTradeTargetItem",
	"SetMerchantItem",
	"SetMerchantCostItem",
	"SetBuybackItem",
	"SetSocketGem",
	"SetExistingSocketGem",
	"SetHyperlinkCompareItem",
	"SetGuildBankItem",
}

local handlers = {}

local hook_Tooltip_SetItem = function(tooltip)
	item, link = tooltip:GetItem()
	if item and link then
		id = tonumber(strmatch(link, "item:(%d+)") or "")
		for method, handler in pairs(handlers) do
			if handler == true then
				method(tooltip, item, link, id)
			else
				method[handler](method, tooltip, item, link, id)
			end
		end
		tooltip:Show()
	end

end

local hook_Tooltip_SetSpell = function(tooltip)
	spell, rank, id = tooltip:GetSpell()
	if spell then
		link = GetSpellLink(id)
		if link then
			if rank ~= "" then
				spell = spell.."("..rank..")"
			end
			for method, handler in pairs(handlers) do
				if handler == true then
					method(tooltip, spell, link, -id)
				else
					method[handler](method, tooltip, spell, link, -id)
				end
			end
			tooltip:Show()
		end
	end
end

local hook_CreateFrame = function(frameType, name)
	if frameType == "GameTooltip" and name and _G[name] then
		for i, s in ipairs(tooltips) do
			if name:find(s) then
				_G[name].litHooks = _G[name].litHooks or {}
				for _, w in ipairs(hookWidget) do
					if _G[name][w] and not _G[name].litHooks[w] then
						_G[name].litHooks[w] = true
						hooksecurefunc(_G[name], w, hook_Tooltip_SetItem)
					end
				end
				if not _G[name].litHooks.OnTooltipSetSpell then
					_G[name].litHooks.OnTooltipSetSpell = true
					_G[name]:HookScript("OnTooltipSetSpell", hook_Tooltip_SetSpell)
				end
				if name == s then
					tremove(tooltips, i)
				end
				break
			end
		end
	end
end

function lib.eventFrame:ADDON_LOADED()
	lib.eventFrame:UnregisterEvent("ADDON_LOADED")
	local t = EnumerateFrames()
	while t do
		hook_CreateFrame(t:GetObjectType(), t:GetName())
		t = EnumerateFrames(t)
	end
	hooksecurefunc("CreateFrame", hook_CreateFrame)
end

function lib:Register(method, handler)
	if type(method) == "string" and _G[method] then
		handlers[_G[method]] = true
	elseif type(method) == "function" then
		handlers[method] = true
	elseif type(method) == "table" and type(handler) == "string" then
		handlers[method] = handler
	end
end

function lib:Unregister(method)
	if type(method) == "string" and _G[method] then
		handlers[_G[method]] = nil
	else
		handlers[method] = nil
	end
end