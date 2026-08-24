AzerothAdminEasy = AzerothAdminEasy or {}
local addon = AzerothAdminEasy

-- Runtime ownership moves to this feature module. The identical Core.lua copy
-- is kept as a one-release compatibility fallback until the stacked module is
-- game-tested, then removed in a follow-up cleanup PR. Because this file loads
-- after Core.lua, this definition is the active implementation.
addon.ReviveModuleRevision = "1.0.0-fallback"

function addon:ReviveSmart(definition)
    local selfDead = false
    if UnitIsDeadOrGhost then selfDead = UnitIsDeadOrGhost("player") and true or false end
    if not selfDead and UnitIsDead then selfDead = UnitIsDead("player") and true or false end
    if not selfDead and UnitIsGhost then selfDead = UnitIsGhost("player") and true or false end

    if selfDead then
        local playerName = UnitName("player")

        -- AzerothCore .revive resolves the current selected player or self when
        -- no character argument is supplied.  Clear the selection so the command
        -- cannot accidentally resolve to a stale target after dying/releasing.
        if ClearTarget then pcall(ClearTarget) end

        -- Do not depend on SAY while dead.  WHISPER-to-self is still a normal
        -- CMSG_MESSAGECHAT packet and AzerothCore parses the GM command before
        -- regular chat delivery checks.  This also keeps the command syntax at
        -- the core-native '.revive' form.
        self:RunAfter(0.05, function()
            if ClearTarget then pcall(ClearTarget) end
            addon:SendNow(".revive", definition, "WHISPER", playerName)
        end)

        -- Retry only while the client still reports corpse/ghost.  The second
        -- whisper covers selection-update latency; the final SAY is a compatibility
        -- fallback for custom cores that only accept commands from SAY.
        self:RunAfter(0.35, function()
            local stillDead = (UnitIsDeadOrGhost and UnitIsDeadOrGhost("player"))
                or (UnitIsDead and UnitIsDead("player"))
                or (UnitIsGhost and UnitIsGhost("player"))
            if stillDead then
                if ClearTarget then pcall(ClearTarget) end
                addon:SendNow(".revive", nil, "WHISPER", playerName)
            end
        end)
        self:RunAfter(0.90, function()
            local stillDead = (UnitIsDeadOrGhost and UnitIsDeadOrGhost("player"))
                or (UnitIsDead and UnitIsDead("player"))
                or (UnitIsGhost and UnitIsGhost("player"))
            if stillDead then
                if ClearTarget then pcall(ClearTarget) end
                addon:SendNow(".revive")
            end
        end)
        return
    end

    -- Alive GM: preserve normal target-or-self behavior for reviving another
    -- selected player.
    self:SendNow(".revive", definition)
end

if addon.RegisterModule and not addon:GetModule("revive") then
    addon:RegisterModule("revive", {
        status = "module-active-legacy-fallback",
        dependencies = { "shell", "commands" },
        runtimeFiles = { "Modules/Revive/Module.lua", "Core.lua" },
        dataFiles = {},
        tests = { "tools/test_self_revive_flow.py" },
        futurePath = "AzerothAdmin/Modules/Revive",
    })
end
