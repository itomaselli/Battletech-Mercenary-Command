extends SceneTree
func _initialize():call_deferred("run")
func settle():
 for i in range(8):await process_frame
func button(h,prefix):
 for b in h.content.find_children("*","Button",true,false):
  if b.is_visible_in_tree() and b.text.begins_with(prefix):return b
 assert(false,"Missing "+prefix);return null
func run():
 var h=load("res://ui/main.tscn").instantiate();h.testing=true;root.add_child(h);await settle()
 var before=h.sim.state.duplicate(true)
 for dimensions in [Vector2i(1100,740),Vector2i(1360,960)]:
  root.size=dimensions;root.content_scale_size=dimensions;h.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
  h.settings.text_size=18;h.apply_visual_settings()
  for dest in [["Mando","Bandeja"],["Compañía","Hangar"],["Finanzas","Previsión"],["Mundo","Atlas"],["Mundo","Entorno"]]:
   h.navigate(dest[0],dest[1]);await settle()
   assert(h.scroll.get_h_scroll_bar().max_value<=h.scroll.size.x+1,"Horizontal overflow "+str(dest))
   if dest[0]!="Finanzas":assert(h.scroll.get_v_scroll_bar().max_value<=h.scroll.size.y+2,"Outer scroll "+str(dest))
   for label in h.content.find_children("*","Label",true,false):
    if label.is_visible_in_tree() and label.text.length()>30:assert(label.size.x>=100,"Collapsed text "+label.text)
   if DisplayServer.get_name()!="headless":
    await RenderingServer.frame_post_draw;root.get_texture().get_image().save_png("res://docs/desk-%s-%d.png"%[dest[1],dimensions.x])
 assert(before==h.sim.state,"Browsing changed simulation")
 h.sim.accept_contract(0);h.navigate("Operaciones","Plan");await settle()
 for dimensions in [Vector2i(1100,740),Vector2i(1360,960)]:
  root.size=dimensions;root.content_scale_size=dimensions;await settle()
  assert(h.scroll.get_v_scroll_bar().max_value<=h.scroll.size.y+2,"Plan outer scroll")
  for b in h.content.find_children("*","Button",true,false):
   if b.is_visible_in_tree():assert(b.size.y<120,"Collapsed plan button: "+b.text)
  if DisplayServer.get_name()!="headless":
   await RenderingServer.frame_post_draw;root.get_texture().get_image().save_png("res://docs/desk-Plan-%d.png"%dimensions.x)
 assert(button(h,"Continuar al plan").disabled)
 for check in h.content.find_children("*","CheckBox",true,false):
  if not check.disabled:check.button_pressed=true
 var selected=h.selected.duplicate()
 button(h,"Continuar al plan").pressed.emit();await settle()
 assert(h.preference("step")==1 and h.selected==selected)
 button(h,"Revisar despliegue").pressed.emit();await settle()
 assert(h.preference("step")==2 and h.sim.state.active.is_empty())
 button(h,"← Paso anterior").pressed.emit();await settle()
 assert(h.preference("step")==1 and h.selected==selected)
 button(h,"Revisar despliegue").pressed.emit();await settle()
 button(h,"Autorizar despliegue").pressed.emit();await settle()
 assert(not h.sim.state.active.is_empty() and h.section=="Batalla")
 print("COMMAND_DESK_PASS: five views, two sizes, read-only navigation, staged dispatch")
 quit()
