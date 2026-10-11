extends RefCounted
static func create() -> Dictionary:
 return {"regions":{}}
static func ensure(sim) -> Dictionary:
 var regions=sim.state.rpg.conflicts.regions
 var id=sim.state.location_id
 if not regions.has(id):
  var actors=sim.RPG.Agenda.known(sim)
  if actors.is_empty():return {}
  regions[id]={"system":id,"actors":actors.slice(0,2),"started":int(sim.state.day),"last":int(sim.state.day),"next_action":int(sim.state.day),"tension":5,"resources":4,"status":"active","reports":[],"interventions":0}
  report(sim,regions[id],"Boletín de tránsito","Disputa por prioridad de transporte y suministros. Los enlaces solicitan seguridad y mediación; se desconoce la capacidad de quienes amenazan la ruta.")
 return regions[id]
static func report(sim,c: Dictionary,source: String,text: String):
 c.reports.append({"day":int(sim.state.day),"source":source,"text":text})
 sim.RPG.note(sim,"Región · "+sim.Universe.system(c.system).name,source+": "+text)
static func affect(sim,system: String,delta: int,source: String):
 var c=sim.state.rpg.conflicts.regions.get(system,{})
 if c.is_empty() or c.status!="active":return
 c.tension=clampi(c.tension+delta,0,10)
 c.interventions+=1
 report(sim,c,source,"Se registra un cambio en la disputa local: "+("menor presión sobre rutas" if delta<0 else "mayor presión sobre rutas")+". No confirma control militar del territorio.")
 if c.tension==0:
  c.status="settled"
  sim.RPG.Social.milestone(sim,"conflict:"+system,2)
  report(sim,c,"Enlaces locales","Acuerdo de tránsito alcanzado. Se mantiene el seguimiento comercial; fronteras históricas sin cambios.")
static func command(sim,args: Dictionary) -> String:
 if not sim.state.rpg.captain.configured or sim.in_transit():return "No puede intervenir desde tránsito."
 var c=ensure(sim)
 if args.get("action","")=="briefing":return "Boletín consultado; revise los actores y los informes disponibles."
 if c.is_empty() or c.status!="active":return "Sin disputa activa local."
 if sim.state.day<c.next_action:return "Debe esperar hasta el día %d para otra iniciativa regional."%c.next_action
 var action=str(args.get("action",""))
 if action=="supply":
  if sim.state.supplies<10:return "Se requieren diez suministros."
  sim.state.supplies-=10
  c.resources=mini(10,c.resources+3)
  affect(sim,c.system,-2,"Entrega autorizada por el capitán")
 elif action in ["mediate","investigate"]:
  if sim.RPG.busy(sim) or sim.RPG.waiting(sim) or not sim.state.active.is_empty():return "El capitán está ocupado."
  if not sim.RPG.spend(sim,3000,"Iniciativa regional: "+action):return "Fondos insuficientes."
  sim.state.rpg.jobs.append({"kind":"conflict","person":-1,"due":int(sim.state.day)+2,"system":c.system,"approach":action})
 else:return "Acción inválida."
 c.next_action=int(sim.state.day)+7
 return "Intervención registrada. Mediación o investigación tarda dos días; próxima iniciativa en siete días."
static func finish_job(sim,j: Dictionary):
 var c=sim.state.rpg.conflicts.regions.get(j.system,{})
 if c.is_empty() or c.status!="active":return
 var skill="trato" if j.approach=="mediate" else "investigacion"
 var result=sim.RPG.check_roll(sim,skill,9)
 if result!="failure":
  affect(sim,j.system,-2 if result=="success" else -1,"Informe del capitán")
  if j.approach=="investigate":
   var region=sim.Missions.region(sim.state.missions,j.system)
   region.intel=mini(10,region.intel+1)
 else:report(sim,c,"Informe del capitán","No fue posible corroborar o acordar una solución; todavía puede aportar suministros o intervenir mediante contratos.")
static func tick(sim):
 if not sim.state.rpg.captain.configured:return
 if not sim.in_transit():ensure(sim)
 for c in sim.state.rpg.conflicts.regions.values():
  var near=c.system==sim.state.location_id and not sim.in_transit()
  var period=7 if near else 14
  if c.status!="active" or sim.state.day-c.last<period:continue
  c.last=int(sim.state.day)
  c.resources=maxi(0,c.resources-1)
  c.tension=clampi(c.tension+(1 if c.resources<3 else -1),0,10)
  var region=sim.Missions.region(sim.state.missions,c.system)
  region.pressure=clampi(region.pressure+(1 if c.tension>=7 else -1 if c.tension<=3 else 0),0,8)
  region.supply=clampi(region.supply+(-1 if c.resources<3 else 1),-5,5)
  if near:report(sim,c,"Boletín comercial","Recursos de la ruta %d/10; tensión estimada %d/10. %s"%[c.resources,c.tension,"Se solicitan suministros y escoltas." if c.resources<3 else "Los enlaces sostienen los envíos."])
  elif sim.state.day-c.started>=28:report(sim,c,"Resumen remoto","La disputa continúa; informe agregado, sin detalle de fuerzas.")
static func finish_operation(sim,result: String):
 if not sim.state.rpg.captain.configured:return
 var system=sim.state.active.contract.get("system_id",sim.state.location_id)
 affect(sim,system,-2 if result=="success" else -1 if result=="partial" else 1,"Parte de operación: "+sim.state.active.contract.name)
static func view(sim) -> Array:
 var result=[]
 if sim.state.rpg.conflicts.regions.is_empty():return [{"title":"Situación regional","text":"Consulte a los enlaces locales para abrir el seguimiento de tránsito y abastecimiento.","actions":[sim.RPG.button("Consultar boletín local","conflict",{"action":"briefing"})]}]
 for c in sim.state.rpg.conflicts.regions.values():
  var text="%s · actores: %s · ruta: %s · recursos %d/10 · tensión estimada %d/10. Iniciado día %d. Ficción de campaña: no cambia fronteras canónicas."%[sim.Universe.system(c.system).name,", ".join(c.actors),c.status,c.resources,c.tension,c.started]
  for r in c.reports.slice(maxi(0,c.reports.size()-5)):text+="\nDía %d · %s: %s"%[r.day,r.source,r.text]
  var actions=[]
  if c.system==sim.state.location_id and c.status=="active":
   actions=[sim.RPG.button("Aportar 10 suministros · presión −2","conflict",{"action":"supply"}),sim.RPG.button("Mediar · Trato 9 · 2 días / 3.000","conflict",{"action":"mediate"}),sim.RPG.button("Investigar ruta · Investigación 9 · 2 días / 3.000","conflict",{"action":"investigate"})]
  result.append({"title":"Conflicto regional","text":text,"actions":actions})
 return result
static func valid(c: Variant,day: int) -> bool:
 if not c is Dictionary or not c.get("regions") is Dictionary:return false
 for r in c.regions.values():
  if not r is Dictionary or not r.get("system") is String or not r.get("actors") is Array or not r.get("reports") is Array or not r.get("status") in ["active","settled"]:return false
  for k in ["started","last","next_action","interventions"]:
   if not num(r.get(k),0,1000000000):return false
  if not num(r.get("tension"),0,10) or not num(r.get("resources"),0,10):return false
  for report_item in r.reports:
   if not report_item is Dictionary or not num(report_item.get("day"),0,day) or not report_item.get("source") is String or not report_item.get("text") is String:return false
 return true
static func num(v: Variant,low: int,high: int) -> bool:
 return preload("res://sim/operations.gd").integer(v,low,high)
