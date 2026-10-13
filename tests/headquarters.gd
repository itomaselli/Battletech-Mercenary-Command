extends SceneTree
const C=preload("res://sim/campaign.gd")
const H=preload("res://sim/headquarters.gd")
var failures=0
var checks=0
func check(ok,label):
 checks+=1
 if not ok:failures+=1;printerr("FAIL: "+label)
func fresh():
 var s=C.new(5027);s.state.funds=2000000;tick(s,60);s.state.reputation=4;s.state.hq.wins=4;s.state.funds=1500000;return s
func tick(s,n):
 for i in range(n):
  s.state.issues.clear() # Isolate HQ from unrelated company decision popups.
  s.advance(1)
func bought():
 var s=fresh();s.hq_command({"action":"inspect"});s.hq_command({"action":"buy"});tick(s,14);return s
func install(s,id,level=1):
 for i in range(level):s.hq_command({"action":"upgrade","module":id});tick(s,7+i*3)
func roundtrip(s,label):
 var path="user://hq-test-%d.json"%Time.get_ticks_usec();var copy=C.new()
 check(s.save_game(path)==OK,label+" write");check(copy.load_game(path)==OK,label+" load");check(copy.state==s.state,label+" equality");DirAccess.remove_absolute(path)
func _initialize():
 var s=C.new();var before=s.state.duplicate(true)
 s.hq_command({"action":"inspect"});check(s.state==before,"Early acquisition rejected without mutation")
 s=fresh();s.hq_command({"action":"inspect"});check(s.state.hq.stage=="inspected","Inspection")
 var cash=s.state.funds;s.hq_command({"action":"inspect"});check(s.state.funds==cash,"Inspection idempotent")
 s.state.funds=450000;s.hq_command({"action":"buy"});check(s.state.hq.stage=="inspected","Operating reserve enforced")
 s.state.funds=1500000;s.hq_command({"action":"buy"});check(s.state.hq.stage=="refit","Purchase refit")
 cash=s.state.funds;s.hq_command({"action":"buy"});check(s.state.funds==cash,"No double purchase")
 roundtrip(s,"refit");tick(s,14);check(s.state.hq.stage=="owned","Delivered once");roundtrip(s,"owned")
 check(H.daily(s)==400 and H.rate(s,"workshop")==0,"Base running cost and no bonus")
 var count=s.state.hq.history.size();tick(s,1);check(s.state.hq.history.size()==count,"No duplicate ceremony")
 check(s.MAX_DEPLOYED==4 and s.MAX_HANGAR==8,"Unit limits unchanged")
 s.hq_command({"action":"rename","name":"Bastión"});s.hq_command({"action":"officer","id":4});check(s.state.hq.name=="Bastión" and s.state.hq.officer==4,"Identity and liaison")
 # Sponsor consumes real positive settlements only, with a cap and deduplication.
 var reward=fresh();reward.hq_command({"action":"inspect"});var employer=reward.state.offers[0].employer
 reward.hq_command({"action":"pledge","employer":employer});roundtrip(reward,"pledged")
 cash=reward.state.funds
 H.operation(reward,{"id":1,"name":"Test","employer":employer},false,100000)
 check(reward.state.hq.credit==0 and reward.state.funds==cash,"Failure never funds reward")
 for i in range(4):
  var contract={"id":i+2,"name":"Test","employer":employer}
  H.operation(reward,contract,true,100000);H.operation(reward,contract,true,100000)
 check(reward.state.hq.credit==180000 and reward.state.hq.sponsor_wins==4,"Reward cap and replay prevention")
 check(reward.state.funds==cash-180000,"Credits are spent, not minted")
 reward.hq_command({"action":"claim"});tick(reward,14);check(reward.state.hq.stage=="owned","Reward delivery")
 cash=reward.state.funds;H.operation(reward,{"id":99,"name":"Later","employer":employer},true,100000);check(reward.state.funds==cash,"No obligation after delivery")
 # Recovery requires a real processed-lot history, then survey and refit.
 var salvage=fresh();salvage.hq_command({"action":"inspect"});cash=salvage.state.funds
 salvage.hq_command({"action":"survey"});check(salvage.state.funds==cash,"Recovery qualification")
 for i in range(3):salvage.state.rpg.negotiation.salvage.append({"status":"processed"})
 salvage.hq_command({"action":"survey"});tick(salvage,14);check(salvage.state.hq.stage=="located","Survey completion")
 salvage.hq_command({"action":"claim"});tick(salvage,21);check(salvage.state.hq.stage=="owned","Recovery delivery")
 # Modules, slots, project pause and diminishing returns.
 s=bought();install(s,"workshop",2);check(H.rate(s,"workshop")==8,"Upgrade replaces 5 with 8")
 cash=s.state.funds;s.hq_command({"action":"upgrade","module":"workshop"});check(s.state.funds==cash,"Max level")
 install(s,"storage");install(s,"medical");install(s,"quarters");check(s.state.hq.modules.size()==4,"Four slots")
 cash=s.state.funds;s.hq_command({"action":"upgrade","module":"comms"});check(s.state.funds==cash,"No fifth module")
 check(H.daily(s)==600,"Crew and module upkeep")
 var total=0
 for i in range(100):total+=H.extra(s,"workshop","test",10)
 check(total==80,"Eight percent exact over time")
 total=0
 for i in range(100):total+=H.extra(s,"storage","test",2)
 check(total==6,"Three percent savings, no integer rounding inflation")
 s.hq_command({"action":"reserve"});check(H.rate(s,"workshop")==0 and H.daily(s)==100,"Reserve suspends advantages")
 s.hq_command({"action":"reserve"});s.state.hq.debt=400
 check(H.rate(s,"workshop")==0,"Debt suspends advantages")
 s.hq_command({"action":"pay"});check(H.rate(s,"workshop")==8,"Repayment restores advantages")
 roundtrip(s,"installed")
 s.hq_command({"action":"remove","module":"quarters"});check(not s.state.hq.modules.has("quarters"),"Reconfiguration")
 s.hq_command({"action":"upgrade","module":"simulator"});var left=s.state.hq.project.left
 s.hq_command({"action":"reserve"});tick(s,3);check(s.state.hq.project.left==left,"Reserved HQ pauses project")
 s.hq_command({"action":"reserve"});tick(s,left);check(s.state.hq.modules.has("simulator"),"Resumed project")
 s.hq_command({"action":"train","id":0});check(not s.person_available(s.state.staff[0]),"Course reserves pilot")
 var xp=s.state.staff[0].experience;roundtrip(s,"training");tick(s,7)
 check(s.state.staff[0].experience==xp+1 and s.person_available(s.state.staff[0]),"Course delivers exactly once and releases pilot")
 cash=s.state.funds;s.hq_command({"action":"train","id":0});check(s.state.funds==cash,"Training cooldown")
 s.state.staff[0].injury=8;s.state.hq.modules.erase("medical");s.state.hq.last_request=-30;H.requests(s)
 check(s.state.hq.request.get("module")=="medical","Causal injury request")
 s.hq_command({"action":"respond","choice":"later"});check(s.state.hq.request.is_empty(),"Response archived")
 check(s.state.staff[0].memories.size()>0,"Personal continuity")
 # Promises persist and close only when the actual installation is finished.
 s=bought();s.state.staff[0].injury=8;H.requests(s);s.hq_command({"action":"respond","choice":"support"})
 check(s.state.hq.promises.medical.status=="pending","Supported request remains an obligation")
 install(s,"medical");check(s.state.hq.promises.medical.status=="fulfilled","Completed installation fulfills promise")
 roundtrip(s,"fulfilled promise")
 # Forecast includes accrued cost and arrears. Poor month never makes negative cash.
 s=bought();s.state.funds=0;s.state.day=89;s.state.hq.accrued=4000;tick(s,1)
 check(s.state.hq.debt==4400 and s.state.funds==0,"Unpaid upkeep becomes debt")
 check(s.financial_report().hq.next_bill==4400+12000,"Forecast includes debt plus next month")
 # Invalid state must be rejected without changing live campaign.
 s=bought();var valid=s.state.hq.duplicate(true)
 var broken=valid.duplicate(true);broken.modules={"workshop":3};check(not H.valid(broken,s.state.day),"Reject third level")
 broken=valid.duplicate(true);broken.modules={"bogus":1};check(not H.valid(broken,s.state.day),"Reject unknown module")
 broken=valid.duplicate(true);broken.fractions={"workshop:0":100};check(not H.valid(broken,s.state.day),"Reject inflated credit")
 broken=valid.duplicate(true);broken.credit=180001;check(not H.valid(broken,s.state.day),"Reject excess subsidy")
 broken=valid.duplicate(true);broken.project={"id":"medical","level":2,"left":7,"cost":70000};check(not H.valid(broken,s.state.day),"Reject skipped level")
 # Mechanics integration: no modifications to combat damage, ordinary reports stay limited.
 s=bought();install(s,"workshop");s.state.mechs[0].hp=0;s.state.supplies=500;s.repair(0)
 s._workshop_tick();s._workshop_tick();check(s.state.mechs[0].hp==21,"Real workshop receives 5 percent work")
 var intel=bought();install(intel,"intelligence",2);install(intel,"comms");install(intel,"salvage")
 check(H.price(intel,"intelligence",500)==460,"Consultation discount capped at 8 percent")
 check(H.price(intel,"salvage",2000)==1900,"Processing discount")
 var quote=intel.supply_quote(true);intel.state.hq.reserve=true
 check(quote.cost==ceili(intel.supply_quote(true).cost*0.95),"Urgent order uses communications modifier")
 if failures==0:print("HQ_PASS: %d checks"%checks)
 quit(1 if failures else 0)
