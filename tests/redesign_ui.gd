extends SceneTree
func _initialize():call_deferred("run")
func settle():
 for i in range(12):await process_frame
func button(h,prefix):
 for b in h.find_children("*","Button",true,false):
  if b.is_visible_in_tree() and b.text.begins_with(prefix):return b
 assert(false,"Missing "+prefix);return null
func shot(name):
 if DisplayServer.get_name()!="headless":
  await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png("res://docs/redesign-"+name+".png")
func run():
 var h=load("res://ui/main.tscn").instantiate();h.testing=true;root.add_child(h);await settle()
 h.sim.rpg_command("configure",{"origin":"mercenario","specialty":"trato","motivation":"independencia"})
 var before=h.sim.state.duplicate(true)
 for dimensions in [Vector2i(1100,740),Vector2i(1672,940)]:
  root.size=dimensions;root.content_scale_size=dimensions;h.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);h.settings.text_size=18;h.apply_visual_settings();await settle()
  for route in h.ROUTES:
   for section in h.ROUTES[route]:
    h.navigate(route,section);await settle()
    assert(h.content.get_child_count()>0,"Empty route "+h.key())
    assert(h.sidebar is VBoxContainer)
    assert(h.scroll.size.y>300,"Header/footer consume the page "+h.key()+" "+str(h.scroll.size))
    assert(h.save_button.size.x>=90 and h.save_button.size.y<70,"Utility button collapsed")
    assert(h.sidebar.get_global_rect().end.x<=dimensions.x,"Navigation overflow "+h.key())
    assert(h.footer.get_global_rect().end.x<=dimensions.x,"Footer overflow "+h.key()+" "+str(h.footer.size))
    assert(h.scroll.get_h_scroll_bar().max_value<=h.scroll.size.x+1,"Horizontal overflow "+h.key())
    for b in h.sidebar.get_children():assert(b.size.y<90,"Collapsed navigation")
    if section in ["Territorio","Bandeja","Hangar","Personal","Previsión","Atlas","Personaje","Unidades","Identidad"]:await shot(section+"-"+str(dimensions.x))
 assert(before==h.sim.state,"Reading UI changed campaign")
 h.navigate("Campaña","Identidad");await settle()
 var choices=h.content.find_children("*","Button",true,false).filter(func(b):return b.tooltip_text.begins_with("50 ·"))
 assert(choices.size()==1);choices[0].pressed.emit();await settle();assert(h.sim.state.emblem_id==49)
 assert(h.emblem.texture.region==load("res://visual/emblems.gd").texture(49).region)
 h.navigate("Compañía","Hangar");await settle();button(h,"ABRIR EXPEDIENTE").pressed.emit();await settle()
 assert(h.preference("sheet",false));button(h,"Historia").pressed.emit();await settle();assert(h.preference("dossier_tab")=="Historia")
 h.sim.accept_contract(0);h.navigate("Operaciones","Plan");await settle()
 for check in h.content.find_children("*","CheckBox",true,false):
  if not check.disabled:check.button_pressed=true
 await shot("preparacion-1672")
 assert(h.selected.size()==4 and not h.task_button.disabled)
 button(h,"Continuar al plan").pressed.emit();await settle();button(h,"Revisar despliegue").pressed.emit();await settle()
 assert(h.sim.state.active.is_empty());await shot("revision-1672")
 button(h,"Autorizar despliegue").pressed.emit();await settle();assert(h.section=="Batalla" and not h.sim.state.active.is_empty())
 for dimensions in [Vector2i(1100,740),Vector2i(1672,940)]:
  root.size=dimensions;root.content_scale_size=dimensions;await settle()
  assert(h.footer.get_global_rect().end.x<=dimensions.x,"Battle overflow")
  assert(h.scroll.get_v_scroll_bar().max_value<=h.scroll.size.y+2,"Battle page overflow "+str(h.scroll.get_v_scroll_bar().max_value)+" / "+str(h.scroll.size.y))
  await shot("batalla-"+str(dimensions.x))
 h.navigate("Campaña","Partidas");h.wizard=load("res://ui/pages/new_career.gd").new();h.render();await settle()
 for step in range(4):
  h.wizard.step=step;h.render();await settle();assert(h.task_button.visible)
 await shot("carrera-1672")
 print("REDESIGN_UI_PASS: all routes, sizes, cards, history, staged deployment, new career")
 quit()
