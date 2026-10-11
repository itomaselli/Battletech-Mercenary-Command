"""Build a self-contained local macOS app with the installed Godot runtime."""
from pathlib import Path
import plistlib, shutil, os, sys
root=Path(__file__).resolve().parents[1]
engine=Path(sys.argv[1] if len(sys.argv)>1 else '/tmp/mercenary-godot/Godot.app')
version=next(line.split('"')[1] for line in (root/'project.godot').read_text().splitlines() if line.startswith('config/version='))
app=root/'exports'/f'Mercenary Command {version}.app'
if app.exists():
    raise SystemExit(f'Build already exists; preserve or remove it explicitly: {app}')
contents=app/'Contents'; resources=contents/'Resources'; macos=contents/'MacOS'
resources.mkdir(parents=True); macos.mkdir()
shutil.copytree(engine,resources/'Engine.app')
game=resources/'game'; game.mkdir()
for name in ['sim','ui','visual','assets','data']:
    shutil.copytree(root/name,game/name)
shutil.copy2(root/'project.godot',game/'project.godot')
shutil.copytree(root/'.godot',game/'.godot',ignore=shutil.ignore_patterns('editor'))
launcher=macos/'MercenaryCommand'
launcher.write_text('''#!/bin/zsh
set -eu
bundle_root="${0:A:h:h}"
exec "$bundle_root/Resources/Engine.app/Contents/MacOS/Godot" --path "$bundle_root/Resources/game" "$@"
''')
launcher.chmod(0o755)
icon=engine/'Contents/Resources/Godot.icns'
if icon.exists():shutil.copy2(icon,resources/'Game.icns')
with (contents/'Info.plist').open('wb') as f:
    plistlib.dump({'CFBundleName':'Mercenary Command','CFBundleDisplayName':'Mercenary Command','CFBundleExecutable':'MercenaryCommand','CFBundleIdentifier':'local.mercenary.command','CFBundlePackageType':'APPL','CFBundleShortVersionString':version,'CFBundleVersion':version,'CFBundleIconFile':'Game.icns','LSMinimumSystemVersion':'10.15','NSHighResolutionCapable':True,'LSApplicationCategoryType':'public.app-category.games'},f)
(resources/'LEEME.txt').write_text('Aplicación local autocontenida: incluye Godot 4.4.1 y una copia independiente del juego. No requiere el proyecto ni el motor de /tmp. Use Cargar para recuperar su campaña existente. El guardado conserva la ubicación habitual de Godot. No está notarizada para distribución pública.\n')
print(app)
