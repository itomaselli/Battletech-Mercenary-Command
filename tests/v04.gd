extends SceneTree
const Campaign = preload("res://sim/campaign.gd")
var checks = 0
var failures = 0
func check(ok: bool, description: String):
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL v0.4: ", description)
func _initialize():
	careers()
	conditions()
	stories()
	causal_operations()
	persistence()
	long_campaigns()
	print("v0.4: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
func careers():
	var c = Campaign.new()
	c.accept_contract(0)
	c.dispatch(0, [0, 1, 2, 3], 1)
	c.advance(3)
	check(c.person_by_id(0).missions == 1 and c.person_by_id(0).experience == 2, "experience from completed operation")
	check(c.person_by_id(4).experience == 0, "support does not gain pilot experience")
	c.person_by_id(0).experience = 6
	var cash = c.state.funds
	c.promote(0)
	check(c.person_by_id(0).skill == 4 and c.person_by_id(0).salary == 7000 and c.state.funds == cash - 3000, "promotion skill salary and expense")
	c.promote(0)
	check(c.person_by_id(0).promotions == 1, "promotion requires next threshold")
	c.person_by_id(0).experience = 12
	c.promote(0)
	c.promote(0)
	check(c.person_by_id(0).skill == 5 and c.person_by_id(0).promotions == 2, "promotion cap")
	c.dismiss(0)
	check(c.state.alumni.size() == 1 and c.state.alumni[0].memories.size() >= 4, "departure preserves personal history")
	c.hire(0)
	check(c.person_by_id(6).experience == 0, "new hires get fresh career")

func conditions():
	var c = Campaign.new()
	c.person_by_id(0).fatigue = 85
	c.accept_contract(0)
	c.dispatch(0, [0, 1], 1)
	check(c.state.active.is_empty(), "exhausted pilot cannot deploy")
	c.grant_leave(0)
	c.advance(2)
	check(c.person_by_id(0).fatigue == 57 and not c.person_available(c.person_by_id(0)), "leave recovers fatigue while unavailable")
	c.advance()
	check(c.person_available(c.person_by_id(0)), "leave ends on third day")
	for issue in c.state.issues.duplicate(): c.resolve_issue(issue.id, "continue")
	c.dispatch(0, [0, 1], 1)
	c.grant_leave(0)
	check(c.person_by_id(0).rest_until == 3, "cannot grant leave during deployment")
	var bonds = Campaign.new()
	bonds._update_bonds([0, 1], true)
	bonds._update_bonds([0, 1], true)
	bonds._update_bonds([0, 1], true)
	check(bonds.state.bonds["0:1"].score == 3 and bonds.team_cohesion([0, 1]) == 1.0, "shared success builds bounded cohesion")
	bonds.dismiss(0)
	check(bonds.person_name(0).contains("baja") and bonds.state.bonds.has("0:1"), "departed colleague stays in relationship history")
	var support = Campaign.new()
	support.grant_leave(4)
	check(support.workshop_capacity() == 0, "technician leave reduces workshop capacity")
	support.advance(3)
	check(support.workshop_capacity() == 1, "technician returns after leave")

func stories():
	var c = Campaign.new()
	c.person_by_id(0).injury = 8
	c._operation_story({"team": [0, 1]})
	check(c.state.issues.size() == 1 and c.state.issues[0].kind == "medical", "injury generates reported decision")
	c.advance(7)
	check(c.state.day == 0, "personal decision pauses calendar")
	var id = c.state.issues[0].id
	var funds = c.state.funds
	c.resolve_issue(id, "care")
	check(c.person_by_id(0).injury == 5 and c.state.funds == funds - 2000 and c.state.issues.is_empty(), "medical decision applies costs and recovery")
	c.resolve_issue(id, "care")
	check(c.state.funds == funds - 2000, "decision cannot charge twice")
	c._operation_story({"team": [0, 1]})
	check(c.state.issues.is_empty(), "medical event has cooldown")
	var conflict = Campaign.new()
	conflict._update_bonds([0, 1], false)
	conflict._update_bonds([0, 1], false)
	conflict._operation_story({"team": [0, 1]})
	check(conflict.state.issues[0].kind == "team_conflict", "repeated shared failures cause conflict")
	conflict.resolve_issue(conflict.state.issues[0].id, "mediate")
	check(conflict.state.bonds["0:1"].score == 0 and not conflict.person_available(conflict.person_by_id(0)), "mediation improves bond but requires downtime")
	conflict.advance(2)
	check(conflict.person_available(conflict.person_by_id(0)), "mediation downtime expires")
	var departed = Campaign.new()
	departed.person_by_id(0).injury = 5
	departed._operation_story({"team": [0, 1]})
	departed.dismiss(0)
	check(departed.state.issues.is_empty() and departed.state.alumni.size() == 1, "departure closes obsolete personal issue")

func write_fixture(path: String, data):
	var file = FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(data))
	file.close()

func persistence():
	var c = Campaign.new(15)
	c.person_by_id(0).experience = 6
	c.promote(0)
	c._update_bonds([0, 1], false)
	c._update_bonds([0, 1], false)
	c._operation_story({"team": [0, 1]})
	c.dismiss(3)
	check(c.save_game("user://v04_test.json") == OK, "save histories, promotion, archived staff and conflict")
	var loaded = Campaign.new()
	check(loaded.load_game("user://v04_test.json") == OK and loaded.state == c.state, "personal state roundtrip")
	c.resolve_issue(c.state.issues[0].id, "mediate")
	loaded.resolve_issue(loaded.state.issues[0].id, "mediate")
	c.advance(7)
	loaded.advance(7)
	check(c.state == loaded.state, "continued personal decisions reproduce exactly")
	for version in [9, 10, 11]:
		var old = Campaign.new()
		old.set_identity("Veteranos", "Ana")
		old.accept_contract(0)
		old.dispatch(0, [0, 1, 2, 3], 1)
		var fixture = old.state.duplicate(true)
		fixture.version = version
		fixture["rng_state"] = str(old.rng.state)
		for person in fixture.staff: person.erase("last_care_event")
		if version < 11:
			fixture.erase("bonds")
			for person in fixture.staff:
				person.erase("fatigue")
				person.erase("rest_until")
		if version < 10:
			fixture.erase("alumni")
			for person in fixture.staff:
				for key in ["experience", "promotions", "missions", "victories", "memories"]: person.erase(key)
		write_fixture("user://v04_legacy.json", fixture)
		var migrated = Campaign.new()
		check(migrated.load_game("user://v04_legacy.json") == OK, "migrate career schema %d" % version)
		check(migrated.person_by_id(0).experience == 0 and migrated.state.funds == old.state.funds and migrated.state.active.remaining == 3, "migration preserves campaign without invented history %d" % version)
		migrated.advance(3)
		check(migrated.person_by_id(0).missions == 1, "migrated operation earns experience %d" % version)
	var bad = c.state.duplicate(true)
	bad["rng_state"] = str(c.rng.state)
	bad.staff[0].memories = [{"day": 0, "text": 42}]
	write_fixture("user://v04_invalid.json", bad)
	var before = loaded.state.duplicate(true)
	check(loaded.load_game("user://v04_invalid.json") == ERR_INVALID_DATA and loaded.state == before, "invalid personal history rejected atomically")
	var poor = Campaign.new()
	poor.person_by_id(0).injury = 8
	poor._operation_story({"team": [0]})
	poor.state.funds = 0
	poor.resolve_issue(poor.state.issues[0].id, "care")
	check(poor.person_by_id(0).injury == 8 and poor.state.issues.size() == 1, "unaffordable care leaves decision pending")
	poor.resolve_issue(poor.state.issues[0].id, "standard")
	check(poor.state.issues.is_empty(), "free treatment resolves decision")
	var closed = Campaign.new()
	closed.state.ended = true
	before = closed.state.duplicate(true)
	closed.grant_leave(0)
	closed.promote(0)
	check(closed.state == before, "closed campaign rejects career orders")

func long_campaigns():
	var outcomes = []
	for seed_value in range(20):
		var c = Campaign.new(seed_value)
		c.hire(1)
		var turns = 0
		while c.state.day < 180 and not c.state.ended and turns < 400:
			turns += 1
			for issue in c.state.issues.duplicate():
				match issue.kind:
					"medical": c.resolve_issue(issue.id, "care" if c.available_funds() >= 2000 else "standard")
					"team_conflict": c.resolve_issue(issue.id, "mediate")
					"deadline": c.resolve_issue(issue.id, "continue")
					"salary": c.resolve_issue(issue.id, "pay" if c.available_funds() >= c.state.arrears else "release")
			if c.state.ownership_debt > 0: c.settle_ownership_debt()
			if c.state.supplies < 60 and c.state.orders.is_empty(): c.order_supplies(false)
			for person in c.state.staff:
				if c.promotion_eligible(person.id) and not c.personnel_deployed(person.id): c.promote(person.id)
			if c.state.active.is_empty():
				var team = []
				for i in range(c.state.mechs.size()):
					if c.state.mechs[i].hp < 80 and not c.state.mechs[i].repair: c.repair(i)
					if team.size() < 4 and c.mech_ready(i) and c.state.mechs[i].hp >= 80 and not c.state.mechs[i].repair and c.person_available(c.pilot_for(i)): team.append(i)
				if team.size() >= 3:
					if c.state.accepted.is_empty(): c.accept_contract(0)
					c.dispatch(0, team, seed_value % 3)
			c.advance()
		check(c.state.day == 180 or c.state.ended, "personal campaign reaches horizon %d" % seed_value)
		var balance = int(c.state.opening_balance)
		for entry in c.state.ledger: balance += int(entry.amount)
		check(c.state.funds == balance and c.state.funds >= c.committed_payments() and c.state.supplies >= 0, "personal economy reconciles %d" % seed_value)
		check(c.state.staff[0].missions >= 3 and c.state.staff[0].memories.size() >= 3 and not c.state.bonds.is_empty(), "campaign produces service histories and bonds %d" % seed_value)
		outcomes.append(c.state.funds)
	check(outcomes.min() != outcomes.max(), "career campaigns have different outcomes")

func causal_operations():
	var c = Campaign.new()
	c.state.offers[0].difficulty = 100
	c.state.mechs[0].hp = 40
	c.state.mechs[1].hp = 40
	c.accept_contract(0)
	c.dispatch(0, [0, 1], 1)
	c.advance(7)
	check(c.state.day == 3 and c.state.issues.size() == 1 and c.state.issues[0].kind == "medical", "actual combat injury produces paused medical story")
	check(c.person_by_id(0).experience == 1 and c.person_by_id(0).fatigue == 32, "failed operation applies experience and fatigue")
	var conflicts = Campaign.new()
	for n in range(2):
		conflicts._refresh_offers()
		conflicts.state.offers[0].difficulty = 100
		conflicts.state.mechs[0].hp = 100
		conflicts.state.mechs[1].hp = 100
		conflicts.accept_contract(0)
		conflicts.dispatch(0, [0, 1], 1)
		conflicts.advance(3)
	check(conflicts.state.issues.size() == 1 and conflicts.state.issues[0].kind == "team_conflict", "actual repeated failure generates a team conflict")
