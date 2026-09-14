local A = AzerothAdminAC335
A:RegisterModule("search", { status = "module-active-static-verified-game-test-pending", dependencies = { "commands" }, runtimeFiles = { "Modules/Search/Module.lua", "Modules/Search/Registration.lua" }, tests = { "tests/test_release_contract.py", "tools/verify_release.py" }, notes = "AC335 3.3.5a Build 12340 in-game smoke pending" })
