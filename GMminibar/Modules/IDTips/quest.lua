-- Adapted from user supplied nidtip5, Silverwind / nidtip5 rebuild.
local A=AzerothAdminAC335
local function safeHook(target,method,callback)
 if type(target)=='string' then if type(_G[target])=='function' then hooksecurefunc(target,method) end
 elseif target and type(target[method])=='function' then hooksecurefunc(target,method,callback) end
end
local labels = GMminibarNidtip.labels
local addLine = GMminibarNidtip.addLine
local hideGameTooltip = function(owner)A:HideHintTooltip(owner)end
local parseLink = GMminibarNidtip.parseLink

---@param index number|nil
---@return string|number|nil
local function getQuestIdFromIndex(index)
  -- Resolve quest IDs from Pandaria quest log indices.
  if not index or not GetQuestLogTitle then return nil end

  local link = GetQuestLink and GetQuestLink(index)
  local linkType, linkId = parseLink(link)
  if linkType == "quest" and linkId then return linkId end

  local _,_,_,header,_,_,_,id=A.ReadQuestLogTitle(index)
  return not header and id or nil
end

---@param button table
---@return string|number|nil
local function getQuestIndexFromButton(button)
  -- Convert visible quest row IDs into real quest log indices.
  if not button then return nil end
  if button.questLogIndex then return button.questLogIndex end
  if not button.GetID then return nil end

  local offset = 0
  if QuestLogListScrollFrame and FauxScrollFrame_GetOffset then
    offset = FauxScrollFrame_GetOffset(QuestLogListScrollFrame) or 0
  end

  if QuestLogScrollFrame and QuestLogScrollFrame.buttons then return button:GetID() end
  return offset + button:GetID()
end

---@param button table
---@return string|number|nil
local function getQuestIdFromButton(button)
  -- Resolve quest IDs from common quest log, watch, and map button fields.
  if not button then return nil end
  local index = getQuestIndexFromButton(button)
  return button.questID or button.questId or getQuestIdFromIndex(index) or button.id
end

---@param textFrame table
---@param id string|number
local function appendQuestIdToText(textFrame, id)
  -- GMminibar keeps quest IDs in a separate list column; never alter titles.
  return
end

---@param button table
---@param id string|number
local function appendQuestIdToButtonTitle(button, id)
  -- Append a compact quest ID suffix to a quest row title.
  local name = button.GetName and button:GetName()
  local fontString = button.GetFontString and button:GetFontString()
  appendQuestIdToText(button.Text or button.NormalText or fontString or _G[(name or "") .. "NormalText"], id)
end

---@param id string|number|nil
local function appendQuestIdToSelectedTitle(id)
  -- Append a compact quest ID suffix to the selected quest detail title.
  if not id then return end

  appendQuestIdToText(QuestLogQuestTitle, id)
  appendQuestIdToText(QuestLogTitleText, id)
  appendQuestIdToText(QuestLogDetailTitle, id)
  appendQuestIdToText(QuestInfoTitleHeader, id)
end

---@return string|number|nil
local function getSelectedQuestId()
  -- Resolve the currently selected quest ID from the quest log selection.
  if not GetQuestLogSelection then return nil end
  return getQuestIdFromIndex(GetQuestLogSelection())
end

local function updateSelectedQuestTitle()
  -- Refresh the selected quest detail title suffix.
  appendQuestIdToSelectedTitle(getSelectedQuestId())
end

---@param button table
local function onQuestButtonEnter(button)
  -- Show quest IDs when hovering Pandaria quest title buttons.
  local id = getQuestIdFromButton(button)
  if not id then return end

  local GameTooltip=A:BeginHintTooltip(button, "ANCHOR_RIGHT")
  addLine(GameTooltip, id, labels.quest)
  appendQuestIdToButtonTitle(button, id)
end

---@param frame table
local function hookQuestButton(frame)
  -- Hook one quest-bearing frame and add a title suffix immediately.
  if not frame or frame.nidtipQuestHooked then return end

  frame:HookScript("OnEnter", onQuestButtonEnter)
  frame:HookScript("OnLeave", hideGameTooltip)
  frame.nidtipQuestHooked = true

  local id = getQuestIdFromButton(frame)
  if id then appendQuestIdToButtonTitle(frame, id) end
end

local function hookQuestLogButtons()
  -- Hook visible Pandaria quest log title buttons.
  for index = 1, 50 do hookQuestButton(_G["QuestLogTitle" .. index]) end
  for _,b in ipairs(QuestLogScrollFrame and QuestLogScrollFrame.buttons or {}) do hookQuestButton(b) end
end

---@param frame table
local function onSelectedQuestFrameEnter(frame)
  -- Show selected quest IDs when hovering the quest detail area.
  local id = getSelectedQuestId()
  if not id then return end

  local GameTooltip=A:BeginHintTooltip(frame, "ANCHOR_RIGHT")
  addLine(GameTooltip, id, labels.quest)
  appendQuestIdToSelectedTitle(id)
end

---@param frame table
local function hookSelectedQuestFrame(frame)
  -- Hook one quest detail frame for selected quest hover support.
  if not frame or frame.nidtipSelectedQuestHooked then return end

  frame:HookScript("OnEnter", onSelectedQuestFrameEnter)
  frame:HookScript("OnLeave", hideGameTooltip)
  frame.nidtipSelectedQuestHooked = true
end

local function hookSelectedQuestFrames()
  -- Hook common Pandaria quest detail frames and title strings.
  hookSelectedQuestFrame(QuestLogFrame)
  hookSelectedQuestFrame(QuestLogDetailFrame)
  hookSelectedQuestFrame(QuestLogDetailScrollFrame)
  updateSelectedQuestTitle()
end

local function refreshQuestDisplay()
  -- Refresh all quest row and selected quest ID decorations.
  hookQuestLogButtons()
  hookSelectedQuestFrames()
end

---@param frame table
local function onQuestPoiEnter(frame)
  -- Add quest IDs to map or tracker tooltip frames when Blizzard exposes the ID.
  addLine(WorldMapTooltip or GameTooltip, getQuestIdFromButton(frame), labels.quest)
end

local function hookQuestMethods()
  -- Register quest log, map POI, and tracker hooks that exist in Pandaria clients.
  refreshQuestDisplay()

  if QuestLog_Update and not GMminibarNidtip_QUEST_LOG_UPDATE_HOOKED then
    safeHook("QuestLog_Update", refreshQuestDisplay)
    GMminibarNidtip_QUEST_LOG_UPDATE_HOOKED = true
  end
  if SelectQuestLogEntry and not GMminibarNidtip_SELECT_QUEST_LOG_ENTRY_HOOKED then
    safeHook("SelectQuestLogEntry", updateSelectedQuestTitle)
    GMminibarNidtip_SELECT_QUEST_LOG_ENTRY_HOOKED = true
  end
  if QuestLog_SetSelection and not GMminibarNidtip_QUEST_LOG_SET_SELECTION_HOOKED then
    safeHook("QuestLog_SetSelection", updateSelectedQuestTitle)
    GMminibarNidtip_QUEST_LOG_SET_SELECTION_HOOKED = true
  end
  if QuestLog_UpdateQuestDetails and not GMminibarNidtip_QUEST_LOG_DETAILS_HOOKED then
    safeHook("QuestLog_UpdateQuestDetails", updateSelectedQuestTitle)
    GMminibarNidtip_QUEST_LOG_DETAILS_HOOKED = true
  end
  if QuestPOIButton_OnEnter and not GMminibarNidtip_QUEST_POI_HOOKED then
    safeHook("QuestPOIButton_OnEnter", onQuestPoiEnter)
    GMminibarNidtip_QUEST_POI_HOOKED = true
  end
  if TaskPOI_OnEnter and not GMminibarNidtip_TASK_POI_HOOKED then
    safeHook("TaskPOI_OnEnter", onQuestPoiEnter)
    GMminibarNidtip_TASK_POI_HOOKED = true
  end
end

hookQuestMethods()
