from pathlib import Path
import zipfile,subprocess
import sys
root=Path(__file__).resolve().parents[1];engine=sys.argv[1] if len(sys.argv)>1 else 'godot'
for release in ['v0.11','v0.12','v0.13','v0.14']:
 dest=Path('/tmp/bmc-migrations')/release;dest.mkdir(parents=True,exist_ok=True)
 with zipfile.ZipFile(root/'releases'/f'{release}-source.zip') as z:z.extractall(dest)
 script='''extends SceneTree
const C = preload("res://sim/campaign.gd")
func _initialize():
 var sim = C.new(821,3060)
 sim.set_identity("Prueba migración","Capitán Histórico")
 sim.accept_contract(0)
 sim.dispatch(0,[0,1,2,3],1)
 sim.advance(1)
 assert(sim.save_game("user://actual-RELEASE.json") == OK)
 print("Saved schema ",sim.VERSION)
 quit()
'''.replace('RELEASE',release)
 (dest/'migration_fixture.gd').write_text(script)
 result=subprocess.run([engine,'--headless','--path',str(dest),'--script','migration_fixture.gd'],capture_output=True,text=True,timeout=30)
 print(release,result.stdout,result.stderr)
 if result.returncode or 'ERROR:' in result.stderr: raise RuntimeError('migration fixture failed')
