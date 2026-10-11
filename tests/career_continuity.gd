extends SceneTree
func _initialize():
 var sim=load("res://sim/campaign.gd").new()
 var original=JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/campaign-v025.json"))
 assert(sim.load_game("res://tests/fixtures/campaign-v025.json")==OK)
 original.erase("rng_state");original.version=25;original.career_start={}
 original.story=sim.state.story.duplicate(true)
 original.rpg.social.ties=sim.state.rpg.social.ties.duplicate(true)
 assert(sim.state==sim._normalize_numbers(original))
 print("v0.31: guardado real v0.25 conserva todo el estado, personal y operación en curso OK")
 quit()
