extends SceneTree
const C=preload("res://sim/campaign.gd")
var failures=0
func check(ok: bool,text: String):
 if not ok:failures+=1;push_error(text)
func pending(s):
 for issue in s.state.issues.duplicate():
  match issue.kind:
   "medical":s.resolve_issue(issue.id,"standard")
   "team_conflict":s.resolve_issue(issue.id,"mediate")
   "deadline":s.resolve_issue(issue.id,"cancel")
   "salary":s.resolve_issue(issue.id,"pay")
 if s.military_waiting():s.decide_operation("press")
func _initialize():
 for year in [3027,3060]:
  for seed_value in [9,47,3027]:run_campaign(year,seed_value)
 print("Campañas RPG prolongadas: fallos ",failures)
 quit(1 if failures else 0)
func run_campaign(year: int,seed_value: int):
 var s=C.new(seed_value,year)
 s.rpg_command("configure",{"origin":"tecnico","specialty":"investigacion","motivation":"independencia","bond":4})
 s.rpg_command("arcs",{"action":"choose","kind":"independencia"})
 s.hire(1)
 s.configure_operation("recon","consult","objective")
 s.rpg_command("adventure",{"action":"open","family":"sabotage"})
 var case_id=s.state.rpg.adventures.cases[0].id
 s.rpg_command("adventure",{"action":"approach","id":case_id,"approach":"records"})
 var guard=0
 while s.state.day<180 and guard<600:
  guard+=1
  pending(s)
  if s.state.ended:break
  var c=s.RPG.Adventures.find(s,case_id)
  if c.status=="open" and c.clues.any(func(e):return e.kind=="observación"):s.rpg_command("adventure",{"action":"resolve","id":case_id,"choice":"evidence"})
  if s.state.supplies<70 and s.state.orders.is_empty():s.order_supplies(false)
  if s.state.ownership_debt>0:s.settle_ownership_debt()
  if s.state.contract_debt>0:s.settle_contract_debt()
  if s.state.arrears>0:s.settle_arrears()
  if s.state.active.is_empty() and not s.RPG.busy(s):
   var team=[]
   for i in range(s.state.mechs.size()):
    var m=s.state.mechs[i]
    var f=s.state.rpg.workshop.faults.get(str(m.uid),{})
    if not f.is_empty():
     if s.RPG.Workshop.tech(s)>=0 and not s.state.rpg.workshop.jobs.any(func(j):return j.uid==m.uid):
      while s.state.rpg.workshop.parts[f.kind]<2 and s.available_funds()>=4000:s.rpg_command("workshop",{"action":"buy_parts","kind":f.kind})
      s.rpg_command("workshop",{"action":"full","uid":m.uid})
    elif m.hp<90 and not m.repair:s.repair(i)
    if s.mech_ready(i) and m.hp>=90 and not m.repair and s.person_available(s.pilot_for(i)):team.append(i)
   if team.size()==4 and s.state.supplies>=44:
    if s.state.accepted.is_empty():
     for offer in s.state.missions.offers:
      if offer.mission_type in ["recon","interdiction"] and offer.expires>s.state.day:s.accept_mission(offer.id);break
    if not s.state.accepted.is_empty():s.dispatch(0,team,0)
  if s.RPG.Arcs.ready(s):s.rpg_command("arcs",{"action":"close"})
  var old_day=s.state.day
  s.advance(1)
  check(s.state.funds>=0 and s.state.supplies>=0,"Recursos negativos")
  if s.state.day==old_day and s.state.issues.is_empty() and not s.military_waiting():break
  if s.state.day in [45,90,135,180]:
   check(s.save_game("user://rpg-long.json")==OK,"Guardar campaña RPG larga")
   var loaded=C.new()
   check(loaded.load_game("user://rpg-long.json")==OK,"Cargar campaña RPG larga")
   check(s.state==loaded.state,"Continuidad RPG larga")
   s=loaded
 check(s.state.day==180 and not s.state.ended,"Seis meses RPG sin aportes artificiales")
 check(s.state.rpg.adventures.cases[0].status=="closed","Asunto cerrado durante campaña")
 check(s.state.military.archive.size()>=5,"Cinco operaciones o más")
 print("RPG ",year," seed ",seed_value," día ",s.state.day," fondos ",s.state.funds," operaciones ",s.state.military.archive.size()," memorias ",s.state.rpg.director.summaries.size())
