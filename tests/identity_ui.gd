extends SceneTree
func _initialize():
	call_deferred("run")
func run():
	var screen = load("res://tests/fixtures/v025_main.tscn").instantiate()
	root.add_child(screen)
	await process_frame
	screen.edit_identity()
	await process_frame
	var dialog = screen.get_child(screen.get_child_count() - 1)
	var fields = dialog.find_children("*", "LineEdit", true, false)
	assert(fields.size() == 2)
	fields[0].text = "Lobos del Sur"
	fields[1].text = "Iván Vega"
	dialog.confirmed.emit()
	assert(screen.sim.state.company_name == "Lobos del Sur")
	assert(screen.identity.text.contains("Iván Vega"))
	await process_frame
	print("Identity UI: dialog applied names and refreshed header")
	quit()
