extends SceneTree
var checks = 0
var failures = 0
func check(ok: bool, description: String):
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL UI v0.3: ", description)
func _initialize(): call_deferred("run")
func press(parent: Node, prefix: String):
	for item in parent.find_children("*", "Button", true, false):
		if item.text.begins_with(prefix):
			item.pressed.emit()
			return
	check(false, "missing button: " + prefix)
func confirm_dialog(parent: Node, accept: bool):
	for child in parent.get_children():
		if child is ConfirmationDialog:
			if accept: child.confirmed.emit()
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
	press(screen, "Hangar / mercado")
	await process_frame
	var dialog = screen.get_child(screen.get_child_count() - 1)
	check(dialog.tabs.get_tab_count() == 8 and dialog.tabs.current_tab == 4, "hangar reachable from main toolbar")
	dialog.tabs.current_tab = 5
	await capture("res://docs/market-preview.png")
	var lot = screen.sim.state.mech_market[0].id
	var cash = screen.sim.state.funds
	press(dialog, "Comprar lote #%d" % lot)
	await process_frame
	confirm_dialog(dialog, false)
	await process_frame
	check(screen.sim.state.funds == cash and screen.sim.state.mech_orders.is_empty(), "cancel purchase leaves campaign unchanged")
	press(dialog, "Comprar lote #%d" % lot)
	await process_frame
	confirm_dialog(dialog, true)
	await process_frame
	check(screen.sim.state.mech_orders.size() == 1 and screen.sim.hangar_used() == 5, "confirm purchase reserves capacity")
	dialog.hide()
	await process_frame
	press(screen, "+ 7 días")
	check(screen.sim.state.mechs.size() == 5 and screen.sim.state.mech_orders.is_empty(), "delivered machine appears in hangar")
	check(screen.selected.is_empty(), "fleet mutation clears stale deployment selections")
	screen.show_management(4)
	await process_frame
	dialog = screen.get_child(screen.get_child_count() - 1)
	await capture("res://docs/hangar-preview.png")
	press(dialog, "Almacenar #0")
	await process_frame
	confirm_dialog(dialog, true)
	await process_frame
	check(screen.sim.state.mechs[0].stored and screen.sim.state.mechs[0].pilot_id == -1, "storage confirmation releases pilot")
	press(dialog, "Reactivar #0")
	await process_frame
	check(not screen.sim.mech_ready(0), "reactivation is not instant")
	var quote = screen.sim.sale_quote(4)
	cash = screen.sim.state.funds
	press(dialog, "Vender #4")
	await process_frame
	confirm_dialog(dialog, false)
	await process_frame
	check(screen.sim.mech_index(4) >= 0 and screen.sim.state.funds == cash, "cancel sale preserves asset")
	press(dialog, "Vender #4")
	await process_frame
	confirm_dialog(dialog, true)
	await process_frame
	check(screen.sim.mech_index(4) == -1 and screen.sim.state.funds == cash + quote, "confirmed sale updates roster and funds")
	dialog.tabs.current_tab = 2
	await capture("res://docs/ownership-preview.png")
	dialog.hide()
	await process_frame
	await capture("res://preview.png")
	print("v0.3 UI: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
