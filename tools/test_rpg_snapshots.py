"""Produce real historical RPG saves from each release's own source."""
from pathlib import Path
import zipfile,subprocess,sys,json
root=Path(__file__).resolve().parents[1]
engine=sys.argv[1]
results=[]
for revision in range(16,25):
 release=f'v0.{revision}'
 dest=Path('/tmp/bmc-rpg-migrations')/release
 dest.mkdir(parents=True,exist_ok=True)
 with zipfile.ZipFile(root/'releases'/f'{release}-source.zip') as z:
  for name in z.namelist():
   if not name.startswith(('exports/','releases/')):z.extract(name,dest)
 script='''extends SceneTree
const C=preload("res://sim/campaign.gd")
func _initialize():
 var s=C.new(826,3060)
 s.set_identity("Continuidad RPG","Capitana Histórica")
 s.rpg_command("configure",{"origin":"oficial","specialty":"trato","motivation":"proteccion","bond":0})
 s.rpg_command("start_cargo")
 assert(s.state.rpg.scene=="briefing")
 assert(s.save_game("user://actual-rpg-REVISION.json")==OK)
 print("Saved RPG ",s.state.rpg.revision)
 quit()
'''.replace('REVISION',str(revision))
 (dest/'rpg_fixture.gd').write_text(script)
 r=subprocess.run([engine,'--headless','--path',str(dest),'--script','rpg_fixture.gd'],capture_output=True,text=True,timeout=30)
 output=r.stdout+r.stderr
 ok=r.returncode==0 and 'ERROR:' not in output
 print(release,'PASS' if ok else output,flush=True)
 results.append({'release':release,'passed':ok,'output':output})
 if not ok:raise SystemExit(1)
(root/'docs/rpg-migration-fixtures.json').write_text(json.dumps(results,ensure_ascii=False,indent=2))
