extends SceneTree
func _initialize():call_deferred("run")
func run():
 var screen=load("res://tests/fixtures/v025_main.tscn").instantiate()
 root.add_child(screen)
 await process_frame
 screen.sim.rpg_command("configure",{"origin":"tecnico","specialty":"investigacion","motivation":"deuda","bond":4})
 screen.sim.RPG.Conflicts.ensure(screen.sim)
 screen.show_rpg()
 await process_frame
 var d=screen.get_child(screen.get_child_count()-1)
 for page in ["Escena","Personaje","Asuntos","Agenda","Contratos","Taller","Región","Oficiales","Memoria","Legado"]:
  d.page=page
  d.rebuild()
  await process_frame
  assert(d.content.get_child_count()>2)
  assert(d.size.y<900 and d.size.x<=1050)
  for label in d.content.find_children("*","Label",true,false):assert(label.size.x>=850)
  if DisplayServer.get_name()!="headless" and page in ["Oficiales","Legado"]:
   await RenderingServer.frame_post_draw
   root.get_texture().get_image().save_png("res://docs/rpg-"+("officers" if page=="Oficiales" else "legacy")+".png")
 d.page="Oficiales"
 d.custom_delegation=true
 d.rebuild()
 await process_frame
 assert(d.content.find_children("*","OptionButton",true,false).size()==5)
 assert(d.content.find_children("*","SpinBox",true,false).size()==3)
 print("RPG UI: diez secciones con controles legibles y ventana acotada OK")
 quit()
