extends RefCounted
const PRACTICES={"care":"Cuidado del personal","sharing":"Reparto de beneficios","duty":"Cumplimiento profesional","risk":"Exposición voluntaria al riesgo"}
static func create() -> Dictionary:
 return {"practices":{"care":0,"sharing":0,"duty":0,"risk":0},"seen":{},"units":{},"next_bonus":0,"bonuses":0,"expectation":0,"reviewed":false}
static func ensure(sim):
 for m in sim.state.mechs:
  var key=str(m.uid)
  if not sim.state.story.culture.units.has(key):sim.state.story.culture.units[key]={"name":m.name,"since":int(sim.state.day),"service":0,"pilots":{},"sold":false,"events":[]}
static func practice(sim,kind: String,key: String):
 var c=sim.state.story.culture
 if c.seen.has(key):return
 c.seen[key]=true;c.practices[kind]=mini(100,int(c.practices[kind])+1)
static func care(sim,id: int):
 practice(sim,"care","leave:%d:%d"%[id,int(sim.state.day/28)])
static func operation(sim,outcome: String):
 ensure(sim)
 var key=sim.Story.operation_key(sim)
 if outcome=="success":practice(sim,"duty",key+":duty")
 if sim.state.active.doctrine==2:practice(sim,"risk",key+":risk")
 var cautious=sim.state.military.current.get("orders",{}).get("priority","")=="preserve"
 if cautious:practice(sim,"care",key+":care")
 var parent=sim.state.story.threads.get(key,0)
 for i in sim.state.active.team:
  var m=sim.state.mechs[i]
  var u=sim.state.story.culture.units[str(m.uid)]
  u.service+=1
  var pid=str(m.pilot_id)
  u.pilots[pid]=int(u.pilots.get(pid,0))+1
  var e=sim.log_event("Servicio de unidad","%s regresó de %s: %s; integridad %d%%. Operador: %s."%[m.name,sim.state.active.contract.name,outcome,m.hp,sim.person_name(m.pilot_id)],[m.pilot_id],[m.uid],"unit:%d"%m.uid,[parent] if parent>0 else [])
  u.events.append(e)
  var profile=sim.state.story.people.profiles.get(pid,{})
  if cautious and profile.get("value","")=="care":sim.Story.People.remember(sim,m.pilot_id,"Reconoce la orden de preservar a la fuerza.",1,0,[e])
  if sim.state.active.doctrine==2 and m.hp<40 and profile.get("value","")=="care":sim.Story.People.remember(sim,m.pilot_id,"Cuestiona la exposición agresiva que terminó con su máquina gravemente dañada.",-1,0,[e])
static func sale_warning(sim,uid: int) -> String:
 var u=sim.state.story.culture.units.get(str(uid),{})
 var names=[]
 for key in u.get("pilots",{}):
  if u.pilots[key]>=2 and not sim.person_by_id(int(key)).is_empty():names.append(sim.person_name(int(key)))
 return "" if names.is_empty() else " Vínculo de servicio: %s. Venderla reduce en 1 su confianza; la historia se conserva."%", ".join(names)
static func sale(sim,m: Dictionary):
 ensure(sim)
 var u=sim.state.story.culture.units[str(m.uid)]
 u.sold=true
 var event=sim.log_event("Despedida de unidad",m.name+" sale de la compañía; se conserva su historial.",[],[m.uid],"unit:%d"%m.uid)
 u.events.append(event)
 for key in u.pilots:
  if u.pilots[key]>=2 and not sim.person_by_id(int(key)).is_empty():sim.Story.People.remember(sim,int(key),"Lamenta la venta de "+m.name+", con la que compartió varias operaciones.",-1,0,[event])
static func command(sim,args: Dictionary) -> String:
 if args.get("action")!="bonus":return "Práctica desconocida."
 var c=sim.state.story.culture
 if sim.state.day<c.next_bonus:return "El próximo reparto está disponible el día %d."%c.next_bonus
 if sim.state.staff.is_empty() or sim.state.arrears>0:return "Regularice salarios antes de repartir beneficios."
 var cost=sim.state.staff.size()*1000
 if not sim.RPG.spend(sim,cost,"Bonificación equitativa al personal"):return "Fondos libres insuficientes."
 c.next_bonus=int(sim.state.day)+28;c.bonuses+=1
 if c.bonuses>=2:c.expectation=int(sim.state.day)+56;c.reviewed=false
 practice(sim,"sharing","bonus:%d"%sim.state.day)
 var event=sim.log_event("Reparto","Cada empleado recibe 1.000 C-bills; total %d. Tras dos repartos se espera revisar la práctica dentro de 56 días."%cost)
 for p in sim.state.staff:sim.Story.People.remember(sim,p.id,"Participó del reparto de beneficios: 1.000 C-bills.",1,0,[event])
 return "Bonificación pagada; próxima revisión en 28 días."
static func tick(sim):
 ensure(sim)
 var c=sim.state.story.culture
 if c.expectation>0 and sim.state.day>c.expectation and not c.reviewed:
  c.reviewed=true
  sim.log_event("Expectativas","El personal solicita revisar la continuidad del reparto habitual. Es una expectativa, no una deuda salarial; no se deduce dinero ni se impone una penalidad.")
static func valid(c: Variant,day: int) -> bool:
 if not c is Dictionary or not c.get("practices") is Dictionary or not c.get("seen") is Dictionary or not c.get("units") is Dictionary or not c.get("reviewed") is bool:return false
 for key in PRACTICES:
  if not num(c.practices.get(key),0,100):return false
 for key in ["next_bonus","bonuses","expectation"]:
  if not num(c.get(key),0,1000000000):return false
 for key in c.units:
  if not key is String or not key.is_valid_int():return false
  var u=c.units[key]
  if not u is Dictionary or not u.get("name") is String or not u.get("sold") is bool or not u.get("pilots") is Dictionary or not u.get("events") is Array or not num(u.get("since"),0,day) or not num(u.get("service"),0,1000000000):return false
  for pid in u.pilots:
   if not pid is String or not pid.is_valid_int() or not num(u.pilots[pid],1,1000000000):return false
  for event in u.events:
   if not num(event,1,1000000000):return false
 return true
static func num(v: Variant,low: int,high: int) -> bool:
 return preload("res://sim/operations.gd").integer(v,low,high)
