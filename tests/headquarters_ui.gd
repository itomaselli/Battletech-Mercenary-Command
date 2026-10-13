extends SceneTree
const C=preload("res://sim/campaign.gd")
var failed=false
func check(ok,label):
 if not ok:failed=true;printerr("FAIL: "+label)
func _initialize():call_deferred("run")
func settle():
 for i in range(8):await process_frame
func shot(name):
 if DisplayServer.get_name()!="headless":
  await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png("res://docs/hq-"+name+".png")
func run():
 var host=load("res://ui/main.tscn").instantiate();host.testing=true;root.add_child(host);await settle()
 for size in [Vector2i(1100,740),Vector2i(1672,940)]:
  root.size=size;root.content_scale_size=size;await settle()
  host.navigate("Mando","HQ");await settle();check(host.task_button.text.contains("INSPECCIONAR"),"Acquisition task")
  await shot("acquisition-"+str(size.x))
  for state in ["inspected","pledged","survey","located","refit"]:
   host.sim.state.hq.stage=state;host.render();await settle()
   check(host.content.get_child_count()>0,"Acquisition page "+state)
   check(host.scroll.get_h_scroll_bar().max_value<=host.scroll.size.x+1,"Acquisition overflow "+state)
  var h=host.sim.state.hq;h.stage="owned";h.acquired=0;h.path="purchase";h.origin="Comprada usada mediante corredor en Galatea";h.modules={"workshop":1,"medical":1};h.request={"module":"quarters","person":0,"text":"Elena pide mejorar los camarotes.","day":0}
  var before=host.sim.state.duplicate(true)
  for tab in ["Resumen","Instalaciones","Proyectos","Historia"]:
   host.remember("hq_tab",tab);host.render();await settle()
   check(host.footer.get_global_rect().end.x<=size.x,"Footer "+tab)
   check(host.scroll.size.y>300,"Content height "+tab)
   check(host.scroll.get_h_scroll_bar().max_value<=host.scroll.size.x+1,"Page overflow "+tab)
   check(host.content.get_child_count()>0,"Nonempty "+tab)
   for b in host.content.find_children("*","Button",true,false):
    if b.text.begins_with("ESPACIO"):check(b.size.x>=140 and b.size.y<160,"Deck slot must not collapse")
   await shot(tab+"-"+str(size.x))
  check(host.sim.state==before,"Browsing HQ does not change campaign")
  host.sim=C.new(50)
 if not failed:print("HQ_UI_PASS: acquisition and four tabs at two sizes")
 quit(1 if failed else 0)
