extends SceneTree
var checks = 0
var failures = 0
func check(ok: bool, message: String):
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL UI v0.5: ", message)
func _initialize(): call_deferred("run")
func press(parent: Node, prefix: String):
	for item in parent.find_children("*", "Button", true, false):
		if item.text.begins_with(prefix):
			item.pressed.emit()
			return
	check(false, "missing button " + prefix)
func confirm(parent: Node, accept: bool):
	for child in parent.get_children():
		if child is ConfirmationDialog:
			if accept: child.confirmed.emit()
			child.hide()
			return
	check(false, "confirmation missing")
func capture(path: String):
	if DisplayServer.get_name() != "headless":
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(path)
func run():
	root.gui_embed_subwindows = true
	var screen = load("res://tests/fixtures/v025_main.tscn").instantiate()
	root.add_child(screen)
	await process_frame
	screen.sim.state.world.actors[0].private.priority = "SECRET_SENTINEL"
	press(screen, "Mundo")
	await process_frame
	var dialog = screen.get_child(screen.get_child_count() - 1)
	check(dialog.tabs.current_tab == 7 and dialog.tabs.get_tab_count() == 8, "world directory opens from toolbar")
	var picker = dialog.tabs.get_child(7).find_children("*", "OptionButton", true, false)[0]
	check(picker.item_count == 7, "seven actor profiles selectable")
	var text = ""
	for label in dialog.tabs.get_child(7).find_children("*", "Label", true, false): text += label.text
	check(not text.contains("SECRET_SENTINEL") and text.contains("no confirmadas"), "UI shows reports instead of internal facts")
	await capture("res://docs/world-employer-preview.png")
	var cash = screen.sim.state.funds
	press(dialog, "Establecer contacto")
	await process_frame
	confirm(dialog, false)
	await process_frame
	check(screen.sim.state.funds == cash, "cancel contact leaves funds unchanged")
	press(dialog, "Establecer contacto")
	await process_frame
	confirm(dialog, true)
	await process_frame
	check(screen.sim.state.funds == cash - 1000 and screen.sim.state.world.actors[0].contact_day == 0, "contact confirmed through UI")
	picker = dialog.tabs.get_child(7).find_children("*", "OptionButton", true, false)[0]
	picker.item_selected.emit(4)
	await process_frame
	check(dialog.world_actor_id == "grey_lances", "rival profile selected")
	await capture("res://docs/world-rival-preview.png")
	dialog.hide()
	await process_frame
	await capture("res://preview.png")
	print("v0.5 UI: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
