extends SceneTree
const Campaign = preload("res://sim/campaign.gd")
var checks = 0
var failures = 0
func check(ok: bool, description: String):
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: ", description)
func _initialize():
	personnel()
	logistics()
	contracts()
	management()
	edge_cases()
	persistence()
	long_campaigns()
	print("v0.2: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
func personnel():
	var c = Campaign.new()
	c.hire(0)
	check(c.state.staff.size() == 7 and c.state.funds == 228000, "hiring fee")
	c.assign_pilot(1, 0)
	check(c.state.mechs[1].pilot_id == 1, "unique assignments")
	c.assign_pilot(0, 6)
	check(c.pilot_for(0).name == "Lucía Serrano", "reserve assignment")
	c.accept_contract(0)
	c.person_by_id(6).injury = 3
	c.dispatch(0, [0], 1)
	check(c.state.active.is_empty(), "injured reserve cannot deploy")
	c.person_by_id(6).injury = 0
	c.dispatch(0, [0, 1], 1, 6)
	c.dismiss(6)
	check(not c.person_by_id(6).is_empty(), "deployed staff cannot be dismissed")
	c.advance(3)
	c.dismiss(6)
	check(c.person_by_id(6).is_empty() and c.state.mechs[0].pilot_id == -1, "dismissal unassigns pilot")
	check(c.monthly_payroll() == 37000, "payroll tracks roster")

func logistics():
	var c = Campaign.new()
	c.state.mechs[0].hp = 80
	c.state.mechs[1].hp = 80
	c.repair(0)
	c.repair(1)
	c.prioritize_repair(1)
	c.advance()
	check(c.state.mechs[1].hp == 90 and c.state.mechs[0].hp == 80, "one technical lane respects priority")
	c.hire(1)
	check(c.workshop_capacity() == 2, "hired technician expands capacity")
	c.advance()
	check(c.state.mechs[0].hp == 90 and c.state.mechs[1].hp == 100, "two simultaneous repairs")
	c.repair(0)
	var stock = c.state.supplies
	var cash = c.state.funds
	var quote = c.supply_quote(false)
	c.order_supplies(false)
	check(c.state.supplies == stock and c.committed_payments() > 0, "supply orders reserve balance and wait")
	check(c.available_funds() == cash - quote.cost, "reservation excludes committed cash")
	c.advance(quote.days)
	check(c.state.supplies == stock + 30 and c.state.funds == cash - quote.cost, "delivery charged exactly once")
	c.advance()
	check(c.state.supplies == stock + 30, "delivery cannot duplicate")
	c.order_supplies(true)
	c.advance()
	check(c.state.supplies == stock + 60, "urgent delivery next day")
	check(c.supply_quote(true).cost > c.supply_quote(false).cost, "urgency premium")

func contracts():
	var c = Campaign.new()
	c.dispatch(0, [0, 1], 1)
	check(c.state.active.is_empty(), "acceptance required before deployment")
	var initial = c.state.funds
	c.accept_contract(0)
	var contract = c.state.accepted.duplicate(true)
	check(c.state.funds == initial + contract.advance, "advance on acceptance")
	c.accept_contract(0)
	check(c.state.funds == initial + contract.advance, "advance cannot duplicate")
	c.dispatch(0, [0], 1)
	check(c.state.active.is_empty(), "minimum force enforced")
	c.dispatch(0, [0, 1, 2, 3], 1, 2)
	check(c.state.active.leader == 2, "chosen deployed leader")
	c.advance(3)
	check(c.state.accepted.is_empty() and c.state.active.is_empty(), "settlement closes commitment")
	check(c.state.funds == initial + contract.pay, "success pays total minus advance")
	var settled_cash = c.state.funds
	c.advance(2)
	check(c.state.funds == settled_cash, "no repeated settlement")
	check(c.state.relationships[contract.employer] == 1, "success improves employer relationship")
	var late = Campaign.new()
	late.accept_contract(0)
	late.advance(7)
	check(late.state.day == 3 and late.state.issues.size() == 1, "deadline warning interrupts seven-day advance")
	late.resolve_issue(late.state.issues[0].id, "continue")
	late.advance(3)
	check(late.state.accepted.is_empty() and late.state.funds == 240000, "deadline breach refunds advance")
	check(late.state.relationships[contract.employer] == -2, "breach damages employer trust")
	var retreat = Campaign.new()
	retreat.accept_contract(0)
	retreat.dispatch(0, [0, 1], 1)
	retreat.cancel_contract()
	check(retreat.state.active.is_empty() and retreat.state.funds == 240000, "retreat refunds and releases units")
	var debt = Campaign.new()
	debt.accept_contract(0)
	debt.state.funds = 0
	debt.cancel_contract()
	debt.accept_contract(0)
	check(debt.state.contract_debt > 0 and debt.state.accepted.is_empty(), "unpaid refund blocks advance cycling")

func ledger_balance(c) -> int:
	var balance = int(c.state.opening_balance)
	for entry in c.state.ledger: balance += int(entry.amount)
	return balance

func management():
	var c = Campaign.new()
	c.hire(0)
	c.order_supplies(false)
	c.accept_contract(0)
	var report = c.financial_report()
	check(report.conditional == c.state.accepted.pay - c.state.accepted.advance, "conditional income is separated")
	check(report.projected == c.state.funds - c.committed_payments() - c.monthly_payroll() - c.ownership_forecast().next_bill, "forecast subtracts committed costs including ownership")
	c.dispatch(0, [0, 1, 2, 3], 1)
	c.advance(4)
	c.repair(0)
	c.advance(3)
	check(ledger_balance(c) == c.state.funds, "ledger reconciles hiring deliveries contracts and workshop")
	var salary = Campaign.new()
	salary.state.funds = 0
	salary.advance(30)
	salary.advance(30)
	check(salary.state.issues.size() == 1 and salary.state.issues[0].kind == "salary", "repeated missed payroll creates personnel demand")
	var day = salary.state.day
	salary.advance(7)
	check(salary.state.day == day, "urgent demand pauses all time")
	var id = salary.state.issues[0].id
	salary.resolve_issue(id, "pay")
	check(salary.state.issues.size() == 1, "insufficient payment keeps decision pending")
	var departing = salary.state.issues[0].person
	salary.resolve_issue(id, "release")
	check(salary.person_by_id(departing).is_empty() and salary.state.arrears == 74000, "voluntary exit preserves unpaid debt")
	salary.advance()
	check(salary.state.day == day + 1, "time resumes after decision")
	var pay = Campaign.new()
	pay.state.arrears = 12000
	pay.state.missed_payrolls = 2
	pay._check_issues()
	pay.resolve_issue(pay.state.issues[0].id, "pay")
	check(pay.state.arrears == 0 and pay.state.issues.is_empty() and pay.state.funds == 228000, "paying resolves personnel demand")
	var relation = Campaign.new()
	relation._change_relation("Liga comercial", 3)
	relation._refresh_offers()
	check(relation.state.offers[0].pay == 54000 and relation.state.offers[0].advance > 13500, "relationship improves future conditions")

func write_fixture(path: String, data):
	var file = FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(data))
	file.close()

func persistence():
	var c = Campaign.new(456)
	c.set_identity("Guardia del Sur", "Iván")
	c.hire(0)
	c.assign_pilot(0, 6)
	c.order_supplies(false)
	c.accept_contract(0)
	c.advance(3)
	check(c.save_game("user://v02_test.json") == OK, "save pending order and urgent decision")
	var loaded = Campaign.new()
	check(loaded.load_game("user://v02_test.json") == OK and loaded.state == c.state, "roundtrip preserves full management state")
	c.resolve_issue(c.state.issues[0].id, "continue")
	loaded.resolve_issue(loaded.state.issues[0].id, "continue")
	c.dispatch(0, [0, 1, 2, 3], 2, 6)
	loaded.dispatch(0, [0, 1, 2, 3], 2, 6)
	c.advance(3)
	loaded.advance(3)
	check(c.state == loaded.state, "continued operation and delivery deterministic")
	var original = Campaign.new(777)
	original.accept_contract(0)
	original.dispatch(0, [0, 1, 2, 3], 1)
	for version in range(1, 6):
		var fixture = original.state.duplicate(true)
		fixture.version = version
		for key in ["next_mech_uid", "market_seed", "mech_market", "mech_orders", "next_market_id", "ownership_due", "ownership_debt"]: fixture.erase(key)
		for mech in fixture.mechs:
			for key in ["uid", "model", "stored", "ready_day"]: mech.erase(key)
		fixture["rng_state"] = str(original.rng.state)
		for key in ["ledger", "opening_balance", "issues", "next_issue_id", "missed_payrolls"]: fixture.erase(key)
		if version < 5:
			for key in ["accepted", "relationships", "contract_debt"]: fixture.erase(key)
			for contract in fixture.offers + [fixture.active.contract]:
				for key in ["advance", "min_force", "deadline", "reliability", "failure_pay"]: contract.erase(key)
		if version < 4:
			for key in ["orders", "repair_queue", "next_order_id"]: fixture.erase(key)
		if version < 3:
			for key in ["candidates", "next_staff_id"]: fixture.erase(key)
			for person in fixture.staff: person.erase("id")
			for mech in fixture.mechs: mech.erase("pilot_id")
			fixture.active.erase("leader")
		if version < 2:
			fixture.erase("company_name")
			fixture.erase("captain_name")
		write_fixture("user://migration_test.json", fixture)
		var migrated = Campaign.new()
		check(migrated.load_game("user://migration_test.json") == OK, "migrate schema %d" % version)
		check(migrated.state.funds == original.state.funds and migrated.state.active.remaining == 3, "migration retains money and active operation %d" % version)
		migrated.advance(3)
		check(migrated.state.active.is_empty(), "migrated operation resolves %d" % version)
	var invalid = c.state.duplicate(true)
	invalid["rng_state"] = str(c.rng.state)
	invalid.orders = [{"quantity": "bad"}]
	write_fixture("user://invalid_v02.json", invalid)
	var before = loaded.state.duplicate(true)
	check(loaded.load_game("user://invalid_v02.json") == ERR_INVALID_DATA and loaded.state == before, "malformed management data rejected atomically")

func long_campaigns():
	var outcomes = []
	for seed_value in range(20):
		var c = Campaign.new(seed_value)
		c.hire(1)
		var iterations = 0
		while c.state.day < 180 and not c.state.ended and iterations < 400:
			iterations += 1
			for issue in c.state.issues.duplicate():
				if issue.kind == "medical": c.resolve_issue(issue.id, "standard")
				elif issue.kind == "team_conflict": c.resolve_issue(issue.id, "separate")
				elif issue.kind == "deadline": c.resolve_issue(issue.id, "continue")
				else: c.resolve_issue(issue.id, "pay" if c.available_funds() >= c.state.arrears else "release")
			if c.state.supplies < 60 and c.state.orders.is_empty(): c.order_supplies(false)
			if c.state.active.is_empty():
				var team = []
				for i in range(4):
					if c.state.mechs[i].hp < 80 and not c.state.mechs[i].repair: c.repair(i)
					if c.state.mechs[i].hp >= 80 and not c.state.mechs[i].repair and not c.pilot_for(i).is_empty() and c.pilot_for(i).injury == 0: team.append(i)
				if team.size() >= 3:
					if c.state.accepted.is_empty(): c.accept_contract(0)
					c.dispatch(0, team, seed_value % 3)
			c.advance()
		check(c.state.day == 180 or c.state.ended, "campaign reaches six months or legitimate end %d" % seed_value)
		check(c.state.funds >= c.committed_payments() and c.state.supplies >= 0 and ledger_balance(c) == c.state.funds, "resources and ledger reconcile seed %d" % seed_value)
		var completed = 0
		for event in c.state.chronicle:
			if event.kind == "Resultado": completed += 1
		check(completed >= 3, "campaign resolves repeated contracts %d" % seed_value)
		outcomes.append(c.state.funds)
	check(outcomes.min() != outcomes.max(), "different seeds create distinct outcomes")

func edge_cases():
	var c = Campaign.new()
	c.state.funds = 9000
	var before = c.state.duplicate(true)
	c.hire(0)
	c.order_supplies(false)
	check(c.state == before, "unaffordable hiring and orders are atomic")
	var no_tech = Campaign.new()
	no_tech.dismiss(4)
	no_tech.state.mechs[0].hp = 50
	no_tech.repair(0)
	no_tech.advance(2)
	check(no_tech.state.mechs[0].hp == 50 and no_tech.repair_estimates()[0].days == -1, "no technicians means no progress or finite ETA")
	var cap = Campaign.new()
	cap.person_by_id(5).skill = 100
	check(cap.supply_quote(false).discount == 15 and cap.supply_quote(false).days == 2, "logistics bonuses capped")
	var failure = Campaign.new()
	failure.state.offers[0].difficulty = 100
	failure.accept_contract(0)
	var contract = failure.state.accepted.duplicate(true)
	failure.dispatch(0, [0, 1, 2, 3], 1)
	failure.advance(3)
	check(failure.state.funds == 240000 + contract.failure_pay and failure.state.relationships[contract.employer] == -1, "failure refunds excess advance")
	check(ledger_balance(failure) == failure.state.funds, "negative contract settlement reconciles")
	var boundary = Campaign.new()
	boundary.accept_contract(0)
	boundary.advance(3)
	boundary.resolve_issue(boundary.state.issues[0].id, "continue")
	boundary.advance(2)
	boundary.dispatch(0, [0, 1], 1)
	check(not boundary.state.active.is_empty(), "deployment allowed on deadline day")
	var closure = Campaign.new()
	closure.state.ended = true
	before = closure.state.duplicate(true)
	closure.hire(0)
	closure.dismiss(0)
	closure.order_supplies(false)
	closure.accept_contract(0)
	closure.assign_pilot(0, -1)
	closure.settle_arrears()
	closure.settle_contract_debt()
	check(closure.state == before, "closed campaign rejects new management commands")
