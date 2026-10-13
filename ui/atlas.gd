extends VBoxContainer
const Art = preload("res://visual/art.gd")
var title: Label
var location = ""
var map: TextureRect
var crew: HBoxContainer
var summary: Label
var sector = 0
var seed_value = -1
var signature = ""
var animation = true
var timer = 0.0
var lamp: Label
func _ready():
	add_theme_constant_override("separation", 8)
	var row = HBoxContainer.new()
	add_child(row)
	title = Label.new()
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.text = "GALATEA / ARCHIVO CARTOGRÁFICO"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(title)
	lamp = Label.new()
	lamp.text = "● ENLACE"
	row.add_child(lamp)
	var selector = OptionButton.new()
	selector.fit_to_longest_item = false
	selector.custom_minimum_size.x = 170
	for title_text in ["Distrito de base", "Cuenca exterior", "Cinturón industrial"]: selector.add_item(title_text)
	selector.item_selected.connect(func(index):
		sector = index
		render_map())
	row.add_child(selector)
	map = TextureRect.new()
	map.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	map.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	map.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	map.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(map)
	var note = Label.new()
	note.text = "80 × 25 / Entorno ilustrativo · Sin posiciones tácticas ni rutas de viaje jugables"
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(note)
	summary = Label.new()
	summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(summary)
	var crew_scroll = ScrollContainer.new()
	crew_scroll.custom_minimum_size.y = 118
	add_child(crew_scroll)
	crew = HBoxContainer.new()
	crew.add_theme_constant_override("separation", 16)
	crew_scroll.add_child(crew)
func render_map():
	map.texture = ImageTexture.create_from_image(Art.map_image(seed_value + location.hash(), sector))
func refresh(sim):
	if location != sim.state.location_id:
		location = sim.state.location_id
		title.text = sim.Universe.system(location).name.to_upper() + " / ENTORNO LOCAL"
		render_map()
	if seed_value != int(sim.state.military.seed):
		seed_value = int(sim.state.military.seed)
		render_map()
	var new_signature = str(seed_value) + sim.state.captain_name + JSON.stringify(sim.state.staff.map(func(person): return [person.id, person.name, person.role]))
	if new_signature != signature:
		signature = new_signature
		for child in crew.get_children():
			crew.remove_child(child)
			child.queue_free()
		var people = [{"id": -1, "name": sim.state.captain_name, "role": "Capitán"}] + sim.state.staff
		for person in people:
			var card = HBoxContainer.new()
			crew.add_child(card)
			card.add_child(Art.portrait_view(int(person.get("portrait_seed",seed_value)), int(person.get("portrait_id",person.id)), 3))
			var name_label = Label.new()
			name_label.text = "%s\n%s" % [person.name, person.role]
			card.add_child(name_label)
	summary.text = "Órdenes y flota: preparar despliegues · Mundo: contactos y oportunidades · Crónica: partes recibidos"
	if not sim.state.active.is_empty(): summary.text = "OPERACIÓN EN CURSO · " + sim.state.active.contract.name + " · Consultá Mando de operaciones para leer los partes."
	if sim.in_transit(): summary.text = "EN TRÁNSITO · %d días hasta %s" % [sim.state.travel.arrival-sim.state.day,sim.Universe.system(sim.state.travel.destination).name]
	if sim.military_waiting(): summary.text = "DECISIÓN PENDIENTE · El jefe espera instrucciones en Mando de operaciones."
func _process(delta: float):
	timer += delta
	if lamp: lamp.modulate.a = 0.6 + 0.4 * (0.5 + 0.5 * sin(timer * 2.0)) if animation else 1.0
