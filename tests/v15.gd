extends SceneTree
const C = preload("res://sim/campaign.gd")
const U = preload("res://sim/universe.gd")
const T = preload("res://sim/travel.gd")
var checks = 0
var failures = 0
func check(ok: bool):
 checks += 1
 if not ok: failures += 1; push_error("v15 check %d" % checks)
func _initialize():
 T.build_graph()
 for year in [3027,3060]:
  var sim = C.new(12,year)
  var origin = sim.state.location_id
  var destination = T.graph[origin][0]
  var quote = sim.travel_quote(destination)
  check(quote.hops == 1 and quote.days == 11)
  var funds = sim.state.funds
  check(sim.start_travel(destination,quote.cost).contains("iniciado"))
  check(sim.state.funds == funds-quote.cost)
  check(sim.start_travel(destination).contains("curso"))
  check(sim.state.funds == funds-quote.cost)
  check(sim.accept_mission(sim.state.missions.offers[0].id).contains("traslado"))
  check(sim.purchase_mech(sim.state.mech_market[0].id).contains("traslado"))
  check(sim.order_supplies(false).contains("traslado"))
  check(sim.hire(0).contains("traslado"))
  sim.advance(5)
  check(sim.state.day == 5)
  check(sim.save_game("user://v15-travel.json") == OK)
  var loaded = C.new()
  check(loaded.load_game("user://v15-travel.json") == OK)
  check(loaded.state.travel == sim.state.travel)
  sim.advance(6)
  loaded.advance(6)
  check(sim.state == loaded.state)
  check(sim.state.location_id == destination and not sim.in_transit())
  check(sim.state.day == 11)
  for contract in sim.state.missions.offers: check(contract.system_id == destination and contract.expires>sim.state.day)
  for lot in sim.state.mech_market: check(sim.MECH_CATALOG[lot.model].year <= year)
  check(sim.state.lore_activity.size() == (10 if year == 3027 else 15))
  sim.accept_mission(sim.state.missions.offers[0].id)
  check(sim.travel_quote(origin).has("error"))
  check(sim.save_game("user://v15-arrival.json") == OK)
  check(C.new().load_game("user://v15-arrival.json") == OK)
 var remote = C.new(10)
 for system in U.load_data().systems:
  if system.affiliations["3027"] == "U":
   remote.state.location_id = system.id
   break
 remote.Missions.generate(remote.state)
 remote._refresh_offers()
 remote._refresh_mech_market(remote.state)
 check(remote.state.missions.offers.is_empty() and remote.state.offers.is_empty() and remote.state.mech_market.is_empty())
 check(remote.hire(0).contains("servicios"))
 check(remote.order_supplies(false).contains("servicios"))
 check(T.route(U.galatea(),"invalid").is_empty())
 var s = C.new()
 var before = s.state.duplicate(true)
 check(s.start_travel("invalid").contains("Sin ruta"))
 check(s.state == before)
 print("v0.15: ",checks," comprobaciones; fallos: ",failures)
 quit(1 if failures else 0)
