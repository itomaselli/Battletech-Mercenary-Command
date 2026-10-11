from pathlib import Path
import zipfile,sys
root=Path(__file__).resolve().parents[1]
version=sys.argv[1]
(root/'releases').mkdir(exist_ok=True)
with zipfile.ZipFile(root/'releases'/f'{version}-source.zip','w',zipfile.ZIP_DEFLATED) as z:
 for p in root.rglob('*'):
  if not p.is_file() or any(part in {'.git','.godot','releases','exports','__pycache__'} for part in p.relative_to(root).parts): continue
  if p.suffix in {'.tmp','.import'}: continue
  z.write(p,p.relative_to(root))
print('Snapshot',version)
