extends SceneTree
const C = preload("res://sim/campaign.gd")
func write_data(data):
 var f = FileAccess.open("user://expansion-invalid.json",FileAccess.WRITE)
 f.store_string(JSON.stringify(data))
 f.close()
func _initialize():
 var sim = C.new(2,3060)
 sim.accept_mission(sim.state.missions.offers[0].id)
 sim.dispatch(0,[0,1,2,3],1)
 var original = sim.state.duplicate(true)
 var saved = original.duplicate(true)
 saved.rng_state = str(sim.rng.state)
 var corruptions = []
 var bad = saved.duplicate(true)
 bad.active.objective.profiles = []
 corruptions.append(bad)
 bad = saved.duplicate(true)
 bad.active.objective.progress = 999
 corruptions.append(bad)
 bad = saved.duplicate(true)
 bad.missions.offers[0].employer_id = "lore-wolf"
 corruptions.append(bad)
 bad = saved.duplicate(true)
 bad.missions.regions[sim.state.location_id].supply = -100
 corruptions.append(bad)
 bad = saved.duplicate(true)
 bad.travel = {"route":[],"arrival":999}
 corruptions.append(bad)
 bad = saved.duplicate(true)
 bad.mechs[0].model_id = "no-such-variant"
 corruptions.append(bad)
 for entry in corruptions:
  write_data(entry)
  assert(sim.load_game("user://expansion-invalid.json") == ERR_INVALID_DATA)
  assert(sim.state == original)
 print("Expansión: seis guardados corruptos rechazados sin alterar campaña")
 quit()
