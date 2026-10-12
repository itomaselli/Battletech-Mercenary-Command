extends RefCounted
static func draw(host):
 var UI=host.UI
 var sim=host.sim
 if host.section=="Encargos":
  host.rpg_adapter.content=host.content
  host.rpg_adapter.delegation_form()
  host.rpg_sections(host.content,"Oficiales",func(e):return not e.title.begins_with("Delegar a "))
  return
 if host.section=="Resumen":summary(host);return
 if host.section=="Informe":debrief(host);return
 if host.section=="Batalla" and not sim.battle_view().is_empty():
  if host.preference("battle_controls")==null:host.remember("battle_controls",{})
  var panel=preload("res://ui/battle_panel.gd").new();panel.sim=sim;panel.ui_state=host.preference("battle_controls")
  panel.encounter_status.connect(func(done):host.continue_button.disabled=not done;host.one_day_button.disabled=not done)
  host.content.add_child(panel)
  panel.fit_height(maxf(340,host.scroll.size.y-95));return
 if host.section=="Batalla":
  if not sim.state.active.is_empty():host.operations_adapter.content=UI.block(host.content,"Parte de la operación");host.operations_adapter.rebuild()
  else:
   UI.text(host.content,"No hay un encuentro desplegado.")
   UI.primary(host.content,"Preparar una operación →",func():host.navigate("Operaciones","Plan"))
  return
 if host.section=="Plan":prepare(host);return
 var contracts=sim.state.offers+sim.state.missions.offers
 for o in sim.state.frontier.opportunities:
  if o.status=="open":contracts.append(o.contract)
 if not sim.state.accepted.is_empty():contracts.push_front(sim.state.accepted)
 var filters=UI.block(host.content,"Ofertas de contrato","Seleccione una oferta para ver sus condiciones.")
 var query=LineEdit.new();query.placeholder_text="Filtrar contrato o empleador";query.text=host.preference("query","");filters.add_child(query)
 var body=UI.column(host.content)
 var fill=func():
  UI.clear(body)
  var all=contracts.filter(func(c):return query.text.is_empty() or (c.name+" "+c.employer).to_lower().contains(query.text.to_lower()))
  var id=int(host.preference("contract",all[0].id if not all.is_empty() else -1))
  if not all.any(func(c):return c.id==id) and not all.is_empty():id=int(all[0].id)
  var panes=UI.split(body,host.size.x)
  var interval=UI.pager(panes[0],all.size(),maxi(0,int(all.map(func(c):return c.id).find(id)/6)),6,func(page):host.remember("page",page);host.remember("contract",all[page*6].id);host.render())
  for c in all.slice(interval[0],interval[1]):
   var b=UI.button(panes[0],"%s\n%d · %d días · %s"%[c.name,c.pay,c.days,c.employer],func():host.remember("contract",c.id);host.render())
   b.toggle_mode=true;b.button_pressed=c.id==id
  var found=all.filter(func(c):return c.id==id)
  if found.is_empty():UI.text(panes[1],"No hay ofertas que coincidan.");return
  var c=found[0]
  panes[1]=UI.block(panes[1],"Contrato seleccionado · "+c.name)
  UI.text(panes[1],"%s\n%s\nPago %d · anticipo incluido %d · mínimo %d unidades\nDuración %d días · oferta hasta día %d"%[c.employer,c.intel,c.pay,c.advance,c.min_force,c.days,c.expires])
  UI.text(panes[1],c.get("cause","")+"\n"+c.get("objective","")+"\n"+c.get("briefing",""))
  if not sim.state.accepted.is_empty():
   UI.text(panes[1],"Compromiso exclusivo: "+sim.state.accepted.name)
   UI.primary(panes[1],"Preparar fuerza →",func():host.navigate("Operaciones","Plan"))
   UI.button(panes[1],"Cancelar contrato…",func():host.cancel_contract())
  else:
   UI.primary(panes[1],"Aceptar condiciones originales y preparar →",func():
    var message="Oferta ya no disponible."
    if c.has("mission_type"):message=sim.accept_mission(c.id)
    else:
     var index=sim.state.offers.find(c)
     if index>=0:message=sim.accept_contract(index)
     else:
      for o in sim.state.frontier.opportunities:
       if o.contract.id==c.id:message=sim.accept_opportunity(o.contract.id);break
    host.report(message)
    if not sim.state.accepted.is_empty():host.navigate("Operaciones","Plan"))
   if sim.state.rpg.captain.configured:host.rpg_sections(UI.disclosure(panes[1],"Negociación"),"Contratos",func(e):return e.title=="Negociar: "+c.name)
   else:UI.text(panes[1],"Complete el trasfondo del capitán para negociar paquetes especiales.")
 query.text_changed.connect(func(q):host.remember("query",q);host.remember("page",0);fill.call());fill.call()
static func prepare(host):
 var sim=host.sim
 var UI=host.UI
 if sim.state.accepted.is_empty():UI.text(host.content,"Primero acepte un contrato.");UI.button(host.content,"Revisar contratos →",func():host.navigate("Operaciones","Contratos"));return
 if not sim.state.active.is_empty():
  UI.text(host.content,"La fuerza ya está desplegada. Ajuste sus órdenes desde Batalla.")
  UI.primary(host.content,"Abrir batalla →",func():host.navigate("Operaciones","Batalla"));return
 var mission=UI.block(host.content,"1 · Compromiso",sim.state.accepted.name)
 var force=UI.block(host.content,"2 · Fuerza de despliegue","Seleccione hasta cuatro unidades; el orden define Alfa y Bravo.")
 UI.text(mission,"Desplegar antes del día %d. Mínimo %d unidades. Máximo cuatro."%[sim.state.accepted.deadline,sim.state.accepted.min_force])
 for m in sim.state.mechs:
  var i=sim.mech_index(m.uid)
  var person=sim.pilot_for(i)
  var eligible=sim.mech_ready(i) and m.hp>=40 and not m.repair and sim.person_available(person) and not sim.deployed(i)
  if not eligible:host.selected.erase(m.uid)
  var check=CheckBox.new();check.text="%s · %d%% · %s"%[m.name,m.hp,"sin asignar" if person.is_empty() else person.name];check.disabled=not eligible;check.button_pressed=m.uid in host.selected;force.add_child(check)
  check.toggled.connect(func(on):
   if on and host.selected.size()<4:host.selected.append(m.uid)
   elif on:check.set_pressed_no_signal(false)
   else:host.selected.erase(m.uid))
 var command=UI.block(host.content,"3 · Mando y autorización")
 var doctrine=UI.picker(command,"Doctrina",{0:"Cautelosa · +1 día",1:"Equilibrada",2:"Agresiva · mayor desgaste"},host.doctrine)
 doctrine.item_selected.connect(func(i):host.doctrine=int(doctrine.get_item_metadata(i)))
 var leaders={-1:"Primera persona de la fuerza seleccionada"}
 for p in sim.state.staff:
  if p.role in ["Piloto","Dotación"]:leaders[p.id]=p.name
 var leader=UI.picker(command,"Jefe de operación",leaders,host.leader_id)
 leader.item_selected.connect(func(i):host.leader_id=int(leader.get_item_metadata(i)))
 var rules=UI.disclosure(command,"Condiciones y organización de la fuerza")
 UI.text(rules,"El cumplimiento parcial paga el importe parcial del contrato o, si no tiene uno específico, el 60% del total; el anticipo se descuenta al liquidar.")
 UI.text(rules,"Mapa de mando: Alfa agrupa las primeras dos unidades seleccionadas y Bravo las restantes. Puede pausar al inicio para enviar planes por sector, dejar reservas o delegar. La doctrina fija la actitud inicial; cautelosa permite retiradas autónomas por daños según los valores del piloto.")
 UI.primary(command,"Autorizar despliegue →",func():
  var team=[]
  for uid in host.selected:
   var index=sim.mech_index(uid)
   if index>=0:team.append(index)
  host.report(sim.dispatch_battle(team,host.doctrine,host.leader_id))
  if not sim.state.active.is_empty():host.navigate("Operaciones","Batalla"))
 UI.button(command,"Retirarse / cancelar…",func():host.cancel_contract())

static func summary(host):
 var UI=host.UI;var sim=host.sim
 var active=sim.state.active
 var situation=UI.block(host.content,"Situación operacional")
 if active.is_empty():
  UI.text(situation,"Sin fuerzas desplegadas. "+("Contrato aceptado: "+sim.state.accepted.name if not sim.state.accepted.is_empty() else "Seleccione un contrato para iniciar una operación."))
  UI.primary(situation,"Preparar fuerza →" if not sim.state.accepted.is_empty() else "Buscar contrato →",func():host.navigate("Operaciones","Plan" if not sim.state.accepted.is_empty() else "Contratos"))
 else:
  UI.text(situation,active.contract.name+" · Jefe: "+sim.person_name(active.leader))
  UI.text(situation,"Regreso estimado: %d jornadas de campaña. El reloj táctico se controla en Batalla."%active.remaining)
  var view=sim.battle_view()
  if not view.is_empty():UI.text(situation,"Objetivo %d%% · %s"%[view.progress,"Encuentro terminado; pendiente de regreso" if view.done else "Encuentro disponible"])
  UI.primary(situation,"Abrir batalla →",func():host.navigate("Operaciones","Batalla"))
  var forces=UI.block(host.content,"Fuerzas comprometidas")
  for i in active.team:UI.text(forces,sim.state.mechs[i].name+" · "+sim.pilot_for(i).name)
  UI.button(situation,"Cancelar contrato…",func():host.cancel_contract())
 var help=UI.block(host.content,"Flujo de operaciones")
 UI.text(help,"Contrato → Plan → Batalla → Regreso → Informe. El calendario de campaña gestiona los días; el reloj de batalla gestiona el encuentro.")
static func debrief(host):
 var UI=host.UI
 var entries=host.sim.operation_report().archive.duplicate();entries.reverse()
 if entries.is_empty():UI.text(host.content,"Todavía no hay operaciones cerradas. El informe aparece tras el regreso y la liquidación.");return
 var panes=UI.split(host.content,host.size.x)
 var selected=int(host.preference("operation",entries[0].id))
 if not entries.any(func(e):return e.id==selected):selected=int(entries[0].id)
 var interval=UI.pager(panes[0],entries.size(),maxi(0,int(entries.map(func(e):return e.id).find(selected)/6)),6,func(page):host.remember("page",page);host.remember("operation",entries[page*6].id);host.render())
 for e in entries.slice(interval[0],interval[1]):
  var b=UI.button(panes[0],e.contract+" · "+e.outcome,func():host.remember("operation",e.id);host.render());b.toggle_mode=true;b.button_pressed=e.id==selected
 var e=entries.filter(func(item):return item.id==selected)[0]
 var result=UI.block(panes[1],e.contract,e.outcome)
 UI.text(result,"Jefe: %s · días %d–%d"%[e.leader,e.started,e.ended])
 for loss in e.losses:UI.text(result,"%s · daño registrado %d"%[loss.name,loss.damage])
 var reports=UI.disclosure(panes[1],"Partes de la operación")
 for item in e.reports:UI.text(reports,"Día %d · %s: %s"%[item.day,item.source,item.text])
