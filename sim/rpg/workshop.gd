extends RefCounted
static func create() -> Dictionary:
 return {"parts":{"mobility":0,"electronics":0},"faults":{},"jobs":[],"reserved":[],"support_until":0,"policy":{"cash":0,"supplies":0,"routine":false},"last_order":-14}
static func blocked(sim,uid: int) -> bool:
 var w=sim.state.rpg.workshop
 if sim.state.rpg.delegation.jobs.any(func(j):return j.uid==uid):return true
 if uid in w.reserved or w.jobs.any(func(j):return j.get("uid",-1)==uid):return true
 var f=w.faults.get(str(uid),{})
 return not f.is_empty() and f.temporary_until<=sim.state.day
static func tech(sim) -> int:
 for p in sim.state.staff:
  if (p.role=="Técnico" or p.role=="Jefa técnica") and sim.person_available(p) and not sim.personnel_deployed(p.id):return int(p.id)
 return -1
static func command(sim,args: Dictionary) -> String:
 var w=sim.state.rpg.workshop
 var action=str(args.get("action",""))
 if not sim.state.rpg.captain.configured or sim.in_transit():return "Taller RPG no disponible."
 if action=="policy":
  var cash=int(args.get("cash",0))
  var supplies=int(args.get("supplies",0))
  if not cash in [0,50000,100000] or not supplies in [0,30,60]:return "Política inválida."
  w.policy={"cash":cash,"supplies":supplies,"routine":bool(args.get("routine",false))}
  return "Política guardada: solo compras automáticas de suministros, máximo una cada 14 días y respetando caja mínima."
 if action=="buy_parts":
  var kind=str(args.get("kind",""))
  if not kind in w.parts:return "Categoría inválida."
  if not sim.RPG.spend(sim,4000,"Repuesto: "+kind):return "Fondos insuficientes."
  w.parts[kind]+=1
  return "Un repuesto comprado por 4.000."
 if action=="support":
  if w.support_until>sim.state.day:return "Ya tiene apoyo vigente."
  if not sim.RPG.spend(sim,12000,"Subcontrato de apoyo local por siete días"):return "Fondos insuficientes."
  w.support_until=int(sim.state.day)+7
  return "Apoyo local contratado: −2 daño por máquina al resolver operaciones iniciadas dentro de siete días. No sustituye la fuerza mínima."
 if action=="salvage":
  var id=str(args.get("id",""))
  for lot in sim.state.rpg.negotiation.salvage:
   if lot.id!=id:continue
   if lot.system!=sim.state.location_id or not lot.status in ["rights","assessed"]:return "Lote no disponible aquí o trabajo en curso."
   var technician=tech(sim)
   if technician<0:return "Se necesita un técnico libre."
   if not sim.RPG.spend(sim,3000 if lot.status=="rights" else sim.HQ.price(sim,"salvage",2000),"Salvamento "+id):return "Fondos insuficientes."
   w.jobs.append({"kind":"assess" if lot.status=="rights" else "process","lot":id,"uid":-1,"person":technician,"due":int(sim.state.day)+2})
   lot.status="transit"
   sim.person_by_id(technician).rest_until=int(sim.state.day)+2
   return "Transporte/evaluación o procesamiento encargado: dos días."
  return "Lote no encontrado."
 var uid=int(args.get("uid",-1))
 var index=sim.mech_index(uid)
 if index<0 or sim.deployed(index):return "Unidad ausente o desplegada."
 var m=sim.state.mechs[index]
 if sim.state.rpg.delegation.jobs.any(func(j):return j.uid==uid):return "Unidad comprometida en un encargo; cancele o espere su cierre."
 if w.jobs.any(func(j):return j.uid==uid) or m.repair:return "Hay trabajo de taller pendiente en esta máquina."
 if action=="reserve":
  if uid in w.reserved:w.reserved.erase(uid)
  else:w.reserved.append(uid)
  return "Reserva actualizada; una unidad reservada no se puede desplegar."
 if action=="cannibalize":
  if m.hp<=0:return "No queda material aprovechable."
  m.hp=0
  w.parts.mobility+=1
  w.parts.electronics+=1
  w.faults[str(uid)]={"kind":"mobility","temporary_until":0}
  sim.RPG.note(sim,"Canibalización","%s #%d desmontado: integridad cero; recuperados un repuesto de movilidad y uno electrónico."%[m.name,uid])
  return "Máquina desmontada; deberá reconstruirla para volver a usarla."
 if not action in ["full","temporary"]:return "Acción no disponible."
 var f=w.faults.get(str(uid),{})
 if f.is_empty():return "Sin avería funcional; use el taller normal para integridad."
 if m.stored:return "Reactive la unidad antes de intervenir."
 if action=="temporary" and (m.hp<40 or f.temporary_until>sim.state.day):return "El arreglo exige integridad mínima 40 y no se puede renovar antes de vencer."
 var technician=tech(sim)
 if technician<0:return "Se necesita un técnico libre."
 var count=2 if action=="full" else 0
 if w.parts[f.kind]<count:return "La reparación completa requiere dos repuestos de la categoría afectada."
 if not sim.RPG.spend(sim,6000 if action=="full" else 2000,"Taller funcional: "+action):return "Fondos insuficientes."
 w.parts[f.kind]-=count
 var days=3 if action=="full" else 1
 w.jobs.append({"kind":action,"uid":uid,"lot":"","person":technician,"due":int(sim.state.day)+days})
 sim.person_by_id(technician).rest_until=int(sim.state.day)+days
 return "Trabajo encargado; técnico y máquina quedan reservados."
static func tick(sim):
 var w=sim.state.rpg.workshop
 for j in w.jobs.duplicate():
  if j.due>sim.state.day:continue
  w.jobs.erase(j)
  var p=sim.person_by_id(j.person)
  if p.is_empty() or p.injury>0:
   for lot in sim.state.rpg.negotiation.salvage:
    if lot.id==j.lot:lot.status="rights" if j.kind=="assess" else "assessed"
   sim.RPG.note(sim,"Taller","Trabajo interrumpido por ausencia del técnico; el gasto ya realizado no se recupera.")
   continue
  if j.kind in ["assess","process"]:
   for lot in sim.state.rpg.negotiation.salvage:
    if lot.id!=j.lot:continue
    lot.status="assessed" if j.kind=="assess" else "processed"
    if j.kind=="process":w.parts.mobility+=1;w.parts.electronics+=1
   sim.RPG.note(sim,"Salvamento",j.lot+": "+("evaluado; contiene un repuesto de cada categoría" if j.kind=="assess" else "dos repuestos incorporados al inventario"))
  else:
   var i=sim.mech_index(j.uid)
   if i<0:continue
   if j.kind=="full":w.faults.erase(str(j.uid));sim.state.mechs[i].hp=100
   elif w.faults.has(str(j.uid)):w.faults[str(j.uid)].temporary_until=int(sim.state.day)+7
   sim.RPG.note(sim,"Taller","%s #%d: %s"%[p.name,j.uid,"reparación completa" if j.kind=="full" else "arreglo provisional habilitado por siete días; conserva integridad actual"])
 if w.policy.routine and sim.state.supplies<w.policy.supplies and sim.state.day-w.last_order>=14 and sim.state.orders.is_empty() and not sim.in_transit():
  var q=sim.supply_quote(false)
  if sim.available_funds()-int(q.cost)>=w.policy.cash:
   sim.order_supplies(false)
   w.last_order=int(sim.state.day)
static func finish(sim):
 if not sim.state.rpg.captain.configured:return
 var w=sim.state.rpg.workshop
 for i in sim.state.active.team:
  var m=sim.state.mechs[i]
  if m.hp<65 and not w.faults.has(str(m.uid)):
   w.faults[str(m.uid)]={"kind":"mobility" if m.uid%2==0 else "electronics","temporary_until":0}
   sim.RPG.note(sim,"Diagnóstico","%s #%d: avería de %s tras daños; requiere arreglo provisional o reparación funcional."%[m.name,m.uid,w.faults[str(m.uid)].kind])
static func view(sim) -> Array:
 var w=sim.state.rpg.workshop
 var actions=[]
 for kind in w.parts:actions.append(sim.RPG.button("Comprar repuesto "+kind+" · 4.000","workshop",{"action":"buy_parts","kind":kind}))
 actions.append(sim.RPG.button("Subcontratar apoyo local · 7 días · 12.000","workshop",{"action":"support"}))
 actions.append(sim.RPG.button("Política prudente: caja 50.000 / suministros 30 / compra rutinaria","workshop",{"action":"policy","cash":50000,"supplies":30,"routine":true}))
 actions.append(sim.RPG.button("Política manual: suspender compras automáticas","workshop",{"action":"policy"}))
 var result=[{"title":"Taller y políticas","text":"Repuestos: movilidad %d / electrónica %d. Política: caja %d, suministros %d, automático %s. Solo aplica a compras rutinarias; órdenes manuales prevalecen. Apoyo contratado hasta día %d."%[w.parts.mobility,w.parts.electronics,w.policy.cash,w.policy.supplies,str(w.policy.routine),w.support_until],"actions":actions}]
 for m in sim.state.mechs:
  var f=w.faults.get(str(m.uid),{})
  actions=[sim.RPG.button("Alternar reserva de unidad","workshop",{"action":"reserve","uid":m.uid}),sim.RPG.button("Canibalizar · integridad a CERO · obtiene dos repuestos","workshop",{"action":"cannibalize","uid":m.uid})]
  if not f.is_empty():
   actions.append(sim.RPG.button("Reparar completamente · 3 días / 6.000 / 2 repuestos","workshop",{"action":"full","uid":m.uid}))
   actions.append(sim.RPG.button("Arreglo por 7 días · 1 día / 2.000 / integridad actual","workshop",{"action":"temporary","uid":m.uid}))
  result.append({"title":"Taller: "+m.name,"text":"#%d · reserva %s · %s"%[m.uid,str(m.uid in w.reserved),"sin avería funcional" if f.is_empty() else "avería "+f.kind+"; provisional hasta día "+str(f.temporary_until)],"actions":actions})
 for lot in sim.state.rpg.negotiation.salvage:
  result.append({"title":"Lote "+lot.id,"text":lot.source+" · "+lot.status,"actions":[sim.RPG.button("Transportar/evaluar · 3000, 2 días / procesar · %d, 2 días"%sim.HQ.price(sim,"salvage",2000),"workshop",{"action":"salvage","id":lot.id})] if lot.status in ["rights","assessed"] else []})
 return result
static func valid(w: Variant,day: int) -> bool:
 if not w is Dictionary or not w.get("parts") is Dictionary or not w.get("faults") is Dictionary or not w.get("jobs") is Array or not w.get("reserved") is Array or not w.get("policy") is Dictionary:return false
 for k in ["mobility","electronics"]:
  if not num(w.parts.get(k),0,1000000):return false
 if not num(w.get("support_until"),0,1000000000) or not num(w.get("last_order"),-14,day):return false
 if not num(w.policy.get("cash"),0,100000) or not num(w.policy.get("supplies"),0,60) or not w.policy.get("routine") is bool:return false
 if not int(w.policy.cash) in [0,50000,100000] or not int(w.policy.supplies) in [0,30,60]:return false
 for f in w.faults.values():
  if not f is Dictionary or not f.get("kind") in ["mobility","electronics"] or not num(f.get("temporary_until"),0,1000000000):return false
 for j in w.jobs:
  if not j is Dictionary or not j.get("kind") in ["full","temporary","assess","process"] or not num(j.get("uid"),-1,1000000) or not num(j.get("person"),0,1000000) or not num(j.get("due"),day+1,day+3) or not j.get("lot") is String:return false
 return true
static func num(v: Variant,low: int,high: int) -> bool:
 return preload("res://sim/operations.gd").integer(v,low,high)
