extends SceneTree
const C=preload("res://sim/campaign.gd")
var failed=false
func check(ok,label):
 if not ok:failed=true;printerr("FAIL: "+label)
func _initialize():
 var baseline=C.new(52);baseline.state.funds=2000000
 var owned=C.new(52);owned.state.funds=2000000;owned.state.hq.stage="owned";owned.state.hq.path="purchase";owned.state.hq.acquired=0
 var developed=C.new(52);developed.state.funds=2000000;developed.state.hq=owned.state.hq.duplicate(true);developed.state.hq.modules={"workshop":2,"storage":2,"medical":2,"quarters":2}
 for d in range(180):
  for s in [baseline,owned,developed]:s.state.issues.clear();s.advance(1)
 check(baseline.state.day==180 and owned.state.day==180,"Six months of calendar")
 check(baseline.state.funds-owned.state.funds==72000,"Basic HQ costs exactly 12000/month")
 check(baseline.state.funds-developed.state.funds==129600,"Four level-two modules cost 21600/month")
 check(baseline.rng.state==owned.rng.state and baseline.rng.state==developed.rng.state,"HQ consumes no combat randomness")
 var estimate={"period_days":180,"baseline_expense":2000000-baseline.state.funds,"hq_extra_expense":baseline.state.funds-owned.state.funds,"developed_hq_extra_expense":baseline.state.funds-developed.state.funds,"purchase":450000,"inspection":10000,"minimum_cash_before_purchase":450000+baseline.HQ.reserve_required(baseline),"note":"Controlled overhead comparison, same roster, no contracts or workshop activity; does not predict individual campaign income."}
 var file=FileAccess.open("res://docs/hq-economy.json",FileAccess.WRITE);file.store_string(JSON.stringify(estimate,"  "));file.close()
 if not failed:print("HQ_ECONOMY_PASS: "+JSON.stringify(estimate))
 quit(1 if failed else 0)
