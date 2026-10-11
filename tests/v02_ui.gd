extends SceneTree
var failures = 0
var checks = 0
func check(ok: bool, description: String):
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL UI: ", description)
func _initialize():
	call_deferred("run")
func find_button(parent: Node, prefix: String) -> Button:
	for item in parent.find_children("*", "Button", true, false):
		if item.text.begins_with(prefix): return item
	return null
func press(parent: Node, prefix: String):
	var button = find_button(parent, prefix)
	check(button != null, "button exists: " + prefix)
	if button != null: button.pressed.emit()
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
	screen.show_management(0)
	await process_frame
	var dialog = screen.get_child(screen.get_child_count() - 1)
	check(dialog.tabs.get_tab_count() == 8, "management pages plus hangar")
	press(dialog, "Contratar · incorporación 12000")
	await process_frame
	check(screen.sim.state.staff.size() == 7, "hire through UI")
	var picker = dialog.tabs.get_child(0).find_children("*", "OptionButton", true, false)[0]
	picker.item_selected.emit(5)
	await process_frame
	check(screen.sim.state.mechs[0].pilot_id == 6, "assign reserve through UI")
	dialog.tabs.current_tab = 1
	await process_frame
	press(dialog, "Normal: 30 suministros")
	await process_frame
	check(screen.sim.state.orders.size() == 1, "order supplies through UI")
	dialog.tabs.current_tab = 2
	await capture("res://docs/finance-preview.png")
	dialog.hide()
	await process_frame
	press(screen, "ACEPTAR CONTRATO")
	check(not screen.sim.state.accepted.is_empty(), "accept through UI")
	press(screen, "+ 7 días")
	check(screen.sim.state.day == 3 and screen.urgent_button.visible, "urgent stop visible in main UI")
	screen.show_management(3)
	await process_frame
	dialog = screen.get_child(screen.get_child_count() - 1)
	await capture("res://docs/issues-preview.png")
	press(dialog, "Mantener compromiso")
	check(screen.sim.state.issues.is_empty(), "resolve pending decision through UI")
	dialog.hide()
	await process_frame
	press(screen, "AUTORIZAR DESPLIEGUE")
	check(not screen.sim.state.active.is_empty(), "deploy assigned reserve through UI")
	press(screen, "+ 7 días")
	check(screen.sim.state.active.is_empty() and screen.sim.state.orders.is_empty(), "operation and delivery complete through UI")
	screen.show_management(0)
	await process_frame
	dialog = screen.get_child(screen.get_child_count() - 1)
	await capture("res://docs/personnel-preview.png")
	dialog.hide()
	await process_frame
	await capture("res://preview.png")
	print("v0.2 UI: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
