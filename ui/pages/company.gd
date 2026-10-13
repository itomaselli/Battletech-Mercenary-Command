extends RefCounted
static func draw(host):
 var UI=host.UI;var sim=host.sim
 var personal=host.section=="Personal"
 var all=sim.state.staff+sim.state.alumni if personal else sim.state.mechs
 if host.section=="Hangar":all=all.filter(func(m):return sim.MECH_CATALOG[m.model].kind==host.preference("kind","mech"))
 var info=host.contextual("ESTADO DEL PERSONAL" if personal else "ESTADO DE LA FUERZA")
 UI.text(info,"%d expedientes"%all.size(),true)
 UI.text(info,"Seleccione una tarjeta para consultar su situación, su historia y las acciones disponibles.")
 UI.muted(info,"Los vínculos y acontecimientos se conservan en cada expediente; no se pierde su historia al cambiar de pantalla.")
 var key="id" if personal else "uid"
 var chosen=int(host.preference(key,-1))
 var found=all.filter(func(e):return e[key]==chosen)
 var steps=HBoxContainer.new();host.content.add_child(steps)
 var list_button=UI.button(steps,"1 · Plantilla" if personal else "1 · Unidades",func():host.remember("sheet",false);host.render())
 list_button.toggle_mode=true;list_button.button_pressed=not host.preference("sheet",false)
 var detail_button=UI.button(steps,"2 · Expediente" if personal else "2 · Ficha de unidad",func():host.remember("sheet",true);host.render())
 detail_button.toggle_mode=true;detail_button.button_pressed=host.preference("sheet",false);detail_button.disabled=found.is_empty()
 if host.preference("sheet",false) and not found.is_empty():
  var selected=found[0]
  UI.clear(info);UI.text(info,selected.name,true)
  if personal:
   info.add_child(preload("res://visual/art.gd").portrait_view(int(selected.get("portrait_seed",sim.state.military.seed)),int(selected.get("portrait_id",selected.id)),3))
   UI.text(info,selected.role+" · "+sim.career_rank(selected))
  else:
   UI.unit_icon(info,sim.MECH_CATALOG[selected.model]).custom_minimum_size=Vector2(96,144)
   UI.text(info,"Integridad: %d%%"%selected.hp)
  UI.muted(info,"Consulte las secciones de la ficha para revisar historia, asignaciones y disponibilidad.")
  var tabs=["Resumen","Perfil","Historia","Gestión"] if personal else ["Resumen","Taller","Historia","Disponibilidad"]
  var bar=HBoxContainer.new();host.content.add_child(bar)
  for tab in tabs:
   var b=UI.button(bar,tab,func():host.remember("dossier_tab",tab);host.render());b.toggle_mode=true;b.button_pressed=host.preference("dossier_tab","Resumen")==tab
  var pane=UI.block(host.content,selected.name)
  if personal:person(host,pane,selected)
  else:unit(host,pane,selected)
  host.set_task("VOLVER A LA PLANTILLA →" if personal else "VOLVER A LA FUERZA →",func():host.remember("sheet",false);host.render())
  return
 var toolbar=HBoxContainer.new();host.content.add_child(toolbar)
 var search=LineEdit.new();search.size_flags_horizontal=Control.SIZE_EXPAND_FILL;search.placeholder_text="Buscar nombre o función" if personal else "Buscar unidad";search.text=host.preference("query","");toolbar.add_child(search)
 var order=OptionButton.new();order.custom_minimum_size.x=180;order.add_item("Por nombre");order.add_item("Por condición");order.selected=int(host.preference("sort",0));toolbar.add_child(order)
 var body=UI.column(host.content)
 var fill=func():
  UI.clear(body)
  var entries=all.filter(func(e):return search.text.is_empty() or (e.name+e.get("role","")).to_lower().contains(search.text.to_lower()))
  entries.sort_custom(func(a,b):return a.name<b.name if order.selected==0 else (a.injury>b.injury if personal else a.hp<b.hp))
  var span=UI.pager(body,entries.size(),int(host.preference("page",0)),4,func(page):host.remember("page",page);host.render())
  var grid=GridContainer.new();grid.columns=2 if host.scroll.size.x<1000 else 4;grid.add_theme_constant_override("h_separation",16);grid.add_theme_constant_override("v_separation",16);body.add_child(grid)
  for e in entries.slice(span[0],span[1]):
   var card=UI.block(grid,e.name)
   if personal:
    card.add_child(preload("res://visual/art.gd").portrait_view(int(e.get("portrait_seed",sim.state.military.seed)),int(e.get("portrait_id",e.id)),3))
    UI.text(card,e.role+" · "+sim.career_rank(e))
    UI.muted(card,"Competencia %d · fatiga %d · Lesión: %d días"%[e.skill,e.fatigue,e.injury])
   else:
    var icon=UI.unit_icon(card,sim.MECH_CATALOG[e.model]);icon.custom_minimum_size=Vector2(96,144)
    UI.text(card,"Integridad %d%% · %s"%[e.hp,"En reparación" if e.repair else "Almacenado" if e.stored else "Desplegado" if sim.deployed(sim.mech_index(e.uid)) else "En base"])
    var p=sim.pilot_for(sim.mech_index(e.uid));UI.muted(card,p.get("name","Sin asignación"))
   var b=UI.primary(card,"ABRIR EXPEDIENTE →",func():host.remember(key,e[key]);host.remember("sheet",true);host.remember("dossier_tab","Resumen");host.render());b.toggle_mode=true;b.button_pressed=e[key]==chosen
  if entries.is_empty():UI.text(body,"No hay coincidencias. Pruebe otra búsqueda.")
 search.text_changed.connect(func(q):host.remember("query",q);host.remember("page",0);fill.call())
 order.item_selected.connect(func(i):host.remember("sort",i);fill.call());fill.call()
 if personal:preload("res://ui/story.gd").culture(host,UI.disclosure(host.content,"Identidad y beneficios de compañía"))
 if host.section=="Taller":
  var workshop=UI.block(host.content,"Planificación del taller")
  host.admin.logistics_page(workshop)
  host.rpg_sections(workshop,"Taller",func(e):return e.title=="Taller y políticas" or e.title.begins_with("Lote "))
static func person(host,parent: Node,p: Dictionary):
 var sim=host.sim
 var UI=host.UI
 parent.add_child(preload("res://visual/art.gd").portrait_view(int(p.get("portrait_seed",sim.state.military.seed)),int(p.get("portrait_id",p.id)),3))
 UI.text(parent,p.name,true)
 UI.text(parent,"%s · %s · competencia %d · salario %d/mes\nFatiga %d · lesión %d días · experiencia %d · operaciones %d"%[p.role,sim.career_rank(p),p.skill,p.salary,p.fatigue,p.injury,p.experience,p.missions])
 var personality=UI.column(parent);personality.visible=host.preference("dossier_tab","Resumen")=="Perfil"
 var profile=sim.state.story.people.profiles.get(str(p.id),{})
 if not profile.is_empty():
  UI.text(personality,"Aspiración: %s · %s\nValor: %s\nLímite declarado: %s"%[sim.Story.People.GOALS[profile.goal],"cumplida" if profile.status=="fulfilled" else "en curso",sim.Story.People.VALUES[profile.value],profile.limit])
 if p.has("background"):UI.text(personality,p.callsign+" · "+p.background)
 if p.has("departure_day"):UI.text(parent,"Baja: "+p.departure_reason)
 else:
  var actions=UI.block(parent,"Acciones para "+p.name);actions.get_parent().visible=host.preference("dossier_tab","Resumen")=="Gestión"
  host.action(actions,"Conceder descanso · 3 días",func():return sim.grant_leave(p.id))
  if sim.promotion_eligible(p.id):host.action(actions,"Ascender · 3.000 / salario +1.000",func():return sim.promote(p.id))
  var social=UI.disclosure(actions,"Conversación y relación")
  if sim.state.rpg.social.ties.has(str(p.id)):
   var t=sim.state.rpg.social.ties[str(p.id)];UI.text(social,"Confianza %+d · respeto %+d · prioridad %s"%[t.trust,t.respect,t.value])
   host.action(social,"Escuchar · 1 día",func():return sim.rpg_command("social",{"action":"talk","person":p.id,"topic":"listen"}))
   host.action(social,"Explicar decisiones · 1 día",func():return sim.rpg_command("social",{"action":"talk","person":p.id,"topic":"explain"}))
  UI.button(UI.disclosure(actions,"Baja de personal"),"Despedir…",func():host.confirm("Despedir", "Indemnización %d. Conserva el expediente; deja de trabajar en la compañía."%p.salary,func():return sim.dismiss(p.id)))
 var history=UI.column(parent);history.visible=host.preference("dossier_tab","Resumen")=="Historia"
 preload("res://ui/story.gd").history(host,history,p.id)
 for memory in p.memories.slice(-12):UI.text(history,"Día %d · %s"%[memory.day,memory.text])
 for bond in sim.state.bonds.values():
  if bond.a==p.id or bond.b==p.id:UI.text(history,"Vínculo con %s: %s"%[sim.person_name(bond.b if bond.a==p.id else bond.a),sim.bond_description(bond.score)])
static func unit(host,parent: Node,m: Dictionary):
 var sim=host.sim
 var UI=host.UI
 var index=sim.mech_index(m.uid)
 host.admin.unit_picture(parent,sim.MECH_CATALOG[m.model])
 UI.text(parent,"#%d · integridad %d%% · %s"%[m.uid,m.hp,"almacenado" if m.stored else "desplegado" if sim.deployed(index) else "en base"])
 var history=UI.column(parent);history.visible=host.preference("dossier_tab","Resumen")=="Historia"
 preload("res://ui/story.gd").history(host,history,-1,m.uid)
 var people={-1:"Sin asignar"}
 for p in sim.state.staff:
  if p.role==sim.required_role(m):people[p.id]=p.name+" · competencia "+str(p.skill)
 var picker=UI.picker(parent,"Piloto / dotación",people,m.pilot_id)
 picker.item_selected.connect(func(i):host.run(func():return sim.assign_pilot(index,picker.get_item_metadata(i))))
 if m.pilot_id>=0:UI.button(parent,"Abrir expediente del personal →",func():host.navigate("Compañía","Personal");host.remember("id",m.pilot_id);host.render())
 UI.text(parent,"Mantenimiento %d/mes · venta %d"%[sim.mech_daily_cost(m)*30,sim.sale_quote(m.uid)])
 var workshop=UI.column(parent);workshop.visible=host.preference("dossier_tab","Resumen")=="Taller"
 host.action(workshop,"Suspender reparación" if m.repair else "Reparar integridad · 1.000 + 2 suministros/día",func():return sim.repair(index))
 host.rpg_sections(workshop,"Taller",func(s):return s.title=="Taller: "+m.name,m.uid)
 var ownership=UI.column(parent);ownership.visible=host.preference("dossier_tab","Resumen")=="Disponibilidad"
 UI.button(ownership,"Almacenar / reactivar…",func():host.confirm("Disponibilidad","Almacenar libera su piloto. Reactivar cuesta 1.000 y tarda dos días.",func():return sim.set_stored(m.uid,not m.stored)))
 var quote=sim.sale_quote(m.uid)
 UI.button(ownership,"Vender · %d…"%quote,func():host.confirm("Vender unidad","Se retira la unidad de la compañía y libera al piloto. Importe: %d."%quote+sim.Story.Culture.sale_warning(sim,m.uid),func():return sim.sell_mech(m.uid,quote)))
