extends RefCounted
# Optional campaign subsystem: no random draws from the combat RNG.
const MODULES={
 "workshop":{"name":"Taller de diagnóstico","effect":"Trabajo técnico +5% / +8%; requiere técnicos disponibles.","price":35000},
 "storage":{"name":"Control de inventario","effect":"Suministros de mantenimiento −3% / −5%; no afecta combate.","price":25000},
 "medical":{"name":"Enfermería y rehabilitación","effect":"Recuperación de lesiones en base +5% / +8%; equipo médico incluido.","price":35000},
 "quarters":{"name":"Camarotes y descanso","effect":"Recuperación de fatiga en base +5% / +8%.","price":25000},
 "simulator":{"name":"Simuladores de entrenamiento","effect":"Cursos de siete días: 1 experiencia y progreso adicional +5% / +8%.","price":40000},
 "intelligence":{"name":"Sala de análisis","effect":"Coste de consultas a contactos −5% / −8%. Sin información adicional.","price":35000},
 "comms":{"name":"Comunicaciones logísticas","effect":"Coste de pedidos urgentes −5% / −8%. No modifica órdenes de batalla.","price":30000},
 "salvage":{"name":"Banco de recuperación","effect":"Coste de procesamiento de lotes −5% / −8%. No aumenta botín.","price":35000}}
static func create() -> Dictionary:
 return {"stage":"none","path":"","name":"Hogar errante","origin":"","officer":-1,"acquired":-1,"wins":0,"seen":[],"sponsor":"","sponsor_wins":0,"credit":0,"survey_left":0,"refit_left":0,"modules":{},"project":{},"training":{},"trained":{},"fractions":{},"accrued":0,"debt":0,"reserve":false,"history":[],"promises":{},"request":{},"asked":[],"last_request":-30,"crew":[{"name":"Mara Sorel","role":"Capitana de la Union"},{"name":"Elias Brenner","role":"Jefe de máquinas"},{"name":"Nadia Sol","role":"Oficial médica"}]}
static func note(sim,text: String,people: Array=[]):
 var h=sim.state.hq
 h.history.append({"day":int(sim.state.day),"text":text})
 sim.log_event("HQ",text,people,[],"hq")
static func active(sim) -> bool:
 var h=sim.state.hq
 return h.stage=="owned" and not h.reserve and h.debt==0
static func rate(sim,id: String) -> int:
 if not active(sim):return 0
 var level=int(sim.state.hq.modules.get(id,0))
 return ([0,3,5] if id=="storage" else [0,5,8])[level]
static func extra(sim,id: String,key: String,base: int) -> int:
 var percent=rate(sim,id)
 if percent==0 or base<=0:return 0
 var h=sim.state.hq;var tag=id+":"+key
 var value=int(h.fractions.get(tag,0))+base*percent
 h.fractions[tag]=value%100
 return int(value/100)
static func price(sim,id: String,base: int) -> int:
 return ceili(base*(100-rate(sim,id))/100.0)
static func daily(sim) -> int:
 var h=sim.state.hq
 if h.stage!="owned":return 0
 if h.reserve:return 100
 var cost=400
 for level in h.modules.values():cost+=40*int(level)
 return cost
static func forecast(sim) -> Dictionary:
 var h=sim.state.hq;var remaining=30-int(sim.state.day)%30
 return {"daily":daily(sim),"accrued":h.accrued,"debt":h.debt,"next_bill":int(h.accrued)+int(h.debt)+daily(sim)*remaining,"days":remaining}
static func eligible(sim) -> bool:
 return sim.state.day>=60 and sim.state.reputation>=4 and sim.state.hq.wins>=4
static func reserve_required(sim) -> int:return sim.monthly_payroll()*2+12000
static func local(sim) -> bool:return not sim.in_transit() and sim.local_services() and sim.state.active.is_empty()
static func spend(sim,cost: int,detail: String) -> bool:
 if sim.available_funds()<cost:return false
 sim.state.funds-=cost;sim._record_transaction("HQ",-cost,detail);return true
static func operation(sim,contract: Dictionary,success: bool,payment: int):
 var h=sim.state.hq;var key="%s:%s:%d"%[contract.id,contract.name,sim.state.day]
 if key in h.seen:return
 h.seen.append(key)
 if success:h.wins+=1
 if not success or h.path!="reward" or h.stage!="pledged" or contract.employer!=h.sponsor:return
 h.sponsor_wins+=1
 var amount=mini(180000-int(h.credit),mini(50000,mini(maxi(0,payment),sim.available_funds())))
 if amount>0:
  spend(sim,amount,"Cesión pactada al patrocinador");h.credit+=amount
 note(sim,"Patrocinio de %s: %d/3 éxitos, %d/180000 C-bills cedidos. Esta operación aportó %d."%[h.sponsor,h.sponsor_wins,h.credit,amount])
static func command(sim,args: Dictionary) -> String:
 if sim.state.ended:return "La campaña ha terminado."
 var h=sim.state.hq;var action=str(args.get("action",""))
 if action=="rename":
  if h.stage!="owned" or not sim._valid_name(args.get("name")):return "Nombre inválido o HQ no adquirido."
  if h.name==args.name:return "Nombre sin cambios."
  h.name=args.name;note(sim,"La tripulación bautiza su hogar: "+h.name);return "Nombre registrado."
 if action=="officer":
  var id=int(args.get("id",-1));var p=sim.person_by_id(id)
  if h.stage!="owned" or p.is_empty() or not sim.person_available(p) or sim.personnel_deployed(id):return "Se necesita un empleado disponible en base."
  if h.officer==id:return "Ya es el enlace del HQ."
  h.officer=id;note(sim,p.name+" asume el enlace de la compañía con la tripulación naval.",[id]);return "Responsable asignado; conserva sus tareas habituales."
 if action=="pay":
  if h.debt<=0:return "No hay deuda del HQ."
  var amount=mini(int(h.debt),sim.available_funds())
  if amount<=0:return "Sin fondos libres."
  spend(sim,amount,"Regularización del HQ");h.debt-=amount;note(sim,"Deuda del HQ abonada: %d."%amount);return "Pago registrado."
 if action=="reserve":
  if h.stage!="owned":return "HQ no adquirido."
  h.reserve=not h.reserve;note(sim,"HQ en reserva: proyectos y ventajas suspendidos." if h.reserve else "HQ reactivado; requiere estar al día con sus pagos.");return "Estado actualizado."
 if action=="respond":return respond(sim,str(args.get("choice","")))
 if action=="train":return train(sim,int(args.get("id",-1)))
 if action=="cancel_training":
  var key=str(int(args.get("id",-1)))
  if not h.training.has(key):return "No hay curso."
  h.training.erase(key);note(sim,"Curso cancelado sin reembolso.");return "Personal liberado."
 if not local(sim):return "Requiere estar en un sistema con servicios, sin traslado ni operación activa."
 if action=="inspect":
  if h.stage!="none" or not eligible(sim):return "Requiere día 60, reputación 4 y cuatro operaciones cumplidas."
  if not spend(sim,10000,"Inspección de Union usada"):return "Inspección: 10000 C-bills libres."
  h.stage="inspected";note(sim,"Inspección: Union usada con casco certificado; necesita rehabilitación. Compra 450000; existe vía de patrocinio o recuperación. No incluye capacidad de salto.");return "Informe de inspección disponible."
 if action in ["buy","pledge","survey"]:
  if h.stage!="inspected":return "Primero inspeccione; la ruta ya iniciada no puede cambiarse."
  if action=="buy":
   if sim.available_funds()<450000+reserve_required(sim):return "Necesita 450000 más reserva de dos nóminas y 12000 C-bills."
   spend(sim,450000,"Compra y rehabilitación de Union");h.path="purchase";h.stage="refit";h.refit_left=14;h.origin="Comprada usada mediante corredor en "+str(sim.Universe.system(sim.state.location_id).name);note(sim,"Compra autorizada. Rehabilitación: 14 días de astillero.");return "Union comprada; entrega pendiente."
  if action=="pledge":
   var employer=str(args.get("employer",""));var known=sim.state.offers.any(func(c):return c.employer==employer)
   if not known:return "Seleccione un empleador de las ofertas vigentes."
   h.path="reward";h.stage="pledged";h.sponsor=employer
   note(sim,"Patrocinio firmado con %s: tres éxitos nuevos y 180000 C-bills cedidos de liquidaciones positivas (máximo 50000 por éxito). Rehabilitación final: 60000. Sin cesión tras la entrega."%employer);return "Acuerdo firmado; no acepta contratos automáticamente."
  var count=0
  for lot in sim.state.rpg.negotiation.salvage:
   if lot.status=="processed":count+=1
  if count<3:return "La red de recuperadores requiere tres lotes ya procesados."
  if not spend(sim,20000,"Prospección de casco Union"):return "Prospección: 20000 C-bills."
  h.path="recovery";h.stage="survey";h.survey_left=14
  note(sim,"La red de recuperadores inicia prospección y comprobación de derechos sobre una Union abandonada: 14 días. No es una nave obtenida de los lotes de máquinas.");return "Prospección encargada."
 if action=="claim":
  if h.stage=="pledged" and h.sponsor_wins>=3 and h.credit>=180000:
   if sim.available_funds()<60000+reserve_required(sim):return "Necesita 60000 y la reserva operativa."
   spend(sim,60000,"Rehabilitación del HQ concedido");h.origin="Concedida por "+h.sponsor;h.refit_left=14
  elif h.stage=="located":
   if sim.available_funds()<160000+reserve_required(sim):return "Necesita 160000 y la reserva operativa."
   spend(sim,160000,"Rescate y rehabilitación de Union");h.origin="Recuperada mediante prospección y derechos de salvamento";h.refit_left=21
  else:return "Aún no reúne las condiciones de entrega."
  h.stage="refit";note(sim,"Transferencia autorizada: "+h.origin);return "Rehabilitación iniciada."
 if action in ["upgrade","remove","cancel_project"]:
  if h.stage!="owned":return "Adquiera el HQ primero."
  if action=="cancel_project":
   if h.project.is_empty():return "No hay obra."
   note(sim,"Obra cancelada sin reembolso: "+MODULES[h.project.id].name);h.project={};return "Espacio liberado."
  var id=str(args.get("module",""))
  if not MODULES.has(id):return "Instalación inválida."
  if not h.project.is_empty():return "Termine o cancele la obra actual primero."
  if action=="remove":
   if not h.modules.has(id):return "Instalación ausente."
   if id=="simulator" and not h.training.is_empty():return "Termine o cancele los cursos primero."
   h.modules.erase(id)
   for key in h.fractions.keys():
    if key.begins_with(id+":"):h.fractions.erase(key)
   note(sim,"Desmontada sin reembolso: "+MODULES[id].name);return "Espacio disponible."
  if not active(sim):return "HQ en reserva o con deuda; no puede modernizar."
  var level=int(h.modules.get(id,0))
  if level>=2:return "Nivel máximo alcanzado."
  if level==0 and h.modules.size()>=4:return "Cuatro espacios ocupados; desmonte otra instalación."
  var cost=int(MODULES[id].price)*(level+1)
  if not spend(sim,cost,"Modernización: "+MODULES[id].name):return "Fondos libres insuficientes."
  h.project={"id":id,"level":level+1,"left":7+level*3,"cost":cost}
  note(sim,"Autorizada "+MODULES[id].name+"; avance solo en puerto, con HQ activo. El responsable coordina la obra.");return "Proyecto financiado."
 return "Acción de HQ no disponible."
static func train(sim,id: int) -> String:
 var h=sim.state.hq;var p=sim.person_by_id(id);var key=str(id)
 if rate(sim,"simulator")==0 or p.is_empty() or not p.role in ["Piloto","Dotación"] or not sim.person_available(p) or sim.personnel_deployed(id):return "Requiere simulador activo y piloto/dotación disponible en base."
 if not h.training.is_empty():return "El simulador ya tiene un curso."
 if int(h.trained.get(key,-30))+30>sim.state.day:return "Una matrícula por persona cada 30 días."
 if not spend(sim,1000,"Curso de simulador: "+p.name):return "Curso: 1000 C-bills."
 h.training[key]={"left":7};h.trained[key]=int(sim.state.day);note(sim,p.name+" inicia siete jornadas de simulador; no estará disponible para desplegar.",[id]);return "Curso iniciado."
static func respond(sim,choice: String) -> String:
 var h=sim.state.hq
 if h.request.is_empty() or not choice in ["support","later","decline"]:return "Petición o respuesta inválida."
 var r=h.request;var p=sim.person_by_id(int(r.person))
 var text={"support":"El comandante prioriza la propuesta; debe financiar la obra en Instalaciones.","later":"El comandante aplaza la propuesta; queda archivada para reconsiderarla.","decline":"El comandante rechaza la propuesta sin penalización automática."}[choice]
 note(sim,text+" Motivo: "+r.text,[int(r.person)] if not p.is_empty() else [])
 if choice=="support":h.promises[r.module]={"person":int(r.person),"status":"pending"}
 if not p.is_empty():sim._remember(p,"HQ: "+text)
 h.request={};return "Decisión registrada; no se gastaron fondos automáticamente."
static func tick(sim):
 var h=sim.state.hq
 if h.stage=="survey" and local(sim):
  h.survey_left-=1
  if h.survey_left==0:h.stage="located";note(sim,"Prospección completada: derechos de recuperación verificados. Rehabilitación disponible por 160000 y 21 días.")
 if h.stage=="refit" and local(sim):
  h.refit_left-=1
  if h.refit_left==0:
   h.stage="owned";h.acquired=int(sim.state.day)
   note(sim,"Ceremonia de entrega: %s, Union reacondicionada. El emblema de %s identifica el nuevo hogar. %s presenta a su tripulación."%[h.name,sim.state.company_name,h.crew[0].name])
 if h.stage!="owned":return
 if h.officer>=0 and sim.person_by_id(int(h.officer)).is_empty():h.officer=-1;note(sim,"El puesto de enlace del HQ quedó vacante.")
 h.accrued+=daily(sim)
 if sim.state.day%30==0:
  var due=int(h.accrued)+int(h.debt);var amount=mini(due,sim.available_funds())
  spend(sim,amount,"Tripulación y mantenimiento del HQ");h.debt=due-amount;h.accrued=0
  if h.debt>0:note(sim,"Deuda del HQ: %d. Ventajas y proyectos suspendidos hasta regularizar; la nave permanece en propiedad."%h.debt)
 if not active(sim):return
 if not h.project.is_empty() and local(sim):
  h.project.left-=1
  if h.project.left==0:
   var id=h.project.id
   h.modules[id]=h.project.level;note(sim,"Instalación terminada: %s, nivel %d."%[MODULES[id].name,h.project.level])
   if h.promises.has(id) and h.promises[id].status=="pending":
    h.promises[id].status="fulfilled"
    var person=sim.person_by_id(int(h.promises[id].person))
    note(sim,"Compromiso cumplido: "+MODULES[id].name,[int(h.promises[id].person)])
    if not person.is_empty():sim.Story.People.remember(sim,person.id,"El comandante cumplió la mejora prometida del HQ: "+MODULES[id].name)
   h.project={}
 for key in h.training.keys():
  var p=sim.person_by_id(int(key))
  if p.is_empty():h.training.erase(key);note(sim,"Curso cancelado por salida del alumno.");continue
  if p.injury>0 or sim.personnel_deployed(int(key)):continue
  h.training[key].left-=1
  if h.training[key].left==0:
   sim._gain_experience(p,1+extra(sim,"simulator",key,1),"Curso en el HQ")
   h.training.erase(key);note(sim,p.name+" completó el curso de simulador.",[int(key)])
 requests(sim)
static func requests(sim):
 var h=sim.state.hq
 if not h.request.is_empty() or sim.state.day<h.last_request+30:return
 var id="";var person=-1;var reason=""
 for p in sim.state.staff:
  if p.injury>0 and not h.modules.has("medical") and not "medical" in h.asked:id="medical";person=p.id;reason=p.name+" sigue recuperándose de sus lesiones; solicita rehabilitación a bordo.";break
  if p.role in ["Técnico","Jefa técnica"] and not sim.state.repair_queue.is_empty() and not h.modules.has("workshop") and not "workshop" in h.asked:id="workshop";person=p.id;reason=p.name+" propone diagnóstico de taller ante la cola de reparaciones.";break
  if p.fatigue>=40 and not h.modules.has("quarters") and not "quarters" in h.asked:id="quarters";person=p.id;reason=p.name+" pide mejores espacios de descanso después del esfuerzo acumulado.";break
 if id.is_empty():return
 h.request={"module":id,"person":int(person),"text":reason,"day":int(sim.state.day)};h.asked.append(id);h.last_request=int(sim.state.day);note(sim,reason,[person])
static func integer(v,minimum: int=0,maximum: int=1000000000) -> bool:
 return (v is int or v is float) and v==int(v) and v>=minimum and v<=maximum
static func valid(h,day: int) -> bool:
 if not h is Dictionary:return false
 var template=create()
 for key in template:
  if not h.has(key) or typeof(h[key])!=typeof(template[key]) and not (template[key] is int and integer(h[key],-1000000000)):return false
 if not h.stage in ["none","inspected","pledged","survey","located","refit","owned"] or not h.path in ["","purchase","reward","recovery"]:return false
 if h.name.strip_edges().is_empty() or h.name.length()>48:return false
 for i in range(h.name.length()):
  if h.name.unicode_at(i)<32:return false
 for key in ["wins","sponsor_wins","credit","survey_left","refit_left","accrued","debt"]:
  if not integer(h[key]):return false
 if h.credit>180000 or not integer(h.officer,-1) or not integer(h.acquired,-1,day) or not integer(h.last_request,-30,day):return false
 if h.modules.size()>4 or h.training.size()>1:return false
 if h.stage=="owned" and (h.acquired<0 or h.path.is_empty()):return false
 if h.stage!="owned" and (not h.modules.is_empty() or not h.project.is_empty() or not h.training.is_empty()):return false
 if h.stage in ["pledged","survey","located","refit"] and h.path.is_empty():return false
 if h.stage=="pledged" and (h.path!="reward" or h.sponsor.is_empty()):return false
 if h.stage=="survey" and (h.path!="recovery" or not integer(h.survey_left,1,14)):return false
 if h.stage=="located" and h.path!="recovery":return false
 if h.stage=="refit" and not integer(h.refit_left,1,21):return false
 for id in h.modules:
  if not MODULES.has(id) or not integer(h.modules[id],1,2):return false
 if not h.project.is_empty():
  var p=h.project
  if not MODULES.has(p.get("id")):return false
  if not integer(p.get("level"),1,2) or not integer(p.get("left"),1,10) or not integer(p.get("cost"),1):return false
  if p.level!=int(h.modules.get(p.id,0))+1 or p.cost!=MODULES[p.id].price*p.level:return false
  if not h.modules.has(p.id) and h.modules.size()>=4:return false
 for key in h.fractions:
  if not key is String or not MODULES.has(key.get_slice(":",0)) or not integer(h.fractions[key],0,99):return false
 for key in h.training:
  if not key is String or not key.is_valid_int() or not h.training[key] is Dictionary or not integer(h.training[key].get("left"),1,7) or not h.modules.has("simulator"):return false
 for key in h.trained:
  if not key is String or not key.is_valid_int() or not integer(h.trained[key],0,day):return false
 for e in h.history:
  if not e is Dictionary or not integer(e.get("day"),0,day) or not e.get("text") is String:return false
 for key in h.seen:
  if not key is String:return false
 var seen=[]
 for key in h.seen:
  if key in seen:return false
  seen.append(key)
 for key in h.asked:
  if not MODULES.has(key):return false
 for id in h.promises:
  var promise=h.promises[id]
  if not MODULES.has(id) or not promise is Dictionary or not integer(promise.get("person")) or not promise.get("status") in ["pending","fulfilled"]:return false
 if h.crew!=template.crew:return false
 if not h.request.is_empty():
  var r=h.request
  if not MODULES.has(r.get("module")) or not integer(r.get("person"),0) or not r.get("text") is String or not integer(r.get("day"),0,day):return false
 return true
