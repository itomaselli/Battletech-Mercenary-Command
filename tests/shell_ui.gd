extends SceneTree
func _initialize():call_deferred("run")
func run():
 var screen=load("res://ui/main.tscn").instantiate();screen.testing=true;root.add_child(screen);await process_frame
 assert(screen.route=="Operaciones" and screen.section=="Territorio")
 screen.navigate("Compañía","Hangar");await process_frame
 assert(screen.content.get_child_count()>1)
 screen.navigate("Finanzas","Previsión");screen.back();await process_frame
 assert(screen.route=="Compañía" and screen.section=="Hangar")
 assert(screen.find_children("*","Window",true,false).filter(func(n):return n.visible).is_empty())
 print("v0.26: estructura persistente, hangar, finanzas y navegación sin ventanas OK")
 quit()
