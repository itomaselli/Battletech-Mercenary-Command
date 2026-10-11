extends SceneTree
var checks = 0
var failures = 0
func check(ok: bool, message: String):
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL UI v0.4: ", message)
func _initialize(): call_deferred("run")
func press(parent: Node, prefix: String):
	for button in parent.find_children("*", "Button", true, false):
		if button.text.begins_with(prefix):
			button.pressed.emit()
			return
	check(false, "missing control: " + prefix)
func confirm(parent: Node):
	for child in parent.get_children():
		if child is ConfirmationDialog:
			child.confirmed.emit()
			child.hide()
			return
	check(false, "missing confirmation")
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
	# Seed a coherent service record for the UI fixture.
	for i in range(3):
		screen.sim._award_operation({"team": [0, 1], "contract": {"name": "Escolta de convoy"}, "doctrine": 1}, true)
	press(screen, "Expedientes")
	await process_frame
	var dialog = screen.get_child(screen.get_child_count() - 1)
	check(dialog.tabs.get_tab_count() == 8 and dialog.tabs.current_tab == 6, "dossiers accessible")
	press(dialog, "Ascender a Elena Voss")
	await process_frame
	confirm(dialog)
	await process_frame
	check(screen.sim.person_by_id(0).promotions == 1, "promotion through UI")
	press(dialog, "Conceder descanso a Elena Voss")
	await process_frame
	confirm(dialog)
	await process_frame
	check(screen.sim.person_by_id(0).rest_until == 3, "leave through UI")
	await capture("res://docs/dossier-preview.png")
	dialog.hide()
	await process_frame
	screen.sim.person_by_id(1).injury = 8
	screen.sim._operation_story({"team": [1]})
	screen.refresh()
	press(screen, "+ 7 días")
	check(screen.sim.state.day == 0 and screen.urgent_button.visible, "story pauses calendar and displays alert")
	screen.show_management(3)
	await process_frame
	dialog = screen.get_child(screen.get_child_count() - 1)
	await capture("res://docs/personal-story-preview.png")
	press(dialog, "Atención especializada")
	check(screen.sim.person_by_id(1).injury == 5 and screen.sim.state.issues.is_empty(), "medical decision through UI")
	dialog.hide()
	await process_frame
	press(screen, "+ 7 días")
	check(screen.sim.state.day == 7 and screen.sim.person_by_id(1).injury == 0, "time resumes and patient recovers")
	screen.show_management(6)
	await process_frame
	dialog = screen.get_child(screen.get_child_count() - 1)
	screen.sim.dismiss(0)
	dialog.rebuild()
	check(screen.sim.state.alumni.size() == 1, "archived dossier available")
	await capture("res://docs/alumni-preview.png")
	dialog.hide()
	await process_frame
	await capture("res://preview.png")
	print("v0.4 UI: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
