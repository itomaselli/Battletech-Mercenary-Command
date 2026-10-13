extends RefCounted
const REVISION = 25
const Arcs = preload("res://sim/rpg/arcs.gd")
const Director = preload("res://sim/rpg/director.gd")
const Delegation = preload("res://sim/rpg/delegation.gd")
const Conflicts = preload("res://sim/rpg/conflicts.gd")
const Workshop = preload("res://sim/rpg/workshop.gd")
const Negotiation = preload("res://sim/rpg/negotiation.gd")
const Agenda = preload("res://sim/rpg/agenda.gd")
const Adventures = preload("res://sim/rpg/adventures.gd")
const Social = preload("res://sim/rpg/social.gd")
const ORIGINS = {"oficial":"Antiguo oficial", "mercenario":"Familia mercenaria", "tecnico":"Técnico convertido en comandante"}
const SKILLS = {"mando":"Mando", "trato":"Trato", "investigacion":"Investigación"}
const MOTIVES = {"independencia":"Independencia", "prestigio":"Prestigio profesional", "proteccion":"Proteger a mi gente", "deuda":"Resolver una deuda personal"}
static func create(seed_value: int) -> Dictionary:
 return {"arcs":Arcs.create(),"director":Director.create(),"delegation":Delegation.create(),"conflicts":Conflicts.create(),"workshop":Workshop.create(),"negotiation":Negotiation.create(),"agenda":Agenda.create(),"adventures":Adventures.create(),"social":Social.create(),"revision":REVISION,"seed":seed_value,"sequence":0,"captain":{"id":"captain","configured":false,"origin":"","specialty":"","motivation":"","bond":-1,"skills":{"mando":2,"trato":2,"investigacion":2}},"circle":[],"journal":[],"scene":"","cargo":{"stage":"available","contract_id":-1,"choice":"","evidence":false,"extra":false,"prepared":[],"base_pay":0,"outcome":""},"jobs":[],"results":[]}
static func upgrade(data: Dictionary):
 if data.get("revision")==16:
  data["social"] = Social.create()
  data.revision=17
 if data.get("revision")==17:
  data["adventures"]=Adventures.create()
  data.revision=18
 if data.get("revision")==18:
  data["agenda"]=Agenda.create()
  data.revision=19
 if data.get("revision")==19:
  data["negotiation"]=Negotiation.create()
  data.revision=20
 if data.get("revision")==20:
  data["workshop"]=Workshop.create()
  data.revision=21
 if data.get("revision")==21:
  data["conflicts"]=Conflicts.create()
  data.revision=22
 if data.get("revision")==22:
  data["delegation"]=Delegation.create()
  data.revision=23
 if data.get("revision")==23:
  data["director"]=Director.create()
  data.revision=24
 if data.get("revision")==24:
  data["arcs"]=Arcs.create()
  data.revision=25
static func note(sim, kind: String, text: String):
 sim.state.rpg.journal.append({"day":int(sim.state.day),"kind":kind,"text":text})
 sim.log_event("Capitán · " + kind,text)
static func circle(sim) -> Array:
 var result = []
 for role in ["Piloto","Jefa técnica","Logística"]:
  for person in sim.state.staff:
   if person.role == role and not person.id in result: result.append(person.id); break
 for person in sim.state.staff:
  if result.size()>=3: break
  if not person.id in result: result.append(person.id)
 return result
static func waiting(sim) -> bool:
 return not sim.state.get("rpg",{}).get("scene","").is_empty() or Delegation.waiting(sim) or sim.state.rpg.arcs.retired
static func busy(sim) -> bool:
 if sim.Story.Objectives.busy(sim,-1):return true
 return not sim.state.rpg.jobs.is_empty() or sim.state.rpg.agenda.jobs.any(func(j):return j.person<0)
static func check_roll(sim, skill: String, difficulty: int) -> String:
 var r = sim.state.rpg
 r.sequence += 1
 var dice = RandomNumberGenerator.new()
 dice.seed = int(r.seed) + int(r.sequence)*104729
 var roll = dice.randi_range(1,6)+dice.randi_range(1,6)
 var ability = int(r.captain.skills[skill])
 var result = "success" if roll+ability>=difficulty else "partial" if roll+ability>=difficulty-2 else "failure"
 note(sim,"Comprobación","%s: 2d6 (%d) + competencia %d frente a %d; %s. Riesgo propio, sin revelar datos enemigos." % [SKILLS[skill],roll,ability,difficulty,{"success":"logrado","partial":"logrado con límites","failure":"sin corroborar"}[result]])
 return result
static func spend(sim, cost: int, detail: String) -> bool:
 if sim.available_funds()<cost: return false
 sim.state.funds -= cost
 sim._record_transaction("Rol",-cost,detail)
 return true
static func configure(sim, args: Dictionary) -> String:
 var c = sim.state.rpg.captain
 if c.configured: return "El trasfondo ya está establecido; el personaje progresa mediante sus actos."
 if not args.get("origin") in ORIGINS or not args.get("specialty") in SKILLS or not args.get("motivation") in MOTIVES: return "Complete el trasfondo."
 var bond = int(args.get("bond",-1))
 if bond != -1 and sim.person_by_id(bond).is_empty(): return "El vínculo debe ser una persona de la compañía."
 c.origin = args.origin
 c.specialty = args.specialty
 c.motivation = args.motivation
 c.bond = bond
 c.skills[{"oficial":"mando","mercenario":"trato","tecnico":"investigacion"}[c.origin]] += 1
 c.skills[c.specialty] += 1
 c.configured = true
 sim.state.rpg.circle = circle(sim)
 Social.ensure(sim)
 if c.bond>=0:sim.state.rpg.social.ties[str(c.bond)].trust=mini(5,int(sim.state.rpg.social.ties[str(c.bond)].trust)+1)
 note(sim,"Identidad","%s establece su trasfondo: %s; especialidad %s; motivación: %s. El vínculo se establece desde hoy, sin recuerdos retroactivos." % [sim.state.captain_name,ORIGINS[c.origin],SKILLS[c.specialty],MOTIVES[c.motivation]])
 return "Trasfondo establecido. Puede iniciar una aventura desde Capitán."
static func start_cargo(sim) -> String:
 var r = sim.state.rpg
 if not r.captain.configured: return "Complete primero el trasfondo del capitán."
 if r.cargo.stage != "available": return "Esta aventura ya está iniciada o concluida."
 if busy(sim) or waiting(sim) or sim.in_transit() or not sim.state.accepted.is_empty(): return "Termine sus compromisos antes de reunirse con el empleador."
 var offer = {}
 for item in sim.state.missions.offers:
  if item.mission_type == "recovery" and item.expires>sim.state.day: offer = item; break
 if offer.is_empty(): return "Se necesita una oferta local de recuperación vigente; consulte el próximo boletín."
 var result = sim.accept_mission(offer.id)
 if sim.state.accepted.is_empty(): return result
 sim.state.accepted["rpg_id"] = "cargo"
 r.cargo.contract_id = int(sim.state.accepted.id)
 r.cargo.base_pay = int(sim.state.accepted.pay)
 r.cargo.stage = "preparing"
 r.scene = "briefing"
 note(sim,"Contrato","La carga que no figuraba: el enlace pide recuperar material. El manifiesto no incluye personal; no confirma si el sitio está vacío.")
 return "Reunión abierta. El calendario espera su respuesta."
static func prepare(sim, approach: String) -> String:
 var r = sim.state.rpg
 if waiting(sim) or busy(sim) or r.cargo.stage != "preparing" or not sim.state.active.is_empty(): return "Preparación no disponible."
 if approach in r.cargo.prepared or not approach in ["investigate","transport","organize"]: return "Enfoque ya utilizado o inválido."
 if sim.state.day+1>sim.state.accepted.deadline: return "No queda un día libre antes del plazo; despliegue o renegocie su compromiso."
 var bond_ready = not sim.person_by_id(r.captain.bond).is_empty() and sim.person_available(sim.person_by_id(r.captain.bond))
 var cost = (8000 if bond_ready else 12000) if approach == "transport" else 1000
 if not spend(sim,cost,"Preparación: " + approach): return "Fondos libres insuficientes."
 r.cargo.prepared.append(approach)
 r.jobs.append({"kind":approach,"due":int(sim.state.day)+1,"person":-1})
 note(sim,"Preparación","%s: %d C-bills, un día. El capitán queda ocupado hasta recibir el resultado." % [{"investigate":"Contrastar manifiestos","transport":"Contratar transporte adicional","organize":"Preparar coordinación de evacuación"}[approach],cost])
 return "Preparación encargada; avance un día."
static func tick(sim):
 Social.tick(sim)
 Adventures.tick(sim)
 Agenda.tick(sim)
 Workshop.tick(sim)
 Conflicts.tick(sim)
 Delegation.tick(sim)
 Director.tick(sim)
 var r = sim.state.rpg
 for job in r.jobs.duplicate():
  if job.due>sim.state.day: continue
  r.jobs.erase(job)
  match job.kind:
   "rest": Director.finish_job(sim)
   "conflict": Conflicts.finish_job(sim,job)
   "case": Adventures.finish_job(sim,job)
   "conversation": Social.finish_job(sim,job)
   "transport":
    r.cargo.extra = true
    note(sim,"Preparación","El transporte auxiliar contratado está listo. Capacidad adicional confirmada.")
   "investigate":
    var result = check_roll(sim,"investigacion",9)
    r.cargo.evidence = result != "failure"
    note(sim,"Testimonio","El registro sugiere trabajadores todavía en el lugar; corroboración limitada, se debe verificar en campo." if r.cargo.evidence else "Los registros son incompletos. La ausencia de nombres no demuestra que el lugar esté vacío.")
   "organize":
    var result = "success" if "logista" in r.social.perks else check_roll(sim,"mando",9)
    if result == "success": r.cargo.extra = true
    elif result == "partial": r.cargo.evidence = true
    note(sim,"Preparación","Se coordinó un transporte de apoyo local." if result == "success" else "La coordinación no garantiza transporte adicional; el despliegue sigue siendo posible.")
static func operation_tick(sim) -> bool:
 var r = sim.state.rpg
 if sim.state.active.contract.get("rpg_id","") != "cargo" or r.cargo.stage != "preparing": return false
 if sim.state.military.current.get("elapsed",0)<2: return false
 r.cargo.stage = "discovery"
 r.scene = "discovery"
 note(sim,"Informe","El jefe confirma trabajadores en el sitio. La capacidad disponible obliga a priorizar personas o material, salvo apoyo adicional. Espera su decisión.")
 return true
static func choose(sim, choice: String) -> String:
 var r = sim.state.rpg
 match r.scene:
  "briefing":
   if not choice in ["professional","people","questions"]: return "Respuesta inválida."
   r.scene = ""
   if choice == "people": Social.promise_people(sim)
   if choice == "questions":
    var result = check_roll(sim,"trato",9)
    r.cargo.evidence = result != "failure"
    note(sim,"Declaración","El enlace admite que no puede confirmar una evacuación previa." if result != "failure" else "El enlace mantiene su versión; puede contrastarla con registros o en campo.")
   else: note(sim,"Intención","El capitán declara prioridad al personal encontrado." if choice == "people" else "El capitán confirma su compromiso con el material contratado, sujeto a la situación en campo.")
   return "Reunión terminada. Puede preparar un enfoque opcional y desplegar desde Operaciones."
  "discovery":
   if not choice in ["people","material","both","withdraw"]: return "Orden inválida."
   if choice == "both" and not r.cargo.extra: return "Necesita transporte adicional; esa capacidad no está confirmada."
   if choice == "withdraw":
    r.scene = ""
    return sim.cancel_contract("El capitán ordena retirarse tras encontrar trabajadores")
   r.cargo.choice = choice
   r.cargo.stage = "executing"
   r.scene = ""
   if choice == "people":
    sim.state.active.contract.pay = int(r.cargo.base_pay*0.6)
    sim.state.active.contract.partial_pay = int(sim.state.active.contract.pay*0.6)
    sim.state.active.contract.failure_pay = int(sim.state.active.contract.pay*0.15)
    sim.state.active.contract.mission_type = "extraction"
    sim.state.active.objective.kind = "extraction"
    sim.state.active.objective.progress = 0
    sim.state.active.objective.access = 40
    sim.state.accepted = sim.state.active.contract.duplicate(true)
   if choice == "both": sim.state.active.remaining += 1
   note(sim,"Decisión","Orden: %s. La ejecución y sus riesgos siguen a cargo del jefe; el desenlace aún no está garantizado." % {"people":"evacuar personas; techo de pago reducido al 60% del original","material":"recuperar material; solicitar a terceros que atiendan a los trabajadores","both":"evacuar personas y recuperar material con transporte adicional; un día más"}[choice])
   return "Orden transmitida. Avance el calendario para recibir el resultado."
  "debrief":
   if not choice in ["explain","listen","followup"]: return "Respuesta inválida."
   r.scene = ""
   Social.settle_cargo(sim)
   r.cargo.stage = "closed"
   note(sim,"Conversación",{"explain":"El capitán explica sus prioridades al estado mayor; queda registrada su responsabilidad por la decisión.","listen":"El capitán escucha las objeciones del equipo y registra la necesidad de revisar los próximos manifiestos.","followup":"El capitán deja abierto el asunto de los trabajadores y solicita conservar los testimonios para investigarlo."}[choice])
   r.results.append({"id":"cargo","day":int(sim.state.day),"choice":r.cargo.choice,"outcome":r.cargo.outcome,"followup":choice == "followup"})
   return "Aventura cerrada; las consecuencias quedan en la compañía y su diario."
 return "No hay escena pendiente."
static func finish_operation(sim, result: String):
 Negotiation.finish(sim,result)
 Workshop.finish(sim)
 Conflicts.finish_operation(sim,result)
 if sim.state.active.get("contract",{}).get("rpg_id","") != "cargo": return
 var r = sim.state.rpg
 r.cargo.stage = "debrief"
 r.cargo.outcome = result
 r.scene = "debrief"
 note(sim,"Consecuencia","La carga que no figuraba: %s; prioridad %s. El resultado militar determina lo que se logró. La liquidación y los daños figuran en la crónica; el estado mayor solicita hablar." % [result,r.cargo.choice if not r.cargo.choice.is_empty() else "retirada"])
static func command(sim, action: String, args: Dictionary) -> String:
 if sim.state.ended: return "La campaña está cerrada."
 match action:
  "story_local": return sim.Story.Society.command(sim,args)
  "story_objective": return sim.Story.Objectives.command(sim,args)
  "story_culture": return sim.Story.Culture.command(sim,args)
  "story_people": return sim.Story.People.command(sim,args)
  "arcs": return Arcs.command(sim,args)
  "director": return Director.command(sim,args)
  "delegation": return Delegation.command(sim,args)
  "conflict": return Conflicts.command(sim,args)
  "workshop": return Workshop.command(sim,args)
  "negotiation": return Negotiation.command(sim,args)
  "agenda": return Agenda.command(sim,args)
  "adventure": return Adventures.command(sim,args)
  "social": return Social.command(sim,str(args.get("action","")),args)
  "configure": return configure(sim,args)
  "start_cargo": return start_cargo(sim)
  "prepare": return prepare(sim,str(args.get("approach","")))
  "choose": return choose(sim,str(args.get("choice","")))
 return "Acción de rol no disponible."
static func button(label: String, action: String, args: Dictionary = {}) -> Dictionary:
 return {"label":label,"action":action,"args":args}
static func group(sections: Array,page: String) -> Array:
 for section in sections:section["page"]=page
 return sections
static func view(sim) -> Array:
 var r = sim.state.rpg
 var sections = []
 if not r.captain.configured: return [{"title":"El capitán","text":"Complete el trasfondo. Sus actos y vínculos definirán la historia desde este momento.","actions":[]}]
 sections.append({"page":"Personaje","title":sim.state.captain_name,"text":"%s · %s\nMotivación: %s\nMando %d · Trato %d · Investigación %d\nVínculo: %s" % [ORIGINS[r.captain.origin],SKILLS[r.captain.specialty],MOTIVES[r.captain.motivation],r.captain.skills.mando,r.captain.skills.trato,r.captain.skills.investigacion,sim.person_name(r.captain.bond) if r.captain.bond>=0 else "sin vínculo inicial"],"actions":[]})
 var actions = []
 var text = ""
 match r.scene:
  "briefing":
   text = "El enlace solicita material del depósito. El manifiesto no menciona personal. ¿Qué expresa el capitán? Preguntar usa Trato: 2d6 + competencia, objetivo 9; 7–8 da información limitada. Un fallo no bloquea otras fuentes."
   actions = [button("Confirmar el compromiso profesional","choose",{"choice":"professional"}),button("Declarar prioridad a las personas","choose",{"choice":"people"}),button("Preguntar por la evacuación previa · Trato","choose",{"choice":"questions"})]
  "discovery":
   text = "El jefe informa trabajadores en el sitio. No hay capacidad para todo salvo transporte auxiliar. La orden cambia prioridades, no garantiza el éxito."
   actions = [button("Evacuar personas · techo de pago 60% del original","choose",{"choice":"people"}),button("Priorizar material · las personas quedan a cargo de terceros","choose",{"choice":"material"}),button("Retirar la fuerza · devolver anticipo","choose",{"choice":"withdraw"})]
   if r.cargo.extra: actions.append(button("Atender ambos objetivos · transporte disponible · +1 día","choose",{"choice":"both"}))
  "debrief":
   text = "El estado mayor espera una conversación sobre lo ocurrido. Puede explicar su decisión, escuchar las objeciones o dejar un seguimiento pendiente."
   actions = [button("Explicar mi decisión","choose",{"choice":"explain"}),button("Escuchar al equipo","choose",{"choice":"listen"}),button("Solicitar seguimiento del asunto","choose",{"choice":"followup"})]
  _:
   text = "La carga que no figuraba · estado: " + r.cargo.stage
   if r.cargo.stage == "available": actions.append(button("Reunirse y aceptar recuperación local · anticipo y plazo de 5 días","start_cargo"))
   if r.cargo.stage == "preparing" and sim.state.active.is_empty() and not busy(sim):
    text += "\nPreparación opcional: un día por acción; puede desplegar sin agotar los enfoques."
    for spec in [["investigate","Contrastar manifiestos · Investigación 9 · 1.000"],["transport","Contratar transporte · 8.000 con vínculo apto / 12.000 sin él"],["organize","Coordinar apoyo · Mando 9 · 1.000"]]:
     if not spec[0] in r.cargo.prepared: actions.append(button(spec[1],"prepare",{"approach":spec[0]}))
 if busy(sim): text += "\nPreparación en curso; avance un día."
 sections.append({"page":"Escena","title":"Escena y aventura","text":text,"actions":actions})
 sections.append_array(group(Social.view(sim),"Personaje"))
 sections.append_array(group(Adventures.view(sim),"Asuntos"))
 sections.append_array(group(Agenda.view(sim),"Agenda"))
 sections.append_array(group(Negotiation.view(sim),"Contratos"))
 sections.append_array(group(Workshop.view(sim),"Taller"))
 sections.append_array(group(Conflicts.view(sim),"Región"))
 sections.append_array(group(Delegation.view(sim),"Oficiales"))
 sections.append_array(group(Director.view(sim),"Memoria"))
 sections.append_array(group(Arcs.view(sim),"Legado"))
 var entries = []
 for entry in r.journal.slice(maxi(0,r.journal.size()-30)): entries.append("Día %d · %s · %s" % [entry.day,entry.kind,entry.text])
 sections.append({"page":"Memoria","title":"Diario del capitán","text":"\n\n".join(entries),"actions":[]})
 return sections
static func integer(value: Variant, low: int, high: int) -> bool:
 return preload("res://sim/operations.gd").integer(value,low,high)
static func valid(r: Variant, day: int) -> bool:
 if not r is Dictionary or r.get("revision") != REVISION: return false
 if not integer(r.get("seed"),-9000000000000000000,9000000000000000000) or not integer(r.get("sequence"),0,1000000000): return false
 var c = r.get("captain")
 if not c is Dictionary or c.get("id") != "captain" or not c.get("configured") is bool or not c.get("skills") is Dictionary: return false
 if c.configured and (not c.get("origin") in ORIGINS or not c.get("specialty") in SKILLS or not c.get("motivation") in MOTIVES): return false
 if not integer(c.get("bond"),-1,1000000): return false
 for key in SKILLS:
  if not integer(c.skills.get(key),0,8): return false
 if not r.get("circle") is Array or not r.get("journal") is Array or not r.get("jobs") is Array or not r.get("results") is Array: return false
 if not Arcs.valid(r.get("arcs"),day): return false
 if not Director.valid(r.get("director"),day): return false
 if not Delegation.valid(r.get("delegation"),day): return false
 if not Conflicts.valid(r.get("conflicts"),day): return false
 if not Workshop.valid(r.get("workshop"),day): return false
 if not Negotiation.valid(r.get("negotiation"),day): return false
 if not Agenda.valid(r.get("agenda"),day): return false
 if not Adventures.valid(r.get("adventures"),day): return false
 if not Social.valid(r.get("social"),day): return false
 if not r.get("scene") in ["","briefing","discovery","debrief"]: return false
 for entry in r.journal:
  if not entry is Dictionary or not integer(entry.get("day"),0,day) or not entry.get("kind") is String or not entry.get("text") is String: return false
 var cargo = r.get("cargo")
 if not cargo is Dictionary or not cargo.get("stage") in ["available","preparing","discovery","executing","debrief","closed"]: return false
 for key in ["evidence","extra"]:
  if not cargo.get(key) is bool: return false
 if not cargo.get("prepared") is Array or not cargo.get("choice") in ["","people","material","both"] or not cargo.get("outcome") is String: return false
 if not integer(cargo.get("base_pay"),0,1000000000) or not integer(cargo.get("contract_id"),-1,1000000000): return false
 for job in r.jobs:
  if not job is Dictionary or not job.get("kind") in ["transport","investigate","organize","conversation","case","conflict","rest"] or not integer(job.get("due"),day+1,day+30): return false
 return true
static func person_busy(sim,id: int) -> bool:
 if sim.state.get("hq",{}).get("training",{}).has(str(id)):return true
 if sim.Story.Objectives.busy(sim,id):return true
 if sim.state.get("story",{}).get("people",{}).get("jobs",[]).any(func(j):return j.person==id):return true
 var r=sim.state.get("rpg",{})
 for module in ["agenda","workshop","delegation"]:
  for j in r.get(module,{}).get("jobs",[]):
   if j.get("person",-1)==id:return true
 for j in r.get("jobs",[]):
  if j.get("person",-1)==id:return true
 return false
static func valid_links(data: Dictionary) -> bool:
 var r=data.rpg
 for c in [data.accepted,data.active.get("contract",{})]:
  if c.has("terms"):
   if not Negotiation.terms_valid(c.terms) or c.terms.id!=c.id or c.terms.employer!=c.employer:return false
 if data.active.has("rpg_start_hp"):
  if not data.active.rpg_start_hp is Dictionary:return false
  for hp in data.active.rpg_start_hp.values():
   if not integer(hp,0,100):return false
 if data.active.has("rpg_danger") and (not integer(data.active.rpg_danger,80,120) or not int(data.active.rpg_danger) in [80,100,120]):return false
 if data.active.has("rpg_support") and not data.active.rpg_support is bool:return false
 for key in r.social.ties:
  if not str(key).is_valid_int():return false
  for m in r.social.ties[key].memories:
   if not m is Dictionary or not integer(m.get("day"),0,int(data.day)) or not m.get("text") is String:return false
 for p in r.social.promises:
  if not integer(p.get("person"),-1,1000000):return false
 for key in ["milestones","perks"]:
  var unique=[]
  for item in r.social[key]:
   if not item is String or item in unique:return false
   unique.append(item)
 for module in ["adventures","agenda"]:
  for v in r[module].cooldowns.values():
   if not integer(v,0,1000000000):return false
 for id in r.circle:
  if not integer(id,0,1000000):return false
 for approach in r.cargo.prepared:
  if not approach in ["investigate","transport","organize"]:return false
 for job in r.jobs:
  if not integer(job.get("person"),-1,1000000):return false
  match job.kind:
   "conversation":
    if not job.get("topic") in ["listen","explain"]:return false
   "case":
    if not integer(job.get("case"),1,1000000000) or not job.get("approach") in ["interview","records","guarantee"]:return false
   "conflict":
    if not job.get("system") is String or not job.get("approach") in ["mediate","investigate"]:return false
 for c in r.adventures.cases:
  for approach in c.approaches:
   if not approach in ["interview","records","guarantee"]:return false
 for j in r.agenda.jobs:
  if not j.contact in data.relationships and not j.contact in r.agenda.contacts and not (data.offers+data.missions.offers).any(func(o):return o.employer==j.contact):
   # Contacts can leave current offer rotation; their attributed job remains valid.
   if j.contact.is_empty():return false
 var reserved=[]
 for module in ["agenda","workshop","delegation"]:
  for j in r[module].jobs:
   if j.person>=0:
    if j.person in reserved:return false
    reserved.append(j.person)
 for id in r.workshop.reserved:
  if not integer(id,0,1000000):return false
 for key in r.workshop.faults:
  if not str(key).is_valid_int():return false
 for j in r.delegation.jobs:
  if j.budget<3000 or j.budget>20000 or j.quote<3000 or j.quote>20000:return false
 for region in r.conflicts.regions.values():
  if preload("res://sim/universe.gd").system(region.system).is_empty():return false
 for goal in r.agenda.goals:
  if preload("res://sim/universe.gd").system(goal.system).is_empty():return false
 return true
