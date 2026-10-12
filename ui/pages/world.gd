extends RefCounted
static func draw(host):
 if host.section=="Entorno":
  var panes=host.UI.workspace(host.content,host,1.8,1.0)
  panes[0].size_flags_stretch_ratio=1.8
  var atlas=preload("res://ui/atlas.gd").new();panes[0].add_child(atlas);atlas.map.custom_minimum_size.y=220;atlas.animation=host.settings.animation;atlas.refresh(host.sim)
  atlas.crew.get_parent().hide()
  var context=host.UI.block(panes[1],"Oportunidades y comunicaciones")
  host.UI.text(context,"Entorno ilustrativo del sistema actual. Las posiciones de combate se consultan en Batalla.")
  if not host.sim.state.accepted.is_empty():
   host.UI.text(context,host.sim.state.accepted.name,true)
   host.UI.primary(context,"Seguir contrato →",func():host.navigate("Operaciones","Resumen"))
  else:host.UI.primary(context,"Revisar contratos →",func():host.navigate("Operaciones","Contratos"))
  var local=host.sim.state.story.society.pending
  if not local.is_empty():
   host.UI.text(context,local.text)
   host.UI.button(context,"Responder al enlace →",func():host.navigate("Mando","Bandeja");host.remember("entry","local:"+local.key);host.render())
  host.UI.button(context,"Consultar región →",func():host.navigate("Mundo","Región"))
  host.UI.button(context,"Abrir comunicaciones →",func():host.navigate("Mando","Bandeja"))
  return
 if host.section=="Región":
  preload("res://ui/story.gd").society(host,host.content)
  host.rpg_sections(host.content,"Región");return
 if host.section=="Contactos":contacts(host);return
 var UI=host.UI
 var sim=host.sim
 UI.text(host.content,"Afiliaciones de referencia: %s · escenario %d. No cambia fronteras canónicas."%[sim.Universe.load_data().reference_dates[str(sim.state.scenario_year)],sim.state.scenario_year])
 var panes=UI.workspace(host.content,host,1.8,1.0)
 panes[0].size_flags_stretch_ratio=1.8
 var search=LineEdit.new();search.placeholder_text="Buscar sistema o alias";search.text=host.preference("query","");panes[0].add_child(search)
 var results=ItemList.new();results.custom_minimum_size.y=90;panes[0].add_child(results)
 var fill=func(q):
  results.clear()
  var matches=sim.Universe.find_systems(q,sim.state.scenario_year).slice(0,100)
  for p in matches:results.add_item(p.name);results.set_item_metadata(results.item_count-1,p.id)
 search.text_changed.connect(func(q):host.remember("query",q);fill.call(q));fill.call(search.text)
 var map=preload("res://ui/star_map.gd").new();map.year=sim.state.scenario_year;map.location_id=sim.state.location_id;map.size_flags_horizontal=Control.SIZE_EXPAND_FILL;panes[0].add_child(map);map.custom_minimum_size=Vector2(0,220)
 var codes={"":"Todas las afiliaciones"}
 for system in sim.Universe.load_data().systems:
  var code=system.affiliations[str(sim.state.scenario_year)];codes[code]=sim.Universe.faction_name(code)
 var filter=UI.picker(panes[1],"Afiliación",codes,host.preference("faction",""));map.faction=host.preference("faction","")
 filter.item_selected.connect(func(i):host.remember("faction",filter.get_item_metadata(i));map.faction=filter.get_item_metadata(i);map.queue_redraw())
 var detail=UI.block(panes[1],"Sistema seleccionado")
 var select=func(id):
  host.remember("system",id);UI.clear(detail)
  var p=sim.Universe.system(id)
  UI.text(detail,p.name,true);UI.text(detail,"%s · %s\n%s"%[sim.Universe.faction_name(p.affiliations[str(sim.state.scenario_year)]),p.id,p.source])
  UI.button(detail,"Cotizar traslado",func():
   var quote=sim.travel_quote(id)
   if quote.has("error"):host.report(quote.error);return
   UI.text(detail,"%d saltos · %d días · %d C-bills; salarios y mantenimiento adicionales."%[quote.hops,quote.days,quote.cost])
   UI.button(detail,"Confirmar partida…",func():host.confirm("Traslado a "+p.name,"Coste %d y %d días. Salarios y mantenimiento continúan."%[quote.cost,quote.days],func():return sim.start_travel(id,quote.cost))))
 var id=host.preference("system",sim.state.location_id);map.focus(id);select.call(id)
 if host.preference("center") is Vector2:map.center=host.preference("center");map.zoom=host.preference("zoom",0.42)
 map.gui_input.connect(func(_event):host.remember("center",map.center);host.remember("zoom",map.zoom))
 map.selected.connect(select)
 results.item_selected.connect(func(i):var target=results.get_item_metadata(i);map.focus(target);select.call(target))
 UI.button(panes[1],"Ver atlas completo",func():map.center=Vector2.ZERO;map.zoom=0.105;map.queue_redraw())
static func contacts(host):
 var sim=host.sim
 var UI=host.UI
 var names={}
 for a in sim.world_report().actors:names[a.id]=a.name
 for a in sim.Lore.available(sim.state.scenario_year):names[a.id]=a.name
 var selected=str(host.preference("contact",names.keys()[0]))
 var picker=UI.picker(host.content,"Organización",names,selected)
 picker.item_selected.connect(func(i):host.remember("contact",picker.get_item_metadata(i));host.render())
 var actor=sim.Lore.get_actor(selected)
 if not actor.is_empty():
  UI.text(host.content,actor.name,true);UI.text(host.content,"%s · %s\nFuente: %s"%[actor.kind,actor.headquarters,actor.source])
  var bulletin=sim.state.lore_activity.get(actor.id,{})
  if not bulletin.is_empty():UI.text(host.content,"Día %d · %s"%[bulletin.day,bulletin.text])
  host.action(host.content,"Establecer contacto · 1.000",func():return sim.contact_lore(actor.id))
 else:
  host.admin.world_actor_id=selected;host.admin.world_page(host.content)
 if names.has(selected):host.rpg_sections(host.content,"Agenda",func(e):return e.title=="Enlace: "+names[selected])
