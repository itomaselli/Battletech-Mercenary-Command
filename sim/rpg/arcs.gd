extends RefCounted
const TITLES={"independencia":"Compañía independiente", "prestigio":"Un nombre respetado", "proteccion":"Una comunidad segura", "deuda":"Saldar una deuda personal"}
static func create() -> Dictionary:
 return {"current":{},"completed":[],"retired":false,"settings":{"economy":100,"danger":100,"frequency":14}}
static func ready(sim) -> bool:
 var a=sim.state.rpg.arcs.current
 if a.is_empty() or a.status!="open":return false
 match a.kind:
  "independencia":return sim.available_funds()>=300000 and sim.state.arrears==0 and sim.state.contract_debt==0 and sim.state.ownership_debt==0 and sim.state.day-a.started>=30 and sim.state.mechs.filter(func(m):return m.hp>=60 and not m.stored).size()>=2
  "prestigio":return sim.state.reputation>=5 and sim.state.military.archive.size()-a.operations>=3 and sim.state.rpg.delegation.reputation.values().any(func(r):return r.reliability>=3)
  "proteccion":return sim.state.rpg.conflicts.regions.get(a.system,{}).get("status","")=="settled" and sim.state.rpg.adventures.cases.any(func(c):return c.system==a.system and c.family=="asylum" and c.status=="closed" and c.outcome!="abandonado")
  "deuda":return a.paid>=50000
 return false
static func command(sim,args: Dictionary) -> String:
 var arcs=sim.state.rpg.arcs
 var action=str(args.get("action",""))
 if action=="settings":
  var economy=int(args.get("economy",arcs.settings.economy))
  var danger=int(args.get("danger",arcs.settings.danger))
  var frequency=int(args.get("frequency",arcs.settings.frequency))
  if not economy in [80,100,120] or not danger in [80,100,120] or not frequency in [7,14,28]:return "Ajuste inválido."
  arcs.settings={"economy":economy,"danger":danger,"frequency":frequency}
  sim.RPG.note(sim,"Preferencias","Mantenimiento futuro %d%%, daño de próximos despliegues %d%%, invitaciones cada %d días elegibles. No modifica salarios ni contratos vigentes."%[economy,danger,frequency])
  return "Preferencias guardadas."
 if action=="continue":arcs.retired=false;return "La campaña abierta continúa; el cierre del arco permanece en la memoria."
 if arcs.retired:return "Reanude la campaña antes de cambiar de arco."
 if not sim.state.rpg.captain.configured:return "Establezca el trasfondo."
 var a=arcs.current
 if action=="choose":
  var kind=str(args.get("kind",""))
  if not kind in TITLES:return "Arco inválido."
  if not a.is_empty() and a.status=="open":return "Cierre o abandone el arco actual antes de elegir otro."
  arcs.current={"kind":kind,"system":sim.state.location_id,"started":int(sim.state.day),"operations":sim.state.military.archive.size(),"paid":0,"status":"open"}
  sim.RPG.note(sim,"Arco personal",TITLES[kind]+" en "+sim.Universe.system(sim.state.location_id).name+". Compromiso elegido desde hoy, sin reconstruir historia previa."+(" El capitán reconoce una deuda personal de 50.000, sin interés; se paga voluntariamente." if kind=="deuda" else ""))
  return "Arco elegido; consulte los requisitos visibles para concluirlo."
 if a.is_empty():return "Elija un arco personal."
 if action=="pay":
  var amount=int(args.get("amount",10000))
  if a.kind!="deuda" or a.status!="open" or a.paid>=50000 or not amount in [5000,10000,25000]:return "Pago no disponible."
  amount=mini(amount,50000-int(a.paid))
  if not sim.RPG.spend(sim,amount,"Deuda personal elegida por el capitán"):return "Fondos libres insuficientes."
  a.paid+=amount
  sim.RPG.note(sim,"Deuda personal","Abonados %d; saldo %d."%[amount,50000-a.paid])
  return "Pago registrado."
 if action=="abandon" and a.status=="open":a.status="abandoned";sim.RPG.note(sim,"Arco",TITLES[a.kind]+": dejado atrás. No se recuperan recursos gastados.");return "Arco abandonado."
 if action=="close":
  if not ready(sim):return "Todavía no cumple los requisitos del arco."
  a.status="closed"
  arcs.completed.append({"kind":a.kind,"day":int(sim.state.day),"system":a.system,"started":a.started})
  sim.RPG.Social.milestone(sim,"arc:"+a.kind,2)
  sim.RPG.note(sim,"Legado",TITLES[a.kind]+": arco concluido por decisión del capitán. Puede continuar o retirarse voluntariamente.")
  return "Arco cerrado. Su historia continúa si usted lo decide."
 if action=="retire":
  if a.status!="closed" or sim.RPG.busy(sim) or sim.RPG.waiting(sim) or not sim.state.accepted.is_empty() or not sim.state.rpg.delegation.jobs.is_empty():return "Cierre el arco y termine los compromisos antes de retirarse."
  arcs.retired=true
  sim.RPG.note(sim,"Retiro","El capitán elige cerrar esta etapa. El calendario queda detenido; puede continuar esta misma campaña desde Legado.")
  return "Retiro registrado. Campaña conservada y reanudable."
 return "Acción no disponible."
static func view(sim) -> Array:
 var arcs=sim.state.rpg.arcs
 var a=arcs.current
 var actions=[]
 var text="Elija qué significa una campaña satisfactoria para su capitán. Puede continuar tras concluir un arco; no hay muerte permanente ni sucesión automática."
 if a.is_empty() or a.status!="open":
  for kind in TITLES:actions.append(sim.RPG.button("Elegir arco: "+TITLES[kind],"arcs",{"action":"choose","kind":kind}))
 if not a.is_empty():
  text+="\n%s · %s · desde día %d · %s"%[TITLES[a.kind],a.status,a.started,sim.Universe.system(a.system).name]
  text+="\n"+{"independencia":"Requiere 30 días desde la elección, 300.000 libres, cero deuda salarial/contractual/hangar y dos unidades al 60% o más sin almacenar.","prestigio":"Requiere reputación global 5, tres operaciones archivadas desde la elección y fiabilidad 3 ante un enlace.","proteccion":"Requiere cerrar la disputa en este sistema y resolver allí una petición de protección.","deuda":"Deuda voluntariamente reconocida: 50.000. Abonado: %d."%a.paid}[a.kind]
  if a.status=="open":
   actions.append(sim.RPG.button("Concluir arco · "+("requisitos cumplidos" if ready(sim) else "requisitos pendientes"),"arcs",{"action":"close"}))
   actions.append(sim.RPG.button("Abandonar este objetivo","arcs",{"action":"abandon"}))
   if a.kind=="deuda":
    for amount in [5000,10000,25000]:actions.append(sim.RPG.button("Abonar %d de deuda personal"%amount,"arcs",{"action":"pay","amount":amount}))
  elif a.status=="closed":actions.append(sim.RPG.button("Retirarse voluntariamente · pausa reanudable","arcs",{"action":"retire"}))
 if arcs.retired:actions=[sim.RPG.button("Continuar campaña abierta","arcs",{"action":"continue"})];text+="\nRETIRO VOLUNTARIO: calendario detenido."
 var result=[{"title":"Legado del capitán","text":text,"actions":actions}]
 actions=[]
 for value in [80,100,120]:
  actions.append(sim.RPG.button("Mantenimiento futuro: %d%%"%value,"arcs",{"action":"settings","economy":value}))
  actions.append(sim.RPG.button("Daño de próximos despliegues: %d%%"%value,"arcs",{"action":"settings","danger":value}))
 for days in [7,14,28]:actions.append(sim.RPG.button("Invitaciones narrativas cada %d días elegibles"%days,"arcs",{"action":"settings","frequency":days}))
 result.append({"title":"Preferencias de campaña","text":"Mantenimiento %d%% · daño %d%% · frecuencia %d días. Ajustes separados, sin cambiar salarios, deudas anteriores, cláusulas aceptadas ni amenazas ocultas."%[arcs.settings.economy,arcs.settings.danger,arcs.settings.frequency],"actions":actions})
 return result
static func valid(a: Variant,day: int) -> bool:
 if not a is Dictionary or not a.get("current") is Dictionary or not a.get("completed") is Array or not a.get("retired") is bool or not a.get("settings") is Dictionary:return false
 for key in ["economy","danger","frequency"]:
  if not num(a.settings.get(key),0,120):return false
 if not int(a.settings.economy) in [80,100,120] or not int(a.settings.danger) in [80,100,120] or not int(a.settings.frequency) in [7,14,28]:return false
 var c=a.current
 if not c.is_empty():
  if not c.get("kind") in TITLES or not c.get("status") in ["open","closed","abandoned"] or not c.get("system") is String or not num(c.get("started"),0,day) or not num(c.get("operations"),0,1000000) or not num(c.get("paid"),0,50000):return false
 if a.retired and (c.is_empty() or c.status!="closed"):return false
 for entry in a.completed:
  if not entry is Dictionary or not entry.get("kind") in TITLES or not entry.get("system") is String or not num(entry.get("day"),0,day) or not num(entry.get("started"),0,day):return false
 return true
static func num(v: Variant,low: int,high: int) -> bool:
 return preload("res://sim/operations.gd").integer(v,low,high)
