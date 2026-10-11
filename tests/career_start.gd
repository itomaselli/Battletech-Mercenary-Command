extends SceneTree
const Start=preload("res://sim/career_start.gd")
const Campaign=preload("res://sim/campaign.gd")
func _initialize():
 for year in [3027,3060]:
  var seen={}
  for seed_value in range(1000):
   var draft=Start.generate(seed_value,year)
   assert(Start.valid(draft,year));assert(draft==Start.generate(seed_value,year))
   assert(draft.units==Start.generate(seed_value,year,0,1).units)
   for id in draft.units:seen[id]=true
  assert(seen.size()==Start.Catalog.eligible(year).size())
 var vehicles=[]
 for m in Start.Catalog.all():
  if m.kind=="vehicle" and m.year<=3027:vehicles.append(m.id)
 var draft=Start.assemble(42,3027,[vehicles[0],vehicles[0],vehicles[0],vehicles[0]])
 var sim=Campaign.new(42,3027,draft)
 for i in range(4):assert(sim.pilot_for(i).role=="Dotación");assert(sim.state.mechs[i].uid==i)
 assert(sim.save_game("user://test-career-start.json")==OK)
 var copy=Campaign.new();assert(copy.load_game("user://test-career-start.json")==OK);assert(copy.state==sim.state)
 sim.accept_contract(0);sim.dispatch(0,[0,1,2,3],1)
 assert(not sim.state.active.is_empty())
 sim.advance(10)
 assert(sim.state.active.is_empty())
 sim.state.mechs[0].hp=60
 sim.repair(0)
 sim.advance(1)
 assert(sim.state.mechs[0].hp>60)
 for year in [3027,3060]:
  var mechs=[]
  for m in Start.Catalog.all():
   if m.kind!="vehicle" and m.year<=year:mechs.append(m.id)
  for units in [[mechs[0],mechs[0],mechs[0],mechs[0]],[vehicles[0],mechs[0],vehicles[0],mechs[-1]]]:
   var c=Campaign.new(86,year,Start.assemble(86,year,units))
   c.accept_contract(0);c.dispatch(0,[0,1,2,3],1);assert(not c.state.active.is_empty());c.advance(10);assert(c.state.active.is_empty())
 print("v0.29: 2000 semillas, pool completo, reproducibilidad, cuatro vehículos y guardado OK")
 quit()
