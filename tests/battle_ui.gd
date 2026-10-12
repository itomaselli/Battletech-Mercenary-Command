extends SceneTree
func _initialize():call_deferred("run")
func settle():
 for i in range(5):await process_frame
func run():
 var h=load("res://ui/main.tscn").instantiate();h.testing=true;root.add_child(h);await settle()
 h.sim.accept_contract(0);h.sim.dispatch_battle([0,1,2,3],1)
 for dimensions in [Vector2i(1100,740),Vector2i(1360,960)]:
  root.size=dimensions;root.content_scale_size=dimensions
  h.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
  h.navigate("Operaciones","En curso");await settle()
  var panel=h.content.get_children().filter(func(n):return n.get_script()==load("res://ui/battle_panel.gd"))[0]
  assert(panel.map.size.x>=640 and panel.map.size.y>=300)
  assert(h.scroll.get_h_scroll_bar().max_value<=h.scroll.size.x+1,"Map horizontal overflow")
  panel.group.selected=1;panel.order.selected=5
  var buttons=panel.find_children("*","Button",true,false)
  for b in buttons:
   if b.text=="Transmitir al sector seleccionado":b.pressed.emit()
  assert(h.sim.state.military.current.battle.pending.size()==1)
  h.sim.battle_step();h.sim.battle_step();assert(h.sim.state.military.current.battle.groups.Bravo.order=="reserve")
  panel.clock_button.pressed.emit();assert(panel.playing)
  panel.clock_button.pressed.emit();assert(not panel.playing)
  if DisplayServer.get_name()!="headless":
   await RenderingServer.frame_post_draw;root.get_texture().get_image().save_png("res://docs/battle-"+str(dimensions.x)+".png")
 for i in range(60):h.sim.battle_step()
 var p=h.content.get_children().filter(func(n):return n.get_script()==load("res://ui/battle_panel.gd"))[0]
 p.refresh();await settle()
 if DisplayServer.get_name()!="headless":
  await RenderingServer.frame_post_draw;root.get_texture().get_image().save_png("res://docs/battle-contact.png")
 h.sim.battle_delegate();panel_check(h)
 print("BATTLE_UI_PASS")
 quit()
func panel_check(h):
 h.navigate("Operaciones","En curso")
 assert(h.content.get_children().filter(func(n):return n.get_script()==load("res://ui/battle_panel.gd"))[0].clock_button.disabled)
