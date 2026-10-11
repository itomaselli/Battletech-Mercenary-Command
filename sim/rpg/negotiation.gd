extends RefCounted
const PACKAGES={"cash":"Liquidez: 40% de anticipo, pago −8%", "pay":"Remuneración: pago +8%, anticipo 10%", "transport":"Transporte local cubierto: 8.000, pago −10%", "salvage":"Derechos sobre repuestos: pago −10%", "insurance":"Cobertura de reparación hasta 6.000: pago −6%"}
static func create() -> Dictionary:
 return {"drafts":{},"settled":[],"salvage":[]}
static func offer(sim,id: int) -> Dictionary:
 for o in sim.state.offers+sim.state.missions.offers:
  if o.id==id and o.expires>sim.state.day:return o
 return {}
static func quote(sim,id: int,package: String,favor: bool=false) -> Dictionary:
 var o=offer(sim,id)
 if o.is_empty() or not package in PACKAGES:return {}
 var relation=int(sim.state.relationships.get(o.employer,0))
 var influence=int(sim.state.rpg.captain.skills.trato)+relation+(2 if favor else 0)+int(sim.state.rpg.delegation.reputation.get(o.employer,{}).get("reliability",0))
 var permitted=package!="pay" or influence>=4
 var factor={"cash":0.92,"pay":1.08,"transport":0.9,"salvage":0.9,"insurance":0.94}[package]
 var terms={"package":package,"pay":int(o.pay*factor),"advance":0,"transport":8000 if package=="transport" else 0,"salvage":package=="salvage","coverage":6000 if package=="insurance" else 0,"employer":o.employer,"id":id,"expires":int(o.expires),"system":sim.state.location_id,"allowed":permitted,"favor":favor}
 terms.advance=int(terms.pay*(0.4 if package=="cash" else 0.1 if package=="pay" else 0.25))
 return terms
static func command(sim,args: Dictionary) -> String:
 if not sim.state.rpg.captain.configured or sim.in_transit():return "Negociación local no disponible."
 var n=sim.state.rpg.negotiation
 var id=int(args.get("id",-1))
 var key=str(id)
 var action=str(args.get("action",""))
 if not sim.state.accepted.is_empty():return "Ya existe un compromiso exclusivo: complete o cancele antes de aceptar otro."
 if action=="negotiate":
  if n.drafts.has(key):return "Las condiciones ya están pactadas para esta oferta."
  var use_favor=bool(args.get("favor",false))
  var q=quote(sim,id,str(args.get("package","")),use_favor)
  if q.is_empty():return "Oferta o paquete no disponible."
  var contact=sim.state.rpg.agenda.contacts.get(q.employer,{})
  if use_favor and contact.get("favors",0)<1:return "No tiene un favor de este enlace."
  if not q.allowed:return "El empleador no acepta mayor pago: requiere Trato + relación + favor (2) de al menos 4. Pruebe otra distribución de riesgos."
  if use_favor:contact.favors-=1
  n.drafts[key]=q
  sim.RPG.note(sim,"Negociación","%s: %s. Total %d, anticipo %d descontado al liquidar. Vigente hasta día %d."%[q.employer,PACKAGES[q.package],q.pay,q.advance,q.expires])
  return "Condiciones pactadas. Revise y acepte antes del vencimiento."
 if action=="accept":
  if not n.drafts.has(key):return "Negocie primero las condiciones."
  var q=n.drafts[key]
  if q.expires<=sim.state.day or q.system!=sim.state.location_id or offer(sim,id).is_empty():return "Acuerdo vencido o fuera de ubicación."
  var result=""
  if id>=200000000:result=sim.accept_mission(id)
  else:
   for index in range(sim.state.offers.size()):
    if sim.state.offers[index].id==id: result=sim.accept_contract(index);break
  if sim.state.accepted.is_empty():return result
  var c=sim.state.accepted
  var delta=int(q.advance)-int(c.advance)+int(q.transport)
  c.pay=int(q.pay)
  c.advance=int(q.advance)
  c.partial_pay=int(c.pay*0.6)
  c.failure_pay=int(c.pay*0.15)
  c["terms"]=q.duplicate(true)
  sim.state.funds+=delta
  sim._record_transaction("Negociación",delta,"Ajuste de anticipo y transporte local comprometido")
  sim.RPG.note(sim,"Compromiso","Cláusulas congeladas. Desplegar antes del día %d; ocupación estimada %d días. Transporte es reembolso local no recuperable; anticipo se devuelve al cancelar."%[c.deadline,c.days])
  return "Contrato negociado aceptado; no puede superponerse con otro."
 return "Acción no disponible."
static func begin(sim):
 if not sim.state.active.contract.has("terms"):return
 var hp={}
 for i in sim.state.active.team:hp[str(sim.state.mechs[i].uid)]=int(sim.state.mechs[i].hp)
 sim.state.active["rpg_start_hp"]=hp
static func finish(sim,result: String):
 var op=sim.state.active
 var c=op.get("contract",{})
 if not c.has("terms"):return
 var n=sim.state.rpg.negotiation
 if c.id in n.settled:return
 n.settled.append(c.id)
 var t=c.terms
 var damage=0
 for i in op.team:damage+=maxi(0,int(op.get("rpg_start_hp",{}).get(str(sim.state.mechs[i].uid),sim.state.mechs[i].hp))-int(sim.state.mechs[i].hp))
 var refund=mini(int(t.coverage),damage*100)
 if refund>0:
  sim.state.funds+=refund
  sim._record_transaction("Cobertura",refund,"Daño sufrido durante "+c.name)
 if t.salvage and result in ["success","partial"]:
  n.salvage.append({"id":str(c.id)+":parts","contract":int(c.id),"source":c.name,"system":sim.state.location_id,"status":"rights","kind":"parts","day":int(sim.state.day)})
 sim.RPG.note(sim,"Cláusulas","%s: cobertura liquidada %d. %s"%[c.name,refund,"Derechos sobre un lote de repuestos; requiere transporte y evaluación." if t.salvage and result!="failure" else "Sin nuevos derechos de salvamento."])
static func view(sim) -> Array:
 var result=[]
 if not sim.state.accepted.is_empty():
  var c=sim.state.accepted
  result.append({"title":"Compromiso vigente","text":"%s · pago %d · anticipo %d · límite de despliegue día %d. Exclusivo hasta su resolución."%[c.name,c.pay,c.advance,c.deadline],"actions":[]})
 for o in sim.state.offers+sim.state.missions.offers:
  var actions=[]
  var text="%s · mínimo %d máquinas · %d días de operación · oferta vence día %d. Fondos libres actuales: %d. El anticipo forma parte del pago; fracasar puede generar devolución."%[o.employer,o.min_force,o.days,o.expires,sim.available_funds()]
  var draft=sim.state.rpg.negotiation.drafts.get(str(o.id),{})
  if not draft.is_empty():
   text+="\nPACTADO: pago %d · anticipo %d · transporte %d · cobertura %d · salvamento %s"%[draft.pay,draft.advance,draft.transport,draft.coverage,str(draft.salvage)]
   actions.append(sim.RPG.button("Aceptar estas condiciones · plazo de despliegue 5 días","negotiation",{"action":"accept","id":o.id}))
  else:
   for package in PACKAGES:
    var q=quote(sim,o.id,package)
    if q.is_empty():continue
    actions.append(sim.RPG.button("%s · total %d / anticipo %d"%[PACKAGES[package],q.pay,q.advance],"negotiation",{"action":"negotiate","id":o.id,"package":package}))
   if sim.state.rpg.agenda.contacts.get(o.employer,{}).get("favors",0)>0:actions.append(sim.RPG.button("Pedir mayor pago usando un favor","negotiation",{"action":"negotiate","id":o.id,"package":"pay","favor":true}))
  result.append({"title":"Negociar: "+o.name,"text":text,"actions":actions})
 return result
static func valid(n: Variant,day: int) -> bool:
 if not n is Dictionary or not n.get("drafts") is Dictionary or not n.get("settled") is Array or not n.get("salvage") is Array:return false
 for d in n.drafts.values():
  if not terms_valid(d):return false
 for s in n.salvage:
  if not s is Dictionary or not s.get("id") is String or not s.get("source") is String or not s.get("system") is String or not s.get("status") in ["rights","transit","assessed","processed"] or s.get("kind")!="parts" or not num(s.get("day"),0,day) or not num(s.get("contract"),0,1000000000):return false
 return true
static func terms_valid(t: Variant) -> bool:
 if not t is Dictionary or not t.get("package") in PACKAGES or not t.get("salvage") is bool or not t.get("allowed") is bool or not t.get("favor") is bool or not t.get("employer") is String or not t.get("system") is String:return false
 for k in ["pay","advance","transport","coverage","id","expires"]:
  if not num(t.get(k),0,1000000000):return false
 return t.advance<=t.pay and t.coverage<=6000 and t.transport<=8000
static func num(v: Variant,low: int,high: int) -> bool:
 return preload("res://sim/operations.gd").integer(v,low,high)
