-- Adapted from user supplied nidtip5, Silverwind / nidtip5 rebuild.
local A=AzerothAdminAC335
local function safeHook(target,method,callback)
 if type(target)=='string' then if type(_G[target])=='function' then hooksecurefunc(target,method) end
 elseif target and type(target[method])=='function' then hooksecurefunc(target,method,callback) end
end
local config = GMminibarNidtip_CONFIG
local labels = config.labels

---@param tooltip GameTooltip
---@param label string
---@return boolean
local function tooltipHasLabel(tooltip, label)
  -- Check existing tooltip rows so repeated hooks do not add duplicate IDs.
  local name = tooltip and tooltip.GetName and tooltip:GetName()
  if not name then return false end

  for index = 1, config.duplicateScanLines do
    local row = _G[name .. "TextLeft" .. index]
    local text = row and row.GetText and row:GetText()
    if text == label then return true end
  end

  return false
end

---@param tooltip GameTooltip
---@param id string|number|nil
---@param label string
local function addLine(tooltip, id, label)
  -- Append a colored ID row to a tooltip when the ID is valid and not already shown.
  if not tooltip or not tonumber(id) or tonumber(id)<=0 or not tooltip.AddDoubleLine then return end
  if tooltipHasLabel(tooltip, label) then return end
  tooltip.gmSeenIDs=tooltip.gmSeenIDs or {}
  local key=label..tostring(id);if tooltip.gmSeenIDs[key] then return end;tooltip.gmSeenIDs[key]=true
  if not tooltip.gmIDClearHook then tooltip.gmIDClearHook=true;tooltip:HookScript('OnTooltipCleared',function(t)t.gmSeenIDs=nil end) end

  tooltip:AddDoubleLine(label, config.color .. id .. '|r')
  local n=tooltip.GetName and tooltip:GetName();local i=tooltip.NumLines and tooltip:NumLines()
  if n and i then A:ApplyLocaleFont(_G[n..'TextLeft'..i]);A:ApplyLocaleFont(_G[n..'TextRight'..i]) end
  tooltip:Show()
end

---@param link string|nil
---@return string|nil, string|nil
local function parseLink(link)
  -- Extract the first hyperlink type and numeric ID from a WoW hyperlink string.
  if not link then return nil, nil end
  local linkType, id = link:match("|H([%a_]+):(%-?%d+)")
  if linkType and id then return linkType, id end
  return link:match("^([%a_]+):(%-?%d+)")
end

---@param guid string|nil
---@return number|nil
local function parseNpcId(guid)
  -- Resolve NPC IDs from legacy hex GUIDs and newer dash-separated GUIDs.
  if not guid then return nil end

  local modernId = (guid:match("^Creature%-") or guid:match("^Vehicle%-")) and guid:match("%a+%-%d+%-%d+%-%d+%-%d+%-(%d+)%-%x+")
  if modernId then return tonumber(modernId, 10) end

  local legacyType = tonumber(guid:sub(5, 5), 16)
  if legacyType == 3 or legacyType == 5 then
    return tonumber(guid:sub(7, 12), 16)
  end

  return nil
end

---@param guid string|nil
---@return number|nil
local function parseObjectId(guid)
  -- Resolve game object IDs from object GUIDs when the client exposes them.
  if not guid then return nil end

  local modernId = guid:match("GameObject%-%d+%-%d+%-%d+%-%d+%-(%d+)%-%x+")
  if modernId then return tonumber(modernId, 10) end

  local legacyType = tonumber(guid:sub(5, 5), 16)
  if legacyType == 1 then return tonumber(guid:sub(7, 12), 16) end

  return nil
end

---@param tooltip GameTooltip
---@param linkType string|nil
---@param id string|nil
local function addLinkId(tooltip, linkType, id)
  -- Map known hyperlink types to the matching tooltip label.
  if linkType == "item" then
    addLine(tooltip, id, labels.item)
  elseif linkType == "spell" or linkType == "enchant" or linkType == "trade" then
    addLine(tooltip, id, labels.spell)
  elseif linkType == "quest" then
    addLine(tooltip, id, labels.quest)
  elseif linkType == "achievement" then
    addLine(tooltip, id, labels.achievement)
  elseif linkType == "talent" then
    addLine(tooltip, id, labels.talent)
  elseif linkType == "currency" then
    addLine(tooltip, id, labels.currency)
  elseif linkType == "glyph" then
    addLine(tooltip, id, labels.glyph)
  elseif linkType == "gameobject" or linkType == "gameobject_entry" or linkType == "object" or linkType == "gobject" then
    addLine(tooltip, id, labels.object)
  end
end

---@param tooltip GameTooltip
---@param link string|nil
local function onSetHyperlink(tooltip, link)
  -- Add IDs to detached or explicitly-set hyperlinks.
  local linkType, id = parseLink(link)
  addLinkId(tooltip, linkType, id)
end

---@param tooltip GameTooltip
local function onTooltipSetItem(tooltip)
  -- Add item IDs to item-bearing tooltip variants.
  local _, link = tooltip:GetItem()
  local linkType, id = parseLink(link)
  if linkType == "item" then addLine(tooltip, id, labels.item) end
end

---@param tooltip GameTooltip
local function onTooltipSetSpell(tooltip)
  -- Add spell IDs to spell tooltips from spellbook, action bars, and linked spells.
  local id = select(3, tooltip:GetSpell())
  addLine(tooltip, id, labels.spell)
end

---@param tooltip GameTooltip
---@param unit string
---@param index number
---@param filter string|nil
local function onSetUnitBuff(tooltip, unit, index, filter)
  -- Add spell IDs to unit buff tooltips.
  local id = select(11, UnitBuff(unit, index, filter))
  addLine(tooltip, id, labels.spell)
end

---@param tooltip GameTooltip
---@param unit string
---@param index number
---@param filter string|nil
local function onSetUnitDebuff(tooltip, unit, index, filter)
  -- Add spell IDs to unit debuff tooltips.
  local id = select(11, UnitDebuff(unit, index, filter))
  addLine(tooltip, id, labels.spell)
end

---@param tooltip GameTooltip
---@param unit string
---@param index number
---@param filter string|nil
local function onSetUnitAura(tooltip, unit, index, filter)
  -- Add spell IDs to generic unit aura tooltips.
  local id = select(11, UnitAura(unit, index, filter))
  addLine(tooltip, id, labels.spell)
end

---@param tooltip GameTooltip
local function onTooltipSetUnit(tooltip)
  -- Add NPC IDs to non-player unit tooltips.
  local _, unit = tooltip:GetUnit()
  if not unit or UnitIsPlayer(unit) then return end

  local id = parseNpcId(UnitGUID(unit))
  addLine(tooltip, id, labels.npc)
end

---@param tooltip GameTooltip
local function onTooltipShow(tooltip)
  -- Add object IDs when the client or server exposes object GUIDs on tooltip owners.
  local owner = tooltip.GetOwner and tooltip:GetOwner()
  local guid = owner and (owner.guid or owner.GUID or owner.nidtipGuid)
  local id = parseObjectId(guid)
  addLine(tooltip, id, labels.object)
end

---@param link string|nil
local function onSetItemRef(link)
  -- Add IDs to chat-link reference tooltips.
  local linkType, id = parseLink(link)
  addLinkId(ItemRefTooltip, linkType, id)
end

---@param tooltip GameTooltip
---@param index number
local function onSetCurrencyToken(tooltip, index)
  -- Add currency IDs from the currency list tooltip.
  local link = GetCurrencyListLink and GetCurrencyListLink(index)
  local linkType, id = parseLink(link)
  if linkType == "currency" then addLine(tooltip, id, labels.currency) end
end

---@param tooltip GameTooltip
---@param id number|string
local function onSetCurrencyById(tooltip, id)
  -- Add currency IDs when a tooltip is directly assigned by ID.
  addLine(tooltip, id, labels.currency)
end

---@param tooltip GameTooltip
---@param id number|string
local function onSetCurrencyTokenById(tooltip, id)
  -- Add currency token IDs when a tooltip is directly assigned by token ID.
  addLine(tooltip, id, labels.currency)
end

local function hideGameTooltip(owner)
  -- Hide GameTooltip for nidtip-created tooltip overlays.
  A:HideHintTooltip(owner)
end

GMminibarNidtip = GMminibarNidtip or {}
GMminibarNidtip.addLine = addLine
GMminibarNidtip.hideGameTooltip = hideGameTooltip
GMminibarNidtip.labels = labels
GMminibarNidtip.parseLink = parseLink
GMminibarNidtip.parseNpcId=parseNpcId
GMminibarNidtip.parseObjectId=parseObjectId
A.IDTips=GMminibarNidtip

---@param button table
local function onAchievementButtonEnter(button)
  -- Add achievement IDs on achievement list buttons.
  if not button or not button.id then return end

  local GameTooltip=A:BeginHintTooltip(button, "ANCHOR_NONE")
  GameTooltip:SetPoint("TOPLEFT", button, "TOPRIGHT", 0, 0)
  addLine(GameTooltip, button.id, labels.achievement)
end

---@param frame table
local function onAchievementCriteriaEnter(frame)
  -- Add achievement and criteria IDs when hovering an achievement criteria row.
  local parent = frame:GetParent()
  local button = parent and parent:GetParent()
  if not button or not button.id then return end

  local criteriaId = select(10, GetAchievementCriteriaInfo(button.id, frame.nidtipCriteriaIndex))
  local GameTooltip=A:BeginHintTooltip(frame, "ANCHOR_NONE")
  GameTooltip:SetPoint("TOPLEFT", frame, "TOPRIGHT", 0, 0)
  addLine(GameTooltip, button.id, labels.achievement)
  addLine(GameTooltip, criteriaId, labels.criteria)
end

---@param frame table
---@param index number
local function hookAchievementCriteria(frame, index)
  -- Add achievement and criteria IDs on achievement criteria rows.
  if not frame or frame.nidtipHooked then return end

  frame.nidtipCriteriaIndex = index
  frame:HookScript("OnEnter", onAchievementCriteriaEnter)
  frame:HookScript("OnLeave", hideGameTooltip)
  frame.nidtipHooked = true
end

---@param index number
---@param renderOffScreen boolean|nil
local function onAchievementButtonGetCriteria(index, renderOffScreen)
  -- Hook criteria frames as Blizzard creates or reuses them.
  local suffix = renderOffScreen and "OffScreen" or ""
  hookAchievementCriteria(_G["AchievementFrameCriteria" .. suffix .. index], index)
end

---@param button table
local function hookAchievementButton(button)
  -- Hook one achievement button if it has not been hooked yet.
  if not button or button.nidtipHooked then return end
  button:HookScript("OnEnter", onAchievementButtonEnter)
  button:HookScript("OnLeave", hideGameTooltip)
  button.nidtipHooked = true
end

local function hookAchievementFrame()
  -- Hook Pandaria achievement buttons and criteria rows after Blizzard_AchievementUI loads.
  if not AchievementFrameAchievementsContainer then return end

  for _, button in ipairs(AchievementFrameAchievementsContainer.buttons or {}) do
    hookAchievementButton(button)
  end

  if AchievementButton_GetCriteria and not GMminibarNidtip_ACHIEVEMENT_CRITERIA_HOOKED then
    safeHook("AchievementButton_GetCriteria", onAchievementButtonGetCriteria)
    GMminibarNidtip_ACHIEVEMENT_CRITERIA_HOOKED = true
  end

  if AchievementFrameAchievements_Update and not GMminibarNidtip_ACHIEVEMENT_UPDATE_HOOKED then
    safeHook("AchievementFrameAchievements_Update", hookAchievementFrame)
    GMminibarNidtip_ACHIEVEMENT_UPDATE_HOOKED = true
  end
end

---@param tooltip GameTooltip
---@param socketId number
local function onSetGlyph(tooltip, socketId)
  -- Add glyph IDs when glyph socket tooltips expose socket info.
  if not GetGlyphSocketInfo then return end
  local _, _, _, glyphSpellId = GetGlyphSocketInfo(socketId)
  addLine(tooltip, glyphSpellId, labels.glyph)
end

local function hookItemTooltips()
  -- Register item tooltip hooks across base, reference, and shopping tooltips.
  local tooltips = {};for _,t in pairs({GameTooltip,ItemRefTooltip,A:GetHintTooltip()}) do tooltips[#tooltips+1]=t end

  for index = 1, config.shoppingTooltipCount do
    tooltips[#tooltips + 1] = _G["ItemRefShoppingTooltip" .. index]
    tooltips[#tooltips + 1] = _G["ShoppingTooltip" .. index]
  end

  for _, tooltip in ipairs(tooltips) do
    if tooltip then
      tooltip:HookScript("OnTooltipSetItem", function(t)if t.GetItem then onTooltipSetItem(t) end end)
      safeHook(tooltip,'SetHyperlink',onSetHyperlink)
    end
  end
end

local function hookTooltipMethods()
  -- Register all direct GameTooltip and ItemRefTooltip method hooks.
  GameTooltip:HookScript("OnTooltipSetSpell", onTooltipSetSpell)
  GameTooltip:HookScript("OnTooltipSetUnit", onTooltipSetUnit)
  GameTooltip:HookScript("OnShow", onTooltipShow)

  safeHook(GameTooltip, "SetUnitBuff", onSetUnitBuff)
  safeHook(GameTooltip, "SetUnitDebuff", onSetUnitDebuff)
  safeHook(GameTooltip, "SetUnitAura", onSetUnitAura)
  safeHook(GameTooltip, "SetHyperlink", onSetHyperlink)
  safeHook(ItemRefTooltip, "SetHyperlink", onSetHyperlink)
  safeHook("SetItemRef", onSetItemRef)

  if GameTooltip.SetCurrencyToken then
    safeHook(GameTooltip, "SetCurrencyToken", onSetCurrencyToken)
  end
  if GameTooltip.SetCurrencyByID then
    safeHook(GameTooltip, "SetCurrencyByID", onSetCurrencyById)
  end
  if GameTooltip.SetCurrencyTokenByID then
    safeHook(GameTooltip, "SetCurrencyTokenByID", onSetCurrencyTokenById)
  end
  if GameTooltip.SetGlyph then
    safeHook(GameTooltip, "SetGlyph", onSetGlyph)
  end
end

local function onAddonLoaded(_, _, addonName)
  -- Delay achievement hooks until Blizzard's achievement UI exists.
  if addonName == "Blizzard_AchievementUI" then hookAchievementFrame() end
end

local function initialize()
  -- Wire Pandaria-safe tooltip hooks once at addon load.
  hookItemTooltips()
  hookTooltipMethods()
  hookAchievementFrame()

  local frame = CreateFrame("Frame")
  frame:RegisterEvent("ADDON_LOADED")
  frame:SetScript("OnEvent", onAddonLoaded)
end

initialize()
