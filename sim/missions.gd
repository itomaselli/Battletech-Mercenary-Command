extends RefCounted
const U = preload("res://sim/universe.gd")
const Lore = preload("res://sim/lore.gd")
const KINDS = ["recon", "extraction", "defense", "interdiction", "recovery"]
const TITLES = ["Reconocimiento de zona", "Rescate y extracción", "Defensa de instalación", "Interdicción de convoy", "Recuperación de material"]
const GOALS = ["Relevar sectores y regresar con información", "Abrir acceso y evacuar grupos", "Conservar la integridad de la instalación", "Localizar el convoy y detener transportes", "Asegurar el lugar y transportar material"]
const CHOICES = [["Reconocer con discreción", "Ampliar barrido"], ["Asegurar corredor", "Evacuación rápida"], ["Defensa concentrada", "Defensa adelantada"], ["Capturar transportes", "Destruir transportes"], ["Salvamento protegido", "Carga apresurada"]]
static func create(seed_value: int) -> Dictionary:
 return {"seed": seed_value, "sequence": 0, "offers": [], "archive": [], "regions": {}, "tactic": "careful"}
static func region(data: Dictionary, id: String) -> Dictionary:
 if not data.regions.has(id): data.regions[id] = {"pressure": 3, "supply": 0, "intel": 0, "last_day": 0}
 return data.regions[id]
static func employers(year: int, code: String) -> Array:
 var result = []
 for actor in Lore.available(year):
  if not actor.employer: continue
  if code in actor.get("codes",[actor.code]) or actor.id == "lore-comstar": result.append(actor)
 return result
static func generate(state: Dictionary):
 var data = state.missions
 data.sequence += 1
 var dice = RandomNumberGenerator.new()
 dice.seed = int(data.seed) + int(data.sequence)*104729 + state.location_id.hash()
 var place = U.system(state.location_id)
 var local = region(data,state.location_id)
 var pool = employers(state.scenario_year,place.affiliations[str(state.scenario_year)])
 data.offers = []
 if pool.is_empty() or place.affiliations[str(state.scenario_year)] in ["U","A","X",""]: return
 for i in range(5):
  var employer = pool[(i+data.sequence)%pool.size()]
  var kind = (i+data.sequence-1)%5
  var terrain = ["llanura", "colinas", "urbano"][dice.randi_range(0,2)]
  var need = int(local.pressure)
  var source = "Solicitud local: cobertura y logística pendientes"
  if local.supply < 0: source = "Solicitud local tras pérdidas de abastecimiento"
  elif local.intel > 0: source = "Seguimiento de reconocimientos anteriores"
  elif need >= 5: source = "Solicitud local ante presión de seguridad elevada"
  var pay = 65000 + need*4000 + kind*4000 + int(state.relationships.get(employer.name,0))*3000 + (2000 if state.lore_contacts.has(employer.id) else 0)
  data.offers.append({"id":200000000+data.sequence*10+i,"name":TITLES[kind]+" · "+place.name,"mission_type":KINDS[kind],"system_id":place.id,"employer":employer.name,"employer_id":employer.id,"difficulty":6+need,"days":5,"pay":pay,"advance":int(pay/4),"failure_pay":int(pay*0.15),"partial_pay":int(pay*0.6),"expires":int(state.day)+14,"deadline":int(state.day)+5,"min_force":2,"intel":"Presencia hostil posible; composición sin confirmar.","reliability":"estimativa","terrain":terrain,"cause":source,"objective":GOALS[kind],"briefing":"Completo: 75% o más; parcial: 35–74%. Cinco jornadas efectivas; las maniobras pueden prolongar la exposición."})
static func begin(contract: Dictionary, profiles: Array, tactic: String) -> Dictionary:
 return {"kind":contract.mission_type,"progress":0,"access":0,"integrity":100,"elapsed":0,"profiles":profiles.duplicate(true),"tactic":tactic}
static func ability(objective: Dictionary, a: String, b: String) -> int:
 var total = 0
 for unit in objective.profiles: total += int((unit[a]+unit[b])*unit.condition/100.0)
 return int(total/8.0) # Four elements at full strength: average of their two aptitudes.
static func tick(objective: Dictionary, contract: Dictionary, seed_value: int, preserve: bool):
 objective.elapsed += 1
 var dice = RandomNumberGenerator.new()
 dice.seed = seed_value + int(contract.id)*31 + int(objective.elapsed)*7919
 var friction = dice.randi_range(0,5) + maxi(0,int(contract.difficulty)-9)
 var push = objective.tactic == "push" and not preserve
 var pace = 6 if push else 0
 var terrain = 2 if contract.terrain == "colinas" else 0
 match objective.kind:
  "recon":
   objective.progress += maxi(0,8+ability(objective,"recon","mobility")*3 + pace-friction-terrain)
  "extraction":
   objective.access = mini(100,objective.access+ability(objective,"mobility","protection")*5+pace-friction)
   if objective.access >= 40: objective.progress += maxi(0,9+ability(objective,"cargo","mobility")*4+pace-friction)
  "defense":
   objective.integrity -= maxi(1,19+friction+pace-ability(objective,"protection","support")*3)
   objective.integrity = maxi(0,objective.integrity)
   objective.progress = objective.integrity
  "interdiction":
   objective.access = mini(100,objective.access+ability(objective,"recon","mobility")*5-friction-terrain)
   if objective.access >= 40: objective.progress += maxi(0,8+ability(objective,"firepower","mobility")*4+pace*2-friction)
  "recovery":
   objective.access = mini(100,objective.access+ability(objective,"firepower","protection")*5-friction)
   if objective.access >= 40: objective.progress += maxi(0,14+ability(objective,"cargo","support")*5+pace-friction)
 objective.progress = clampi(int(objective.progress),0,100)
static func outcome(objective: Dictionary) -> String:
 if objective.elapsed == 0: return "failure"
 return "success" if objective.progress >= 75 else "partial" if objective.progress >= 35 else "failure"
static func report(objective: Dictionary) -> String:
 var metric = {"recon":"sectores relevados", "extraction":"grupos evacuados", "defense":"integridad de instalación", "interdiction":"transportes detenidos", "recovery":"material recuperado"}[objective.kind]
 return "%s: %d%% · jornada %d. %s" % [metric,objective.progress,objective.elapsed,"Acceso asegurado %d%%." % objective.access if objective.kind in ["extraction","interdiction","recovery"] else ""]
static func finish(state: Dictionary, contract: Dictionary, objective: Dictionary, result: String):
 var data = state.missions
 var local = region(data,contract.system_id)
 local.pressure = clampi(int(local.pressure)+(1 if result == "failure" else -1),0,8)
 if result != "failure":
  if objective.kind == "recon": local.intel = mini(10,int(local.intel)+ (2 if result == "success" else 1))
  if objective.kind in ["recovery","interdiction"]:
   var recovered = 0 if objective.kind == "interdiction" and objective.tactic == "push" else int(objective.progress/10)
   state.supplies += recovered
   local.supply = mini(5,int(local.supply)+1)
 else: local.supply = maxi(-5,int(local.supply)-1)
 data.archive.append({"id":contract.id,"day":int(state.day),"system_id":contract.system_id,"kind":objective.kind,"result":result,"progress":objective.progress,"tactic":objective.tactic})
 if data.archive.size()>100: data.archive.pop_front()
static func integer(value: Variant, low: int, high: int) -> bool:
 return preload("res://sim/operations.gd").integer(value,low,high)
static func valid_contract(c: Variant) -> bool:
 if not c is Dictionary or not c.get("mission_type") in KINDS: return false
 if U.system(str(c.get("system_id",""))).is_empty(): return false
 if not c.get("terrain") in ["llanura","colinas","urbano"]: return false
 for key in ["cause","objective","briefing"]:
  if not c.get(key) is String: return false
 return integer(c.get("partial_pay"),0,1000000000) and integer(c.get("min_force"),1,4) and integer(c.get("days"),1,20)
static func valid(data: Variant, active: Dictionary) -> bool:
 if not data is Dictionary or not data.get("offers") is Array or not data.get("archive") is Array or not data.get("regions") is Dictionary: return false
 if not data.get("tactic") in ["careful","push"]: return false
 for key in ["seed","sequence"]:
  if not integer(data.get(key),0,9000000000000000000): return false
 var ids = []
 for c in data.offers:
  if not valid_contract(c) or not integer(c.get("id"),200000000,1000000000) or c.id in ids: return false
  ids.append(c.id)
 for entry in data.archive:
  if not entry is Dictionary or not entry.get("kind") in KINDS or not entry.get("result") in ["success","partial","failure"]: return false
  if not integer(entry.get("progress"),0,100) or not integer(entry.get("day"),0,1000000000): return false
  if U.system(str(entry.get("system_id",""))).is_empty(): return false
 for id in data.regions:
  if U.system(id).is_empty(): return false
  var r = data.regions[id]
  if not r is Dictionary: return false
  if not integer(r.get("pressure"),0,8) or not integer(r.get("supply"),-5,5) or not integer(r.get("intel"),0,10) or not integer(r.get("last_day"),0,1000000000): return false
 if active.has("objective"):
  var o = active.objective
  if not o is Dictionary or not o.get("kind") in KINDS or not o.get("profiles") is Array or not o.get("tactic") in ["careful","push"]: return false
  if o.kind != active.contract.get("mission_type") or o.profiles.size() != active.team.size(): return false
  for k in ["progress","access","integrity","elapsed"]:
   if not (o.get(k) is int or o.get(k) is float) or o[k] < 0 or o[k]>100: return false
  for p in o.profiles:
   if not p is Dictionary: return false
   for k in ["recon","mobility","protection","support","firepower","cargo","condition"]:
    if not (p.get(k) is int or p.get(k) is float) or p[k]<0 or p[k]>100: return false
 return true
