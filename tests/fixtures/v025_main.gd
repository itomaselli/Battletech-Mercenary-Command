extends Control
const Campaign = preload("res://sim/campaign.gd")
var sim = Campaign.new()
var identity: Label
var stats: Label
var roster: VBoxContainer
var offers: VBoxContainer
var journal: RichTextLabel
var journal_filter: LineEdit
var status: Label
var operation: Label
var doctrine: OptionButton
var selected: Array = [0, 1, 2, 3]
var chosen_offer = 0
var urgent_button: Button
var fleet_signature: Array = []
var leader: OptionButton
var sections: TabContainer
var atlas
var settings = preload("res://visual/settings.gd").new()
var terminal_material: ShaderMaterial

func _ready():
	settings.load_settings()
	theme = preload("res://visual/style.gd").build()
	get_viewport().gui_embed_subwindows = true
	var margin = MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]: margin.add_theme_constant_override("margin_" + side, 18)
	add_child(margin)
	var root = VBoxContainer.new()
	root.add_theme_constant_override("separation", 10)
	margin.add_child(root)
	var title = label("MERCENARY COMMAND   /      v0.25.0", root)
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color("d9b56f"))
	var identity_row = HBoxContainer.new()
	root.add_child(identity_row)
	identity = label("", identity_row)
	identity.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	identity.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	button("Nombrar compañía / capitán", identity_row, edit_identity)
	stats = label("", root)
	var toolbar = HFlowContainer.new()
	root.add_child(toolbar)
	button("+ 1 día", toolbar, func(): advance_days(1))
	button("+ 7 días", toolbar, func(): advance_days(7))
	var shortcuts = HFlowContainer.new()
	shortcuts.visible = false
	root.add_child(shortcuts)
	button("Abastecimiento", shortcuts, func(): show_management(1))
	button("Guardar", shortcuts, func(): report("Campaña guardada." if sim.save_game() == OK else "No se pudo guardar."))
	button("Cargar", shortcuts, func(): report("Campaña cargada." if sim.load_game() == OK else "Guardado ausente o inválido; estado conservado."))
	button("Nueva", shortcuts, confirm_new)
	button("Gestión", shortcuts, func(): show_management(0))
	button("Hangar / mercado", shortcuts, func(): show_management(4))
	button("Expedientes", shortcuts, func(): show_management(6))
	button("Mundo", shortcuts, func(): show_management(7))
	button("Opciones visuales", shortcuts, show_visual_options)
	button("Campaña", toolbar, show_campaign_menu)
	var nav = HFlowContainer.new()
	root.add_child(nav)
	button("Resumen", nav, func(): sections.current_tab = 0)
	button("Operaciones", nav, func(): sections.current_tab = 1)
	button("Capitán", nav, show_rpg)
	button("Compañía", nav, func(): show_management(0))
	button("Inner Sphere", nav, show_sphere)
	button("Mercado", nav, func(): show_management(5))
	button("Finanzas", nav, func(): show_management(2))
	button("Crónica", nav, func(): sections.current_tab = 2)
	button("Accesos rápidos", toolbar, func(): shortcuts.visible = not shortcuts.visible)
	urgent_button = button("Decisiones pendientes", root, show_decisions)
	sections = TabContainer.new()
	sections.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(sections)
	atlas = preload("res://ui/atlas.gd").new()
	atlas.name = "Centro de mando"
	sections.add_child(atlas)
	atlas.animation = settings.animation
	var columns = HBoxContainer.new()
	columns.name = "Órdenes y flota"
	columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	columns.add_theme_constant_override("separation", 24)
	sections.add_child(columns)
	var left_scroll = ScrollContainer.new()
	left_scroll.custom_minimum_size.x = 425
	left_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	columns.add_child(left_scroll)
	roster = VBoxContainer.new()
	roster.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left_scroll.add_child(roster)
	var right_scroll = ScrollContainer.new()
	right_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	columns.add_child(right_scroll)
	var right = VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_scroll.add_child(right)
	label("ÓRDENES / CONTRATOS", right)
	doctrine = OptionButton.new()
	for name in ["Cautelosa · +1 día, menos desgaste", "Equilibrada · ritmo normal", "Agresiva · más presión y desgaste"]: doctrine.add_item(name)
	doctrine.selected = 1
	right.add_child(doctrine)
	leader = OptionButton.new()
	right.add_child(leader)
	offers = VBoxContainer.new()
	right.add_child(offers)
	button("ACEPTAR CONTRATO SELECCIONADO", right, func(): report(sim.accept_contract(chosen_offer)))
	button("MANDO DE OPERACIONES", right, show_operations)
	button("AUTORIZAR DESPLIEGUE", right, func(): report(sim.dispatch(chosen_offer, selected, doctrine.selected, leader.get_selected_id())))
	button("Retirarse / cancelar contrato", right, confirm_cancel)
	operation = label("", right)
	operation.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var chronicle_page = VBoxContainer.new()
	chronicle_page.name = "Crónica"
	sections.add_child(chronicle_page)
	label("CRÓNICA / INFORMES RECIBIDOS", chronicle_page)
	journal_filter = LineEdit.new()
	journal_filter.placeholder_text = "Filtrar por fecha, personaje, tipo o texto…"
	journal_filter.text_changed.connect(func(_text): refresh_journal())
	chronicle_page.add_child(journal_filter)
	journal = RichTextLabel.new()
	journal.custom_minimum_size.y = 190
	journal.size_flags_vertical = Control.SIZE_EXPAND_FILL
	journal.scroll_following = true
	chronicle_page.add_child(journal)
	status = label("Acepte un contrato, prepare sus unidades y autorice el despliegue.", root)
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status.add_theme_color_override("font_color", Color("d9b56f"))
	var layer = CanvasLayer.new()
	layer.layer = 100
	add_child(layer)
	var overlay = ColorRect.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	terminal_material = ShaderMaterial.new()
	terminal_material.shader = preload("res://visual/terminal.gdshader")
	overlay.material = terminal_material
	layer.add_child(overlay)
	apply_visual_settings()
	refresh()

func label(text: String, parent: Node) -> Label:
	var item = Label.new()
	item.text = text
	parent.add_child(item)
	return item

func button(text: String, parent: Node, action: Callable) -> Button:
	var item = Button.new()
	item.text = text
	item.pressed.connect(action)
	parent.add_child(item)
	return item

func report(message: String):
	status.text = message
	refresh()

func clear(parent: Node):
	for child in parent.get_children():
		parent.remove_child(child)
		child.queue_free()

func refresh():
	atlas.refresh(sim)
	var s = sim.state
	var signature = []
	for mech in s.mechs: signature.append(mech.uid)
	if not fleet_signature.is_empty() and fleet_signature != signature: selected.clear()
	fleet_signature = signature
	urgent_button.visible = not s.issues.is_empty() or sim.military_waiting() or sim.RPG.waiting(sim)
	urgent_button.text = "%d ASUNTO(S) URGENTE(S) · Revisar para continuar" % (s.issues.size() + (1 if sim.military_waiting() else 0) + (1 if sim.RPG.waiting(sim) else 0))
	identity.text = "%s  •  Capitán %s  •  %s" % [s.company_name, s.captain_name, sim.Universe.system(s.location_id).name]
	if sim.in_transit(): identity.text += " → %s · llegada en %d días" % [sim.Universe.system(s.travel.destination).name,s.travel.arrival-s.day]
	stats.text = "%s  |  %d C-bills  |  Suministros %d  |  Moral %d  |  Reputación %+d  |  Deuda %d" % [sim.date_text(), s.funds, s.supplies, s.morale, s.reputation, s.arrears + s.contract_debt + s.ownership_debt]
	clear(roster)
	label("HANGAR · %d/%d plazas · máximo 4 por operación" % [sim.hangar_used(), sim.MAX_HANGAR], roster)
	for i in range(s.mechs.size()):
		var m = s.mechs[i]
		var p = sim.pilot_for(i)
		if m.stored: label("ALMACENADO · reactivar desde Hangar", roster)
		elif m.ready_day > s.day: label("REACTIVANDO · %d días" % (m.ready_day - s.day), roster)
		var available = sim.mech_ready(i) and m.hp >= 40 and not m.repair and sim.person_available(p) and not sim.deployed(i)
		var check = CheckBox.new()
		check.text = "#%d %s   %d%%" % [m.uid, m.name, m.hp]
		check.disabled = not available
		check.button_pressed = i in selected and available
		if not available: selected.erase(i)
		check.toggled.connect(func(on):
			if on and not i in selected:
				if selected.size() >= sim.MAX_DEPLOYED:
					check.set_pressed_no_signal(false)
					status.text = "Máximo cuatro máquinas. Desmarca una antes de elegir otra."
					return
				selected.append(i)
			if not on: selected.erase(i))
		roster.add_child(check)
		var pilot_line = label("  Sin piloto asignado" if p.is_empty() else "  %s · habilidad %d · %s" % [p.name, p.skill, "baja %d · fatiga %d · permiso %d" % [p.injury, p.fatigue, maxi(0, int(p.rest_until - s.day))]], roster)
		pilot_line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		var repair_button = button("  %s" % ("Suspender reparación" if m.repair else "Reparar · 10%/día"), roster, func(): report(sim.repair(i)))
		repair_button.disabled = sim.deployed(i) or m.hp >= 100 or not sim.mech_ready(i)
	for person in s.staff:
		if person.role != "Piloto": label("%s / %s" % [person.name, person.role], roster)
	label("Nómina: %d C-bills cada 30 días.\nTaller: 2 suministros + 1.000 por unidad/día." % sim.monthly_payroll(), roster)
	var previous_leader = leader.get_selected_id()
	leader.clear()
	leader.add_item("Jefe: primer piloto seleccionado", -1)
	# Explicit metadata avoids OptionButton assigning an automatic ID for -1.
	leader.set_item_id(0, -1)
	for person in s.staff:
		if person.role in ["Piloto","Dotación"] and sim.person_available(person):
			leader.add_item("Jefe: " + person.name, person.id)
			if person.id == previous_leader: leader.select(leader.item_count - 1)
	clear(offers)
	button("Misiones locales · generador de oportunidades", offers, show_missions)
	chosen_offer = clampi(chosen_offer, 0, maxi(0, s.offers.size() - 1))
	var group = ButtonGroup.new()
	for i in range(s.offers.size()):
		var c = s.offers[i]
		var pick = CheckBox.new()
		pick.button_group = group
		pick.text = "%s · %d C-bills" % [c.name, c.pay]
		pick.button_pressed = i == chosen_offer
		pick.pressed.connect(func(): chosen_offer = i)
		offers.add_child(pick)
		var details = label("%s · %d días · oferta vence en %d días\nAnticipo %d · mínimo %d máquinas · despliegue en 5 días\nInteligencia %s: %s\nÉxito: total %d; fracaso: total %d. Cancelar: devolver anticipo." % [c.employer, c.days, c.expires - s.day, c.advance, c.min_force, c.reliability, c.intel, c.pay, c.failure_pay], offers)
		details.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	operation.text = "Sin operación activa. Ofertas nuevas cada 14 días."
	if not s.accepted.is_empty(): operation.text = "ACEPTADO: %s\nDesplegar en %d días · mínimo %d máquinas." % [s.accepted.name, s.accepted.deadline - s.day, s.accepted.min_force]
	if not s.active.is_empty(): operation.text = "EN CURSO: %s\nTiempo restante estimado: %d días." % [s.active.contract.name, s.active.remaining]
	if sim.military_waiting(): operation.text += "\nDECISIÓN PENDIENTE en Mando de operaciones."
	if s.ended: operation.text = "CAMPAÑA CERRADA. Puede cargar una partida o comenzar otra."
	refresh_journal()

func confirm_new():
	var dialog = ConfirmationDialog.new()
	dialog.dialog_text = "¿Iniciar otra campaña? Se perderá el progreso sin guardar."
	var scenario = OptionButton.new()
	scenario.add_item("Escenario 3027 · Guerras de Sucesión")
	scenario.add_item("Escenario 3060 · Posinvasión Clan")
	dialog.add_child(scenario)
	dialog.confirmed.connect(func():
		sim = Campaign.new(int(Time.get_unix_time_from_system()), [3027, 3060][scenario.selected])
		selected = [0, 1, 2, 3]
		report("Nueva compañía lista.")
		edit_identity())
	dialog.visibility_changed.connect(func():
		if not dialog.visible: dialog.queue_free())
	add_child(dialog)
	dialog.popup_centered()

func edit_identity():
	var dialog = ConfirmationDialog.new()
	dialog.title = "Identidad de la compañía"
	dialog.ok_button_text = "Aplicar nombres"
	dialog.dialog_hide_on_ok = false
	var form = VBoxContainer.new()
	form.add_theme_constant_override("separation", 10)
	dialog.add_child(form)
	label("Nombre de la compañía", form)
	var company = LineEdit.new()
	company.max_length = 48
	company.text = sim.state.company_name
	form.add_child(company)
	label("Nombre del capitán (tu personaje)", form)
	var captain = LineEdit.new()
	captain.max_length = 48
	captain.text = sim.state.captain_name
	form.add_child(captain)
	label("El jefe de cada operación se elige al desplegar. Máximo: 48 caracteres.", form)
	var feedback = label("", form)
	dialog.confirmed.connect(func():
		if sim.set_identity(company.text, captain.text):
			report("Nombres actualizados. Pulsa Guardar para conservarlos.")
			dialog.hide()
		else:
			feedback.text = "Completa ambos nombres con texto válido.")
	dialog.visibility_changed.connect(func():
		if not dialog.visible: dialog.queue_free())
	add_child(dialog)
	dialog.popup_centered(Vector2i(570, 280))
	company.grab_focus()
	company.select_all()

func show_management(page_index: int = 0):
	var dialog = preload("res://ui/management.gd").new()
	dialog.sim = sim
	dialog.campaign_changed.connect(report)
	add_child(dialog)
	dialog.popup_centered(Vector2i(900, 580))
	dialog.tabs.current_tab = page_index

func confirm_cancel():
	if sim.state.accepted.is_empty():
		report("No hay contrato activo.")
		return
	var dialog = ConfirmationDialog.new()
	dialog.dialog_text = "¿Cancelar / retirarse? Devolverá %d C-bills de anticipo.\nSin pago final; reputación -1, confianza -2 y moral -5.\nEn nuevas operaciones, retirarse tras contacto causa 3 puntos de daño por máquina." % sim.state.accepted.advance
	dialog.confirmed.connect(func(): report(sim.cancel_contract()))
	dialog.visibility_changed.connect(func():
		if not dialog.visible: dialog.queue_free())
	add_child(dialog)
	dialog.popup_centered()

func advance_days(days: int):
	var before = int(sim.state.day)
	sim.advance(days)
	if sim.military_waiting():
		report("Avance detenido: el jefe requiere una decisión en Mando de operaciones.")
	elif not sim.state.issues.is_empty():
		report("Avance detenido tras %d días: hay decisiones urgentes en Asuntos pendientes." % (sim.state.day - before))
	else:
		report("Calendario actualizado: %s." % sim.date_text())


func show_operations():
	var dialog = preload("res://ui/operations.gd").new()
	dialog.sim = sim
	dialog.campaign_changed.connect(report)
	add_child(dialog)
	dialog.popup_centered(Vector2i(850, 610))


func apply_visual_settings():
	terminal_material.set_shader_parameter("scanlines", settings.scanlines)
	terminal_material.set_shader_parameter("vignette", settings.vignette)
	atlas.animation = settings.animation

func show_visual_options():
	var dialog = AcceptDialog.new()
	dialog.title = "Opciones visuales"
	dialog.ok_button_text = "Cerrar"
	var form = VBoxContainer.new()
	dialog.add_child(form)
	label("Efectos de terminal · se guardan fuera de la campaña", form)
	for spec in [["scanlines", "Líneas de escaneo"], ["vignette", "Viñeta"], ["animation", "Animación del indicador de enlace"]]:
		var toggle = CheckBox.new()
		toggle.text = spec[1]
		toggle.button_pressed = settings.get(spec[0])
		toggle.toggled.connect(func(enabled):
			settings.set(spec[0], enabled)
			apply_visual_settings()
			if settings.save_settings() != OK: report("No se pudieron guardar las opciones visuales."))
		form.add_child(toggle)
	label("Los sprites conservan su paleta base. Desactiva los efectos para ver sus colores sin sombreado.", form).autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(dialog)
	dialog.popup_centered(Vector2i(600, 290))


func show_campaign_menu():
	var dialog = AcceptDialog.new()
	dialog.title = "Campaña"
	var box = VBoxContainer.new()
	dialog.add_child(box)
	for spec in [["Guardar", func(): report("Campaña guardada." if sim.save_game() == OK else "Error al guardar.")], ["Cargar", func(): report("Campaña cargada." if sim.load_game() == OK else "No se pudo cargar.")], ["Nueva partida", confirm_new], ["Opciones visuales", show_visual_options], ["Identidad", edit_identity]]:
		button(spec[0], box, func():
			dialog.hide()
			spec[1].call())
	add_child(dialog)
	dialog.popup_centered(Vector2i(420, 330))

func show_decisions():
	if sim.RPG.waiting(sim):
		show_rpg()
		return
	var dialog = AcceptDialog.new()
	dialog.title = "Decisiones del comandante"
	var box = VBoxContainer.new()
	dialog.add_child(box)
	if sim.military_waiting(): button("Responder al jefe de campo", box, func(): dialog.hide(); show_operations())
	if not sim.state.issues.is_empty(): button("Resolver asuntos de compañía", box, func(): dialog.hide(); show_management(3))
	add_child(dialog)
	dialog.popup_centered(Vector2i(450, 230))

func show_sphere():
	var dialog = preload("res://ui/universe.gd").new()
	dialog.sim = sim
	dialog.campaign_changed.connect(report)
	add_child(dialog)
	dialog.popup_centered(Vector2i(1060,700))

func show_missions():
	var dialog = preload("res://ui/missions.gd").new()
	dialog.sim = sim
	dialog.campaign_changed.connect(report)
	add_child(dialog)
	dialog.popup_centered(Vector2i(960,700))

func refresh_journal():
	journal.clear()
	var query = journal_filter.text.to_lower()
	for event in sim.state.chronicle:
		var text = "%s  [%s] %s\n" % [event.date,event.kind,event.text]
		if query.is_empty() or text.to_lower().contains(query): journal.add_text(text)

func show_rpg():
	var dialog = preload("res://ui/rpg.gd").new()
	dialog.sim = sim
	dialog.campaign_changed.connect(report)
	add_child(dialog)
	dialog.popup_centered(Vector2i(1000,760))
