extends SceneTree
const Campaign = preload("res://sim/campaign.gd")
const Catalog = preload("res://sim/catalog.gd")
const Art = preload("res://visual/art.gd")
func _initialize():
 var seen = {}
 assert(Catalog.all().size() == 56)
 for unit in Catalog.all():
  assert(not seen.has(unit.id))
  seen[unit.id] = true
  assert(unit.year <= 3060 and unit.mass > 0)
 assert(Catalog.eligible(3027).size() < Catalog.eligible(3060).size())
 for family in range(7):
  var sprite = Art.unit_sprite(family)
  assert(sprite.get_size() == Vector2i(16,24))
  var colors = {}
  for y in range(24):
   for x in range(16): colors[sprite.get_pixel(x,y)] = true
  assert(colors.size() == 3)
 var sim = Campaign.new(42,3027)
 for day in range(0,224,14):
  sim.state.day = day
  sim._refresh_mech_market(sim.state)
  for lot in sim.state.mech_market: assert(Catalog.all()[lot.model].year <= 3027)
 sim = Campaign.new(42,3060)
 sim.state.funds = 1000000
 var vehicle = -1
 for i in range(Catalog.all().size()):
  if Catalog.all()[i].kind == "vehicle": vehicle = i; break
 sim.state.mech_market[0].model = vehicle
 sim.state.mech_market[0].model_id = Catalog.all()[vehicle].id
 assert(sim.purchase_mech(sim.state.mech_market[0].id).contains("Compra"))
 sim.advance(4)
 assert(sim.state.mechs.size() == 5)
 assert(sim.assign_pilot(4,0).contains("Dotación"))
 sim._refresh_candidates()
 sim.hire(3)
 var crew = sim.state.staff[-1]
 assert(crew.role == "Dotación")
 assert(sim.assign_pilot(4,crew.id).contains("actualizada"))
 assert(sim.unit_profile(0).mobility != sim.unit_profile(4).mobility)
 assert(sim.save_game("user://v13-test.json") == OK)
 var loaded = Campaign.new()
 assert(loaded.load_game("user://v13-test.json") == OK)
 assert(loaded.pilot_for(4).role == "Dotación")
 print("v0.13: 56 registros, fechas, sprites, compra, dotaciones y guardado OK")
 quit()
