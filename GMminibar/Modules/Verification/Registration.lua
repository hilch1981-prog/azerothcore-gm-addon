local A = AzerothAdminAC335
A:RegisterModule("verification", {
    status = "module-active-static-verified-game-test-pending",
    dependencies = { "commands", "database", "teleports" },
    runtimeFiles = {
        "Modules/Verification/StaticChecks.lua",
        "Modules/Verification/Registration.lua",
        "Tests/RuntimeSelfTest.lua",
    },
    tests = { "tests/test_release_contract.py", "tools/verify_release.py" },
    notes = "Read-only runtime self-test; no GM command is sent.",
})
