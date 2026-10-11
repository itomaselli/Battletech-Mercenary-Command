"""Export Windows x64 with official Godot 4.4.1 templates, without local saves/tests."""
from pathlib import Path
import argparse, hashlib, json, re, shutil, struct, subprocess, tempfile, zipfile

ROOT = Path(__file__).resolve().parents[1]
parser = argparse.ArgumentParser()
parser.add_argument("--godot", default="godot")
parser.add_argument("--template", type=Path)
parser.add_argument("--output", type=Path, default=ROOT / "exports")
args = parser.parse_args()
version = re.search(r'config/version="([^"]+)"', (ROOT / "project.godot").read_text())[1]
engine_version = subprocess.check_output([args.godot, "--version"], text=True).strip()
if not engine_version.startswith("4.4.1.stable"):
    raise SystemExit(f"Expected Godot 4.4.1 stable, found {engine_version}")
target = args.output.resolve() / f"Mercenary-Command-{version}-Windows-x64"
archive = target.parent / (target.name + ".zip")
if target.exists() or archive.exists():
    raise SystemExit(f"Output exists; preserve it or choose another --output: {target}")
target.mkdir(parents=True)
with tempfile.TemporaryDirectory(prefix="mercenary-windows-") as tmp:
    stage = Path(tmp)
    for folder in ["sim", "ui", "visual", "assets", "data"]:
        shutil.copytree(ROOT / folder, stage / folder, ignore=shutil.ignore_patterns("*.import", "__pycache__"))
    shutil.copy2(ROOT / "project.godot", stage / "project.godot")
    presets = (ROOT / "export_presets.cfg").read_text()
    if args.template:
        template = args.template.resolve()
        if not template.is_file():
            raise SystemExit(f"Missing template: {template}")
        escaped = str(template).replace("\\", "/").replace('"', '\\"')
        presets = presets.replace('custom_template/release=""', f'custom_template/release="{escaped}"')
    (stage / "export_presets.cfg").write_text(presets)
    logs = []
    for command in [
        [args.godot, "--headless", "--path", str(stage), "--editor", "--import"],
        [args.godot, "--headless", "--path", str(stage), "--export-release",
         "Windows Desktop", str(target / "MercenaryCommand.exe")],
    ]:
        run = subprocess.run(command, capture_output=True, text=True, timeout=180)
        logs.append(run.stdout + run.stderr)
        if run.returncode or "ERROR:" in logs[-1]:
            (target / "build.log").write_text("\n".join(logs))
            raise SystemExit(logs[-1])
    (target / "build.log").write_text("\n".join(logs))
exe = target / "MercenaryCommand.exe"
data = exe.read_bytes()
offset = struct.unpack_from("<I", data, 0x3C)[0]
if data[:2] != b"MZ" or data[offset:offset+4] != b"PE\0\0" or struct.unpack_from("<H", data, offset+4)[0] != 0x8664:
    raise SystemExit("The exported executable is not Windows x86-64 PE")
pack = target / "MercenaryCommand.pck"
if not pack.is_file() or pack.stat().st_size < 10000:
    raise SystemExit("Missing game data pack")
(target / "LEEME.txt").write_text(
    f"Mercenary Command {version} — Windows x64\n\n"
    "1. Extraé TODO el ZIP en una carpeta.\n"
    "2. Abrí MercenaryCommand.exe. Conservá MercenaryCommand.pck junto al EXE.\n"
    "No requiere instalar Godot, Python ni una conexión a Internet.\n\n"
    "Guardados: %APPDATA%\\Godot\\app_userdata\\BattleTech • Mercenary Command\\careers\\\n"
    "Guardá desde el juego antes de cerrarlo. Para trasladar una carrera desde Mac, "
    "copiá su archivo JSON a la carpeta careers de Windows con el juego cerrado; conservá una copia.\n\n"
    "Versión portátil x64 con renderizador Compatibility. No incluye instalador ni firma digital.\n"
    "Proyecto personal no oficial. Fuentes y atribuciones en ATRIBUCIONES.md.\n", encoding="utf-8")
shutil.copy2(ROOT / "data/README.md", target / "ATRIBUCIONES.md")
for license_name in ["LICENSE", "GODOT-LICENSE.txt"]:
    if (ROOT / license_name).exists():
        shutil.copy2(ROOT / license_name, target / license_name)
hashes = {p.name: hashlib.sha256(p.read_bytes()).hexdigest() for p in [exe, pack]}
(target / "SHA256SUMS.txt").write_text("".join(f"{digest}  {name}\n" for name, digest in hashes.items()))
with zipfile.ZipFile(archive, "w", zipfile.ZIP_DEFLATED) as z:
    for p in sorted(target.iterdir()):
        if p.is_file() and p.name != "build.log":
            z.write(p, f"{target.name}/{p.name}")
audit = {"version": version, "engine": engine_version, "platform": "Windows x86_64",
         "executable_format": "PE32+ AMD64", "embedded_pck": False, "sha256": hashes,
         "zip_sha256": hashlib.sha256(archive.read_bytes()).hexdigest(),
         "native_windows_execution": "not_run_by_this_build_script"}
(ROOT / "docs/windows-build.json").write_text(json.dumps(audit, indent=2) + "\n")
print(archive)
