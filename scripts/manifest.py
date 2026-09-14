from pathlib import Path
import hashlib
ROOT=Path(__file__).resolve().parents[1]
def generate():
    base=ROOT/'GMminibar'
    lines=[]
    for p in sorted(base.rglob('*')):
        if p.is_file() and p.name!='FILE_MANIFEST.sha256':
            lines.append(hashlib.sha256(p.read_bytes()).hexdigest()+'  '+p.relative_to(base).as_posix())
    (base/'FILE_MANIFEST.sha256').write_text('\n'.join(lines)+'\n',encoding='utf-8',newline='\n')
    print('Manifest:',len(lines),'files')
if __name__=='__main__':generate()
