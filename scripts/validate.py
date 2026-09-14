from pathlib import Path
import hashlib,json,os,re,subprocess,sys,tempfile,xml.etree.ElementTree as ET
ROOT=Path(__file__).resolve().parents[1]
def main():
    c=json.loads((ROOT/'release.json').read_text('utf-8'));base=ROOT/'GMminibar'
    toc=(base/'GMminibar.toc').read_text('utf-8-sig')
    assert re.search(r'^## Version: '+re.escape(c['version'])+r'\s*$',toc,re.M)
    assert re.search(r'^## Interface: '+str(c['interface'])+r'\s*$',toc,re.M)
    actual={p.relative_to(base).as_posix():p for p in base.rglob('*') if p.is_file()}
    assert len(list(base.rglob('*.toc')))==1
    seen=set()
    for line in toc.splitlines():
        line=line.strip().replace('\\','/')
        if not line or line.startswith('#'):continue
        assert line in actual,('Missing or wrongly cased TOC reference',line)
        assert line not in seen;seen.add(line)
    for p in base.rglob('*.xml'):
        for element in ET.parse(p).iter():
            if 'file' in element.attrib:
                rel=(p.parent/element.attrib['file'].replace('\\','/')).relative_to(base).as_posix()
                assert rel in actual,('XML reference',rel)
    expected={}
    for line in (base/'FILE_MANIFEST.sha256').read_text('utf-8').splitlines():
        digest,rel=line.split('  ',1);assert rel not in expected;expected[rel]=digest
    assert set(expected)==set(actual)-{'FILE_MANIFEST.sha256'}
    for rel,digest in expected.items():assert hashlib.sha256(actual[rel].read_bytes()).hexdigest()==digest,rel
    forbidden={'.mpq','.dll','.exe','.sql','.zip','.7z','.dbc'}
    assert not any(p.suffix.lower() in forbidden for p in actual.values())
    lua_files=sorted(base.rglob('*.lua'))
    if c['key']=='turtle':
        binary=os.environ.get('LUA50','lua')
        source='assert(_VERSION=="Lua 5.0.3",_VERSION)\n'
        for p in lua_files:
            rel=p.relative_to(ROOT).as_posix();source+='assert(loadfile('+json.dumps(rel)+'))\n'
        source+='assert(loadfile("tests/data.lua"))()\nprint("PASS Lua 5.0.3 syntax and data load")\n'
        with tempfile.NamedTemporaryFile('w',encoding='utf-8',suffix='.lua',delete=False) as f:
            f.write(source);name=f.name
        try:subprocess.run([binary,name],cwd=ROOT,check=True)
        finally:Path(name).unlink()
    else:
        from lupa.lua51 import LuaRuntime
        lua=LuaRuntime(unpack_returned_tuples=True)
        compile=lua.eval('function(s,n) local f,e=loadstring(s,n); return f~=nil,e end')
        for p in lua_files:
            ok,err=compile(p.read_bytes().removeprefix(b'\xef\xbb\xbf'),'@'+p.relative_to(base).as_posix())
            assert ok,(str(p),err)
        subprocess.run([sys.executable,str(ROOT/'tests/runtime.py')],cwd=ROOT,check=True)
    print('PASS:',len(lua_files),'Lua files;',len(seen),'TOC entries; XML, version, manifest, package scope')
if __name__=='__main__':main()
