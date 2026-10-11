"""Import factual fields only from locally downloaded mm-data records; no prose/art."""
import json,re,sys,hashlib
from pathlib import Path
from urllib.parse import quote
root=Path(__file__).resolve().parents[1]
manifest=json.loads(Path(sys.argv[1]).read_text())
records=[]
def slug(s): return re.sub('[^a-z0-9]+','-',s.lower()).strip('-')
for source in manifest:
 p=Path(source['file']);text=p.read_text()
 if p.suffix=='.mtf':
  def field(k): return re.search('^'+re.escape(k)+':(.*)$',text,re.M).group(1).strip()
  chassis,variant=field('chassis'),field('model');name=chassis+' '+variant
  mass=int(field('mass'));year=int(field('era'));walk=int(field('walk mp'));jump=int(field('jump mp'))
  weapons=re.search(r'Weapons:\d+\n(.*?)(?:\n\n)',text,re.S).group(1).splitlines()
  role=field('role');kind='mech';motion='Biped';tech=field('techbase')
 else:
  def field(k):
   m=re.search('<'+re.escape(k)+r'>\s*(.*?)\s*</'+re.escape(k)+'>',text,re.S|re.I)
   return m.group(1).strip() if m else ''
  chassis=field('Name');variant=field('Model') or 'Standard';name=chassis+(' '+variant if variant!='Standard' else '')
  mass=int(float(field('tonnage')));year=int(field('year'));walk=int(field('cruiseMP'));jump=0
  weapons=[]
  for k,v in re.findall(r'<([^<>]* Equipment)>(.*?)</[^<>]+>',text,re.S):
   weapons.extend(x for x in v.strip().splitlines() if 'Ammo' not in x and 'ammo' not in x)
  role=field('role');kind='vehicle';motion=field('motion_type');tech=field('type')
 assert year<=3060
 idx=len(records);cls='ground' if kind=='vehicle' else ('light' if mass<=35 else 'medium' if mass<=55 else 'heavy')
 sprite=6 if kind=='vehicle' else {'light':0,'medium':2,'heavy':4}[cls]+(sum(chassis.encode())%2)
 # Abstract balance profiles, not official combat/BV values.
 profile={'mobility':min(10,walk+jump//2),'protection':min(10,max(2,mass//10)), 'firepower':min(10,3+len(weapons)//2), 'support':8 if role in ['Missile Boat','Sniper'] else 3,'recon':min(10,walk+ (2 if mass<=35 else 0)), 'cargo':5 if kind=='vehicle' else 2}
 records.append({'id':slug(name),'name':name,'chassis':chassis,'variant':variant,'kind':kind,'class':cls,'year':year,'mass':mass,'walk':walk,'jump':jump,'motion':motion,'tech':tech,'weapons':weapons,'role':role,'sprite':sprite,'crew':4 if kind=='vehicle' else 1,'profile':profile,'value':int(mass*(2200 if kind=='vehicle' else 3200)*(1.15 if year>3027 else 1)),'maintenance':int(mass*(0.7 if kind=='vehicle' else 1.5)),'source':source['url'],'sha256':hashlib.sha256(p.read_bytes()).hexdigest(),'sarna':'https://www.sarna.net/wiki/'+quote(chassis.replace(' ','_'))})
refs={'Scorpion Light Tank':'Scorpion_(Combat_Vehicle)','Vedette Medium Tank':'Vedette','Striker Light Tank':'Striker_(Combat_Vehicle)','Bulldog Medium Tank':'Bulldog','Manticore Heavy Tank':'Manticore','Demolisher Heavy Tank':'Demolisher','SRM Carrier':'SRM_Carrier','LRM Carrier':'LRM_Carrier'}
for unit in records:
 for name,ref in refs.items():
  if unit['chassis'].startswith(name): unit['sarna']='https://www.sarna.net/wiki/'+ref
first=['locust-lct-1v','shadow-hawk-shd-2h','centurion-cn9-a','vindicator-vnd-1r']
records.sort(key=lambda x:first.index(x['id']) if x['id'] in first else 4)
for r,value,upkeep in zip(records,[90000,180000,170000,140000],[60,90,85,70]):r.update(value=value,maintenance=upkeep)
(root/'data/units.json').write_text(json.dumps(records,ensure_ascii=False,indent=2)+'\n')
print(len(records),'variants;',len({r['chassis'] for r in records if r['kind']=='mech'}),'Mech chassis')
