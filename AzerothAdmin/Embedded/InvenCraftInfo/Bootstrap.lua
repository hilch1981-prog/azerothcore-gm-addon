-- Load the Blizzard trade skill UI before the embedded InvenCraftInfo UI files.
if LoadAddOn and IsAddOnLoaded and not IsAddOnLoaded("Blizzard_TradeSkillUI") then
    pcall(LoadAddOn, "Blizzard_TradeSkillUI")
end
