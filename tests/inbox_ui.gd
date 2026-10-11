extends SceneTree
func _initialize():call_deferred("run")
func run():
 var s=load("res://ui/main.tscn").instantiate();root.add_child(s);await process_frame
 s.sim.state.mechs[0].hp=60
 s.sim._add_issue("medical",0,"Informe médico de prueba")
 var before=s.sim.state.duplicate(true)
 s.render();await process_frame
 assert(s.sim.state==before)
 var records=preload("res://ui/pages/inbox.gd").entries(s.sim)
 assert(records.any(func(e):return e.id.begins_with("issue:")))
 assert(records.any(func(e):return e.id=="unit:0"))
 s.navigate("Compañía","Personal");s.remember("id",4);s.render();await process_frame
 s.navigate("Compañía","Taller");await process_frame
 s.back();assert(s.preference("id")==4)
 assert(s.find_children("*","Window",true,false).filter(func(n):return n.visible).is_empty())
 print("v0.27: bandeja causal, expedientes, selección estable y render sin efectos OK")
 quit()
