extends RefCounted
const ACTIONS={"clue":"Investigar pista","audience":"Solicitar audiencia","visit":"Visitar contacto","proposal":"Proponer encargo"}
static func create() -> Dictionary:
 return {"jobs":[],"history":[],"contacts":{},"goals":[],"cooldowns":{},"next":1}
static func known(sim) -> Array:
 var names=sim.state.relationships.keys()
 for offer in sim.state.offers+sim.state.missions.offers:
  if not offer.employer in names: names.append(offer.employer)
 return names
static func command(sim,args: Dictionary) -> String:
 var a=sim.state.rpg.agenda
 var action=str(args.get("action",""))
 if not sim.state.rpg.captain.configured: return "Establezca el trasfondo."
 if action=="goal":
  var person=int(args.get("person",-1))
  var system=str(args.get("system",sim.state.location_id))
  if sim.person_by_id(person).is_empty() or sim.Universe.system(system).is_empty(): return "Elija una persona y un lugar existentes."
  if a.goals.any(func(g):return g.status=="open"): return "Ya tiene una meta personal activa."
  a.goals.append({"person":person,"system":system,"status":"open","started":int(sim.state.day),"due":int(sim.state.day)+30})
  sim.RPG.note(sim,"Meta","Asegurar una red de apoyo para %s en %s antes del día %d. Requiere visitar allí un contacto y obtener un favor."%[sim.person_name(person),sim.Universe.system(system).name,sim.state.day+30])
  return "Meta personal establecida."
 if action=="drop_goal":
  for g in a.goals:
   if g.status=="open":g.status="abandoned"
  return "Meta abandonada sin bloquear la campaña."
 if not action in ACTIONS or sim.in_transit() or sim.RPG.waiting(sim): return "Acción local no disponible ahora."
 var person=int(args.get("person",-1))
 if person==-1:
  if sim.RPG.busy(sim) or not sim.state.active.is_empty(): return "El capitán está ocupado."
 else:
  var p=sim.person_by_id(person)
  if p.is_empty() or not sim.person_available(p) or sim.personnel_deployed(person) or a.jobs.any(func(j):return j.person==person): return "El oficial no está disponible."
 var contact=str(args.get("contact",""))
 if not contact in known(sim): return "Seleccione un enlace conocido."
 var case_id=int(args.get("case",-1))
 if action=="clue":
  var c=sim.RPG.Adventures.find(sim,case_id)
  if c.is_empty() or c.system!=sim.state.location_id or not c.status in ["open","deferred"] or c.due<sim.state.day+2: return "Necesita una pista local y dos días antes del plazo."
 var key=action+":"+contact+":"+sim.state.location_id
 if int(a.cooldowns.get(key,-1))>sim.state.day: return "Ya realizó esta iniciativa recientemente; disponible cada catorce días."
 var cost=2000 if action!="proposal" else 4000
 if not sim.RPG.spend(sim,cost,ACTIONS[action]): return "Fondos libres insuficientes."
 a.cooldowns[key]=int(sim.state.day)+14
 a.jobs.append({"id":int(a.next),"action":action,"person":person,"contact":contact,"case":case_id,"system":sim.state.location_id,"due":int(sim.state.day)+2})
 a.next+=1
 if person>=0: sim.person_by_id(person).rest_until=maxi(sim.person_by_id(person).rest_until,sim.state.day+2)
 sim.RPG.note(sim,"Agenda","%s a cargo de %s: dos días, %d C-bills."%[ACTIONS[action],sim.person_name(person) if person>=0 else sim.state.captain_name,cost])
 return "Iniciativa encargada. Avance dos días; el personal asignado queda reservado."
static func tick(sim):
 var a=sim.state.rpg.agenda
 for job in a.jobs.duplicate():
  if job.due>sim.state.day: continue
  a.jobs.erase(job)
  var source=sim.state.captain_name if job.person<0 else sim.person_name(job.person)
  if job.person>=0 and (sim.person_by_id(job.person).is_empty() or sim.person_by_id(job.person).injury>0):
   sim.RPG.note(sim,"Agenda","El oficial ya no pertenece a la compañía; el encargo termina sin resultado ni devolución del gasto.")
   continue
  if not a.contacts.has(job.contact): a.contacts[job.contact]={"favors":0,"last":int(sim.state.day),"system":job.system}
  var contact=a.contacts[job.contact]
  contact.last=int(sim.state.day)
  contact.system=job.system
  match job.action:
   "visit": contact.favors=mini(3,contact.favors+1)
   "audience": sim._change_relation(job.contact,1)
   "clue":
    var c=sim.RPG.Adventures.find(sim,job.case)
    if not c.is_empty() and c.status in ["open","deferred"]: sim.RPG.Adventures.clue(sim,c,"observación",source,"El archivo del enlace corrobora la discrepancia. No prueba culpabilidad.")
   "proposal":
    var outcome=sim.RPG.Adventures.open_case(sim,"mediation") if job.system==sim.state.location_id else "La propuesta queda registrada; regrese al sistema para abrir una mediación."
    sim.RPG.note(sim,"Propuesta",outcome)
  a.history.append({"id":job.id,"day":int(sim.state.day),"action":job.action,"system":job.system,"contact":job.contact,"source":source})
  sim.RPG.note(sim,"Agenda",source+" informa: "+ACTIONS[job.action]+" completado con "+job.contact+".")
 for g in a.goals:
  if g.status!="open": continue
  if sim.state.day>g.due:
   g.status="expired"
   sim.RPG.note(sim,"Meta","Venció el plazo de la red de apoyo. Puede elegir otra meta.")
  elif a.history.any(func(h):return h.action=="visit" and h.system==g.system and h.day>=g.started) and a.contacts.values().any(func(c):return c.system==g.system and c.favors>0):
   g.status="completed"
   sim.RPG.Social.milestone(sim,"network:"+g.system+":"+str(g.person),1)
   sim.RPG.note(sim,"Meta","Red de apoyo establecida para "+sim.person_name(g.person)+". El enlace conserva su favor para futuros compromisos.")
static func view(sim) -> Array:
 var a=sim.state.rpg.agenda
 var text="Una actividad del capitán a la vez. Puede encargar iniciativas a oficiales disponibles; quedan reservados dos días. Coste: 2.000 por acción, 4.000 por propuesta. Cada acción/enlace/lugar tiene catorce días de intervalo."
 for job in a.jobs: text+="\n%s · %s · termina día %d"%[ACTIONS[job.action],sim.person_name(job.person) if job.person>=0 else sim.state.captain_name,job.due]
 for g in a.goals: text+="\nMeta: red para %s en %s · %s · día límite %d"%[sim.person_name(g.person),sim.Universe.system(g.system).name,g.status,g.due]
 var actions=[]
 if not a.goals.any(func(g):return g.status=="open"):
  for id in sim.state.rpg.circle:
   if not sim.person_by_id(id).is_empty(): actions.append(sim.RPG.button("Meta: red de apoyo para "+sim.person_name(id)+" aquí · 30 días","agenda",{"action":"goal","person":id}))
 else: actions.append(sim.RPG.button("Abandonar meta personal","agenda",{"action":"drop_goal"}))
 var result=[{"title":"Agenda y metas","text":text,"actions":actions}]
 for contact in known(sim):
  actions=[]
  for action in ["audience","visit","proposal"]: actions.append(sim.RPG.button(ACTIONS[action]+" personalmente · 2 días","agenda",{"action":action,"contact":contact}))
  for id in sim.state.rpg.circle:
   if not sim.person_by_id(id).is_empty(): actions.append(sim.RPG.button("Enviar a %s a visitar · 2 días"%sim.person_name(id),"agenda",{"action":"visit","contact":contact,"person":id}))
  for c in sim.state.rpg.adventures.cases:
   if c.status in ["open","deferred"]: actions.append(sim.RPG.button("Investigar pista del asunto #%d · 2 días"%c.id,"agenda",{"action":"clue","contact":contact,"case":c.id}))
  result.append({"title":"Enlace: "+contact,"text":"Favores disponibles: %d"%a.contacts.get(contact,{}).get("favors",0),"actions":actions})
 return result
static func valid(a: Variant,day: int) -> bool:
 if not a is Dictionary: return false
 for k in ["jobs","history","goals"]:
  if not a.get(k) is Array: return false
 for k in ["contacts","cooldowns"]:
  if not a.get(k) is Dictionary:return false
 if not num(a.get("next"),1,1000000000): return false
 for j in a.jobs:
  if not j is Dictionary or not j.get("action") in ACTIONS or not num(j.get("person"),-1,1000000) or not num(j.get("due"),day+1,day+2) or not num(j.get("id"),1,1000000000) or not num(j.get("case"),-1,1000000000) or not j.get("contact") is String or not j.get("system") is String: return false
 for c in a.contacts.values():
  if not c is Dictionary or not num(c.get("favors"),0,3) or not num(c.get("last"),0,day) or not c.get("system") is String:return false
 for g in a.goals:
  if not g is Dictionary or not num(g.get("person"),0,1000000) or not num(g.get("started"),0,day) or not num(g.get("due"),0,1000000000) or not g.get("system") is String or not g.get("status") in ["open","completed","expired","abandoned"]:return false
 for h in a.history:
  if not h is Dictionary or not h.get("action") in ACTIONS or not num(h.get("day"),0,day) or not h.get("system") is String or not h.get("contact") is String or not h.get("source") is String:return false
 return true
static func num(v: Variant,low: int,high: int) -> bool:
 return preload("res://sim/operations.gd").integer(v,low,high)
