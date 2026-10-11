"""Run isolated test scripts; treat engine script errors as failure even with exit 0."""
from pathlib import Path
import subprocess,sys,json,time
root=Path(__file__).resolve().parents[1]
engine=sys.argv[1] if len(sys.argv)>1 else 'godot'
results=[]
for p in sorted((root/'tests').glob('*.gd')):
 if '_ui' in p.stem or p.stem == 'ui_smoke': continue
 start=time.monotonic()
 try:
  run=subprocess.run([engine,'--headless','--path',str(root),'--script','tests/'+p.name],capture_output=True,text=True,timeout=35)
  output=run.stdout+run.stderr
  ok=run.returncode==0 and 'ERROR:' not in output and 'FAIL:' not in output
 except subprocess.TimeoutExpired as exc:
  ok=False;output='TIMEOUT '+str(exc.stdout)
 results.append({'test':p.name,'passed':ok,'seconds':round(time.monotonic()-start,2),'output':output})
 print(p.name,'PASS' if ok else 'FAIL',flush=True)
 if not ok: print(output[-4000:],flush=True)
(root/'docs/test-results.json').write_text(json.dumps(results,ensure_ascii=False,indent=2))
sys.exit(0 if all(r['passed'] for r in results) else 1)
