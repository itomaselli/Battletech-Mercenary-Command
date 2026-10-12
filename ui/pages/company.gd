extends RefCounted
static func draw(host):
 var UI=host.UI
 var sim=host.sim
 var personal=host.section=="Personal"
 var all=sim.state.staff+sim.state.alumni if personal else sim.state.mechs
 var filters=UI.block(host.content,"Personal de la compañía" if personal else "Flota de la compañía")
 var toolbar=HBoxContainer.new();filters.add_child(toolbar)
 var search=LineEdit.new();search.size_flags_horizontal=Control.SIZE_EXPAND_FILL;search.placeholder_text="Buscar nombre o función" if personal else "Buscar unidad";search.text=host.preference("query","");toolbar.add_child(search)
 var order=OptionButton.new();order.custom_minimum_size.x=170;order.add_item("Por nombre");order.set_item_metadata(0,"name");order.add_item("Por condición");order.set_item_metadata(1,"condition");order.selected=0 if host.preference("order","name")=="name" else 1;toolbar.add_child(order)
 var body=UI.column(host.content)
 var draw_list=func():
  UI.clear(body)
  var entries=all.filter(func(e):return search.text.is_empty() or (e.name+e.get("role","")).to_lower().contains(search.text.to_lower()))
  entries.sort_custom(func(a,b):return a.name<b.name if host.preference("order","name")=="name" else (a.injury>b.injury if personal else a.hp<b.hp))
  var id_key="id" if personal else "uid"
  var chosen=int(host.preference(id_key,entries[0][id_key] if not entries.is_empty() else -1))
  if not entries.any(func(e):return e[id_key]==chosen) and not entries.is_empty():chosen=int(entries[0][id_key])
  var panes=UI.split(body,host.size.x)
  var interval=UI.pager(panes[0],entries.size(),maxi(0,int(entries.map(func(e):return e[id_key]).find(chosen)/7)),7,func(page):host.remember("page",page);host.remember(id_key,entries[page*7][id_key]);host.render())
  UI.text(panes[0],"Personas" if personal else "Unidades",true)
  for e in entries.slice(interval[0],interval[1]):
   var b=UI.button(panes[0],"%s · %s"%[e.name,e.role if personal else str(e.hp)+"%"],func():host.remember(id_key,e[id_key]);host.render())
   b.toggle_mode=true;b.button_pressed=e[id_key]==chosen
  var found=entries.filter(func(e):return e[id_key]==chosen)
  if found.is_empty():UI.text(panes[1],"Sin coincidencias.");return
  panes[1]=UI.block(panes[1],"Expediente seleccionado · "+found[0].name)
  if personal:person(host,panes[1],found[0])
  else:unit(host,panes[1],found[0])
 search.text_changed.connect(func(value):host.remember("query",value);host.remember("page",0);draw_list.call())
 order.item_selected.connect(func(index):host.remember("order",order.get_item_metadata(index));draw_list.call())
 draw_list.call()
 if personal:preload("res://ui/story.gd").culture(host,UI.disclosure(host.content,"Prácticas y beneficios de compañía"))
 if host.section=="Taller":
  var logistics=UI.disclosure(host.content,"Abastecimiento y cola de reparaciones")
  host.admin.logistics_page(logistics)
  host.rpg_sections(logistics,"Taller",func(s):return s.title=="Taller y políticas" or s.title.begins_with("Lote "))
static func person(host,parent: Node,p: Dictionary):
 var sim=host.sim
 var UI=host.UI
 parent.add_child(preload("res://visual/art.gd").portrait_view(int(p.get("portrait_seed",sim.state.military.seed)),int(p.get("portrait_id",p.id)),3))
 UI.text(parent,p.name,true)
 UI.text(parent,"%s · %s · competencia %d · salario %d/mes\nFatiga %d · lesión %d días · experiencia %d · operaciones %d"%[p.role,sim.career_rank(p),p.skill,p.salary,p.fatigue,p.injury,p.experience,p.missions])
 var personality=UI.disclosure(parent,"Perfil, aspiraciones y límites")
 var profile=sim.state.story.people.profiles.get(str(p.id),{})
 if not profile.is_empty():
  UI.text(personality,"Aspiración: %s · %s\nValor: %s\nLímite declarado: %s"%[sim.Story.People.GOALS[profile.goal],"cumplida" if profile.status=="fulfilled" else "en curso",sim.Story.People.VALUES[profile.value],profile.limit])
 if p.has("background"):UI.text(personality,p.callsign+" · "+p.background)
 if p.has("departure_day"):UI.text(parent,"Baja: "+p.departure_reason)
 else:
  var actions=UI.block(parent,"Acciones para "+p.name)
  host.action(actions,"Conceder descanso · 3 días",func():return sim.grant_leave(p.id))
  if sim.promotion_eligible(p.id):host.action(actions,"Ascender · 3.000 / salario +1.000",func():return sim.promote(p.id))
  var social=UI.disclosure(actions,"Conversación y relación")
  if sim.state.rpg.social.ties.has(str(p.id)):
   var t=sim.state.rpg.social.ties[str(p.id)];UI.text(social,"Confianza %+d · respeto %+d · prioridad %s"%[t.trust,t.respect,t.value])
   host.action(social,"Escuchar · 1 día",func():return sim.rpg_command("social",{"action":"talk","person":p.id,"topic":"listen"}))
   host.action(social,"Explicar decisiones · 1 día",func():return sim.rpg_command("social",{"action":"talk","person":p.id,"topic":"explain"}))
  UI.button(UI.disclosure(actions,"Baja de personal"),"Despedir…",func():host.confirm("Despedir", "Indemnización %d. Conserva el expediente; deja de trabajar en la compañía."%p.salary,func():return sim.dismiss(p.id)))
 var history=UI.disclosure(parent,"Historial y vínculos")
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
 preload("res://ui/story.gd").history(host,UI.disclosure(parent,"Historial de servicio"),-1,m.uid)
 var people={-1:"Sin asignar"}
 for p in sim.state.staff:
  if p.role==sim.required_role(m):people[p.id]=p.name+" · competencia "+str(p.skill)
 var picker=UI.picker(parent,"Piloto / dotación",people,m.pilot_id)
 picker.item_selected.connect(func(i):host.run(func():return sim.assign_pilot(index,picker.get_item_metadata(i))))
 if m.pilot_id>=0:UI.button(parent,"Abrir expediente del personal →",func():host.navigate("Compañía","Personal");host.remember("id",m.pilot_id);host.render())
 UI.text(parent,"Mantenimiento %d/mes · venta %d"%[sim.mech_daily_cost(m)*30,sim.sale_quote(m.uid)])
 host.action(parent,"Suspender reparación" if m.repair else "Reparar integridad · 1.000 + 2 suministros/día",func():return sim.repair(index))
 host.rpg_sections(UI.disclosure(parent,"Sistemas y alternativas de taller"),"Taller",func(s):return s.title=="Taller: "+m.name,m.uid)
 var ownership=UI.disclosure(parent,"Disponibilidad y venta")
 UI.button(ownership,"Almacenar / reactivar…",func():host.confirm("Disponibilidad","Almacenar libera su piloto. Reactivar cuesta 1.000 y tarda dos días.",func():return sim.set_stored(m.uid,not m.stored)))
 var quote=sim.sale_quote(m.uid)
 UI.button(ownership,"Vender · %d…"%quote,func():host.confirm("Vender unidad","Se retira la unidad de la compañía y libera al piloto. Importe: %d."%quote+sim.Story.Culture.sale_warning(sim,m.uid),func():return sim.sell_mech(m.uid,quote)))
