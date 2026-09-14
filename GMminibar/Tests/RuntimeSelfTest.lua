local A = AzerothAdminAC335
-- Read-only integrity check. A pass does not verify the live game/server.
function A:RunRuntimeSelfTest()
    local facts = self:CollectStaticRuntimeFacts()
    local failures = {}
    local function check(key, actual, expected)
        if actual ~= expected then failures[#failures+1] = key .. ": " .. tostring(actual) .. " / " .. tostring(expected) end
    end
    for key, expected in pairs(self.Verification.expected) do
        if type(expected) == "table" then
            local actual = key == "security" and self.Security or facts[key] or {}
            for field, value in pairs(expected) do check(key .. "." .. field, actual[field], value) end
        else check(key, facts[key], expected) end
    end
    check("namespace", AzerothAdminAC335, self)
    check("slash", type(SlashCmdList.AZEROTHADMINAC335), "function")
    check("interface", self.interface, 30300)
    check("maximumLevel", self.maximumLevel, 80)
    check("maximumProfessionSkill", self.maximumProfessionSkill, 450)
    check("demorph", self.CommandCatalog.demorph.command, ".morph reset")
    for _, row in ipairs(self.Data.Teleports or {}) do
        local id = row.id
        local meta = self.Data.teleportMeta[id]
        if not (meta and meta==row and meta.levelText and self:TeleportCommandFor(row)) then
            failures[#failures+1] = "teleport metadata: " .. tostring(id)
        end
    end
    for _, name in ipairs({"CreateItemBrowser", "CreateTeleportWindow", "CreateProfessionWindow", "CreateQuestHelperWindow", "OpenSpellBrowser", "OpenBank"}) do
        check(name, type(self[name]), "function")
    end
    if #failures == 0 then
        self:Print("INTEGRITY PASS / GAME TEST PENDING")
        return true
    end
    self:Print("INTEGRITY FAIL (" .. #failures .. ")", true)
    for _, failure in ipairs(failures) do self:Print(failure, true) end
    return false, failures
end
