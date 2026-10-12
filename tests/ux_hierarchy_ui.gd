extends SceneTree
func _initialize():call_deferred("run")
func settle():
 for i in range(8):await process_frame
func panel(h):return h.content.get_children().filter(func(n):return n.get_script()==load("res://ui/battle_panel.gd"))[0]
func run():
 var h=load("res://ui/main.tscn").instantiate();h.testing=true;root.add_child(h);await settle()
 var before=h.sim.state.duplicate(true)
 for dimensions in [Vector2i(1100,740),Vector2i(1360,960)]:
  root.size=dimensions;root.content_scale_size=dimensions;h.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
  h.settings.text_size=18;h.apply_visual_settings()
  for dest in [["Mando","Bandeja"],["Mando","Crónica"],["Compañía","Personal"],["Compañía","Hangar"],["Operaciones","Resumen"],["Operaciones","Contratos"],["Operaciones","Plan"],["Operaciones","Informe"]]:
   h.navigate(dest[0],dest[1]);await settle()
   assert(h.scroll.get_h_scroll_bar().max_value<=h.scroll.size.x+1,"Horizontal overflow "+str(dest))
   if DisplayServer.get_name()!="headless" and dest==["Compañía","Personal"]:
    await RenderingServer.frame_post_draw;root.get_texture().get_image().save_png("res://docs/ux-personal-%d.png"%dimensions.x)
 assert(before==h.sim.state,"Browsing must not change campaign")
 h.sim.accept_contract(0);h.sim.dispatch_battle([0,1,2,3],1)
 for dimensions in [Vector2i(1100,740),Vector2i(1360,960)]:
  root.size=dimensions;root.content_scale_size=dimensions;h.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
  h.navigate("Operaciones","Batalla");await settle()
  var p=panel(h)
  assert(h.scroll.get_h_scroll_bar().max_value<=h.scroll.size.x+1,"Battle horizontal overflow")
  print("Battle layout ",dimensions," outer ",h.scroll.get_v_scroll_bar().max_value," / ",h.scroll.size.y," map ",p.map.size)
  assert(p.map.size.x>=200 and p.map.size.y>=130)
  assert(h.scroll.get_v_scroll_bar().max_value<=h.scroll.size.y+1,"Battle must fit without whole-page scrolling")
  assert(p.transmit.get_global_rect().end.y<=h.scroll.get_global_rect().end.y,"Primary order must stay visible")
  assert(h.continue_button.disabled and not h.save_button.disabled)
  var hit=InputEventMouseButton.new();hit.button_index=MOUSE_BUTTON_LEFT;hit.pressed=true
  var area=p.map.map_rect();hit.position=area.position+Vector2(area.size.x*0.25,area.size.y*0.4)
  p.map._gui_input(hit);assert(p.target==Vector2i(20,10))
  assert(p.transmit.text.contains("20,10"))
  p.group.selected=1;p.group.item_selected.emit(1);p.order.selected=5;p.transmit.pressed.emit()
  assert(h.sim.state.military.current.battle.pending[0].group=="Bravo")
  assert(p.selection.text.contains("Bravo") and p.transmit.disabled)
  h.sim.battle_step();h.sim.battle_step();p.refresh()
  h.render();await settle();assert(panel(h).group.selected==1)
  if DisplayServer.get_name()!="headless":
   await RenderingServer.frame_post_draw;root.get_texture().get_image().save_png("res://docs/ux-battle-%d.png"%dimensions.x)
 # Pagination changes the selected record and keeps every record reachable.
 h.navigate("Mando","Bandeja");h.remember("filter","archive");h.render();await settle()
 for i in range(15):h.sim.log_event("Prueba UX","Informe de prueba %d"%i)
 h.render();await settle()
 var next=h.content.find_children("*","Button",true,false).filter(func(b):return b.text=="Siguiente ›")[0]
 assert(not next.disabled);next.pressed.emit();await settle()
 assert(h.preference("page")==1 and not str(h.preference("entry","")).is_empty())
 h.remember("filter","decision");h.remember("page",0);h.render();await settle()
 assert(h.content.find_children("*","Label",true,false).any(func(l):return l.text=="Sin informes pendientes."))
 print("UX_HIERARCHY_PASS")
 quit()
