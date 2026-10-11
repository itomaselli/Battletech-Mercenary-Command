extends SceneTree
func _initialize(): call_deferred("run")
func run():
 var screen = load("res://tests/fixtures/v025_main.tscn").instantiate()
 root.add_child(screen)
 await process_frame
 screen.show_missions()
 await process_frame
 var dialog = screen.get_child(screen.get_child_count()-1)
 var buttons = []
 for child in dialog.content.get_children():
  if child is Button: buttons.append(child)
 assert(buttons.size() == 5)
 buttons[1].pressed.emit()
 assert(screen.sim.state.accepted.mission_type == "extraction")
 assert(dialog.size.y <= 800)
 if DisplayServer.get_name() != "headless":
  await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png("res://docs/v14-missions.png")
 print("v0.14 UI: cinco ofertas y aceptación OK")
 quit()
