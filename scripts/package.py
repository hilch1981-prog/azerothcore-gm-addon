from pathlib import Path
import hashlib,json,zipfile
ROOT=Path(__file__).resolve().parents[1]
def package():
    c=json.loads((ROOT/'release.json').read_text('utf-8'))
    dest=ROOT/'dist'/c['asset'];dest.parent.mkdir(exist_ok=True)
    paths=[p for p in sorted((ROOT/'GMminibar').rglob('*')) if p.is_file()]
    with zipfile.ZipFile(dest,'w',compression=zipfile.ZIP_DEFLATED,compresslevel=9) as z:
        for p in paths:
            item=zipfile.ZipInfo(p.relative_to(ROOT).as_posix(),(2026,9,14,0,0,0))
            item.compress_type=zipfile.ZIP_DEFLATED;item.external_attr=0o100644<<16
            z.writestr(item,p.read_bytes(),compresslevel=9)
    with zipfile.ZipFile(dest) as z:
        assert z.testzip() is None
        assert set(i.split('/')[0] for i in z.namelist())=={'GMminibar'}
        for p in paths:assert z.read(p.relative_to(ROOT).as_posix())==p.read_bytes()
        assert len(z.namelist())==len(paths)
    digest=hashlib.sha256(dest.read_bytes()).hexdigest()
    print(dest.name,dest.stat().st_size,'bytes; SHA256',digest)
    return dest
if __name__=='__main__':package()
