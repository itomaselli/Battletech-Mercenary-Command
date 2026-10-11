extends SceneTree
const C = preload("res://sim/campaign.gd")
const M = preload("res://sim/missions.gd")
var checks = 0
var failures = 0
func check(condition: bool):
 checks += 1
 if not condition: failures += 1; push_error("v14 check %d" % checks)
func settle(sim):
 for n in range(40):
  if sim.state.active.is_empty(): return
  if sim.military_waiting(): sim.decide_operation("press")
  for issue in sim.state.issues.duplicate():
   sim.resolve_issue(issue.id,"standard" if issue.kind == "injury" else "mediate" if issue.kind == "conflict" else "continue")
  sim.advance(1)
 check(sim.state.active.is_empty())
func _initialize():
 for year in [3027,3060]:
  var one = C.new(15,year)
  var two = C.new(15,year)
  check(one.state.missions.offers == two.state.missions.offers)
  check(one.state.missions.offers.size() == 5)
  for type in M.KINDS:
   var sim = C.new(15,year)
   var offer = {}
   for c in sim.state.missions.offers:
    if c.mission_type == type: offer = c.duplicate(true)
   check(not offer.is_empty())
   check(sim.accept_mission(offer.id).contains("aceptado"))
   var funds = sim.state.funds
   sim.accept_mission(offer.id)
   check(funds == sim.state.funds)
   check(sim.dispatch(0,[0,1,2,3],1).contains("autorizado"))
   sim.advance(1)
   check(sim.state.active.objective.elapsed == 1)
   check(sim.save_game("user://v14-mission.json") == OK)
   var loaded = C.new()
   check(loaded.load_game("user://v14-mission.json") == OK)
   check(loaded.state.active == sim.state.active)
   settle(sim)
   settle(loaded)
   check(sim.state == loaded.state)
   check(sim.state.missions.archive.size() == 1)
   var archived = sim.state.missions.archive[0]
   check(archived.kind == type)
   print(year," ",type," ",archived.result," ",archived.progress)
   # Each evaluator tested with unambiguously strong/weak force profiles.
   for strength in [0,10]:
    var profiles = []
    for i in range(4): profiles.append({"mobility":strength,"recon":strength,"protection":strength,"support":strength,"firepower":strength,"cargo":strength,"condition":100})
    var objective = M.begin(offer,profiles,"careful")
    for day in range(5): M.tick(objective,offer,15,false)
    check(M.outcome(objective) == ("failure" if strength==0 else "success"))
   var partial = M.begin(offer,[],"careful")
   partial.elapsed = 5
   partial.progress = 50
   check(M.outcome(partial) == "partial")
 var sim = C.new(99)
 var id = sim.state.missions.offers[0].id
 sim.accept_mission(id)
 sim.dispatch(0,[0,1],1)
 sim.cancel_contract()
 check(sim.state.active.is_empty() and sim.state.missions.archive[0].result == "failure")
 check(sim.save_game("user://v14-cancel.json") == OK)
 check(C.new().load_game("user://v14-cancel.json") == OK)
 print("v0.14: ",checks," comprobaciones; fallos: ",failures)
 quit(1 if failures else 0)
