AzerothAdminEasy = AzerothAdminEasy or {}
local addon = AzerothAdminEasy
if not addon.RegisterModule then return end

-- Ownership map for existing files. It does not execute, replace, or wrap any
-- legacy feature. Each row is migrated in a separate feature PR.
local modules = {
    { "shell", {}, { "Core.lua", "UI.lua", "Locale.lua" }, {}, { "tools/test_quickslot_actions.py", "tools/test_popup_layer_lifecycle.py" }, "AzerothAdmin/Modules/Shell" },
    { "commands", { "shell" }, { "CommandMeta.lua", "Commands.lua" }, {}, { "tools/test_audit_command_meta.py" }, "AzerothAdmin/Modules/Commands" },
    { "teleports", { "shell", "commands" }, { "FavoriteTeleports.lua" }, { "Teleports.lua" }, {}, "AzerothAdmin/Modules/Teleports" },
    { "search", { "shell" }, { "KoKRSearch.lua" }, { "KoKRSearchData.lua" }, {}, "AzerothAdmin/Modules/Search" },
    { "creatures", { "shell", "search", "teleports" }, { "CreatureBrowser.lua" }, { "FeaturedCreatures.lua" }, { "tools/test_featured_creature_browser.py" }, "AzerothAdmin/Modules/Creatures" },
    { "profession-info", { "shell" }, { "Embedded/InvenCraftInfo/Core.lua", "Embedded/InvenCraftInfoUI/Rebuilt.lua" }, { "Embedded/InvenCraftInfoData" }, { "tools/test_craft_frame_lifecycle.py" }, "AzerothAdmin/Modules/ProfessionInfo" },
    { "integrations", { "shell" }, { "Integrations.lua" }, {}, {}, "AzerothAdmin/Modules/Integrations" },
}

local i
for i = 1, table.getn(modules) do
    local row = modules[i]
    addon:RegisterModule(row[1], {
        status = "legacy-migration-pending",
        dependencies = row[2],
        runtimeFiles = row[3],
        dataFiles = row[4],
        tests = row[5],
        futurePath = row[6],
    })
end
