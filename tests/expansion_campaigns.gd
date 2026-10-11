extends SceneTree
const C = preload("res://sim/campaign.gd")
var failures = 0
var checks = 0
func check(ok: bool, label: String):
 checks += 1
 if not ok: failures += 1; push_error(label)
func _initialize():
 for year in [3027,3060]:
  for seed_value in [9,47,3027]: run_campaign(year,seed_value)
 vehicle()
 print("Campañas de integración: ",checks," comprobaciones; fallos: ",failures)
 quit(1 if failures else 0)
func resolve_pending(sim):
 for issue in sim.state.issues.duplicate():
  match issue.kind:
   "medical": sim.resolve_issue(issue.id,"standard")
   "team_conflict": sim.resolve_issue(issue.id,"mediate")
   "deadline": sim.resolve_issue(issue.id,"cancel")
   "salary": sim.resolve_issue(issue.id,"pay")
 if sim.military_waiting(): sim.decide_operation("press")
func run_campaign(year: int, seed_value: int):
 var sim = C.new(seed_value,year)
 sim.hire(1)
 sim.configure_operation("recon","consult","objective")
 var guard = 0
 while sim.state.day < 180 and guard < 500:
  guard += 1
  resolve_pending(sim)
  if sim.state.ended: break
  if sim.state.supplies < 70 and sim.state.orders.is_empty(): sim.order_supplies(false)
  if sim.state.ownership_debt > 0: sim.settle_ownership_debt()
  if sim.state.contract_debt > 0: sim.settle_contract_debt()
  if sim.state.arrears > 0: sim.settle_arrears()
  if sim.state.active.is_empty():
   var team = []
   for i in range(sim.state.mechs.size()):
    var m = sim.state.mechs[i]
    if m.hp < 90 and not m.repair: sim.repair(i)
    if m.hp >= 90 and not m.repair and sim.person_available(sim.pilot_for(i)): team.append(i)
   if team.size() == 4 and sim.state.supplies >= 44:
    if sim.state.accepted.is_empty():
     for offer in sim.state.missions.offers:
      if offer.mission_type in ["recon","interdiction"] and offer.expires>sim.state.day:
       sim.accept_mission(offer.id)
       break
    if not sim.state.accepted.is_empty(): sim.dispatch(0,team,0)
  var old_day = sim.state.day
  sim.advance(1)
  check(sim.state.funds >= 0 and sim.state.supplies >= 0,"recursos no negativos")
  if sim.state.day == old_day and sim.state.issues.is_empty() and not sim.military_waiting(): break
  if sim.state.day in [45,90,135,180]:
   var path = "user://expansion-six-months.json"
   check(sim.save_game(path)==OK,"guardar campaña larga")
   var loaded = C.new()
   check(loaded.load_game(path)==OK,"cargar campaña larga")
   check(loaded.state == sim.state,"continuidad exacta campaña larga")
   sim = loaded
 check(sim.state.day == 180 and not sim.state.ended,"alcanza seis meses sin aportes artificiales")
 check(sim.state.missions.archive.size() >= 5,"operaciones completadas")
 check(sim.state.lore_activity["lore-steiner"].cycles >= 25,"actividad autónoma")
 print(year," seed ",seed_value," día ",sim.state.day," fondos ",sim.state.funds," misiones ",sim.state.missions.archive.size())
func vehicle():
 var sim = C.new(1)
 var index = -1
 for i in range(sim.MECH_CATALOG.size()):
  if sim.MECH_CATALOG[i].kind == "vehicle": index=i; break
 var offer = sim.state.mech_market[0]
 offer.model = index
 offer.model_id = sim.MECH_CATALOG[index].id
 offer.price = int(sim.MECH_CATALOG[index].value)
 offer.hp = 85
 sim.purchase_mech(offer.id)
 sim.hire(3)
 sim.advance(4)
 var crew = sim.state.staff[-1].id
 check(sim.assign_pilot(4,crew).contains("actualizada"),"dotación asignada")
 check(sim.assign_pilot(0,crew).contains("Piloto"),"dotación no pilota Mech")
 sim.accept_contract(0)
 sim.dispatch(0,[1,2,3,4],1,crew)
 check(not sim.state.active.is_empty(),"despliegue con vehículo autorizado")
 if sim.state.active.is_empty(): return
 check(sim.state.active.leader == crew,"jefe de dotación puede mandar")
 for i in range(12):
  resolve_pending(sim)
  if sim.state.active.is_empty(): break
  sim.advance(1)
 check(sim.person_by_id(crew).missions == 1,"experiencia de dotación")
 check(sim.state.mechs[4].hp < 100,"daño de vehículo")
 resolve_pending(sim)
 var hp = sim.state.mechs[4].hp
 sim.repair(4)
 sim.advance(1)
 check(sim.state.mechs[4].hp>hp,"reparación de vehículo")
 check(sim.save_game("user://expansion-vehicle.json")==OK,"guardar vehículo")
 check(C.new().load_game("user://expansion-vehicle.json")==OK,"cargar vehículo")
