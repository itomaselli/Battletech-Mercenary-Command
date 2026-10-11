extends RefCounted
const PERKS = {"mediador":"Mediador: +1 en Trato y acceso a mediación por garantía", "analista":"Analista: +1 en Investigación y contraste documental", "logista":"Organizador: +1 en Mando y apoyo logístico"}
static func create() -> Dictionary:
 return {"ties":{},"promises":[],"milestones":[],"xp":0,"perks":[],"talked":{},"cargo_settled":false}
static func ensure(sim):
 var s = sim.state.rpg.social
 for id in sim.state.rpg.circle:
  var person = sim.person_by_id(id)
  if person.is_empty() or s.ties.has(str(id)): continue
  var value = "proteger" if person.role in ["Piloto","Dotación"] else "mantener" if person.role.contains("técn") or person.role == "Técnico" else "cumplir"
  s.ties[str(id)] = {"name":person.name,"value":value,"trust":1 if id==sim.state.rpg.captain.bond else 0,"respect":0,"memories":[]}
static func remember(sim, id: int, text: String, trust: int = 0, respect: int = 0):
 var ties = sim.state.rpg.social.ties
 if not ties.has(str(id)): return
 var tie = ties[str(id)]
 tie.trust = clampi(int(tie.trust)+trust,-5,5)
 tie.respect = clampi(int(tie.respect)+respect,-5,5)
 tie.memories.append({"day":int(sim.state.day),"text":text})
 var person = sim.person_by_id(id)
 if not person.is_empty(): sim._remember(person,text)
 sim.RPG.note(sim,"Vínculo",tie.name + ": " + text)
static func milestone(sim, id: String, amount: int):
 var s = sim.state.rpg.social
 if id in s.milestones: return
 s.milestones.append(id)
 s.xp += amount
 sim.RPG.note(sim,"Aprendizaje","Hito %s: %d puntos de experiencia personal; se aprende también de resultados adversos." % [id,amount])
static func promise_people(sim):
 var promises = sim.state.rpg.social.promises
 if promises.any(func(p): return p.id=="cargo-people"): return
 promises.append({"id":"cargo-people","text":"Dar prioridad a las personas encontradas","status":"open","due":int(sim.state.day)+14,"person":int(sim.state.rpg.captain.bond)})
 sim.RPG.note(sim,"Promesa","Priorizar a las personas en la recuperación; resolver al cierre de la operación o revisar en 14 días.")
static func settle_cargo(sim):
 var s = sim.state.rpg.social
 if s.cargo_settled: return
 ensure(sim)
 var cargo = sim.state.rpg.cargo
 var rescued = cargo.choice in ["people","both"] and cargo.outcome in ["success","partial"]
 for key in s.ties:
  var tie = s.ties[key]
  var delta = 1 if (tie.value=="proteger" and rescued) or (tie.value=="cumplir" and cargo.choice in ["material","both"] and cargo.outcome=="success") else -1
  if tie.value=="mantener": delta = 0 if cargo.outcome=="success" else -1
  remember(sim,int(key),"Recuerda la prioridad %s y el resultado %s en la carga no declarada. Su prioridad personal es %s." % [cargo.choice,cargo.outcome,tie.value],delta,0)
 for promise in s.promises:
  if promise.id=="cargo-people" and promise.status in ["open","overdue"]:
   promise.status = "kept" if rescued else "broken"
   sim.RPG.note(sim,"Promesa",promise.text + ": " + ("cumplida" if rescued else "no cumplida; el resultado queda registrado"))
 s.cargo_settled = true
 milestone(sim,"cargo",2)
static func command(sim, action: String, args: Dictionary) -> String:
 if not sim.state.rpg.captain.configured:return "Complete primero el trasfondo."
 ensure(sim)
 var r = sim.state.rpg
 var s = r.social
 match action:
  "learn":
   var perk = str(args.get("perk",""))
   if not perk in PERKS or perk in s.perks or s.xp<2: return "Mejora no disponible: requiere dos puntos y no se puede repetir."
   s.xp -= 2
   s.perks.append(perk)
   r.captain.skills[{"mediador":"trato","analista":"investigacion","logista":"mando"}[perk]] += 1
   sim.RPG.note(sim,"Progresión",PERKS[perk])
   return "Mejora aprendida."
  "talk":
   var id = int(args.get("person",-1))
   var person = sim.person_by_id(id)
   var key = "%d/%d" % [id,int(sim.state.day/14)]
   if person.is_empty() or not sim.person_available(person) or sim.personnel_deployed(id): return "Esa persona no está disponible para conversar."
   if sim.RPG.waiting(sim) or sim.RPG.busy(sim) or sim.in_transit() or not sim.state.active.is_empty(): return "Espere un momento de descanso en base."
   if s.talked.has(key): return "Ya conversaron en este período; no hay un nuevo asunto que repetir."
   var topic = str(args.get("topic","listen"))
   if not topic in ["listen","explain"]: return "Enfoque de conversación inválido."
   s.talked[key] = true
   person.rest_until = int(sim.state.day)+1
   r.jobs.append({"kind":"conversation","due":int(sim.state.day)+1,"person":id,"topic":topic})
   return "Conversación y descanso programados: un día, sin coste adicional ni experiencia repetible."
 return "Acción social desconocida."
static func finish_job(sim, job: Dictionary):
 var person = sim.person_by_id(job.person)
 if person.is_empty():
  sim.RPG.note(sim,"Conversación","La conversación quedó sin efecto: la persona ya no pertenece a la compañía.")
  return
 var text = "El capitán escuchó sus prioridades y su experiencia en la compañía." if job.topic=="listen" else "El capitán explicó sus decisiones; puede mantener el desacuerdo y respetar su responsabilidad."
 remember(sim,job.person,text,1 if job.topic=="listen" else 0,1 if job.topic=="explain" else 0)
 person.fatigue = maxi(0,int(person.fatigue)-10)
static func tick(sim):
 for promise in sim.state.rpg.social.promises:
  if promise.status=="open" and sim.state.day>promise.due:
   promise.status = "overdue"
   sim.RPG.note(sim,"Promesa","Venció el seguimiento conocido: " + promise.text + ". Queda pendiente una explicación, no bloquea la campaña.")
static func view(sim) -> Array:
 var s = sim.state.rpg.social
 var text = "Experiencia personal disponible: %d. Las mejoras cuestan 2; se obtiene experiencia por hitos únicos." % s.xp
 var actions = []
 for perk in PERKS:
  if not perk in s.perks and s.xp>=2: actions.append(sim.RPG.button(PERKS[perk],"social",{"action":"learn","perk":perk}))
 var result = [{"title":"Desarrollo personal","text":text,"actions":actions}]
 for key in s.ties:
  var tie = s.ties[key]
  text = "%s · confianza %+d · respeto %+d\nPrioridad: %s" % [tie.name,tie.trust,tie.respect,{"proteger":"traer a su gente de vuelta","mantener":"conservar el material y las condiciones de trabajo","cumplir":"cumplir compromisos y sostener la compañía"}[tie.value]]
  if not tie.memories.is_empty(): text += "\nRecuerdo: " + tie.memories[-1].text
  actions = []
  if not sim.person_by_id(int(key)).is_empty():
   actions = [sim.RPG.button("Escuchar · un día de descanso","social",{"action":"talk","person":int(key),"topic":"listen"}),sim.RPG.button("Explicar mis decisiones · un día","social",{"action":"talk","person":int(key),"topic":"explain"})]
  else: text += "\nFuera de la compañía; su historia se conserva."
  result.append({"title":"Conversar con " + tie.name,"text":text,"actions":actions})
 for p in s.promises: result.append({"title":"Promesa","text":"%s · %s · seguimiento día %d" % [p.text,{"open":"pendiente","kept":"cumplida","broken":"incumplida","overdue":"plazo vencido"}[p.status],p.due],"actions":[]})
 return result
static func valid(s: Variant, day: int) -> bool:
 if not s is Dictionary or not s.get("ties") is Dictionary or not s.get("promises") is Array or not s.get("milestones") is Array or not s.get("perks") is Array or not s.get("talked") is Dictionary or not s.get("cargo_settled") is bool: return false
 if not preload("res://sim/operations.gd").integer(s.get("xp"),0,1000000): return false
 for perk in s.perks:
  if not perk in PERKS: return false
 for key in s.ties:
  var tie=s.ties[key]
  if not tie is Dictionary or not tie.get("name") is String or not tie.get("value") in ["proteger","mantener","cumplir"] or not tie.get("memories") is Array: return false
  for field in ["trust","respect"]:
   if not preload("res://sim/operations.gd").integer(tie.get(field),-5,5): return false
 for p in s.promises:
  if not p is Dictionary or not p.get("id") is String or not p.get("text") is String or not p.get("status") in ["open","kept","broken","overdue"] or not preload("res://sim/operations.gd").integer(p.get("due"),0,1000000000): return false
 return true
