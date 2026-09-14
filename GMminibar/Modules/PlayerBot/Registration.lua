local A = AzerothAdminAC335
A:RegisterModule("playerbot", { status = "BLOCKED", dependencies = { "commands" }, runtimeFiles = { "Modules/PlayerBot/Module.lua", "Modules/PlayerBot/Registration.lua" }, tests = { "tests/test_release_contract.py", "tools/verify_release.py" }, notes = "PlayerBot POC boot/game gates pending" })
