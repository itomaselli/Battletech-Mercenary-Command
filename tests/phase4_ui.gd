extends SceneTree
var checks = 0
var failures = 0
func check(ok: bool, message: String):
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL Phase IV UI: ", message)
func press(parent: Node, caption: String):
	for button in parent.find_children("*", "Button", true, false):
		if button.text.begins_with(caption):
			button.pressed.emit()
			return
	check(false, "missing " + caption)
func capture(path: String):
	await process_frame
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(path)
func _initialize(): call_deferred("run")
func run():
	var screen = load("res://tests/fixtures/v025_main.tscn").instantiate()
	root.add_child(screen)
	await process_frame
	screen.settings.path = "user://phase4_ui_settings.cfg"
	check(screen.sections.get_tab_count() == 3 and screen.sections.current_tab == 0, "command center is default with three clear sections")
	check(screen.atlas.map.texture.get_size() == Vector2(1280, 600), "full eighty by twenty five raster")
	check(screen.atlas.crew.get_child_count() == 7, "procedural staff portrait cards")
	var old_map = screen.atlas.map.texture.get_image().get_data()
	var picker = screen.atlas.find_children("*", "OptionButton", true, false)[0]
	picker.item_selected.emit(2)
	check(screen.atlas.map.texture.get_image().get_data() != old_map, "sector selector changes procedural environment")
	picker.item_selected.emit(0)
	await capture("res://docs/phase4-command-preview.png")
	press(screen, "Opciones visuales")
	await process_frame
	var dialog = screen.get_child(screen.get_child_count() - 1)
	var toggles = dialog.find_children("*", "CheckBox", true, false)
	for toggle in toggles: toggle.button_pressed = false
	check(not screen.settings.scanlines and not screen.settings.vignette and not screen.settings.animation, "effects disabled through options")
	check(not screen.terminal_material.get_shader_parameter("scanlines") and not screen.terminal_material.get_shader_parameter("vignette"), "options reach CRT shader")
	dialog.hide()
	screen.sections.current_tab = 1
	await process_frame
	check(screen.roster.is_visible_in_tree() and not screen.atlas.is_visible_in_tree(), "fleet controls accessible in their section")
	press(screen, "ACEPTAR CONTRATO")
	press(screen, "AUTORIZAR DESPLIEGUE")
	check(not screen.sim.state.active.is_empty(), "refactored navigation preserves deployment")
	await capture("res://docs/phase4-orders-preview.png")
	screen.sections.current_tab = 2
	await process_frame
	check(screen.journal.is_visible_in_tree(), "chronicle has dedicated reading space")
	screen.show_management(6)
	await process_frame
	dialog = screen.get_child(screen.get_child_count() - 1)
	check(dialog.tabs.get_child(6).find_children("*", "TextureRect", true, false).size() == 1, "dossier uses matching procedural portrait")
	await capture("res://docs/phase4-dossier-preview.png")
	print("Phase IV UI: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
