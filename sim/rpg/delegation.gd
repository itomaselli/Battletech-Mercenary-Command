extends RefCounted
const OBJECTIVES={"supply":"Conseguir suministros", "liaison":"Representar a la compañía", "security":"Apoyar seguridad regional"}
static func create() -> Dictionary:
 return {"jobs":[],"archive":[],"next":1,"reputation":{}}
static func waiting(sim) -> bool:
 return sim.state.rpg.delegation.jobs.any(func(j):return j.status=="consult")
static func command(sim,args: Dictionary) -> String:
 var d=sim.state.rpg.delegation
 var action=str(args.get("action",""))
 if not sim.state.rpg.captain.configured:return "Complete el trasfondo."
 if action in ["approve","cancel"]:
  for j in d.jobs:
   if j.id!=int(args.get("id",-1)):continue
   if action=="cancel":finish(sim,j,false,"Encargo cancelado; presupuesto no gastado devuelto.");return "Encargo cancelado."
   if j.status!="consult":return "El encargo no espera consulta."
   if j.quote>j.budget:return "La cotización supera el presupuesto máximo; cancele y formule otro encargo."
   j.status="working"
   j.due=int(sim.state.day)+1
   var p=sim.person_by_id(j.person)
   if not p.is_empty():p.rest_until=maxi(p.rest_until,j.due)
   return "Excepción autorizada dentro del presupuesto; informe en un día."
  return "Encargo no encontrado."
 if action!="assign" or sim.in_transit():return "Encargo local no disponible."
 var p=sim.person_by_id(int(args.get("person",-1)))
 if p.is_empty() or not sim.person_available(p) or sim.personnel_deployed(p.id):return "Oficial no disponible."
 var objective=str(args.get("objective",""))
 var authority=str(args.get("authority","consult"))
 var budget=int(args.get("budget",8000))
 var threshold=int(args.get("threshold",3000))
 var days=int(args.get("days",5))
 var contact=str(args.get("contact",""))
 if not objective in OBJECTIVES or not authority in ["consult","delegate"] or budget<3000 or budget>20000 or threshold<0 or threshold>budget or days<4 or days>14 or not contact in sim.RPG.Agenda.known(sim):return "Objetivo, presupuesto, plazo o enlace inválido."
 var uid=int(args.get("uid",-1))
 if objective=="security":
  var i=sim.mech_index(uid)
  if i<0 or not sim.mech_ready(i) or sim.deployed(i) or sim.state.mechs[i].repair or sim.state.mechs[i].hp<40:return "Seguridad requiere una unidad disponible como reserva logística; no combate táctico."
 if not sim.RPG.spend(sim,budget,"Depósito para encargo de "+p.name):return "Fondos libres insuficientes."
 var value=sim.state.rpg.social.ties.get(str(p.id),{}).get("value","cumplir")
 var aligned=(value=="mantener" and objective=="supply") or (value=="proteger" and objective=="security") or (value=="cumplir" and objective=="liaison")
 var quote=maxi(3000,8000-int(p.skill)*700-(700 if aligned else 0))
 var j={"id":int(d.next),"person":int(p.id),"name":p.name,"objective":objective,"authority":authority,"budget":budget,"threshold":threshold,"deadline":int(sim.state.day)+days,"due":int(sim.state.day)+3,"status":"travel","quote":quote,"contact":contact,"system":sim.state.location_id,"uid":uid if objective=="security" else -1}
 d.next+=1
 d.jobs.append(j)
 p.rest_until=int(sim.state.day)+days
 if objective=="security":sim.state.rpg.workshop.reserved.append(uid)
 sim.RPG.note(sim,"Delegación","%s recibe %s: depósito %d, consulta por encima de %d, autoridad %s, plazo día %d."%[p.name,OBJECTIVES[objective],budget,threshold,authority,j.deadline])
 return "Encargo delegado; personal y medios quedan reservados. El presupuesto sin utilizar se devuelve al cerrar."
static func finish(sim,j: Dictionary,success: bool,reason: String):
 var d=sim.state.rpg.delegation
 if not j in d.jobs:return
 var spent=int(j.quote) if success else 0
 var refund=int(j.budget)-spent
 sim.state.funds+=refund
 sim._record_transaction("Depósito",refund,"Saldo devuelto del encargo de "+j.name)
 var p=sim.person_by_id(j.person)
 if not p.is_empty():p.rest_until=int(sim.state.day)
 if j.uid>=0:sim.state.rpg.workshop.reserved.erase(j.uid)
 if not d.reputation.has(j.contact):d.reputation[j.contact]={"reliability":0,"discretion":0}
 var rep=d.reputation[j.contact]
 if success:
  rep.reliability=mini(5,rep.reliability+1)
  match j.objective:
   "supply":sim.state.supplies+=10
   "liaison":
    rep.discretion=mini(5,rep.discretion+1)
    if not sim.state.rpg.agenda.contacts.has(j.contact):sim.state.rpg.agenda.contacts[j.contact]={"favors":0,"last":int(sim.state.day),"system":j.system}
    var c=sim.state.rpg.agenda.contacts[j.contact]
    c.favors=mini(3,c.favors+1)
   "security":sim.RPG.Conflicts.affect(sim,j.system,-2,"Informe de "+j.name)
 elif sim.state.day>j.deadline:rep.reliability=maxi(-5,rep.reliability-1)
 d.jobs.erase(j)
 var entry=j.duplicate(true)
 entry["finished"]=int(sim.state.day)
 entry["success"]=success
 entry["reason"]=reason
 d.archive.append(entry)
 sim.RPG.note(sim,"Informe de "+j.name,"%s: %s. Gastado %d; devuelto %d."%[OBJECTIVES[j.objective],reason,spent,refund])
static func tick(sim):
 for j in sim.state.rpg.delegation.jobs.duplicate():
  var p=sim.person_by_id(j.person)
  if p.is_empty() or p.injury>0:finish(sim,j,false,"Personal ausente o incapacitado");continue
  if sim.state.day>j.deadline:finish(sim,j,false,"Plazo vencido");continue
  if j.due>sim.state.day or j.status=="consult":continue
  if j.status=="travel" and (j.quote>j.budget or j.authority=="consult" and j.quote>j.threshold):
   j.status="consult"
   sim.RPG.note(sim,"Consulta de "+j.name,"El proveedor solicita %d; supera el umbral autorizado %d. Aprobar dentro del depósito o cancelar."%[j.quote,j.threshold])
  else:finish(sim,j,true,"Objetivo cumplido con los medios autorizados")
static func view(sim) -> Array:
 var d=sim.state.rpg.delegation
 var result=[]
 for j in d.jobs:
  var actions=[sim.RPG.button("Cancelar y devolver depósito no gastado","delegation",{"action":"cancel","id":j.id})]
  if j.status=="consult":actions.push_front(sim.RPG.button("Autorizar cotización %d dentro del depósito"%j.quote,"delegation",{"action":"approve","id":j.id}))
  result.append({"title":"Encargo de "+j.name,"text":"%s · %s · máximo %d · umbral %d · vence día %d"%[OBJECTIVES[j.objective],j.status,j.budget,j.threshold,j.deadline],"actions":actions})
 for person_id in sim.state.rpg.circle:
  var p=sim.person_by_id(person_id)
  if p.is_empty():continue
  var actions=[]
  var contacts=sim.RPG.Agenda.known(sim)
  if contacts.is_empty():continue
  var contact=contacts[0]
  for objective in OBJECTIVES:
   var uid=-1
   if objective=="security":
    for i in range(sim.state.mechs.size()):
     if sim.mech_ready(i) and not sim.deployed(i):uid=int(sim.state.mechs[i].uid);break
   for authority in ["consult","delegate"]:actions.append(sim.RPG.button("%s · %s · 8.000 máximo / 3.000 umbral / 5 días"%[OBJECTIVES[objective],"consultar excepciones" if authority=="consult" else "resolver dentro del máximo"],"delegation",{"action":"assign","person":p.id,"objective":objective,"authority":authority,"budget":8000,"threshold":3000,"days":5,"contact":contact,"uid":uid}))
  result.append({"title":"Delegar a "+p.name,"text":"Enlace: "+contact+". Capacidad profesional determina la cotización obtenida. Los compromisos reservan al oficial y, en seguridad, una unidad.","actions":actions})
 for contact in d.reputation:result.append({"title":"Reputación ante "+contact,"text":"Fiabilidad %d · discreción %d. Distinta de los vínculos personales del capitán."%[d.reputation[contact].reliability,d.reputation[contact].discretion],"actions":[]})
 return result
static func valid(d: Variant,day: int) -> bool:
 if not d is Dictionary or not d.get("jobs") is Array or not d.get("archive") is Array or not d.get("reputation") is Dictionary or not num(d.get("next"),1,1000000000):return false
 for j in d.jobs+d.archive:
  if not j is Dictionary or not j.get("objective") in OBJECTIVES or not j.get("authority") in ["consult","delegate"] or not j.get("status") in ["travel","consult","working"]:return false
  for k in ["id","person","budget","threshold","deadline","due","quote"]:
   if not num(j.get(k),0,1000000000):return false
  for k in ["name","contact","system"]:
   if not j.get(k) is String:return false
  if not num(j.get("uid"),-1,1000000) or j.threshold>j.budget:return false
 for r in d.reputation.values():
  if not r is Dictionary or not num(r.get("reliability"),-5,5) or not num(r.get("discretion"),-5,5):return false
 return true
static func num(v: Variant,low: int,high: int) -> bool:
 return preload("res://sim/operations.gd").integer(v,low,high)
