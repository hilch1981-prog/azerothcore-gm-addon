-- Adapted from user supplied nidtip5, Silverwind / nidtip5 rebuild.
local A=AzerothAdminAC335
---@class NidtipConfig
---@field color string
---@field duplicateScanLines number
---@field shoppingTooltipCount number
---@field labels table<string, string>
GMminibarNidtip_CONFIG = {
  color = "|cffffffff",
  duplicateScanLines = 30,
  shoppingTooltipCount = 3,
  labels = {
    ability = A:L("IDTIP_ABILITY"),
    achievement = A:L("IDTIP_ACHIEVEMENT"),
    criteria = A:L("IDTIP_CRITERIA"),
    currency = A:L("IDTIP_CURRENCY"),
    glyph = A:L("IDTIP_GLYPH"),
    item = A:L("IDTIP_ITEM"),
    npc = A:L("IDTIP_NPC"),
    object = A:L("IDTIP_OBJECT"),
    quest = A:L("IDTIP_QUEST"),
    spell = A:L("IDTIP_SPELL"),
    talent = A:L("IDTIP_TALENT")
  }
}

-- Resolve labels on demand so saved/client locale and later changes are respected.
GMminibarNidtip_CONFIG.labels=setmetatable({}, {__index=function(_,key) return A:L("IDTIP_"..string.upper(key)) end})
