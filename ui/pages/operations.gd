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
 var contract=sim.state.accepted
 if host.preference("plan_contract",-1)!=contract.id:
  host.remember("plan_contract",contract.id);host.remember("step",0);host.selected.clear();host.leader_id=-1
 host.selected=host.selected.filter(func(uid):return eligible(sim,uid))
 var step=int(host.preference("step",0))
 var steps=HBoxContainer.new();host.content.add_child(steps)
 UI.button(steps,"1 · Contrato",func():host.navigate("Operaciones","Contratos"))
 for i in range(3):
  var button=UI.button(steps,["2 · Fuerza","3 · Plan","4 · Confirmar"][i],func():host.remember("step",i);host.render())
  button.size_flags_horizontal=Control.SIZE_EXPAND_FILL;button.toggle_mode=true;button.button_pressed=step==i
  button.disabled=i>0 and host.selected.size()<contract.min_force
 for b in steps.get_children():b.size_flags_horizontal=Control.SIZE_EXPAND_FILL;b.custom_minimum_size.x=120
 var mission=UI.block(host.content,contract.name,"Mínimo %d · máximo 4 unidades · desplegar antes del día %d"%[contract.min_force,contract.deadline])
 if step==0:
  UI.text(mission,"Seleccione la fuerza. Las primeras dos unidades formarán Alfa y las siguientes Bravo.")
  var panes=UI.workspace(host.content,host,1.8,1.0)
  var grid=GridContainer.new();grid.columns=2;grid.add_theme_constant_override("h_separation",12);grid.add_theme_constant_override("v_separation",12);panes[0].add_child(grid)
  UI.text(panes[1],"Fuerza seleccionada",true)
  var next=UI.primary(panes[1],"Continuar al plan →",func():host.remember("step",1);host.render())
  next.disabled=host.selected.size()<contract.min_force
  var count=UI.text(panes[1],"Seleccionadas: %d / 4"%host.selected.size())
  for m in sim.state.mechs:
   var card=UI.block(grid,m.name)
   UI.unit_icon(card,sim.MECH_CATALOG[m.model])
   var person=sim.pilot_for(sim.mech_index(m.uid))
   UI.text(card,"Integridad %d%% · %s"%[m.hp,"Sin piloto / dotación" if person.is_empty() else person.name])
   var check=CheckBox.new();check.text="Incluir en la fuerza" if eligible(sim,m.uid) else "No disponible para desplegar";check.disabled=not eligible(sim,m.uid);check.button_pressed=m.uid in host.selected;card.add_child(check)
   check.toggled.connect(func(on):
    if on and host.selected.size()<4:host.selected.append(m.uid)
    elif on:check.set_pressed_no_signal(false)
    else:host.selected.erase(m.uid)
    count.text="Seleccionadas: %d / 4"%host.selected.size();next.disabled=host.selected.size()<contract.min_force)
 elif step==1:
  var command=UI.block(host.content,"Plan y mando")
  var doctrine=UI.picker(command,"Doctrina",{0:"Cautelosa · +1 día",1:"Equilibrada",2:"Agresiva · mayor desgaste"},host.doctrine)
  doctrine.item_selected.connect(func(i):host.doctrine=int(doctrine.get_item_metadata(i)))
  var leaders={-1:"Primera persona de la fuerza seleccionada"}
  for uid in host.selected:
   var p=sim.pilot_for(sim.mech_index(uid))
   if not p.is_empty():leaders[p.id]=p.name
  if not leaders.has(host.leader_id):host.leader_id=-1
  var leader=UI.picker(command,"Jefe de operación",leaders,host.leader_id)
  leader.item_selected.connect(func(i):host.leader_id=int(leader.get_item_metadata(i)))
  UI.text(command,"La doctrina fija la actitud inicial. En batalla dará órdenes por grupo y sector; los subordinados ejecutan las maniobras.")
  UI.primary(host.content,"Revisar despliegue →",func():host.remember("step",2);host.render())
 else:
  var review=UI.block(host.content,"Revisión antes del despliegue")
  for i in range(host.selected.size()):
   var m=sim.state.mechs[sim.mech_index(host.selected[i])]
   UI.text(review,"%s · %s · %s · %d%%"%["Alfa" if i<2 else "Bravo",m.name,sim.pilot_for(sim.mech_index(m.uid)).name,m.hp])
  UI.text(review,"Doctrina: %s · Jefe: %s"%[["Cautelosa","Equilibrada","Agresiva"][host.doctrine],"Primera persona seleccionada" if host.leader_id<0 else sim.person_name(host.leader_id)])
  UI.text(review,"Pago total: %d · anticipo: %d. El anticipo se descuenta al liquidar. Cumplimiento parcial: importe contractual o 60%% del total si no está especificado."%[contract.pay,contract.advance])
  var authorize=UI.primary(host.content,"Autorizar despliegue →",func():
   var team=[]
   for uid in host.selected:
    if not eligible(sim,uid):host.report("La disponibilidad cambió. Revise la fuerza.");return
    team.append(sim.mech_index(uid))
   host.report(sim.dispatch_battle(team,host.doctrine,host.leader_id))
   if not sim.state.active.is_empty():host.navigate("Operaciones","Batalla"))
  authorize.disabled=host.selected.size()<contract.min_force
 if step>0:UI.button(host.content,"← Paso anterior",func():host.remember("step",step-1);host.render())
 if step>0:UI.button(UI.disclosure(host.content,"Revisar compromiso contractual"),"Retirarse / cancelar…",func():host.cancel_contract())

static func eligible(sim,uid) -> bool:
 var i=sim.mech_index(uid)
 if i<0:return false
 var m=sim.state.mechs[i]
 return sim.mech_ready(i) and m.hp>=40 and not m.repair and sim.person_available(sim.pilot_for(i)) and not sim.deployed(i)

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
