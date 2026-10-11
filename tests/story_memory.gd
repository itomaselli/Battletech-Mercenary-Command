extends SceneTree
const C=preload("res://sim/campaign.gd")
func _initialize():
 var s=C.new(33)
 var rng=s.rng.state
 var a=s.log_event("Test","Primera decisión",[0],[0],"test")
 var b=s.log_event("Test","Consecuencia",[0],[0],"test")
 assert(s.state.story.events[-1].parents==[a] and b>a)
 assert(s.rng.state==rng)
 assert(s.Story.valid(s.state.story,s.state.day))
 assert(s.save_game("user://story33.json")==OK)
 var copy=C.new()
 assert(copy.load_game("user://story33.json")==OK and copy.state==s.state)
 var broken=s.state.story.duplicate(true)
 broken.events[0].parents=[b]
 assert(not s.Story.valid(broken,s.state.day))
 assert(copy.load_game("res://tests/fixtures/campaign-v025.json")==OK)
 assert(copy.state.story.events.is_empty())
 assert(copy.state.story.since==copy.state.day)
 print("v0.33: enlaces, causalidad anterior, RNG, migración sin recuerdos inventados y guardado OK")
 quit()
