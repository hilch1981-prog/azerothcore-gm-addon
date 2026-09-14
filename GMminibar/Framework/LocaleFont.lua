local A = AzerothAdminAC335
local FALLBACK="Interface\\AddOns\\GMminibar\\Fonts\\GMminibarUnicode.ttf"
-- Match the running client's own font. Keep Unicode coverage when the user
-- explicitly switches to a language the client font cannot represent.
function A:PresentationFont()
 local client=GetLocale and GetLocale() or 'enUS'
 local locale=self:GetConfiguredLocale()
 if locale==client or locale=='enUS' then
  local font=GameFontNormal and GameFontNormal.GetFont and GameFontNormal:GetFont()
  return font or STANDARD_TEXT_FONT or 'Fonts\\FRIZQT__.TTF'
 end
 return FALLBACK
end
function A:ApplyLocaleFont(region)
 if not region or not region.GetFont or not region.SetFont then return end
 local _,size,flags=region:GetFont()
 local font=self:PresentationFont()
 region:SetFont(font,math.max(12,tonumber(size) or 12),font==FALLBACK and 'OUTLINE'or(flags or ''))
 if region.SetShadowColor then region:SetShadowColor(0,0,0,1);region:SetShadowOffset(1,-1) end
end
function A:FitLocaleButton(button)
 local label=button.aaeLabel or (button.GetFontString and button:GetFontString())
 if not label or not label.GetStringWidth or not button.GetWidth then return end
 local _,size,flags=label:GetFont()
 local original=label.gmLocaleSize or math.max(12,tonumber(size) or 12);label.gmLocaleSize=original
 local font=self:PresentationFont();label:SetFont(font,original,flags or '')
 local available=button:GetWidth()-(button.icon and 44 or button.aaeProfessionIcon and 40 or 12);local width=label:GetStringWidth()
 if available>0 and width>available then label:SetFont(font,math.max(11,original*available/width),flags or '') end
end
function A:GetFontObject(kind)
    if kind == "large" then return GameFontNormalLarge end
    if kind == "small" then return GameFontHighlightSmall end
    return GameFontNormal
end
function A:GetHintTooltip()
    if not self.hintTooltip then
        self.hintTooltip=CreateFrame("GameTooltip","GMminibarHintTooltip",UIParent,"GameTooltipTemplate")
    end
    return self.hintTooltip
end
function A:StyleHintTooltip()
    local tip=self.hintTooltip
    if not tip then return end
    for i=1,(tip.NumLines and tip:NumLines() or 0) do
        self:ApplyLocaleFont(_G["GMminibarHintTooltipTextLeft"..i])
        self:ApplyLocaleFont(_G["GMminibarHintTooltipTextRight"..i])
    end
end
function A:HideHintTooltip(owner)
    if self.hintTooltip and (not owner or self.hintOwner==owner) then
        self.hintTooltip:Hide();self.hintOwner=nil
    end
end
function A:BeginHintTooltip(owner,anchor)
    local tip=self:GetHintTooltip()
    self.hintOwner=owner
    tip:SetOwner(owner or UIParent,anchor or "ANCHOR_RIGHT")
    if tip.ClearLines then tip:ClearLines() end
    if owner and owner.HookScript and not owner.gmHintOwnerHooks then
        owner.gmHintOwnerHooks=true
        owner:HookScript("OnLeave",function() A:HideHintTooltip(owner) end)
        owner:HookScript("OnHide",function() A:HideHintTooltip(owner) end)
    end
    return tip
end
