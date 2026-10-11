extends RefCounted
const FAMILIES = {"sabotage":"Manifiestos alterados", "mediation":"Dos compromisos incompatibles", "asylum":"Una petición de protección"}
static func create() -> Dictionary:
 return {"next":1,"cases":[],"cooldowns":{}}
static func find(sim, id: int) -> Dictionary:
 for item in sim.state.rpg.adventures.cases:
  if item.id==id: return item
 return {}
static func open_case(sim, family: String) -> String:
 var a=sim.state.rpg.adventures
 if not family in FAMILIES or sim.in_transit(): return "Asunto local no disponible."
 if a.cases.any(func(c):return c.status in ["open","deferred"]): return "Resuelva, abandone o transforme el asunto pendiente."
 var key=sim.state.location_id+":"+family
 if int(a.cooldowns.get(key,-100))>sim.state.day: return "No hay otro caso de esta familia disponible todavía (28 días)."
 var people=sim.state.staff.filter(func(p):return sim.person_available(p) and not sim.personnel_deployed(p.id))
 if people.is_empty(): return "No hay interlocutor disponible."
 var p=people[0]
 var c={"id":int(a.next),"family":family,"system":sim.state.location_id,"person":int(p.id),"source":p.name,"opened":int(sim.state.day),"due":int(sim.state.day)+10,"status":"open","clues":[],"approaches":[],"outcome":"","transform":false}
 a.next+=1
 a.cases.append(c)
 a.cooldowns[key]=int(sim.state.day)+28
 clue(sim,c,"testimonio",p.name,{"sabotage":"El inventario y el manifiesto no coinciden. La causa no está confirmada.","mediation":"Dos proveedores reclaman prioridad sobre el mismo transporte.","asylum":"Un grupo solicita protección temporal; su relato todavía requiere contraste."}[family])
 return "Asunto abierto durante diez días; no exige abandonar sus otros contratos."
static func clue(sim,c: Dictionary,kind: String,source: String,text: String):
 c.clues.append({"day":int(sim.state.day),"kind":kind,"source":source,"text":text})
 sim.RPG.note(sim,"Asunto #%d"%c.id,"%s · %s: %s"%[kind,source,text])
static func close(sim,c: Dictionary,result: String):
 c.status="closed"
 c.outcome=result
 if result!="abandonado": sim.RPG.Conflicts.affect(sim,c.system,-1,"Cierre del asunto #%d"%c.id)
 if result!="abandonado" or not c.approaches.is_empty(): sim.RPG.Social.milestone(sim,"case:%d"%c.id,1)
 sim.RPG.note(sim,"Cierre #%d"%c.id,"%s: %s. Sus fuentes y decisiones quedan en el expediente."%[FAMILIES[c.family],result])
static func command(sim,args: Dictionary) -> String:
 var action=str(args.get("action",""))
 if not sim.state.rpg.captain.configured: return "Establezca su trasfondo."
 if action=="open": return open_case(sim,str(args.get("family","")))
 var c=find(sim,int(args.get("id",-1)))
 if c.is_empty() or not c.status in ["open","deferred"]: return "Asunto no disponible."
 if sim.state.rpg.jobs.any(func(j):return j.get("case",-1)==c.id): return "Espere el trabajo encargado sobre este asunto."
 if action=="abandon": close(sim,c,"abandonado");return "Asunto abandonado; no bloquea otras actividades."
 if action=="defer":
  c.status="deferred"
  return "Asunto aplazado; su plazo conocido sigue corriendo."
 if action=="transform":
  if c.transform: return "El asunto ya fue transformado."
  c.transform=true
  c.family="mediation"
  c.status="open"
  clue(sim,c,"decisión",sim.state.captain_name,"Se propone un acuerdo entre las partes en lugar de atribuir culpabilidad.")
  return "Asunto transformado en mediación; conserva su fecha límite."
 if sim.state.location_id!=c.system or sim.in_transit(): return "Debe encontrarse en el sistema del asunto."
 if action=="approach":
  if sim.RPG.waiting(sim) or sim.RPG.busy(sim) or not sim.state.active.is_empty(): return "El capitán está ocupado."
  var approach=str(args.get("approach",""))
  if not approach in ["interview","records","guarantee"] or approach in c.approaches: return "Enfoque inválido o ya utilizado."
  if approach=="guarantee" and not "mediador" in sim.state.rpg.social.perks: return "Requiere la capacidad Mediador."
  if sim.state.day+1>c.due: return "No queda tiempo para otro enfoque; resuelva o abandone."
  var cost=3000 if approach=="records" else 6000 if approach=="guarantee" else 1000
  if not sim.RPG.spend(sim,cost,"Asunto #%d · %s"%[c.id,approach]): return "Fondos libres insuficientes."
  c.approaches.append(approach)
  c.status="open"
  sim.state.rpg.jobs.append({"kind":"case","due":int(sim.state.day)+1,"person":-1,"case":c.id,"approach":approach})
  return "Enfoque iniciado: un día. El registro documental ofrece una vía segura, aunque más costosa."
 if action=="resolve":
  var choice=str(args.get("choice",""))
  if choice=="fund":
   if not sim.RPG.spend(sim,8000,"Acuerdo garantizado del asunto #%d"%c.id): return "Se necesitan 8.000 C-bills libres."
   sim.state.morale=mini(100,sim.state.morale+2)
   close(sim,c,"acuerdo financiado")
  elif choice=="evidence":
   if not c.clues.any(func(v):return v.kind=="observación"): return "Necesita contrastar registros o corroborar una entrevista."
   sim.state.supplies+=3 if c.family=="sabotage" else 0
   sim.state.morale=mini(100,sim.state.morale+(3 if c.family=="asylum" else 1))
   close(sim,c,"resuelto con pruebas")
  else: return "Decisión inválida."
  return "Asunto resuelto; consecuencias registradas."
 return "Acción no disponible."
static func finish_job(sim,job: Dictionary):
 var c=find(sim,job.case)
 if c.is_empty() or not c.status in ["open","deferred"]: return
 var certain=job.approach in ["records","guarantee"] or "analista" in sim.state.rpg.social.perks
 var result="success" if certain else sim.RPG.check_roll(sim,"investigacion",9)
 clue(sim,c,"observación" if result!="failure" else "testimonio","Archivo local" if certain else c.source,"Se confirma una discrepancia y una vía para repararla; no demuestra intención criminal." if result!="failure" else "La entrevista no permite corroborar el relato. Puede pagar acceso a registros o financiar un acuerdo.")
static func tick(sim):
 for c in sim.state.rpg.adventures.cases:
  if c.status in ["open","deferred"] and sim.state.day>c.due:
   c.status="expired"
   c.outcome="plazo vencido"
   sim.RPG.note(sim,"Asunto #%d"%c.id,"El plazo conocido venció; las partes buscan otra solución. Puede perseguir otras historias.")
static func view(sim) -> Array:
 var a=sim.state.rpg.adventures
 var actions=[]
 if not a.cases.any(func(c):return c.status in ["open","deferred"]):
  for key in FAMILIES: actions.append(sim.RPG.button("Abrir: "+FAMILIES[key],"adventure",{"action":"open","family":key}))
 var result=[{"title":"Asuntos locales","text":"Tres familias de ficción de campaña. Un asunto abierto; diez días para actuar. Investigar cuesta tiempo y recursos; abandonar es una opción válida.","actions":actions}]
 for c in a.cases.slice(maxi(0,a.cases.size()-8)):
  actions=[]
  var text="%s · %s · plazo día %d · %s"%[sim.Universe.system(c.system).name,c.source,c.due,c.status]
  for entry in c.clues: text+="\nDía %d · %s · %s: %s"%[entry.day,entry.kind,entry.source,entry.text]
  if c.status in ["open","deferred"]:
   for spec in [["interview","Entrevistar · Investigación 9 · 1 día · 1.000"],["records","Contrastar documentos · 1 día · 3.000"],["guarantee","Garantía del mediador · 1 día · 6.000"]]:
    if not spec[0] in c.approaches and (spec[0]!="guarantee" or "mediador" in sim.state.rpg.social.perks): actions.append(sim.RPG.button(spec[1],"adventure",{"action":"approach","id":c.id,"approach":spec[0]}))
   for spec in [["resolve","Resolver con pruebas","evidence"],["resolve","Financiar acuerdo · 8.000","fund"],["defer","Aplazar · el plazo sigue",""],["transform","Transformar en mediación",""],["abandon","Abandonar asunto",""]]: actions.append(sim.RPG.button(spec[1],"adventure",{"action":spec[0],"id":c.id,"choice":spec[2]}))
  result.append({"title":"#%d · %s"%[c.id,FAMILIES[c.family]],"text":text,"actions":actions})
 return result
static func valid(a: Variant,day: int) -> bool:
 if not a is Dictionary or not a.get("cases") is Array or not a.get("cooldowns") is Dictionary or not number(a.get("next")): return false
 var ids=[]
 for c in a.cases:
  if not c is Dictionary or not number(c.get("id")) or c.id in ids or c.id>=a.next or not c.get("family") in FAMILIES or not c.get("status") in ["open","deferred","closed","expired"]: return false
  ids.append(c.id)
  if not c.get("system") is String or preload("res://sim/universe.gd").system(c.system).is_empty() or not c.get("source") is String or not number(c.get("person")) or not number(c.get("due")) or not number(c.get("opened")) or c.opened>day: return false
  if not c.get("approaches") is Array or not c.get("clues") is Array or not c.get("outcome") is String or not c.get("transform") is bool: return false
  for clue_item in c.clues:
   if not clue_item is Dictionary or not number(clue_item.get("day")) or clue_item.day>day or not clue_item.get("kind") in ["observación","testimonio","decisión"] or not clue_item.get("source") is String or not clue_item.get("text") is String: return false
 return true

static func number(value: Variant) -> bool:
 return preload("res://sim/operations.gd").integer(value,-1,1000000000)
