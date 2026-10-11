from pathlib import Path
import subprocess,sys,json
root=Path(__file__).resolve().parents[1];engine=sys.argv[1] if len(sys.argv)>1 else 'godot'
results=[]
for p in sorted((root/'tests').glob('*.gd')):
 if '_ui' not in p.stem and p.stem!='ui_smoke':continue
 try:
  result=subprocess.run([engine,'--headless','--path',str(root),'--script','tests/'+p.name],capture_output=True,text=True,timeout=30)
  output=result.stdout+result.stderr;ok=result.returncode==0 and 'ERROR:' not in output and 'FAIL' not in output
 except subprocess.TimeoutExpired as e:ok=False;output='TIMEOUT '+str(e.stdout)
 print(p.name,'PASS' if ok else 'FAIL',flush=True)
 if not ok:print(output[-3000:],flush=True)
 results.append({'test':p.name,'passed':ok,'output':output})
(root/'docs/ui-test-results.json').write_text(json.dumps(results,ensure_ascii=False,indent=2))
sys.exit(0 if all(r['passed'] for r in results) else 1)
