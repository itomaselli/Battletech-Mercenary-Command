extends RefCounted
const KINDS={"person":"Desarrollar a una persona","community":"Sostener una comunidad","network":"Construir una red de apoyo"}
static func create() -> Dictionary:
 return {"goals":[],"jobs":[],"next":1,"sequence":0,"cooldowns":{}}
static func current(sim) -> Dictionary:
 for g in sim.state.story.objectives.goals:
  if g.status=="open":return g
 return {}
static func command(sim,args: Dictionary) -> String:
 var o=sim.state.story.objectives
 var action=str(args.get("action",""))
 if not sim.state.rpg.captain.configured or sim.state.rpg.arcs.retired:return "Complete el trasfondo y mantenga la campaña activa."
 var g=current(sim)
 if action=="choose":
  var kind=str(args.get("kind",""))
  var subject=int(args.get("person",-1))
  var contact=str(args.get("contact",""))
  if not g.is_empty() or not kind in KINDS or sim.in_transit():return "Elija un objetivo válido cuando esté en un sistema y sin otro objetivo abierto."
  if kind=="person" and sim.person_by_id(subject).is_empty():return "Seleccione una persona actual."
  if kind=="network" and not contact in sim.RPG.Agenda.known(sim):return "Seleccione un contacto conocido."
  var key="%s:%s:%d:%s"%[kind,sim.state.location_id,subject if kind=="person" else -1,contact if kind=="network" else ""]
  if int(o.cooldowns.get(key,0))>sim.state.day:return "Ya trabajó este objetivo recientemente; espere 28 días."
  var id=int(o.next);o.next+=1
  var event=sim.log_event("Iniciativa del capitán",KINDS[kind]+" en "+sim.Universe.system(sim.state.location_id).name,[subject] if kind=="person" else [],[],"goal:%d"%id)
  o.goals.append({"id":id,"kind":kind,"person":subject if kind=="person" else -1,"contact":contact if kind=="network" else "","system":sim.state.location_id,"started":int(sim.state.day),"status":"open","progress":0,"event":event,"next_action":int(sim.state.day),"key":key,"operations":[]})
  o.cooldowns[key]=int(sim.state.day)+28
  return "Objetivo elegido: alcance 3 avances por las vías disponibles. Sin plazo obligatorio."
 if g.is_empty():return "Elija primero un objetivo."
 if action=="abandon":
  g.status="abandoned"
  o.cooldowns[g.key]=int(sim.state.day)+28
  for j in o.jobs.duplicate():
   if j.goal==g.id:o.jobs.erase(j)
  sim.log_event("Objetivo abandonado","Se canceló la iniciativa. Los recursos ya consumidos no se recuperan; el descanso ya concedido se respeta.",[g.person] if g.person>=0 else [],[],"goal:%d"%g.id)
  return "Objetivo archivado. Puede elegir otro."
 if not action in ["material","captain","delegate"]:return "Vía desconocida."
 if sim.in_transit() or sim.state.location_id!=g.system or sim.RPG.waiting(sim) or sim.state.day<g.next_action or not o.jobs.is_empty():return "Espere disponibilidad, termine el encargo o vuelva al sistema del objetivo."
 if g.kind=="community" and action=="material":
  if sim.state.supplies<10:return "Se requieren 10 suministros."
  sim.state.supplies-=10;g.next_action=int(sim.state.day)+7
  progress(sim,g,1,"Entrega de 10 suministros a la comunidad")
  return "Entrega registrada; otra intervención material en 7 días."
 var external=g.kind=="person" and action=="material"
 var person=int(args.get("officer",-1)) if action=="delegate" else -2 if external else -1
 if action=="delegate":
  var officer=sim.person_by_id(person)
  if officer.is_empty() or not sim.person_available(officer) or sim.personnel_deployed(person) or person==g.person:return "Seleccione un oficial disponible distinto de la persona a desarrollar."
 elif not external and (sim.RPG.busy(sim) or not sim.state.active.is_empty()):return "El capitán está ocupado."
 if g.kind=="person":
  var subject=sim.person_by_id(g.person)
  if subject.is_empty() or not sim.person_available(subject) or sim.personnel_deployed(g.person):return "La persona a desarrollar debe estar disponible en base."
 var cost=5000 if external else 3000 if g.kind=="person" else 5000 if action=="material" else 2000
 if not sim.RPG.spend(sim,cost,"Iniciativa: "+KINDS[g.kind]):return "Fondos libres insuficientes."
 var days=2 if g.kind=="person" or action!="material" else 1
 o.sequence+=1
 o.jobs.append({"id":int(o.sequence),"goal":int(g.id),"person":person,"subject":int(g.person),"approach":action,"due":int(sim.state.day)+days})
 if person>=0:sim.person_by_id(person).rest_until=int(sim.state.day)+days
 if g.person>=0:sim.person_by_id(g.person).rest_until=int(sim.state.day)+days
 g.next_action=int(sim.state.day)+days
 sim.log_event("Preparación de iniciativa","%s: %d C-bills, %d días; responsable %s."%[KINDS[g.kind],cost,days,sim.person_name(person) if person>=0 else "formador contratado" if external else sim.state.captain_name],[g.person] if g.person>=0 else [],[],"goal:%d"%g.id)
 return "Trabajo iniciado; avance el calendario."
static func progress(sim,g: Dictionary,amount: int,reason: String):
 if g.status!="open":return
 g.progress=mini(3,int(g.progress)+amount)
 sim.log_event("Avance de objetivo","%s · %d/3. %s"%[KINDS[g.kind],g.progress,reason],[g.person] if g.person>=0 else [],[],"goal:%d"%g.id)
 if g.progress<3:return
 g.status="completed"
 sim.state.story.objectives.cooldowns[g.key]=int(sim.state.day)+28
 match g.kind:
  "person":sim.Story.People.remember(sim,g.person,"El capitán completó el programa de desarrollo que había elegido para mí.",1,1,[sim.state.story.threads["goal:%d"%g.id]])
  "community":
   var region=sim.Missions.region(sim.state.missions,g.system)
   region.pressure=maxi(0,int(region.pressure)-2)
   region.supply=mini(5,int(region.supply)+1)
   sim.RPG.Conflicts.affect(sim,g.system,-2,"Apoyo sostenido de la compañía")
  "network":
   var contacts=sim.state.rpg.agenda.contacts
   if not contacts.has(g.contact):contacts[g.contact]={"favors":0,"last":int(sim.state.day),"system":g.system}
   contacts[g.contact].favors=mini(3,int(contacts[g.contact].favors)+1)
   contacts[g.contact].last=int(sim.state.day);contacts[g.contact].system=g.system
   sim._change_relation(g.contact,1)
 sim.Story.Society.support(sim,g)
 sim.log_event("Objetivo cumplido",KINDS[g.kind]+": compromiso cumplido y consecuencias aplicadas.",[g.person] if g.person>=0 else [],[],"goal:%d"%g.id)
static func tick(sim):
 var o=sim.state.story.objectives
 for j in o.jobs.duplicate():
  if j.due>sim.state.day:continue
  o.jobs.erase(j)
  var found=o.goals.filter(func(g):return g.id==j.goal and g.status=="open")
  if found.is_empty():continue
  var g=found[0]
  var unavailable=false
  for id in [j.person,j.subject]:
   if id>=0 and (sim.person_by_id(id).is_empty() or sim.person_by_id(id).injury>0):unavailable=true
  if unavailable:
   progress(sim,g,0,"El personal faltó o resultó herido; no se devuelve el gasto. Puede elegir otra vía o abandonar.")
   continue
  var amount=1
  if g.kind=="person":
   sim._gain_experience(sim.person_by_id(g.person),1,"Desarrollo elegido por el capitán")
   if j.person>=0:
    var key=sim._bond_key(j.person,g.person)
    if not sim.state.bonds.has(key):sim.state.bonds[key]={"a":mini(j.person,g.person),"b":maxi(j.person,g.person),"score":0,"shared":0,"last_conflict":-100}
    sim.state.bonds[key].score=mini(5,int(sim.state.bonds[key].score)+1)
    var event=sim.log_event("Mentoría","%s y %s fortalecen su relación mediante la formación compartida (vínculo +1)."%[sim.person_name(j.person),sim.person_name(g.person)],[j.person,g.person],[],"goal:%d"%g.id)
    sim.Story.People.remember(sim,g.person,"Recuerda la ayuda de "+sim.person_name(j.person)+" durante su formación.",0,0,[event])
   var profile=sim.state.story.people.profiles[str(g.person)]
   if profile.goal=="mastery" and profile.status=="active":
    profile.progress+=1
    if profile.progress>=2:sim.Story.People.complete(sim,g.person,"Completó su aspiración de formación dentro del programa del capitán.")
  elif j.approach!="material":
   var dice=RandomNumberGenerator.new();dice.seed=int(sim.state.military.seed)+j.id*104729
   var ability=int(sim.person_by_id(j.person).skill) if j.person>=0 else int(sim.state.rpg.captain.skills.trato)
   var roll=dice.randi_range(1,6)+dice.randi_range(1,6)
   amount=2 if roll+ability>=9 else 1 if roll+ability>=7 else 0
   progress(sim,g,amount,"Informe de %s: 2d6 %d + competencia %d, objetivo 9 (7–8 parcial). La vía material sigue disponible."%[sim.person_name(j.person) if j.person>=0 else sim.state.captain_name,roll,ability])
   continue
  progress(sim,g,amount,"Trabajo material o formación completado sin tirada.")
static func operation(sim,result: String):
 var g=current(sim)
 if g.is_empty() or g.kind!="community" or sim.state.active.contract.get("system_id",sim.state.location_id)!=g.system:return
 var kind=sim.state.active.contract.get("mission_type","")
 if not kind in ["defense","extraction","recon"]:return
 var key=sim.Story.operation_key(sim)
 if key in g.operations:return
 g.operations.append(key)
 progress(sim,g,2 if result=="success" else 1 if result=="partial" else 0,"Operación local de protección: "+sim.state.active.contract.name)
static func busy(sim,id: int) -> bool:
 return sim.state.get("story",{}).get("objectives",{}).get("jobs",[]).any(func(j):return j.person==id or (id>=0 and j.subject==id))
static func valid(o: Variant,day: int) -> bool:
 if not o is Dictionary or not o.get("goals") is Array or not o.get("jobs") is Array or not o.get("cooldowns") is Dictionary or not num(o.get("next"),1,1000000000) or not num(o.get("sequence"),0,1000000000):return false
 var ids=[]
 var open_ids=[]
 for g in o.goals:
  if not g is Dictionary or not num(g.get("id"),1,o.next-1) or g.id in ids or not g.get("kind") in KINDS or not g.get("status") in ["open","completed","abandoned"] or not num(g.get("progress"),0,3) or not num(g.get("person"),-1,1000000) or not g.get("operations") is Array:return false
  ids.append(g.id)
  if g.status=="open":open_ids.append(g.id)
  for key in ["system","contact","key"]:
   if not g.get(key) is String:return false
  for key in ["event","next_action","started"]:
   if not num(g.get(key),0,1000000000):return false
 for value in o.cooldowns.values():
  if not num(value,0,1000000000):return false
 for j in o.jobs:
  if not j is Dictionary or not j.get("goal") in open_ids or not num(j.get("id"),1,o.sequence) or not num(j.get("person"),-2,1000000) or not num(j.get("subject"),-1,1000000) or not j.get("approach") in ["material","captain","delegate"] or not num(j.get("due"),day+1,day+2):return false
 return open_ids.size()<=1 and o.jobs.size()<=1 and o.next==o.goals.size()+1
static func num(v: Variant,low: int,high: int) -> bool:
 return preload("res://sim/operations.gd").integer(v,low,high)
