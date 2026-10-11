extends SceneTree
func _initialize(): call_deferred("run")
func run():
 var screen = load("res://tests/fixtures/v025_main.tscn").instantiate()
 root.add_child(screen)
 await process_frame
 screen.show_rpg()
 await process_frame
 var dialog = screen.get_child(screen.get_child_count()-1)
 assert(dialog.content.find_children("*","OptionButton",true,false).size()==4)
 dialog.execute("configure",{"origin":"oficial","specialty":"trato","motivation":"independencia","bond":0})
 dialog.execute("start_cargo",{})
 await process_frame
 assert(screen.sim.RPG.waiting(screen.sim))
 assert(screen.urgent_button.visible)
 assert(dialog.size.y<900)
 if DisplayServer.get_name()!="headless":
  await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png("res://docs/rpg-scene.png")
 print("RPG UI: creación, escena, alerta y dimensiones OK")
 quit()
