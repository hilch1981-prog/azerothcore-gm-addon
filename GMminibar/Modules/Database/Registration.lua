local A = AzerothAdminAC335
A:RegisterModule("database", { status = "module-active-static-verified-game-test-pending", dependencies = { "language" }, runtimeFiles = { "Modules/Database/Module.lua", "Modules/Database/Registration.lua" }, tests = { "tests/test_release_contract.py", "tools/verify_release.py" }, notes = "AC335 3.3.5a Build 12340 in-game smoke pending" })
