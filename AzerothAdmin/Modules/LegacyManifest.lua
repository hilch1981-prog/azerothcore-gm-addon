AzerothAdminEasy = AzerothAdminEasy or {}
local addon = AzerothAdminEasy
if not addon.RegisterModule then return end

local modules = {
    { "shell", {}, { "Core.lua", "UI.lua", "Locale.lua" }, {}, { "tools/test_quickslot_actions.py", "tools/test_popup_layer_lifecycle.py" }, "AzerothAdmin/Modules/Shell" },
    { "commands", { "shell" }, { "CommandMeta.lua", "Commands.lua" }, {}, { "tools/test_audit_command_meta.py" }, "AzerothAdmin/Modules/Commands" },
    { "creatures", { "shell", "search", "teleports" }, { "CreatureBrowser.lua" }, { "FeaturedCreatures.lua" }, { "tools/test_featured_creature_browser.py" }, "AzerothAdmin/Modules/Creatures" },
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
