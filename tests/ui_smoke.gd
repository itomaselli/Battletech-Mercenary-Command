extends SceneTree
func _initialize():
	call_deferred("run")
func run():
	var screen = load("res://tests/fixtures/v025_main.tscn").instantiate()
	root.add_child(screen)
	await process_frame
	screen.sim.accept_contract(0)
	screen.report(screen.sim.dispatch(0, [0, 1, 2, 3], 1))
	screen.sim.advance(3)
	screen.refresh()
	await process_frame
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://preview.png")
	print("UI smoke: scene built, operation resolved, report rendered")
	quit()
