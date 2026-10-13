extends RefCounted
static func entries(sim) -> Array:
 var items=[]
 if not sim.state.hq.request.is_empty():items.append({"id":"hq:request","title":"Propuesta para el HQ","kind":"OPCIONAL","source":"HQ","body":sim.state.hq.request.text,"target":["Mando","HQ"]})
 if sim.state.hq.debt>0:items.append({"id":"hq:debt","title":"Mantenimiento del HQ pendiente","kind":"AVISO","source":"HQ","body":"Las ventajas y obras están suspendidas. Deuda: %d C-bills."%sim.state.hq.debt,"target":["Mando","HQ"]})
 for request in sim.Story.People.pending(sim):items.append({"id":"personal:"+str(request.id),"title":sim.person_name(request.person)+": "+sim.Story.People.GOALS[request.goal],"kind":"OPCIONAL","source":sim.person_name(request.person),"body":sim.Story.People.offer_text(request)+" Puede aplazar 7 días o rechazar (confianza −1). Sin respuesta caduca sin penalidad el día %d."%request.expires,"personal":request})
 var local=sim.state.story.society.pending
 if not local.is_empty():items.append({"id":"local:"+local.key,"title":"Comunicación del enlace civil","kind":"OPCIONAL","source":sim.Universe.system(local.system).name,"body":local.text+" Disponible hasta el día %d; ignorarla no castiga."%local.expires,"local":local})
 for issue in sim.state.issues:items.append({"id":"issue:"+str(issue.id),"title":issue.text,"kind":"DECISIÓN","source":"Estado mayor","body":issue.text,"issue":issue})
 if sim.military_waiting():items.append({"id":"military","title":"El jefe de campo solicita órdenes","kind":"DECISIÓN","source":sim.person_name(sim.state.active.leader),"body":"Hay un contacto que requiere su respuesta. Consulte el parte conocido antes de ordenar.","target":["Operaciones","En curso"]})
 if not sim.state.rpg.scene.is_empty():items.append({"id":"scene","title":"Escena del capitán pendiente","kind":"DECISIÓN","source":"Capitán","body":"El calendario espera su decisión.","rpg":"Escena"})
 for j in sim.state.rpg.delegation.jobs:
  if j.status=="consult":items.append({"id":"job:"+str(j.id),"title":"Consulta de "+j.name,"kind":"DECISIÓN","source":j.name,"body":"Cotización %d; umbral %d; presupuesto %d."%[j.quote,j.threshold,j.budget],"job":j})
 if sim.state.rpg.arcs.retired:items.append({"id":"retired","title":"Retiro voluntario","kind":"PAUSA","source":"Capitán","body":"Puede reanudar la campaña desde su legado.","target":["Capitán","Legado"]})
 if not sim.state.rpg.director.pending.is_empty():items.append({"id":"invitation","title":"Invitación del equipo","kind":"OPCIONAL","source":"Compañía","body":sim.state.rpg.director.pending.text,"rpg":"Memoria"})
 for m in sim.state.mechs:
  if m.hp<90 or sim.state.rpg.workshop.faults.has(str(m.uid)):items.append({"id":"unit:"+str(m.uid),"title":m.name+" requiere atención","kind":"AVISO","source":"Taller","body":"Integridad %d%%. Revise costes y alternativas antes de comprometerla."%m.hp,"uid":m.uid})
 for i in range(sim.state.chronicle.size()-1,maxi(-1,sim.state.chronicle.size()-201),-1):
  var e=sim.state.chronicle[i];items.append({"id":"log:"+str(i),"title":e.kind+" · "+e.date,"kind":"INFORME","source":e.kind,"body":e.text,"when":e.date})
 for item in items:
  if not item.has("when"):item["when"]="Estado actual · "+sim.date_text()
 var prioritized=[]
 for kind in ["DECISIÓN","PAUSA","AVISO","OPCIONAL","INFORME"]:
  prioritized.append_array(items.filter(func(item):return item.kind==kind))
 return prioritized
static func draw(host):
 var UI=host.UI
 var records=entries(host.sim)
 var categories={"all":"Todo","decision":"Requiere decisión","operations":"Operaciones","company":"Compañía","archive":"Archivo"}
 var filters=UI.picker(host.content,"Mostrar comunicaciones",categories,host.preference("filter","all"))
 filters.item_selected.connect(func(i):host.remember("filter",filters.get_item_metadata(i));host.remember("page",0);host.remember("entry","");host.render())
 var category=str(host.preference("filter","all"))
 var all=records.filter(func(e):
  var operation=e.id=="military" or e.source in ["Parte operacional","Resultado","Radio","Orden","Orden de despliegue"]
  return category=="all" or category=="decision" and e.kind=="DECISIÓN" or category=="operations" and operation or category=="archive" and e.kind=="INFORME" or category=="company" and not operation)
 var selected=str(host.preference("entry",all[0].id if not all.is_empty() else ""))
 if not all.any(func(e):return e.id==selected) and not all.is_empty():selected=all[0].id
 var panes=[host.content,host.contextual("COMUNICACIÓN SELECCIONADA")]
 var interval=UI.pager(panes[0],all.size(),maxi(0,int(all.map(func(e):return e.id).find(selected)/6)),6,func(page):host.remember("page",page);host.remember("entry",all[page*6].id);host.render())
 for item in all.slice(interval[0],interval[1]):
  var b=UI.button(panes[0],"%s · %s\n%s"%[item.kind,item.source,item.title.left(90)],func():host.remember("entry",item.id);host.render())
  b.toggle_mode=true;b.button_pressed=item.id==selected
 var found=all.filter(func(e):return e.id==selected)
 if found.is_empty():UI.text(panes[1],"Sin informes pendientes.");return
 var e=found[0]
 panes[1]=UI.block(panes[1],e.kind+" · "+e.source,e.when+"\n"+e.title)
 UI.text(panes[1],e.body)
 if e.has("local"):
  for spec in [["Aceptar intercambio","accept"],["Dejar pasar · sin penalidad","decline"]]:host.action(panes[1],spec[0],func():return host.sim.rpg_command("story_local",{"action":spec[1]}))
 elif e.has("personal"):
  for spec in [["Dar apoyo","support"],["Retomar en 7 días","defer"],["Rechazar · confianza −1","decline"]]:host.action(panes[1],spec[0],func():return host.sim.rpg_command("story_people",{"action":spec[1],"id":e.personal.id}))
 elif e.has("issue"):
  var options={"deadline":[["Mantener compromiso","continue"],["Cancelar y devolver anticipo","cancel"]],"medical":[["Atención especializada · 2.000","care"],["Tratamiento habitual","standard"]],"team_conflict":[["Mediar · 2 días","mediate"],["Separar asignaciones","separate"]],"salary":[["Pagar deuda salarial","pay"],["Aceptar salida; deuda permanece","release"]]}
  for spec in options.get(e.issue.kind,[]):host.action(panes[1],spec[0],func():return host.sim.resolve_issue(e.issue.id,spec[1]))
 elif e.has("job"):
  for spec in [["Aprobar dentro del presupuesto","approve"],["Cancelar y devolver saldo","cancel"]]:host.action(panes[1],spec[0],func():return host.sim.rpg_command("delegation",{"action":spec[1],"id":e.job.id}))
 elif e.has("uid"):UI.button(panes[1],"Revisar alternativas de taller →",func():host.navigate("Compañía","Taller");host.remember("uid",e.uid);host.render())
 elif e.has("target"):UI.button(panes[1],"Abrir expediente →",func():host.navigate(e.target[0],e.target[1]))
 elif e.has("rpg"):host.rpg_sections(panes[1],e.rpg)
