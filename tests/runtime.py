from runtime_loader import full_runtime
lua = full_runtime('ac335')
value = lua.eval('A:RunRuntimeSelfTest()')
ok = value if isinstance(value, bool) else value[0]
assert ok, str(value)
assert lua.eval('A.version') == '1.0.0'
print('PASS Lua 5.1 full TOC load and runtime self-test')
