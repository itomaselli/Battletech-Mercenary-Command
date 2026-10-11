extends SceneTree
const C = preload("res://sim/campaign.gd")
var failed = 0
func _initialize():
 for release in ["v0.11","v0.12","v0.13","v0.14"]:
  var sim = C.new()
  var path = "user://actual-%s.json" % release
  if not FileAccess.file_exists(path):
   print("SKIP snapshot migration ",release," (generar fixtures con tools/test_snapshots.py)")
   continue
  if sim.load_game(path) != OK: failed += 1; push_error("migration "+release); continue
  assert(sim.state.scenario_year == 3060)
  assert(sim.state.company_name == "Prueba migración")
  assert(sim.state.active.remaining == 2)
  assert(sim.state.mechs[0].model_id == "locust-lct-1v")
  sim.advance(2)
  assert(sim.state.active.is_empty())
  print("Migración real ",release," a esquema ",sim.VERSION," OK")
 quit(failed)
