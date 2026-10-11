extends RefCounted
## Independent streams; generated results are persisted, never regenerated on load.
const Catalog=preload("res://sim/catalog.gd")
const FIRST=["Elena","Tomás","Mara","Idris","Ada","Jules","Sana","Erik","Nadia","Hugo","Lian","Amira","Teo","Inés","Kai","Vera"]
const LAST=["Voss","Ríos","Chen","Vale","Ferrer","Aran","Kovac","Marin","Sato","Orlov","Reyes","Quinn","Solano","Becker","Aziz","Novak"]
const CALLS=["Faro","Cuervo","Bruma","Cobre","Eco","Lince","Nómada","Cometa","Tango","Delta","Sombra","Rayo"]
const BACKGROUNDS=["Servicio en una milicia planetaria","Experiencia con convoyes civiles","Formación en una academia local","Veterano de seguridad industrial","Aprendizaje en una compañía mercenaria","Servicio de protección fronteriza"]
static func generate(seed_value: int,year: int,unit_roll: int=0,people_roll: int=0) -> Dictionary:
 var rng=RandomNumberGenerator.new();rng.seed=seed_value+104729+unit_roll*65537
 var pool=Catalog.eligible(year);var units=[]
 for i in range(4):units.append(Catalog.all()[pool[rng.randi_range(0,pool.size()-1)]].id)
 return assemble(seed_value,year,units,unit_roll,people_roll)
static func assemble(seed_value: int,year: int,units: Array,unit_roll: int=0,people_roll: int=0) -> Dictionary:
 var rng=RandomNumberGenerator.new();rng.seed=seed_value+32452843+people_roll*65537
 var people=[];var used=[]
 for i in range(6):
  var name=FIRST[rng.randi_range(0,FIRST.size()-1)]+" "+LAST[rng.randi_range(0,LAST.size()-1)]
  while name in used:name=FIRST[rng.randi_range(0,FIRST.size()-1)]+" "+LAST[rng.randi_range(0,LAST.size()-1)]
  used.append(name)
  var role="Jefa técnica" if i==4 else "Logística"
  if i<4:role="Dotación" if model(units[i]).kind=="vehicle" else "Piloto"
  var skill=rng.randi_range(3 if i==4 else 2,4)
  people.append({"name":name,"role":role,"skill":skill,"injury":0,"salary":3000+skill*1000+(1000 if i==4 else 0),"callsign":CALLS[rng.randi_range(0,CALLS.size()-1)],"background":BACKGROUNDS[rng.randi_range(0,BACKGROUNDS.size()-1)],"portrait_seed":seed_value+people_roll*65537,"portrait_id":i})
 return {"generator":1,"seed":seed_value,"scenario":year,"unit_roll":unit_roll,"people_roll":people_roll,"units":units.duplicate(),"people":people}
static func model(id: String) -> Dictionary:
 for m in Catalog.all():
  if m.id==id:return m
 return {}
static func valid(value: Variant,year: int) -> bool:
 if not value is Dictionary:return false
 if value.is_empty():return true # Migrated careers have no fabricated origin.
 if value.get("generator")!=1 or value.get("scenario")!=year:return false
 for k in ["seed","unit_roll","people_roll"]:
  if not (value.get(k) is int or value.get(k) is float) or not is_finite(value[k]) or value[k]!=floor(value[k]) or abs(value[k])>2147483647:return false
 if not value.get("units") is Array or value.units.size()!=4 or not value.get("people") is Array or value.people.size()!=6:return false
 for id in value.units:
  if not id is String or model(id).is_empty() or model(id).year>year:return false
 for i in range(6):
  var p=value.people[i]
  if not p is Dictionary or not p.get("name") is String or p.name.is_empty():return false
  var role="Jefa técnica" if i==4 else "Logística"
  if i<4:role="Dotación" if model(value.units[i]).kind=="vehicle" else "Piloto"
  if p.get("role")!=role:return false
  for k in ["skill","salary","injury","portrait_seed","portrait_id"]:
   if not (p.get(k) is int or p.get(k) is float) or not is_finite(p[k]):return false
  if p.skill<2 or p.skill>4 or (i==4 and p.skill<3) or p.injury!=0 or p.salary!=3000+p.skill*1000+(1000 if i==4 else 0):return false
  if not p.get("callsign") is String or not p.get("background") is String:return false
 return true
