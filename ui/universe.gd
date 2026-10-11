extends AcceptDialog
signal campaign_changed(message: String)
const U = preload("res://sim/universe.gd")
const Lore = preload("res://sim/lore.gd")
var sim
var map
var results: ItemList
var details: Label
var selected_id = ""
func _ready():
 title = "Inner Sphere · atlas y relaciones"
 var scroll = ScrollContainer.new()
 scroll.custom_minimum_size = Vector2(1000,620)
 add_child(scroll)
 var box = VBoxContainer.new()
 box.custom_minimum_size.x = 980
 box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 scroll.add_child(box)
 var note = Label.new()
 note.text = "Escenario %d · Afiliaciones: referencia %s (no fronteras exactas del día) · %d sistemas importados" % [sim.state.scenario_year,U.load_data().reference_dates[str(sim.state.scenario_year)],U.load_data().systems.size()]
 note.custom_minimum_size.x = 980
 note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 box.add_child(note)
 var search = LineEdit.new()
 search.placeholder_text = "Buscar sistema o alias…"
 box.add_child(search)
 var fit = Button.new()
 fit.text = "Ver atlas completo"
 fit.pressed.connect(func(): map.center = Vector2.ZERO; map.zoom = 0.105; map.queue_redraw())
 box.add_child(fit)
 var body = HBoxContainer.new()
 box.add_child(body)
 body.size_flags_vertical = Control.SIZE_EXPAND_FILL
 map = preload("res://ui/star_map.gd").new()
 map.year = sim.state.scenario_year
 map.location_id = sim.state.location_id
 map.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 body.add_child(map)
 results = ItemList.new()
 results.custom_minimum_size.x = 250
 body.add_child(results)
 search.text_changed.connect(func(query):
  results.clear()
  for item in U.find_systems(query,sim.state.scenario_year).slice(0,100):
   results.add_item(item.name)
   results.set_item_metadata(results.item_count-1,item.id))
 results.item_selected.connect(func(index): select_system(results.get_item_metadata(index)); map.focus(selected_id))
 map.selected.connect(select_system)
 var filter = OptionButton.new()
 filter.add_item("Todas las afiliaciones")
 filter.set_item_metadata(0,"")
 var codes = {}
 for system in U.load_data().systems: codes[system.affiliations[str(sim.state.scenario_year)]] = true
 for code in codes:
  filter.add_item(U.faction_name(code))
  filter.set_item_metadata(filter.item_count-1,code)
 filter.item_selected.connect(func(index): map.faction = filter.get_item_metadata(index); map.queue_redraw())
 box.add_child(filter)
 details = Label.new()
 details.custom_minimum_size.x = 980
 details.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 box.add_child(details)
 var actions = HFlowContainer.new()
 box.add_child(actions)
 var contacts = OptionButton.new()
 for actor in Lore.available(sim.state.scenario_year):
  contacts.add_item(actor.name)
  contacts.set_item_metadata(contacts.item_count-1,actor.id)
 actions.add_child(contacts)
 contacts.item_selected.connect(func(index):
  var actor = Lore.get_actor(contacts.get_item_metadata(index))
  details.text = "%s · %s · Confianza %+d\nSede/ámbito de referencia: %s\nFuente: %s\n%s" % [actor.name,actor.kind,sim.state.relationships.get(actor.name,0),actor.headquarters,actor.source,"Contacto registrado" if sim.state.lore_contacts.has(actor.id) else "Sin canal de contacto"]
  if sim.state.get("lore_activity",{}).has(actor.id):
   var bulletin = sim.state.lore_activity[actor.id]
   details.text += "\nBoletín público (día %d): %s" % [bulletin.day,bulletin.text])
 var button = Button.new()
 button.text = "Contactar · 1.000 C-bills"
 button.pressed.connect(func():
  var result = sim.contact_lore(contacts.get_item_metadata(contacts.selected))
  details.text = result
  campaign_changed.emit(result))
 actions.add_child(button)
 var travel = Button.new()
 travel.text = "Cotizar traslado al sistema seleccionado"
 travel.pressed.connect(func():
  if sim.has_method("travel_quote"): show_travel()
  else: details.text = "Traslados se incorporan en la entrega de integración.")
 actions.add_child(travel)
 var nearby = U.load_data().systems.duplicate()
 var home = U.system(sim.state.location_id)
 nearby.sort_custom(func(a,b): return Vector2(a.x-home.x,a.y-home.y).length_squared() < Vector2(b.x-home.x,b.y-home.y).length_squared())
 for item in nearby.slice(0,30):
  results.add_item(item.name)
  results.set_item_metadata(results.item_count-1,item.id)
 select_system(sim.state.location_id)
 map.focus(sim.state.location_id)
func select_system(id: String):
 selected_id = id
 var item = U.system(id)
 if item.is_empty(): return
 details.text = "%s · %s · (%.1f, %.1f) años luz\nReferencia política: %s · %s\n%s" % [item.name,U.faction_name(item.affiliations[str(sim.state.scenario_year)]),item.x,item.y,U.load_data().reference_dates[str(sim.state.scenario_year)],item.id,item.source]
func show_travel():
 var quote = sim.travel_quote(selected_id)
 if quote.has("error"):
  details.text = quote.error
  return
 var confirm = ConfirmationDialog.new()
 confirm.title = "Confirmar traslado"
 confirm.ok_button_text = "Partir"
 confirm.cancel_button_text = "Cancelar"
 var names = []
 for id in quote.route: names.append(U.system(id).name)
 confirm.dialog_text = "Destino: %s\n%d saltos de hasta 30 años luz · %d días · %d C-bills · %d toneladas\nTiempo de juego: 7 días por salto + 4 de tránsito local.\nSalarios y mantenimiento se pagan además; sin compras o contratos durante el viaje.\nRuta: %s" % [U.system(selected_id).name,quote.hops,quote.days,quote.cost,quote.mass," → ".join(names)]
 confirm.dialog_autowrap = true
 var destination = selected_id
 confirm.confirmed.connect(func():
  var message = sim.start_travel(destination,quote.cost)
  details.text = message
  campaign_changed.emit(message))
 confirm.confirmed.connect(confirm.queue_free)
 confirm.canceled.connect(confirm.queue_free)
 add_child(confirm)
 confirm.popup_centered(Vector2i(800,360))
