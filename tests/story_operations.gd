extends SceneTree
const C=preload("res://sim/campaign.gd")
func _initialize():
 var s=C.new(910)
 s.rpg_command("configure",{"origin":"oficial","specialty":"mando","motivation":"proteccion"})
 s.accept_contract(0)
 s.configure_operation("direct","delegate","preserve")
 s.dispatch(0,[0,1,2,3],0)
 var thread=s.Story.operation_key(s)
 for i in range(12):
  if s.state.active.is_empty():break
  s.advance(1)
 assert(s.state.active.is_empty())
 var events=s.state.story.events.filter(func(e):return e.thread==thread)
 assert(events.size()>=3 and not events[-1].parents.is_empty())
 for m in s.state.mechs:
  assert(s.state.story.culture.units[str(m.uid)].service==1)
 assert(s.state.story.culture.practices.care==1)
 assert(s.save_game("user://story-operation.json")==OK)
 var copy=C.new()
 assert(copy.load_game("user://story-operation.json")==OK and copy.state==s.state)
 # Withdrawal closes the same causal thread.
 var retreat=C.new(911)
 retreat.accept_contract(0);retreat.dispatch(0,[0,1],0)
 thread=retreat.Story.operation_key(retreat)
 retreat.cancel_contract()
 assert(retreat.state.story.events.any(func(e):return e.thread==thread and e.text.contains("retirada ordenada")))
 # External mentorship does not reserve the captain, but keeps the student unavailable.
 s=C.new(912)
 s.rpg_command("configure",{"origin":"oficial","specialty":"mando","motivation":"proteccion"})
 s.rpg_command("story_objective",{"action":"choose","kind":"person","person":0})
 var funds=s.state.funds
 s.rpg_command("story_objective",{"action":"material"})
 assert(s.state.funds==funds-5000 and not s.RPG.busy(s) and not s.person_available(s.person_by_id(0)))
 assert(s.save_game("user://story-external.json")==OK)
 assert(copy.load_game("user://story-external.json")==OK and copy.state==s.state)
 print("Story: partes enlazados, servicio real, retirada y alternativa de formación externa OK")
 quit()
