extends SceneTree
const Campaign = preload("res://sim/campaign.gd")
var checks = 0
var failures = 0
func check(condition: bool, message: String):
	checks += 1
	if not condition:
		failures += 1
		printerr("FAIL: ", message)
func _initialize():
	var c = Campaign.new(42)
	check(c.state.mechs.size() == 4 and c.state.staff.size() == 6, "initial roster")
	check(c.date_text() == "3027-05-17", "calendar epoch")
	check(c.set_identity("  Cóndores de Acero  ", "Iván Ríos"), "custom names accepted")
	check(c.state.company_name == "Cóndores de Acero" and c.state.captain_name == "Iván Ríos", "trim and Unicode names")
	var identity_before = c.state.duplicate(true)
	check(not c.set_identity(" ", "Otro") and c.state == identity_before, "blank name rejected atomically")
	check(not c.set_identity("A".repeat(49), "Otro"), "overlong name rejected")
	var legacy = c.state.duplicate(true)
	legacy.version = 1
	legacy.erase("company_name")
	legacy.erase("captain_name")
	legacy["rng_state"] = str(c.rng.state)
	var legacy_file = FileAccess.open("user://legacy_test.json", FileAccess.WRITE)
	legacy_file.store_string(JSON.stringify(legacy))
	legacy_file.close()
	var migrated = Campaign.new()
	check(migrated.load_game("user://legacy_test.json") == OK and migrated.state.company_name == Campaign.DEFAULT_COMPANY, "v1 save migration")
	check(migrated.state.funds == c.state.funds and migrated.state.chronicle == c.state.chronicle, "migration preserves progress")
	c.accept_contract(0)
	var initial = c.state.duplicate(true)
	c.dispatch(0, [0, 0], 1)
	check(c.state == initial, "duplicate deployment rejected atomically")
	c.dispatch(0, [], 1)
	check(c.state == initial, "empty deployment rejected")
	c.state.supplies = 0
	c.dispatch(0, [0], 1)
	check(c.state.active.is_empty(), "supply gate")
	c.state.supplies = 90
	c.dispatch(0, [0, 1, 2, 3], 1)
	check(c.state.supplies == 50 and c.state.active.remaining == 3, "deployment consumes supplies")
	var active = c.state.duplicate(true)
	c.dispatch(0, [0], 1)
	c.repair(0)
	check(c.state == active, "no double deployment or field repairs")
	check(c.save_game("user://test_campaign.json") == OK, "save active operation")
	var other = Campaign.new(900)
	check(other.load_game("user://test_campaign.json") == OK, "load active operation")
	c.advance(3)
	other.advance(3)
	
	check(c.state == other.state, "saved RNG reproduces consequences")
	check(c.state.active.is_empty() and c.state.mechs[0].hp < 100, "abstract combat consequences")
	c.state.mechs[0].hp = 50
	c.repair(0)
	var funds = c.state.funds
	c.advance()
	check(c.state.mechs[0].hp == 60 and c.state.funds == funds - 1000, "repair resources and progress")
	c.state.mechs[0].repair = false
	c.state.day = 29
	funds = c.state.funds
	var ownership_bill = c.state.ownership_due + c.ownership_daily() + c.state.ownership_debt
	c.advance()
	check(c.state.funds == funds - 37000 - ownership_bill, "monthly salaries")
	check(c.date_text() == "3027-06-16", "month rollover")
	c.state.day = 41
	c.advance()
	check(c.state.offers.size() == 3 and c.state.offers[0].expires == 56, "contract renewal")
	var f = FileAccess.open("user://bad.json", FileAccess.WRITE)
	f.store_string('{"version":1}')
	f.close()
	var before = c.state.duplicate(true)
	check(c.load_game("user://bad.json") == ERR_INVALID_DATA and c.state == before, "corrupt save preserves campaign")
	check(c.load_game("user://missing_test_file.json") == ERR_FILE_NOT_FOUND, "missing save")
	c.state.funds = 0
	c.state.day = 59
	c.advance()
	check(c.state.arrears == 37000, "unpaid salaries become debt")
	c.state.morale = 10
	c.state.day = 89
	c.advance()
	check(c.state.ended, "insolvency has campaign consequence")
	before = c.state.duplicate(true)
	c.advance(7)
	c.buy_supplies()
	check(c.state == before, "closed campaign immutable")
	for seed_value in range(20):
		var run = Campaign.new(seed_value)
		for day in range(180):
			if run.state.active.is_empty() and not run.state.ended:
				var team = []
				for i in range(4):
					if run.state.mechs[i].hp < 80 and not run.state.mechs[i].repair: run.repair(i)
					if run.state.mechs[i].hp >= 80 and not run.state.mechs[i].repair and run.state.staff[i].injury == 0: team.append(i)
				if run.state.supplies < 50: run.buy_supplies()
				if team.size() >= 3:
					if run.state.accepted.is_empty(): run.accept_contract(0)
					run.dispatch(0, team, seed_value % 3)
			run.advance()
		check(run.state.funds >= 0 and run.state.supplies >= 0 and run.state.chronicle.size() > 10, "six-month simulation seed %d" % seed_value)
	print("Tests: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
