extends RefCounted
const GOALS={"rest":"Recuperar un ritmo de trabajo sostenible","mastery":"Completar dos sesiones de formación","security":"Resolver una obligación familiar de 4.000 C-bills","recognition":"Alcanzar el próximo ascenso"}
const VALUES={"care":"Cuidar a la gente","craft":"Conservar y dominar el equipo","duty":"Cumplir compromisos"}
static func create() -> Dictionary:
 return {"profiles":{},"requests":[],"next":1,"last":0,"jobs":[]}
static func ensure(sim):
 var data=sim.state.story.people
 for p in sim.state.staff:
  var key=str(p.id)
  if data.profiles.has(key):continue
  var dice=RandomNumberGenerator.new()
  dice.seed=int(sim.state.military.seed)+int(p.id)*7919
  var goal=GOALS.keys()[dice.randi_range(0,3)]
  if goal=="recognition" and (p.promotions>=2 or p.skill>=5):goal="mastery"
  var value=VALUES.keys()[dice.randi_range(0,2)]
  data.profiles[key]={"name":p.name,"goal":goal,"value":value,"since":int(sim.state.day),"next":int(sim.state.day)+7,"status":"active","progress":0,"baseline":int(p.promotions),"limit":{"care":"Pide descanso antes de que el agotamiento alcance niveles peligrosos.","craft":"Reclama tiempo protegido para aprender y mantener sus herramientas.","duty":"Espera criterios explícitos para reconocer experiencia y cumplir compromisos."}[value],"memories":[]}
  if not sim.state.rpg.social.ties.has(key):
   sim.state.rpg.social.ties[key]={"name":p.name,"value":{"care":"proteger","craft":"mantener","duty":"cumplir"}[value],"trust":0,"respect":0,"memories":[]}
static func remember(sim,id: int,text: String,trust: int=0,respect: int=0,parents: Array=[]):
 var profile=sim.state.story.people.profiles.get(str(id),{})
 if profile.is_empty():return
 var event=sim.log_event("Vida de compañía",profile.name+": "+text,[id],[],"person:%d"%id,parents)
 profile.memories.append(event)
 var tie=sim.state.rpg.social.ties.get(str(id),{})
 if not tie.is_empty():
  tie.trust=clampi(int(tie.trust)+trust,-5,5);tie.respect=clampi(int(tie.respect)+respect,-5,5)
  tie.memories.append({"day":int(sim.state.day),"text":text})
 var person=sim.person_by_id(id)
 if not person.is_empty():sim._remember(person,text)
static func pending(sim) -> Array:
 return sim.state.story.people.requests.filter(func(r):return r.status=="open")
static func eligible(sim,p: Dictionary,profile: Dictionary) -> bool:
 if profile.status!="active" or sim.state.day<profile.next or not sim.person_available(p) or sim.personnel_deployed(p.id):return false
 if profile.goal=="rest":return p.fatigue>=30
 if profile.goal=="recognition":return sim.promotion_eligible(p.id)
 return true
static func complete(sim,id: int,text: String):
 var profile=sim.state.story.people.profiles[str(id)]
 if profile.status=="fulfilled":return
 profile.status="fulfilled"
 remember(sim,id,text,1,1)
 for r in pending(sim):
  if r.person==id:r.status="fulfilled"
static func care(sim,id: int):
 ensure(sim)
 var profile=sim.state.story.people.profiles[str(id)]
 if profile.goal=="rest" and profile.status=="active":
  var jobs=sim.state.story.people.jobs
  if not jobs.any(func(j):return j.person==id):jobs.append({"person":id,"kind":"rest","due":int(sim.state.day)+3})
static func tick(sim):
 ensure(sim)
 var data=sim.state.story.people
 for job in data.jobs.duplicate():
  if job.due>sim.state.day:continue
  data.jobs.erase(job)
  var p=sim.person_by_id(job.person)
  if p.is_empty():continue
  var profile=data.profiles[str(p.id)]
  if job.kind=="training":
   var gained=1+sim.HQ.extra(sim,"simulator",str(p.id),1)
   sim._gain_experience(p,gained,"Formación acordada")
   profile.progress+=1
   remember(sim,p.id,"Completó una sesión de formación; experiencia +%d."%gained,0,1)
   if profile.progress>=2:complete(sim,p.id,"Cumplió su aspiración de formación.")
  else:complete(sim,p.id,"Terminó el permiso protegido que había solicitado.")
 for key in data.profiles:
  var profile=data.profiles[key]
  var p=sim.person_by_id(int(key))
  if p.is_empty():
   for r in pending(sim):
    if r.person==int(key):r.status="departed"
   continue
  if profile.goal=="recognition" and p.promotions>profile.baseline:complete(sim,p.id,"Su ascenso hizo realidad el reconocimiento que buscaba.")
 for r in pending(sim):
  if sim.state.day>r.expires:
   r.status="expired"
   remember(sim,r.person,"Su petición quedó archivada sin respuesta; podrá volver a plantearla. Sin penalización automática.")
 if not sim.Story.Society.available(sim):return
 if not sim.state.rpg.captain.configured or not pending(sim).is_empty() or sim.state.day-data.last<7 or sim.in_transit() or not sim.state.active.is_empty() or sim.RPG.busy(sim) or sim.RPG.waiting(sim) or not sim.state.issues.is_empty():return
 for p in sim.state.staff:
  var profile=data.profiles[str(p.id)]
  if not eligible(sim,p,profile):continue
  var event=sim.log_event("Petición personal",p.name+" pide apoyo: "+GOALS[profile.goal],[p.id],[],"person:%d"%p.id)
  data.requests.append({"id":int(data.next),"person":int(p.id),"goal":profile.goal,"day":int(sim.state.day),"expires":int(sim.state.day)+21,"status":"open","event":event})
  data.next+=1;data.last=int(sim.state.day);sim.state.story.society.pulse=int(sim.state.day);profile.next=int(sim.state.day)+28
  break
static func command(sim,args: Dictionary) -> String:
 var found=pending(sim).filter(func(r):return r.id==int(args.get("id",-1)))
 if found.is_empty():return "La petición ya no está disponible."
 var r=found[0]
 var p=sim.person_by_id(r.person)
 if p.is_empty():return "La persona ya no pertenece a la compañía."
 if sim.state.story.people.profiles[str(p.id)].status!="active":return "La aspiración ya está cumplida."
 var action=str(args.get("action",""))
 if action=="defer":
  r.status="deferred";sim.state.story.people.profiles[str(p.id)].next=int(sim.state.day)+7
  remember(sim,p.id,"El capitán pidió volver a tratar su petición en siete días.",0,0,[r.event])
  return "Petición aplazada; no bloquea el calendario."
 if action=="decline":
  r.status="declined";remember(sim,p.id,"El capitán rechazó su petición; confianza −1.",-1,0,[r.event])
  return "Respuesta registrada. Puede conservar el desacuerdo."
 if action!="support":return "Respuesta desconocida."
 if sim.in_transit() or sim.RPG.waiting(sim) or not sim.person_available(p) or sim.personnel_deployed(p.id):return "Espere a que la persona esté disponible en base."
 var profile=sim.state.story.people.profiles[str(p.id)]
 match r.goal:
  "rest":sim.grant_leave(p.id)
  "recognition":
   if not sim.promotion_eligible(p.id) or sim.available_funds()<3000:return "El ascenso requiere elegibilidad y 3.000 C-bills libres."
   sim.promote(p.id)
   complete(sim,p.id,"El capitán atendió su petición de ascenso.")
  "mastery":
   if not sim.RPG.spend(sim,3000,"Formación de "+p.name):return "Se requieren 3.000 C-bills libres."
   p.rest_until=int(sim.state.day)+2
   sim.state.story.people.jobs.append({"person":int(p.id),"kind":"training","due":int(sim.state.day)+2})
  "security":
   if not sim.RPG.spend(sim,4000,"Ayuda familiar a "+p.name):return "Se requieren 4.000 C-bills libres."
   complete(sim,p.id,"Saldó la obligación familiar con ayuda de la compañía.")
 r.status="supported"
 profile.next=int(sim.state.day)+28
 remember(sim,p.id,"Apoyo autorizado: "+GOALS[r.goal],1,0,[r.event])
 return "Apoyo registrado; consulte disponibilidad y expediente."
static func offer_text(r: Dictionary) -> String:
 return {"rest":"Permiso de 3 días; mantiene salario y queda fuera de servicio.","mastery":"3.000 C-bills, 2 días fuera de servicio, +1 experiencia. Dos sesiones completan la aspiración.","security":"Ayuda única de 4.000 C-bills; satisface su obligación familiar.","recognition":"Ascenso: 3.000 C-bills, salario +1.000/mes y habilidad +1; exige elegibilidad."}[r.goal]
static func valid(data: Variant,day: int) -> bool:
 if not data is Dictionary or not data.get("profiles") is Dictionary or not data.get("requests") is Array or not data.get("jobs") is Array:return false
 if not number(data.get("last"),0,day) or not number(data.get("next"),1,1000000000):return false
 for key in data.profiles:
  if not key is String or not key.is_valid_int():return false
  var p=data.profiles[key]
  if not p is Dictionary or not p.get("name") is String or not p.get("goal") in GOALS or not p.get("value") in VALUES or not p.get("status") in ["active","fulfilled"] or not p.get("limit") is String or not p.get("memories") is Array:return false
  for field in ["since","next","progress","baseline"]:
   if not number(p.get(field),0,1000000000):return false
  for id in p.memories:
   if not number(id,1,1000000000):return false
 var ids=[]
 var opened=0
 for r in data.requests:
  if not r is Dictionary or not number(r.get("id"),1,data.next-1) or r.id in ids or not number(r.get("person"),0,1000000) or not data.profiles.has(str(int(r.person))) or not r.get("goal") in GOALS or not r.get("status") in ["open","supported","fulfilled","deferred","declined","expired","departed"]:return false
  ids.append(r.id)
  for field in ["day","expires","event"]:
   if not number(r.get(field),0,1000000000):return false
  if r.status=="open":opened+=1
 var busy=[]
 for j in data.jobs:
  if not j is Dictionary or not number(j.get("person"),0,1000000) or j.person in busy or not data.profiles.has(str(int(j.person))) or not j.get("kind") in ["rest","training"] or not number(j.get("due"),day+1,day+3):return false
  busy.append(j.person)
 return opened<=1 and data.next==data.requests.size()+1
static func number(v: Variant,low: int,high: int) -> bool:
 return preload("res://sim/operations.gd").integer(v,low,high)
