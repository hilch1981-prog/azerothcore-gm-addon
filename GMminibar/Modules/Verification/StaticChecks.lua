local A = AzerothAdminAC335
A.Verification = A.Verification or {}
A.Verification.expected = {
    version = "1.0.0",
    interface = 30300,
    operatorSecurity = 3,
    security = { PLAYER = 0, MODERATOR = 1, GAMEMASTER = 2, ADMINISTRATOR = 3, CONSOLE = 4 },
    itemSources = 13675,
    professions = 11,
    quickTeleports = 404,
    databaseCatalog = 26,
    professionDetails = 3552,
    legacyCategoryEntries = 190,
    questLocations = 8879,
    teleportMeta = 404,
    generated = { Items = 46096, Quests = 9464, Creatures = 29950, Teleports = 404 },
}

function A:CollectStaticRuntimeFacts()
    local facts = {
        version = self.version,
        interface = self.interface,
        operatorSecurity = self.operatorSecurity,
        itemSources = self.Data and self.Data:CountItemSources() or 0,
        professions = self.Data and self.Data:CountProfessions() or 0,
        quickTeleports = self.Data and table.getn(self.Data.teleports or {}) or 0,
        databaseCatalog = self.Data and table.getn(self.Data.databaseCatalog or {}) or 0,
        professionDetails = self.Data and self.Data:CountTable(self.Data.professionDetails) or 0,
        legacyCategoryEntries = self.Data and self.Data.legacyItemCategories and table.getn(self.Data.legacyItemCategories.entries or {}) or 0,
        questLocations = self.Data and self.Data:CountQuestLocations() or 0,
        teleportMeta = self.Data and self.Data:CountTeleportMeta() or 0,
        commandCount = table.getn(self.CommandOrder or {}),
        moduleCount = table.getn(self.ModuleOrder or {}),
    }
    facts.generated = {}
    for kind in pairs(self.Verification.expected.generated) do
        facts.generated[kind] = self.Data and self.Data:GeneratedCount(kind) or 0
    end
    return facts
end
