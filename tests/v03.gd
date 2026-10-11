extends SceneTree
const Campaign = preload("res://sim/campaign.gd")
var checks = 0
var failures = 0
func check(ok: bool, label: String):
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL v0.3: ", label)
func _initialize():
	hangar()
	market()
	ownership()
	persistence()
	edges()
	long_campaigns()
	print("v0.3: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
func extra_mech(c):
	var mech = c.state.mechs[0].duplicate(true)
	mech.uid = c.state.next_mech_uid
	mech.pilot_id = -1
	c.state.next_mech_uid += 1
	c.state.mechs.append(mech)
func hangar():
	var c = Campaign.new()
	extra_mech(c)
	c.hire(0)
	c.assign_pilot(4, 6)
	check(c.pilot_for(4).id == 6, "fifth machine can receive reserve pilot")
	c.accept_contract(0)
	c.dispatch(0, [0, 1, 2, 3, 4], 1)
	check(c.state.active.is_empty(), "maximum four deployed")
	c.dispatch(0, [1, 2, 3, 4], 1, 6)
	check(not c.state.active.is_empty() and c.personnel_deployed(6), "reserve machine can deploy and lead")
	c.assign_pilot(4, -1)
	check(c.pilot_for(4).id == 6, "deployed reserve assignment locked")
	c.advance(3)
	c.state.mechs[4].hp = 70
	c.repair(4)
	c.advance()
	check(c.state.mechs[4].hp == 80, "workshop repairs fifth machine")
	check(c.save_game("user://v03_hangar.json") == OK, "save expanded hangar")
	var loaded = Campaign.new()
	check(loaded.load_game("user://v03_hangar.json") == OK and loaded.state == c.state, "expanded hangar roundtrip")

func market():
	var c = Campaign.new()
	var offer = c.state.mech_market[0].duplicate(true)
	var funds = c.state.funds
	c.purchase_mech(offer.id, offer.price)
	check(c.state.mechs.size() == 4 and c.state.mech_orders.size() == 1 and c.hangar_used() == 5, "purchase reserves a hangar slot before delivery")
	check(c.state.funds == funds - offer.price, "purchase paid once")
	c.purchase_mech(offer.id)
	check(c.state.funds == funds - offer.price and c.state.mech_orders.size() == 1, "duplicate purchase rejected")
	c.advance(offer.days)
	check(c.state.mech_orders.is_empty() and c.state.mechs.size() == 5 and c.state.mechs[4].hp == offer.hp, "delivery preserves purchased condition")
	check(c.pilot_for(4).is_empty(), "purchase does not invent a pilot")
	c.advance()
	check(c.state.mechs.size() == 5, "delivery cannot duplicate")
	var price = c.sale_quote(4)
	check(price < offer.price, "dealer spread prevents instant resale profit")
	c.sell_mech(4, price)
	funds = c.state.funds
	c.sell_mech(4, price)
	check(c.state.mechs.size() == 4 and c.state.funds == funds, "sale cannot duplicate")
	var rotation = Campaign.new()
	rotation.state.mechs[1].hp = 50
	rotation.repair(1)
	rotation.accept_contract(0)
	rotation.dispatch(0, [2, 3], 1)
	rotation.sell_mech(0)
	check(rotation.state.active.team == [1, 2] and rotation.state.repair_queue == [0], "sale remaps deployed team and workshop queue")
	check(rotation.pilot_for(1).id == 2 and rotation.pilot_for(2).id == 3, "sale preserves deployed pilots")
	rotation.sell_mech(2)
	rotation.sell_mech(1)
	check(rotation.state.mechs.size() == 3, "deployed and repairing sales blocked")
	rotation.advance(3)
	check(rotation.state.active.is_empty() and rotation.state.mechs[0].hp == 80, "operation and repair continue after sale")
	var full = Campaign.new()
	full.state.funds = 1000000
	for item in full.state.mech_market.duplicate(): full.purchase_mech(item.id)
	check(full.hangar_used() == 8, "all transit slots count toward capacity")
	full._refresh_mech_market(full.state)
	var before = full.state.duplicate(true)
	full.purchase_mech(full.state.mech_market[0].id)
	check(full.state == before, "full hangar rejects purchase atomically")
	var renewal = Campaign.new()
	var old_lot = renewal.state.mech_market[0].id
	renewal.advance(14)
	renewal.purchase_mech(old_lot)
	check(renewal.state.mech_orders.is_empty() and renewal.state.mech_market[0].id != old_lot, "stale lot cannot purchase a refreshed offer")
	var poor = Campaign.new()
	poor.state.funds = 1
	before = poor.state.duplicate(true)
	poor.purchase_mech(poor.state.mech_market[0].id)
	check(poor.state == before, "insufficient purchase funds leave state intact")

func ownership():
	var c = Campaign.new()
	var daily = c.ownership_daily()
	check(daily == 345, "initial daily maintenance and storage tariff")
	c.advance(10)
	check(c.state.ownership_due == daily * 10 and c.state.funds == 240000, "costs accrue before cash billing")
	var before = c.state.ownership_due
	c.set_stored(0, true)
	check(c.state.mechs[0].stored and c.state.mechs[0].pilot_id == -1 and c.ownership_daily() == daily - 60, "storage frees pilot and removes maintenance")
	c.advance()
	check(c.state.ownership_due == before + daily - 60, "storage retains earlier accrued costs")
	c.assign_pilot(0, 0)
	check(c.state.mechs[0].pilot_id == -1, "stored unit cannot receive pilot")
	c.set_stored(0, false)
	check(not c.mech_ready(0) and c.state.funds == 239000, "reactivation costs money and two days")
	c.assign_pilot(0, 0)
	c.accept_contract(0)
	c.dispatch(0, [0, 1], 1)
	check(c.state.active.is_empty(), "reactivating unit cannot deploy")
	c.advance(2)
	c.dispatch(0, [0, 1], 1)
	check(not c.state.active.is_empty(), "reactivated unit can deploy")
	var sold = Campaign.new()
	sold.advance(5)
	before = sold.state.ownership_due
	sold.sell_mech(0)
	check(sold.state.ownership_due == before, "sale cannot erase accrued costs")
	var bill = Campaign.new()
	bill.advance(30)
	check(bill.state.funds == 240000 - 37000 - 10350 and bill.state.ownership_due == 0 and bill.state.ownership_debt == 0, "monthly billing after payroll")
	var balance = int(bill.state.opening_balance)
	for entry in bill.state.ledger: balance += int(entry.amount)
	check(balance == bill.state.funds, "ownership expenses reconcile in ledger")
	var poor = Campaign.new()
	poor.state.funds = 37000
	poor.advance(30)
	check(poor.state.ownership_debt == 10350, "unpaid ownership becomes debt")
	poor.accept_contract(0)
	poor.dispatch(0, [0, 1], 1)
	poor.purchase_mech(poor.state.mech_market[0].id)
	check(poor.state.active.is_empty() and poor.state.mech_orders.is_empty(), "ownership debt blocks new deployment and purchases")
	poor.sell_mech(0)
	poor.settle_ownership_debt()
	check(poor.state.ownership_debt == 0, "selling a machine can pay ownership debt")
	var projection = Campaign.new()
	var offer = projection.state.mech_market[0]
	projection.purchase_mech(offer.id)
	var expected = 10350 + (31 - offer.days) * 70
	check(projection.ownership_forecast().next_bill == expected, "forecast includes deliveries from arrival day")
	projection.advance(30)
	check(projection.state.ownership_due == 0 and projection.state.funds == 240000 - offer.price - 37000 - expected, "predicted bill equals actual bill")

func write_fixture(path: String, data):
	var file = FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(data))
	file.close()

func ledger_balance(c) -> int:
	var cash = int(c.state.opening_balance)
	for entry in c.state.ledger: cash += int(entry.amount)
	return cash

func persistence():
	var c = Campaign.new(62)
	c.set_identity("La Guardia del Sur", "Iván")
	c.purchase_mech(c.state.mech_market[0].id)
	c.state.mechs[1].hp = 50
	c.repair(1)
	c.set_stored(0, true)
	c.accept_contract(0)
	c.dispatch(0, [2, 3], 1)
	c.advance()
	check(c.save_game("user://v03_transit.json") == OK, "save operation, purchase, storage and workshop")
	var restored = Campaign.new(12)
	check(restored.load_game("user://v03_transit.json") == OK and restored.state == c.state, "restore full expanded campaign")
	c.advance(5)
	restored.advance(5)
	check(c.state == restored.state, "continued deliveries and operations are deterministic")
	for version in [6, 7, 8]:
		var old = Campaign.new()
		old.set_identity("Veteranos", "Ana")
		old.accept_contract(0)
		old.dispatch(0, [0, 1, 2, 3], 1)
		old.state.mechs[2].hp = 70
		var fixture = old.state.duplicate(true)
		fixture.version = version
		fixture["rng_state"] = str(old.rng.state)
		for key in ["ownership_due", "ownership_debt"]: fixture.erase(key)
		for mech in fixture.mechs:
			mech.erase("stored")
			mech.erase("ready_day")
		if version < 8:
			for key in ["market_seed", "mech_market", "mech_orders", "next_market_id"]: fixture.erase(key)
			for mech in fixture.mechs: mech.erase("model")
		if version < 7:
			fixture.erase("next_mech_uid")
			for mech in fixture.mechs: mech.erase("uid")
		write_fixture("user://v03_legacy.json", fixture)
		var upgraded = Campaign.new()
		check(upgraded.load_game("user://v03_legacy.json") == OK, "migrate schema %d" % version)
		check(upgraded.state.company_name == "Veteranos" and upgraded.state.funds == old.state.funds and upgraded.state.mechs[2].hp == 70, "migration preserves identity, cash and damage %d" % version)
		check(upgraded.state.active.team == [0, 1, 2, 3] and upgraded.state.ownership_due == 0, "migration preserves operation without retroactive maintenance %d" % version)
		upgraded.advance(3)
		check(upgraded.state.active.is_empty(), "migrated operation resolves %d" % version)
	var invalid = c.state.duplicate(true)
	invalid["rng_state"] = str(c.rng.state)
	invalid.mechs[1].uid = invalid.mechs[0].uid
	write_fixture("user://v03_invalid.json", invalid)
	var before = restored.state.duplicate(true)
	check(restored.load_game("user://v03_invalid.json") == ERR_INVALID_DATA and restored.state == before, "duplicate machine serial rejected atomically")
	var empty = Campaign.new()
	for mech in empty.state.mechs.duplicate(): empty.sell_mech(mech.uid)
	empty.save_game("user://v03_empty.json")
	check(restored.load_game("user://v03_empty.json") == OK and restored.state.mechs.is_empty(), "empty hangar can save and load")
	restored.purchase_mech(restored.state.mech_market[0].id)
	restored.advance(4)
	check(restored.state.mechs.size() == 1, "empty hangar can recover through market")

func edges():
	var c = Campaign.new()
	var before = c.state.duplicate(true)
	c.purchase_mech(c.state.mech_market[0].id, 1)
	c.sell_mech(0, 1)
	check(c.state == before, "stale price confirmation rejected without mutation")
	c.state.mechs[0].hp = 20
	c.repair(0)
	c.set_stored(0, true)
	check(not c.state.mechs[0].stored, "cannot store machine during repair")
	c.repair(0)
	c.set_stored(0, true)
	c.repair(0)
	check(not c.state.mechs[0].repair, "stored machine cannot repair")
	c.set_stored(0, false)
	c.set_stored(0, true)
	check(not c.state.mechs[0].stored, "reactivation cannot be cycled during its delay")
	var quote = c.acquisition_estimate(c.state.mech_market[0].id)
	check(quote.total == quote.purchase + quote.repair + quote.supplies_value + quote.monthly, "ownership comparison includes all displayed components")
	var closed = Campaign.new()
	closed.state.ended = true
	before = closed.state.duplicate(true)
	closed.purchase_mech(closed.state.mech_market[0].id)
	closed.sell_mech(0)
	closed.set_stored(0, true)
	closed.settle_ownership_debt()
	check(closed.state == before, "closed campaign rejects hangar commands")
	var expiry = Campaign.new()
	expiry.state.day = 13
	var id = expiry.state.mech_market[0].id
	expiry.purchase_mech(id)
	expiry.advance(4)
	check(expiry.state.mechs.size() == 5 and expiry.state.mech_orders.is_empty(), "market refresh cannot erase a paid purchase")
	var reserved = Campaign.new()
	reserved.state.funds = 65000
	reserved.order_supplies(false)
	before = reserved.state.duplicate(true)
	reserved.purchase_mech(reserved.state.mech_market[0].id)
	check(reserved.state == before, "market cannot spend cash reserved for supply delivery")

func long_campaigns():
	var end_days = []
	for seed_value in range(20):
		var c = Campaign.new(seed_value)
		c.hire(1)
		c.hire(0)
		c.purchase_mech(c.state.mech_market[0].id)
		var turns = 0
		var sold = false
		while c.state.day < 180 and not c.state.ended and turns < 400:
			turns += 1
			for issue in c.state.issues.duplicate():
				if issue.kind == "medical": c.resolve_issue(issue.id, "standard")
				elif issue.kind == "team_conflict": c.resolve_issue(issue.id, "separate")
				elif issue.kind == "deadline": c.resolve_issue(issue.id, "continue")
				else: c.resolve_issue(issue.id, "pay" if c.available_funds() >= c.state.arrears else "release")
			if c.state.ownership_debt > 0: c.settle_ownership_debt()
			if c.state.supplies < 60 and c.state.orders.is_empty(): c.order_supplies(false)
			if not sold and c.state.day >= 90 and c.mech_index(4) >= 0 and not c.deployed(c.mech_index(4)):
				var index = c.mech_index(4)
				if c.state.mechs[index].repair: c.repair(index)
				c.sell_mech(4)
				sold = true
			if c.mech_index(4) >= 0 and c.pilot_for(c.mech_index(4)).is_empty(): c.assign_pilot(c.mech_index(4), 7)
			if c.state.active.is_empty():
				var team = []
				for i in range(c.state.mechs.size() - 1, -1, -1):
					if c.state.mechs[i].hp < 80 and not c.state.mechs[i].repair: c.repair(i)
					if team.size() < 4 and c.mech_ready(i) and c.state.mechs[i].hp >= 80 and not c.state.mechs[i].repair and not c.pilot_for(i).is_empty() and c.pilot_for(i).injury == 0: team.append(i)
				if team.size() >= 3:
					if c.state.accepted.is_empty(): c.accept_contract(0)
					c.dispatch(0, team, seed_value % 3)
			c.advance()
		check(c.state.day == 180 or c.state.ended, "market campaign reaches horizon or end %d" % seed_value)
		check(c.state.funds >= c.committed_payments() and c.state.supplies >= 0 and c.hangar_used() <= 8 and ledger_balance(c) == c.state.funds, "market campaign resources reconcile %d" % seed_value)
		check(c.mech_index(4) == -1 and sold, "reserve rotated and sold during campaign %d" % seed_value)
		end_days.append(c.state.day)
	print("Market campaigns: day range %d-%d" % [end_days.min(), end_days.max()])
