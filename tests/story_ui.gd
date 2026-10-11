extends SceneTree
func _initialize():call_deferred("run")
func settle():
 for i in range(4):await process_frame
func button(h,prefix: String):
 for b in h.content.find_children("*","Button",true,false):
  if b.is_visible_in_tree() and b.text.begins_with(prefix):return b
 assert(false,"Missing "+prefix);return null
func run():
 var h=load("res://ui/main.tscn").instantiate();h.testing=true;root.add_child(h);await settle()
 h.sim.rpg_command("configure",{"origin":"oficial","specialty":"mando","motivation":"proteccion"})
 h.sim.state.story.people.profiles["0"].goal="mastery"
 h.sim.advance(7)
 h.navigate("Mando","Bandeja");h.remember("entry","personal:1");h.render();await settle()
 var cash=h.sim.state.funds
 button(h,"Dar apoyo").pressed.emit();await settle()
 assert(h.sim.state.funds==cash-3000)
 h.sim.advance(2)
 h.navigate("Capitán","Asuntos");await settle()
 button(h,"Elegir iniciativa").pressed.emit();await settle()
 assert(h.sim.Story.Objectives.current(h.sim).kind=="person")
 button(h,"Dedicar tiempo del capitán").pressed.emit();await settle()
 assert(h.sim.RPG.busy(h.sim))
 h.sim.advance(2)
 for dimensions in [Vector2i(1100,740),Vector2i(1360,960)]:
  root.size=dimensions;root.content_scale_size=dimensions;h.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
  for dest in [["Mando","Crónica"],["Compañía","Personal"],["Compañía","Hangar"],["Capitán","Asuntos"],["Mundo","Región"]]:
   h.navigate(dest[0],dest[1]);await settle()
   var before=h.sim.state.duplicate(true)
   h.render();await settle();assert(h.sim.state==before)
   assert(h.scroll.get_h_scroll_bar().max_value<=h.scroll.size.x+1,"Overflow "+str(dest))
   if DisplayServer.get_name()!="headless" and dimensions.x==1360 and dest[0] in ["Capitán","Compañía"] and dest[1]!="Hangar":
    await RenderingServer.frame_post_draw
    root.get_texture().get_image().save_png("res://docs/story-"+("objectives" if dest[0]=="Capitán" else "person")+".png")
 print("Story UI: petición → apoyo → objetivo → trabajo, expedientes y 2 resoluciones sin mutar simulación OK")
 quit()
