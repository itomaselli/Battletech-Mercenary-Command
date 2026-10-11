extends SceneTree
var checks = 0
var failures = 0
func check(ok: bool, message: String):
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL Phase III UI: ", message)
func press(parent: Node, caption: String):
	for button in parent.find_children("*", "Button", true, false):
		if button.text.begins_with(caption):
			button.pressed.emit()
			return
	check(false, "missing " + caption)
func labels(parent: Node) -> String:
	var text = ""
	for label in parent.find_children("*", "Label", true, false): text += label.text
	return text
func capture(path: String):
	await process_frame
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(path)
func _initialize(): call_deferred("run")
func run():
	root.gui_embed_subwindows = true
	var screen = load("res://tests/fixtures/v025_main.tscn").instantiate()
	root.add_child(screen)
	await process_frame
	press(screen, "MANDO DE OPERACIONES")
	await process_frame
	var dialog = screen.get_child(screen.get_child_count() - 1)
	dialog.approach.select(1)
	dialog.authority.select(1)
	dialog.priority.select(0)
	press(dialog, "Guardar plan")
	await process_frame
	check(screen.sim.state.military.plan.approach == "recon" and screen.sim.state.military.plan.authority == "consult", "plan saved from controls")
	await capture("res://docs/operations-plan-preview.png")
	dialog.hide()
	press(screen, "ACEPTAR CONTRATO")
	press(screen, "AUTORIZAR DESPLIEGUE")
	check(not screen.sim.state.active.is_empty() and screen.sim.state.active.remaining == 4, "planned deployment uses main controls")
	press(screen, "+ 7 días")
	check(screen.sim.military_waiting() and screen.status.text.contains("decisión"), "calendar advertises required operational decision")
	press(screen, "MANDO DE OPERACIONES")
	await process_frame
	dialog = screen.get_child(screen.get_child_count() - 1)
	check(labels(dialog).contains("DECISIÓN PENDIENTE"), "pending contact presented")
	check(not labels(dialog).contains("severity") and not labels(dialog).contains("obstacle"), "secret model data not rendered")
	var scroll = dialog.get_children().filter(func(child): return child is ScrollContainer)[0]
	scroll.scroll_vertical = 260
	await capture("res://docs/operations-contact-preview.png")
	var supplies = screen.sim.state.supplies
	press(dialog, "Maniobrar")
	await process_frame
	check(not screen.sim.military_waiting() and screen.sim.state.supplies == supplies - 4, "maneuver from contact controls")
	dialog.hide()
	press(screen, "+ 7 días")
	press(screen, "MANDO DE OPERACIONES")
	await process_frame
	dialog = screen.get_child(screen.get_child_count() - 1)
	check(screen.sim.state.active.is_empty() and labels(dialog).contains("Daño registrado"), "after action report accessible")
	scroll = dialog.get_children().filter(func(child): return child is ScrollContainer)[0]
	scroll.scroll_vertical = 10000
	await capture("res://docs/operations-result-preview.png")
	print("Phase III UI: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
