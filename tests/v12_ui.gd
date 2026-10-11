extends SceneTree
func _initialize(): call_deferred("run")
func run():
 var screen = load("res://tests/fixtures/v025_main.tscn").instantiate()
 root.add_child(screen)
 await process_frame
 screen.show_sphere()
 await process_frame
 for frame in range(5): await process_frame
 var dialog = screen.get_child(screen.get_child_count()-1)
 print("Atlas dimensions ",dialog.size," map ",dialog.map.size)
 assert(dialog.size.y < 850)
 assert(dialog.map.size.y <= 550)
 assert(dialog.map.year == 3027)
 dialog.map.focus(screen.sim.state.location_id)
 assert(not dialog.map.selected_id.is_empty())
 if DisplayServer.get_name() != "headless":
  await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png("res://docs/v12-atlas.png")
 print("v0.12 UI: atlas opened and selected location")
 quit()
