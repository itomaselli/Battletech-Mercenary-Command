extends SceneTree
func _initialize():call_deferred("run")
func button(h,prefix: String):
 for b in h.find_children("*","Button",true,false):
  if b.is_visible_in_tree() and b.text.begins_with(prefix):return b
 assert(false,"Missing button: "+prefix);return null
func settle():
 for i in range(4):await process_frame
func run():
 var h=load("res://ui/main.tscn").instantiate();h.testing=true;h.library.directory="user://test-journey-"+str(Time.get_ticks_usec());root.add_child(h);await settle()
 h.wizard=load("res://ui/pages/new_career.gd").new();h.wizard.seed_value=86;h.wizard.regenerate();h.finish_career();await settle()
 h.navigate("Operaciones","Contratos");await settle()
 button(h,"Aceptar condiciones").pressed.emit();await settle();assert(h.section=="Plan")
 for check in h.content.find_children("*","CheckBox",true,false):check.button_pressed=true
 button(h,"Autorizar despliegue").pressed.emit();await settle();assert(not h.sim.state.active.is_empty() and h.section=="Batalla")
 for i in range(5):
  if h.sim.state.active.is_empty():break
  h.advance_days(1);await settle()
 assert(h.sim.state.active.is_empty())
 h.navigate("Mundo","Contactos");await settle()
 var before=h.sim.state.duplicate(true)
 button(h,"Establecer contacto").pressed.emit();await settle()
 var dialogs=h.find_children("*","ConfirmationDialog",true,false).filter(func(d):return d.visible)
 assert(dialogs.size()==1 and dialogs[0].get_parent()==h)
 dialogs[0].canceled.emit();dialogs[0].hide();await settle();assert(h.sim.state==before)
 print("v0.31: carrera → aceptar → preparar → desplegar → informe, confirmación cancelable OK")
 quit()
