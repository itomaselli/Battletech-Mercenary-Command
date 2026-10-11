extends SceneTree
var checks = 0
var failures = 0
func check(ok: bool, msg: String):
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL Phase II UI: ", msg)
func press(parent: Node, prefix: String):
	for button in parent.find_children("*", "Button", true, false):
		if button.text.begins_with(prefix):
			button.pressed.emit()
			return
	check(false, "missing " + prefix)
func confirm(parent: Node, accept: bool):
	for child in parent.get_children():
		if child is ConfirmationDialog:
			if accept: child.confirmed.emit()
			child.hide()
			return
	check(false, "missing confirmation")
func labels(parent: Node) -> String:
	var result = ""
	for label in parent.find_children("*", "Label", true, false): result += label.text
	return result
func _initialize(): call_deferred("run")
func run():
	root.gui_embed_subwindows = true
	var screen = load("res://tests/fixtures/v025_main.tscn").instantiate()
	root.add_child(screen)
	await process_frame
	screen.sim.advance(14)
	press(screen, "Mundo")
	await process_frame
	var dialog = screen.get_child(screen.get_child_count() - 1)
	var picker = dialog.tabs.get_child(7).find_children("*", "OptionButton", true, false)[0]
	picker.item_selected.emit(3)
	await process_frame
	check(labels(dialog).contains("OPORTUNIDADES DEL MUNDO") and labels(dialog).contains("Refuerzo: Protección industrial"), "causal request shown in employer profile")
	var cash = screen.sim.state.funds
	press(dialog, "Aceptar oportunidad")
	await process_frame
	confirm(dialog, false)
	check(screen.sim.state.funds == cash and screen.sim.state.accepted.is_empty(), "cancel acceptance leaves contract unchanged")
	press(dialog, "Aceptar oportunidad")
	await process_frame
	confirm(dialog, true)
	await process_frame
	check(screen.sim.state.accepted.has("world_origin") and labels(dialog).contains("Aceptada"), "confirmed causal contract displayed")
	press(dialog, "Establecer contacto")
	await process_frame
	confirm(dialog, true)
	await process_frame
	cash = screen.sim.state.funds
	press(dialog, "Solicitar informe")
	await process_frame
	confirm(dialog, false)
	check(screen.sim.state.funds == cash, "report cancellation has no cost")
	press(dialog, "Solicitar informe")
	await process_frame
	confirm(dialog, true)
	await process_frame
	check(screen.sim.state.funds == cash - 500 and labels(dialog).contains("Consulta en curso"), "query confirmed and pending")
	screen.sim.advance(2)
	dialog.rebuild()
	await process_frame
	check(labels(dialog).contains("Observado día 14 · Recibido día 16") and labels(dialog).contains("sin corroboración independiente"), "dated and qualified report arrives")
	check(not labels(dialog).contains("difficulty") and not labels(dialog).contains("capacity"), "internal values remain hidden")
	dialog.tabs.get_child(7).scroll_vertical = 10000
	await process_frame
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://docs/phase2-preview.png")
	print("Phase II UI: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
