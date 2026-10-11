extends SceneTree
const C=preload("res://sim/campaign.gd")
func configured(seed_value: int):
 var s=C.new(seed_value)
 s.rpg_command("configure",{"origin":"mercenario","specialty":"trato","motivation":"proteccion"})
 return s
func _initialize():
 var s=configured(700)
 var contact=s.RPG.Agenda.known(s)[0]
 s.rpg_command("story_objective",{"action":"choose","kind":"network","contact":contact})
 for i in range(3):
  var cash=s.state.funds
  s.rpg_command("story_objective",{"action":"material"})
  assert(s.RPG.busy(s) and s.state.funds==cash-5000)
  s.advance(1)
 assert(s.state.rpg.agenda.contacts[contact].favors==1)
 var again=s.state.duplicate(true)
 s.rpg_command("story_objective",{"action":"choose","kind":"network","contact":contact})
 assert(s.state==again)
 s.rpg_command("story_objective",{"action":"choose","kind":"person","person":0})
 s.rpg_command("story_objective",{"action":"delegate","officer":4})
 s.person_by_id(4).injury=5
 s.advance(2)
 assert(s.Story.Objectives.current(s).progress==0)
 s.rpg_command("story_objective",{"action":"material"})
 s.advance(2)
 assert(s.Story.Objectives.current(s).progress==1)
 s.rpg_command("story_objective",{"action":"abandon"})
 # Optional requests: reject, insufficient funds and archived employee.
 var p=s.state.story.people.profiles["1"]
 p.goal="security";p.next=s.state.day
 s.state.story.people.last=0;s.state.story.society.pulse=0;s.state.rpg.director.pending={}
 s.advance(7)
 var request=s.Story.People.pending(s)[0]
 s.state.funds=0
 var before=s.state.duplicate(true)
 s.rpg_command("story_people",{"action":"support","id":request.id})
 assert(s.state==before)
 s.rpg_command("story_people",{"action":"decline","id":request.id})
 assert(s.Story.People.pending(s).is_empty())
 # Invalid new subsystem links must reject without changing the current campaign.
 before=s.state.duplicate(true)
 var bad=before.duplicate(true);bad.story.people.profiles["1"].memories=[999999]
 bad.rng_state=str(s.rng.state)
 var file=FileAccess.open("user://story-corrupt.json",FileAccess.WRITE);file.store_string(JSON.stringify(bad));file.close()
 assert(s.load_game("user://story-corrupt.json")==ERR_INVALID_DATA and s.state==before)
 # A non-active person remains in memory; no crash after jobs/cases refer to alumni.
 s.state.funds=100000
 s.dismiss(1)
 s.advance(1)
 assert(s.save_game("user://story-edge.json")==OK)
 var copy=C.new()
 assert(copy.load_game("user://story-edge.json")==OK and copy.state==s.state)
 print("Story: red de apoyo, recuperación del fallo, falta de fondos, rechazo, baja y guardado corrupto OK")
 quit()
