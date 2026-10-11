extends SceneTree
const C=preload("res://sim/campaign.gd")
func _initialize():
 var s=C.new(34)
 s.rpg_command("configure",{"origin":"mercenario","specialty":"trato","motivation":"deuda"})
 var profile=s.state.story.people.profiles["0"]
 profile.goal="mastery"
 s.advance(7)
 var requests=s.Story.People.pending(s)
 assert(requests.size()==1 and requests[0].person==0)
 var cash=s.state.funds
 s.rpg_command("story_people",{"id":requests[0].id,"action":"support"})
 assert(s.state.funds==cash-3000 and not s.person_available(s.person_by_id(0)))
 var after=s.state.duplicate(true)
 s.rpg_command("story_people",{"id":requests[0].id,"action":"support"})
 assert(s.state==after)
 s.advance(2)
 assert(profile.progress==1 and s.person_by_id(0).experience==1)
 assert(s.person_available(s.person_by_id(0)))
 assert(s.save_game("user://story34.json")==OK)
 var loaded=C.new()
 assert(loaded.load_game("user://story34.json")==OK and loaded.state==s.state)
 print("v0.34: petición, coste, reserva, formación, antirrepetición y guardado OK")
 quit()
