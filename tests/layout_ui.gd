extends SceneTree
func _initialize():call_deferred("run")
func settle():
 for i in range(5):await process_frame
func run():
 var h=load("res://ui/main.tscn").instantiate();h.testing=true;root.add_child(h);await settle()
 for dimensions in [Vector2i(1100,740),Vector2i(1360,960)]:
  root.size=dimensions;root.content_scale_size=dimensions;h.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
  h.settings.text_size=20;h.apply_visual_settings()
  for dest in [["Mando","Bandeja"],["Compañía","Hangar"],["Operaciones","Contratos"],["Mercado","Unidades"],["Mundo","Contactos"]]:
   h.navigate(dest[0],dest[1]);await settle()
   for node in h.find_children("*","Button",true,false):
    if node.get_parent() is FlowContainer:assert(node.size.x>=100 and node.size.y<120,"Collapsed navigation: "+node.text)
   assert(h.scroll.get_h_scroll_bar().max_value<=h.scroll.size.x+1,"Horizontal overflow: "+str(dest))
  h.navigate("Campaña","Partidas");h.wizard=load("res://ui/pages/new_career.gd").new();h.wizard.step=2;h.render();await settle()
  assert(h.scroll.get_h_scroll_bar().max_value<=h.scroll.size.x+1)
  for label in h.content.find_children("*","Label",true,false):
   if label.text.length()>20:assert(label.size.x>=100,"Collapsed label: "+label.text)
  if DisplayServer.get_name()!="headless":
   await RenderingServer.frame_post_draw;root.get_texture().get_image().save_png("res://docs/career-"+str(dimensions.x)+".png")
  h.wizard=null
 print("v0.31: navegación y asistente a 1100/1360, texto grande, sin columnas colapsadas OK")
 quit()
