extends SceneTree
# Explicit checks also run in release templates, where assert() is disabled.
var failed=false
func check(condition: bool,label: String):
 if not condition:
  failed=true
  printerr("FAIL: "+label)
func _initialize():call_deferred("run")
func run():
 var C=load("res://sim/campaign.gd")
 check(C!=null,"Simulation bundled")
 if failed:quit(1);return
 var sim=C.new(371)
 check(sim.MECH_CATALOG.size()==56,"Full catalogue")
 check(sim.Universe.load_data().systems.size()>3000,"Atlas data")
 var image=load("res://visual/art.gd").unit_sprite(sim.MECH_CATALOG[0].id)
 check(image!=null and image.get_size()==Vector2i(16,24),"Unique unit art registry")
 sim.rpg_command("configure",{"origin":"oficial","specialty":"mando","motivation":"proteccion"})
 sim.rpg_command("story_objective",{"action":"choose","kind":"person","person":0})
 sim.rpg_command("story_objective",{"action":"material"})
 sim.advance(2)
 check(sim.person_by_id(0).experience==1,"Story progression")
 var path="user://export-smoke-%d.json"%Time.get_ticks_usec()
 check(sim.save_game(path)==OK,"Write test save")
 var copy=C.new()
 check(copy.load_game(path)==OK and copy.state==sim.state,"Load test save")
 DirAccess.remove_absolute(path)
 var h=load("res://ui/main.tscn").instantiate()
 h.testing=true;h.sim=sim
 root.add_child(h)
 for i in range(5):await process_frame
 for destination in [["Compañía","Hangar"],["Mundo","Atlas"],["Capitán","Asuntos"],["Mando","Crónica"]]:
  h.navigate(destination[0],destination[1])
  for i in range(3):await process_frame
  check(h.content.get_child_count()>0,"Page "+destination[1])
 print("EXPORT_SMOKE_PASS" if not failed else "EXPORT_SMOKE_FAIL")
 quit(1 if failed else 0)
