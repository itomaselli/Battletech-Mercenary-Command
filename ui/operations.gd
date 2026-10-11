extends AcceptDialog
signal campaign_changed(message: String)
var sim
var embedded=false
var content: VBoxContainer
var feedback: Label
var approach: OptionButton
var authority: OptionButton
var priority: OptionButton

func _ready():
	if embedded:return
	title = "Mando de operaciones"
	ok_button_text = "Cerrar"
	var scroll = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(810, 480)
	add_child(scroll)
	content = VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 10)
	scroll.add_child(content)
	rebuild()

func line(message: String):
	var label = Label.new()
	label.text = message
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(label)

func picker(caption: String, labels: Array, keys: Array, selected: String) -> OptionButton:
	line(caption)
	var control = OptionButton.new()
	control.fit_to_longest_item = not embedded
	for text in labels: control.add_item(text)
	control.selected = maxi(0, keys.find(selected))
	content.add_child(control)
	return control

func action(caption: String, callback: Callable):
	var button = Button.new()
	button.text = caption
	button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	button.pressed.connect(func():
		var result = callback.call()
		campaign_changed.emit(result)
		rebuild()
		line(result))
	content.add_child(button)

func withdrawal():
	var confirm = ConfirmationDialog.new()
	confirm.dialog_text = "¿Ordenar retirada? Se devuelve el anticipo y se aplican las penalizaciones contractuales. Tras contacto, la extracción causa 3 puntos de daño a cada máquina."
	confirm.confirmed.connect(func():
		var result = sim.cancel_contract("Retirada ordenada desde mando de operaciones")
		campaign_changed.emit(result)
		rebuild())
	confirm.visibility_changed.connect(func():
		if not confirm.visible: confirm.queue_free())
	if embedded: get_parent().add_child(confirm)
	else: add_child(confirm)
	confirm.popup_centered(Vector2i(650, 220))

func rebuild():
	for child in content.get_children():
		content.remove_child(child)
		child.queue_free()
	var report = sim.operation_report()
	var current = report.current
	var orders = report.plan if current.is_empty() else current.orders
	line("ÓRDENES DEL COMANDANTE · El contrato fija el objetivo; la doctrina y el jefe se eligen en Operaciones / Preparación.")
	approach = picker("Preparación", ["Avance directo", "Reconocimiento previo · +1 día y 4 suministros"], sim.Operations.APPROACHES, orders.approach)
	authority = picker("Autoridad del jefe", ["Delegar la respuesta al contacto", "Consultar al comandante ante contacto"], sim.Operations.AUTHORITIES, orders.authority)
	priority = picker("Prioridad", ["Cumplir el objetivo", "Preservar la fuerza · retirar si integridad media <65% al contacto"], sim.Operations.PRIORITIES, orders.priority)
	line("Preservar con autoridad delegada permite maniobrar si hay 4 suministros; si la fuerza está por debajo del umbral, el jefe se retira. Consultar deja la decisión en tus manos. La retirada incumple el contrato.")
	if sim.state.accepted.has("mission_type"):
		var kind = sim.Missions.KINDS.find(sim.state.accepted.mission_type)
		line("OBJETIVO: " + sim.state.accepted.objective)
		line(sim.state.accepted.briefing)
		if sim.state.active.is_empty():
			line("Prioridad actual: " + sim.Missions.CHOICES[kind][0 if sim.state.missions.tactic == "careful" else 1])
			action(sim.Missions.CHOICES[kind][0],func(): return sim.configure_mission("careful"))
			action(sim.Missions.CHOICES[kind][1] + " · mayor ritmo/exposición; en interdicción destruye sin recuperar carga",func(): return sim.configure_mission("push"))
		elif sim.state.active.has("objective"):
			line(sim.Missions.report(sim.state.active.objective))
	if sim.state.active.is_empty():
		action("Guardar plan para el próximo despliegue", func(): return sim.configure_operation(sim.Operations.APPROACHES[approach.selected], sim.Operations.AUTHORITIES[authority.selected], sim.Operations.PRIORITIES[priority.selected]))
		line("El plan se aplica al autorizar el despliegue. Se conserva hasta que lo cambies.")
	elif current.is_empty():
		approach.disabled = true
		line("Operación de una partida anterior: conserva sus órdenes y resolución originales. El nuevo mando estará disponible en el siguiente despliegue.")
	else:
		approach.disabled = true
		var leader_person=sim.person_by_id(int(sim.state.active.leader))
		content.add_child(preload("res://visual/art.gd").portrait_view(int(leader_person.get("portrait_seed",sim.state.military.seed)), int(leader_person.get("portrait_id",sim.state.active.leader)), 3))
		line("%s · Jefe: %s\nFase comunicada: %s · Último parte hace %d día(s). El plazo de preparación es una estimación." % [current.contract, current.leader, current.phase, current.age])
		if current.decision:
			line("DECISIÓN PENDIENTE · El calendario está detenido en el parte del jefe.")
			action("Continuar hacia el objetivo", func(): return sim.decide_operation("press"))
			action("Maniobrar · 4 suministros y +1 día", func(): return sim.decide_operation("maneuver"))
		else:
			if current.order_pending: line("Hay una directiva en tránsito. Las órdenes vigentes siguen aplicándose hasta su recepción.")
			action("Transmitir directiva · recepción en 1 día", func(): return sim.send_operation_order(sim.Operations.AUTHORITIES[authority.selected], sim.Operations.PRIORITIES[priority.selected]))
		var retreat = Button.new()
		retreat.text = "Ordenar retirada…"
		retreat.pressed.connect(withdrawal)
		content.add_child(retreat)
		line("PARTES RECIBIDOS · Información de campo parcial; fuerzas enemigas sin confirmar.")
		for item in current.reports:
			line("Día %d · %s: %s" % [item.day, item.source, item.text])
	line("ARCHIVO OPERACIONAL · Últimas 30 operaciones; se muestran las tres más recientes")
	var archive = report.archive.duplicate()
	archive.reverse()
	if archive.is_empty(): line("Todavía no hay operaciones archivadas con el nuevo sistema.")
	for entry in archive.slice(0, 3):
		line("%s · %s\nDías %d–%d · Jefe: %s" % [entry.contract, entry.outcome, entry.started, entry.ended, entry.leader])
		for loss in entry.losses: line("%s · Daño registrado: %d puntos" % [loss.name, loss.damage])
		for item in entry.reports: line("Día %d · %s: %s" % [item.day, item.source, item.text])
