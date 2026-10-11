extends SceneTree
func _initialize():call_deferred("run")
func run():
 var h=load("res://ui/main.tscn").instantiate();h.testing=true
 h.library.directory="user://test-careers-"+str(Time.get_ticks_usec())
 root.add_child(h);await process_frame
 var original=h.sim.state.duplicate(true)
 h.navigate("Campaña","Partidas")
 h.wizard=load("res://ui/pages/new_career.gd").new()
 for step in range(4):h.wizard.step=step;h.render();await process_frame
 assert(h.sim.state==original)
 var draft=h.wizard.draft.duplicate(true)
 h.wizard.step=0;h.render();assert(h.wizard.draft==draft)
 h.wizard.step=3;h.finish_career();h.finish_career();await process_frame
 assert(h.library.entries().size()==2)
 assert(h.sim.state.career_start==draft)
 assert(h.sim.state.rpg.captain.configured)
 var path=h.active_path;h.save_current();h.load_slot(path);await process_frame
 assert(h.sim.state.career_start==draft)
 print("v0.30: asistente reversible, confirmación única y carreras separadas OK")
 quit()
