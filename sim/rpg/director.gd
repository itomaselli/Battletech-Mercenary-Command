extends RefCounted
static func create() -> Dictionary:
 return {"last":0,"seen":[],"pending":{},"summaries":[]}
static func tick(sim):
 var r=sim.state.rpg
 var d=r.director
 if not r.captain.configured:return
 if not d.pending.is_empty() and sim.state.day>d.pending.expires:
  sim.RPG.note(sim,"Vida cotidiana","La invitación quedó atrás; no acarrea penalidad.")
  d.pending={}
 var interval=int(r.get("arcs",{}).get("settings",{}).get("frequency",14))
 if sim.state.day-d.last<interval or sim.in_transit() or not sim.state.active.is_empty() or sim.RPG.busy(sim) or sim.RPG.waiting(sim) or not d.pending.is_empty():return
 if not sim.Story.Society.available(sim):return
 var entries=[]
 for e in r.journal:
  if e.day>d.last and e.kind!="Comprobación":entries.append("Día %d · %s · %s"%[e.day,e.kind,e.text])
 d.summaries.append({"from":int(d.last),"to":int(sim.state.day),"text":"\n".join(entries.slice(maxi(0,entries.size()-8))) if not entries.is_empty() else "Período estable sin nuevos asuntos personales registrados."})
 d.last=int(sim.state.day)
 var key="rest:%d"%int(sim.state.day/28)
 var kind="rest"
 var text="El equipo propone compartir una comida y revisar cómo están. Puede dedicar un día y 500 C-bills, o seguir con sus planes."
 for c in r.adventures.cases:
  var candidate="case:%d"%c.id
  if c.status=="closed" and not candidate in d.seen:
   key=candidate
   kind="reflection"
   text="El equipo recuerda el asunto #%d: %s. Propone conversar sobre cómo su decisión cambió las prioridades de la compañía."%[c.id,c.outcome]
   break
 if key in d.seen:return
 d.seen.append(key)
 sim.state.story.society.pulse=int(sim.state.day)
 d.pending={"id":key,"kind":kind,"text":text,"day":int(sim.state.day),"expires":int(sim.state.day)+14}
 sim.RPG.note(sim,"Invitación",text+" Disponible catorce días; no bloquea el calendario.")
static func command(sim,args: Dictionary) -> String:
 var d=sim.state.rpg.director
 var action=str(args.get("action",""))
 if action=="case":
  var c=sim.RPG.Adventures.find(sim,int(args.get("id",-1)))
  if c.is_empty():return "Expediente no encontrado."
  var text="Asunto #%d · %s · %s"%[c.id,sim.RPG.Adventures.FAMILIES[c.family],c.status]
  for clue in c.clues:text+="\nDía %d · %s · %s: %s"%[clue.day,clue.source,clue.kind,clue.text]
  return text
 if d.pending.is_empty():return "Sin invitación pendiente."
 if action=="decline":d.pending={};return "Continúa con sus planes; sin penalización."
 if action!="rest" or sim.RPG.busy(sim) or sim.RPG.waiting(sim) or not sim.state.active.is_empty() or sim.in_transit():return "Espere un momento libre para reunirse."
 if not sim.RPG.spend(sim,500,"Comida compartida y descanso"):return "Fondos insuficientes."
 sim.state.rpg.jobs.append({"kind":"rest","person":-1,"due":int(sim.state.day)+1})
 d.pending={}
 return "Encuentro organizado: un día de descanso."
static func finish_job(sim):
 sim.state.morale=mini(100,sim.state.morale+2)
 for p in sim.state.staff:
  if not sim.personnel_deployed(p.id):p.fatigue=maxi(0,p.fatigue-5)
 sim.RPG.note(sim,"Vida cotidiana","El capitán compartió una comida con el personal en base. Moral +2 y fatiga −5 de quienes no estaban desplegados.")
static func view(sim) -> Array:
 var d=sim.state.rpg.director
 var result=[]
 if not d.pending.is_empty():result.append({"title":"Un momento para la compañía","text":d.pending.text,"actions":[sim.RPG.button("Compartir un día · 500","director",{"action":"rest"}),sim.RPG.button("Seguir con mis planes","director",{"action":"decline"})]})
 for summary in d.summaries.slice(maxi(0,d.summaries.size()-4)):result.append({"title":"Memoria · días %d–%d"%[summary.from,summary.to],"text":summary.text,"actions":[]})
 var actions=[]
 for c in sim.state.rpg.adventures.cases.slice(maxi(0,sim.state.rpg.adventures.cases.size()-12)):actions.append(sim.RPG.button("Revisar asunto #%d · %s"%[c.id,c.status],"director",{"action":"case","id":c.id}))
 result.append({"title":"Expedientes enlazados","text":"Las memorias usan únicamente informes, declaraciones y decisiones ya conocidos. La prosperidad no genera castigos automáticos.","actions":actions})
 return result
static func valid(d: Variant,day: int) -> bool:
 if not d is Dictionary or not d.get("seen") is Array or not d.get("pending") is Dictionary or not d.get("summaries") is Array or not num(d.get("last"),0,day):return false
 for key in d.seen:
  if not key is String:return false
 if not d.pending.is_empty():
  var p=d.pending
  if not p.get("id") is String or not p.get("kind") in ["rest","reflection"] or not p.get("text") is String or not num(p.get("day"),0,day) or not num(p.get("expires"),0,1000000000):return false
 for s in d.summaries:
  if not s is Dictionary or not num(s.get("from"),0,day) or not num(s.get("to"),0,day) or not s.get("text") is String:return false
 return true
static func num(v: Variant,low: int,high: int) -> bool:
 return preload("res://sim/operations.gd").integer(v,low,high)
