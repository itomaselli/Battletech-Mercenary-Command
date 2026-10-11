extends RefCounted
static func draw(host):
 var UI=host.UI
 var sim=host.sim
 if host.section=="Encargos":
  host.rpg_adapter.content=host.content
  host.rpg_adapter.delegation_form()
  host.rpg_sections(host.content,"Oficiales",func(e):return not e.title.begins_with("Delegar a "))
  return
 if host.section=="En curso":host.operations_adapter.content=UI.column(host.content);host.operations_adapter.rebuild();return
 if host.section=="Preparación":prepare(host);return
 var contracts=sim.state.offers+sim.state.missions.offers
 for o in sim.state.frontier.opportunities:
  if o.status=="open":contracts.append(o.contract)
 if not sim.state.accepted.is_empty():contracts.push_front(sim.state.accepted)
 var query=LineEdit.new();query.placeholder_text="Filtrar contrato o empleador";query.text=host.preference("query","");host.content.add_child(query)
 var body=UI.column(host.content)
 var fill=func():
  UI.clear(body)
  var all=contracts.filter(func(c):return query.text.is_empty() or (c.name+" "+c.employer).to_lower().contains(query.text.to_lower()))
  var id=int(host.preference("contract",all[0].id if not all.is_empty() else -1))
  if not all.any(func(c):return c.id==id) and not all.is_empty():id=int(all[0].id)
  var panes=UI.split(body,host.size.x)
  for c in all:
   var b=UI.button(panes[0],"%s\n%d · %d días · %s"%[c.name,c.pay,c.days,c.employer],func():host.remember("contract",c.id);host.render())
   b.toggle_mode=true;b.button_pressed=c.id==id
  var found=all.filter(func(c):return c.id==id)
  if found.is_empty():UI.text(panes[1],"No hay ofertas que coincidan.");return
  var c=found[0]
  UI.text(panes[1],c.name,true)
  UI.text(panes[1],"%s\n%s\nPago %d · anticipo incluido %d · mínimo %d unidades\nDuración %d días · oferta hasta día %d"%[c.employer,c.intel,c.pay,c.advance,c.min_force,c.days,c.expires])
  UI.text(panes[1],c.get("cause","")+"\n"+c.get("objective","")+"\n"+c.get("briefing",""))
  if not sim.state.accepted.is_empty():
   UI.text(panes[1],"Compromiso exclusivo: "+sim.state.accepted.name)
   UI.button(panes[1],"Preparar fuerza →",func():host.navigate("Operaciones","Preparación"))
   UI.button(panes[1],"Cancelar contrato…",func():host.cancel_contract())
  else:
   UI.button(panes[1],"Aceptar condiciones originales y preparar →",func():
    var message="Oferta ya no disponible."
    if c.has("mission_type"):message=sim.accept_mission(c.id)
    else:
     var index=sim.state.offers.find(c)
     if index>=0:message=sim.accept_contract(index)
     else:
      for o in sim.state.frontier.opportunities:
       if o.contract.id==c.id:message=sim.accept_opportunity(o.contract.id);break
    host.report(message)
    if not sim.state.accepted.is_empty():host.navigate("Operaciones","Preparación"))
   if sim.state.rpg.captain.configured:host.rpg_sections(panes[1],"Contratos",func(e):return e.title=="Negociar: "+c.name)
   else:UI.text(panes[1],"Complete el trasfondo del capitán para negociar paquetes especiales.")
 query.text_changed.connect(func(q):host.remember("query",q);fill.call());fill.call()
static func prepare(host):
 var sim=host.sim
 var UI=host.UI
 if sim.state.accepted.is_empty():UI.text(host.content,"Primero acepte un contrato.");UI.button(host.content,"Revisar contratos →",func():host.navigate("Operaciones","Contratos"));return
 UI.text(host.content,sim.state.accepted.name,true)
 UI.text(host.content,"Desplegar antes del día %d. Mínimo %d unidades. Máximo cuatro."%[sim.state.accepted.deadline,sim.state.accepted.min_force])
 for m in sim.state.mechs:
  var i=sim.mech_index(m.uid)
  var person=sim.pilot_for(i)
  var eligible=sim.mech_ready(i) and m.hp>=40 and not m.repair and sim.person_available(person) and not sim.deployed(i)
  if not eligible:host.selected.erase(m.uid)
  var check=CheckBox.new();check.text="%s · %d%% · %s"%[m.name,m.hp,"sin asignar" if person.is_empty() else person.name];check.disabled=not eligible;check.button_pressed=m.uid in host.selected;host.content.add_child(check)
  check.toggled.connect(func(on):
   if on and host.selected.size()<4:host.selected.append(m.uid)
   elif on:check.set_pressed_no_signal(false)
   else:host.selected.erase(m.uid))
 var doctrine=UI.picker(host.content,"Doctrina",{0:"Cautelosa · +1 día",1:"Equilibrada",2:"Agresiva · mayor desgaste"},host.doctrine)
 doctrine.item_selected.connect(func(i):host.doctrine=int(doctrine.get_item_metadata(i)))
 var leaders={-1:"Primera persona de la fuerza seleccionada"}
 for p in sim.state.staff:
  if p.role in ["Piloto","Dotación"]:leaders[p.id]=p.name
 var leader=UI.picker(host.content,"Jefe de operación",leaders,host.leader_id)
 leader.item_selected.connect(func(i):host.leader_id=int(leader.get_item_metadata(i)))
 host.operations_adapter.content=UI.column(host.content);host.operations_adapter.rebuild()
 UI.button(host.content,"Autorizar despliegue →",func():
  var team=[]
  for uid in host.selected:
   var index=sim.mech_index(uid)
   if index>=0:team.append(index)
  host.report(sim.dispatch(0,team,host.doctrine,host.leader_id))
  if not sim.state.active.is_empty():host.navigate("Operaciones","En curso"))
 UI.button(host.content,"Retirarse / cancelar…",func():host.cancel_contract())
