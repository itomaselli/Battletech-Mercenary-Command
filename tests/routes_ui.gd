extends SceneTree
func _initialize():call_deferred("run")
func run():
 var h=load("res://ui/main.tscn").instantiate();h.testing=true;root.add_child(h);await process_frame
 h.sim.rpg_command("configure",{"origin":"mercenario","specialty":"trato","motivation":"independencia"})
 var before=h.sim.state.duplicate(true)
 for route in h.ROUTES:
  for section in h.ROUTES[route]:
   h.navigate(route,section);await process_frame
   assert(h.content.get_child_count()>1)
   assert(h.find_children("*","Window",true,false).filter(func(n):return n.visible).is_empty())
 assert(before==h.sim.state)
 h.sim.accept_contract(0);h.navigate("Operaciones","Preparación");await process_frame
 h.selected=[0,1,2,3]
 assert(h.content.find_children("*","CheckBox",true,false).size()==4)
 if DisplayServer.get_name()!="headless":
  h.navigate("Mando","Bandeja");await process_frame;await RenderingServer.frame_post_draw;root.get_texture().get_image().save_png("res://docs/ui-integrated.png")
 print("v0.28: todas las rutas integradas, render sin efectos y preparación OK")
 quit()
