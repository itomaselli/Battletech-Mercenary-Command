extends RefCounted
## Local recurring public contacts; distant politics remain in the existing world simulation.
static func create() -> Dictionary:
 return {"locals":{},"pending":{},"seen":[],"last":0,"pulse":0}
static func ensure(sim) -> Dictionary:
 if sim.in_transit() or not sim.local_services():return {}
 var data=sim.state.story.society
 var system=sim.state.location_id
 if not data.locals.has(system):
  var dice=RandomNumberGenerator.new();dice.seed=int(sim.state.military.seed)+int(system.hash())
  var name=["Inés","Hassan","Yuna","Mateo","Nadia","León"][dice.randi_range(0,5)]+" "+["Arden","Wu","Soler","Farah","Novak","Reyes"][dice.randi_range(0,5)]
  var event=sim.log_event("Enlace local",name+" se presenta como enlace civil de "+sim.Universe.system(system).name+". Comunica necesidades locales; no conoce el dispositivo militar enemigo.")
  data.locals[system]={"name":name,"standing":0,"credits":0,"since":int(sim.state.day),"last":int(sim.state.day),"event":event,"memory":[]}
 return data.locals[system]
static func load_count(sim) -> int:
 return sim.Story.People.pending(sim).size()+(0 if sim.state.rpg.director.pending.is_empty() else 1)+(0 if sim.state.story.society.pending.is_empty() else 1)
static func available(sim) -> bool:
 return load_count(sim)<2 and sim.state.day-sim.state.story.society.pulse>=7 and not sim.in_transit() and sim.state.active.is_empty() and sim.state.issues.is_empty() and not sim.RPG.busy(sim) and not sim.RPG.waiting(sim) and sim.state.arrears==0
static func support(sim,g: Dictionary):
 if g.kind!="community":return
 var local=ensure(sim)
 if local.is_empty() or g.system!=sim.state.location_id:return
 local.standing=mini(5,int(local.standing)+2)
 local.credits=mini(3,int(local.credits)+1)
 var event=sim.log_event("Reconocimiento local",local.name+" recuerda el apoyo sostenido: reconocimiento +2 y una ayuda recíproca disponible.",[],[],"local:"+g.system,[sim.state.story.threads["goal:%d"%g.id]])
 local.memory.append(event);local.event=event;local.last=int(sim.state.day)
static func operation(sim,result: String):
 var local=ensure(sim)
 if local.is_empty():return
 if not sim.state.active.contract.get("mission_type","") in ["defense","extraction","recon"]:return
 var delta=1 if result=="success" else 0 if result=="partial" else -1
 local.standing=clampi(int(local.standing)+delta,-5,5)
 var event=sim.log_event("Memoria local",local.name+" recibió el parte de "+sim.state.active.contract.name+"; reconocimiento local %+d."%delta,[],[],"local:"+sim.state.location_id,[sim.state.story.threads[sim.Story.operation_key(sim)]])
 local.memory.append(event);local.event=event;local.last=int(sim.state.day)
static func tick(sim):
 if not sim.state.rpg.captain.configured:return
 var local=ensure(sim)
 var d=sim.state.story.society
 if not d.pending.is_empty() and sim.state.day>d.pending.expires:
  sim.log_event("Oportunidad archivada","La comunicación local venció sin compromiso ni penalidad.",[],[],"local:"+d.pending.system,[d.pending.event])
  d.pending={}
 if local.is_empty() or not d.pending.is_empty() or not available(sim) or sim.state.day-d.last<28:return
 var system=sim.state.location_id
 var region=sim.Missions.region(sim.state.missions,system)
 var kind="aid" if local.credits>0 else "supply" if region.pressure>=4 or region.supply<=-2 else ""
 if kind.is_empty():return
 var key="%s:%s:%d"%[system,kind,local.event if kind=="aid" else int(sim.state.day/28)]
 if key in d.seen:return
 var text=local.name+(": ofrece 10 suministros como reciprocidad por su apoyo. Consume una ayuda disponible." if kind=="aid" else ": solicita 10 suministros por dificultades de abastecimiento observadas. Aportarlos reduce presión local en 1 y aumenta reconocimiento en 1.")
 var event=sim.log_event("Comunicación local",text,[],[],"local:"+system,[local.event])
 d.pending={"key":key,"kind":kind,"system":system,"text":text,"event":event,"expires":int(sim.state.day)+14}
 d.seen.append(key);d.last=int(sim.state.day);d.pulse=int(sim.state.day)
static func command(sim,args: Dictionary) -> String:
 var d=sim.state.story.society
 var p=d.pending
 if p.is_empty():return "Sin comunicación local pendiente."
 var action=str(args.get("action",""))
 if action=="decline":
  sim.log_event("Respuesta local","El capitán deja pasar la propuesta; sin penalidad.",[],[],"local:"+p.system,[p.event])
  d.pending={}
  return "Respuesta registrada."
 if action!="accept":return "Respuesta inválida."
 if sim.in_transit() or sim.state.location_id!=p.system or sim.RPG.waiting(sim):return "Regrese al sistema y resuelva las decisiones urgentes."
 var local=d.locals[p.system]
 if p.kind=="aid":
  if local.credits<=0:return "La ayuda ya no está disponible."
  local.credits-=1;sim.state.supplies+=10
 else:
  if sim.state.supplies<10:return "Se requieren 10 suministros."
  sim.state.supplies-=10
  var region=sim.Missions.region(sim.state.missions,p.system)
  region.pressure=maxi(0,int(region.pressure)-1);region.supply=mini(5,int(region.supply)+1)
  local.standing=mini(5,int(local.standing)+1)
 var event=sim.log_event("Intercambio local","%s: %s."%[local.name,"recibidos 10 suministros; una ayuda consumida" if p.kind=="aid" else "entregados 10 suministros; presión −1, abastecimiento +1, reconocimiento +1"],[],[],"local:"+p.system,[p.event])
 local.memory.append(event);local.last=int(sim.state.day)
 d.pending={}
 return "Intercambio registrado en la compañía y la memoria local."
static func valid(d: Variant,day: int) -> bool:
 if not d is Dictionary or not d.get("locals") is Dictionary or not d.get("pending") is Dictionary or not d.get("seen") is Array or not num(d.get("last"),0,day) or not num(d.get("pulse"),0,day):return false
 for system in d.locals:
  if not system is String or preload("res://sim/universe.gd").system(system).is_empty():return false
  var l=d.locals[system]
  if not l is Dictionary or not l.get("name") is String or not l.get("memory") is Array or not num(l.get("standing"),-5,5) or not num(l.get("credits"),0,3) or not num(l.get("since"),0,day) or not num(l.get("last"),0,day) or not num(l.get("event"),1,1000000000):return false
  for id in l.memory:
   if not num(id,1,1000000000):return false
 for key in d.seen:
  if not key is String:return false
 var p=d.pending
 if not p.is_empty():
  if not p.get("kind") in ["aid","supply"] or not p.get("system") is String or not d.locals.has(p.system) or not p.get("text") is String or not p.get("key") is String or not num(p.get("event"),1,1000000000) or not num(p.get("expires"),0,1000000000):return false
 return true
static func num(v: Variant,low: int,high: int) -> bool:
 return preload("res://sim/operations.gd").integer(v,low,high)
