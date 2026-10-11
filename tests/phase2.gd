extends SceneTree
const Campaign = preload("res://sim/campaign.gd")
const World = preload("res://sim/world.gd")
var checks = 0
var failures = 0
func check(ok: bool, message: String):
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL Phase II: ", message)
func fixture(path: String, data):
	var file = FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(data))
func ready():
	var c = Campaign.new(3027)
	c.advance(14)
	return c
func _initialize():
	var c = Campaign.new()
	check(c.state.frontier.opportunities.is_empty(), "no invented opportunity on creation")
	c.advance(7)
	check(c.state.frontier.opportunities.is_empty(), "no opportunity below need threshold")
	c.advance(7)
	check(not c.state.frontier.opportunities.is_empty(), "unmet needs generate opportunities")
	var o = c.state.frontier.opportunities[-1]
	var id = int(o.contract.id)
	check(o.contract.employer_id == "workshop_consortium", "unserved industrial need creates appropriate employer request")
	check(o.created == 14 and o.contract.expires == 21, "dated seven day window")
	var before = c.state.duplicate(true)
	c.accept_opportunity(-1)
	check(c.state == before, "unknown offer atomic")
	var cash = c.state.funds
	c.accept_opportunity(id)
	check(c.state.accepted.world_origin == id and c.state.funds == cash + o.contract.advance, "common acceptance pays advance")
	before = c.state.duplicate(true)
	c.accept_opportunity(id)
	check(c.state == before, "no double acceptance or advance")
	check(c.save_game("user://phase2_accepted.json") == OK, "save causal contract")
	var restored = Campaign.new()
	check(restored.load_game("user://phase2_accepted.json") == OK and restored.state == c.state, "load causal contract and origin")
	var demand = World.actor(c.state.world, o.contract.employer_id).private.demand
	c.cancel_contract()
	check(o.status == "failed" and World.actor(c.state.world, o.contract.employer_id).private.demand == mini(6, demand + 1), "cancellation leaves greater unresolved need")
	check(c.state.funds == cash, "cancellation returns advance through normal settlement")
	before = c.state.duplicate(true)
	c._close_opportunity(o.contract, false)
	check(c.state == before, "world consequence applied once")
	var win = ready()
	var job = win.state.frontier.opportunities[-1]
	win.accept_opportunity(job.contract.id)
	for person in win.state.staff: person.skill = 5
	win.state.morale = 100
	win.dispatch(0, [0, 1, 2, 3], 2)
	check(not win.state.active.is_empty(), "causal job uses existing deployment")
	win.advance(4)
	check(job.status == "completed" and win.state.active.is_empty(), "operation completes causal job")
	check(World.actor(win.state.world, job.contract.employer_id).private.demand < 4, "player success eases world need")
	var expired = ready()
	var expired_job = expired.state.frontier.opportunities[-1]
	expired.advance(7)
	check(expired_job.status == "expired", "unaccepted offer expires")
	before = expired.state.duplicate(true)
	expired.accept_opportunity(expired_job.contract.id)
	check(expired.state == before, "expired offer cannot pay")
	var withdrawn = ready()
	var withdrawn_job = withdrawn.state.frontier.opportunities[-1]
	World.actor(withdrawn.state.world, withdrawn_job.contract.employer_id).private.demand = 1
	withdrawn.advance(1)
	check(withdrawn_job.status == "withdrawn", "reduced need withdraws unaccepted request")
	var fixed = ready()
	var fixed_job = fixed.state.frontier.opportunities[-1]
	fixed.accept_opportunity(fixed_job.contract.id)
	var agreed = fixed.state.accepted.duplicate(true)
	World.actor(fixed.state.world, fixed_job.contract.employer_id).private.demand = 1
	fixed.advance(1)
	check(fixed.state.accepted == agreed and fixed_job.status == "accepted", "accepted terms survive changed need")
	var intel = Campaign.new()
	before = intel.state.duplicate(true)
	intel.request_world_report("grey_lances")
	check(intel.state == before, "report needs established contact")
	intel.establish_contact("grey_lances")
	cash = intel.state.funds
	var rng_state = intel.rng.state
	intel.request_world_report("grey_lances")
	check(intel.state.funds == cash - 500 and intel.frontier_report("grey_lances").pending, "report charged and pending")
	check(intel.frontier_report("grey_lances").report.is_empty(), "pending intel not exposed early")
	before = intel.state.duplicate(true)
	intel.request_world_report("grey_lances")
	check(intel.state == before, "duplicate query atomic")
	check(intel.save_game("user://phase2_query.json") == OK, "pending query saved")
	var loaded = Campaign.new()
	check(loaded.load_game("user://phase2_query.json") == OK, "pending query loaded")
	intel.advance(2)
	loaded.advance(2)
	check(loaded.state == intel.state, "delayed report survives load exactly")
	var report = intel.frontier_report("grey_lances")
	check(not report.pending and report.report.observed == 0 and report.report.received == 2, "observation and receipt dates distinct")
	before = intel.state.duplicate(true)
	intel.request_world_report("grey_lances")
	check(intel.state == before, "report cooldown prevents spending loop")
	intel.advance(7)
	check(intel.frontier_report("grey_lances").report.stale, "old knowledge explicitly ages")
	intel.request_world_report("grey_lances")
	check(intel.frontier_report("grey_lances").pending, "contact can provide later update")
	check(intel.rng.state == rng_state, "world intel never consumes combat RNG")
	var visible = JSON.stringify(intel.frontier_report("grey_lances"))
	check(not visible.contains("capacity") and not visible.contains("commitments") and not visible.contains("difficulty"), "public projection protects internal facts")
	var public_links = c.world_report().links
	check(public_links.any(func(link): return link.source.contains("Comunicado")), "declared results update public relationships")
	intel.advance(2)
	check(intel.state.chronicle.any(func(entry): return JSON.stringify(entry).contains("revisa su declaración")), "changed contact assessment preserves correction in chronicle")
	var poor = Campaign.new()
	poor.establish_contact("trade_league")
	poor.state.funds = 499
	before = poor.state.duplicate(true)
	poor.request_world_report("trade_league")
	check(poor.state == before, "unaffordable report is atomic")
	var failure = ready()
	var failed_job = failure.state.frontier.opportunities[-1]
	failure.accept_opportunity(failed_job.contract.id)
	for person in failure.state.staff: person.skill = 0
	failure.state.morale = 1
	failure.dispatch(0, [0, 1, 2, 3], 1)
	failure.advance(4)
	check(failed_job.status == "failed", "failed operation closes world opportunity")
	check(World.actor(failure.state.world, failed_job.contract.employer_id).private.demand >= 5, "operation failure leaves need unresolved")
	var legacy = ready().state.duplicate(true)
	legacy.version = 14
	legacy.erase("frontier")
	legacy.rng_state = str(Campaign.new().rng.state)
	fixture("user://phase2_legacy.json", legacy)
	var migrated = Campaign.new()
	check(migrated.load_game("user://phase2_legacy.json") == OK, "v0.6 migration")
	check(migrated.state.frontier.since == legacy.day and migrated.state.frontier.opportunities.is_empty() and migrated.state.world == legacy.world and migrated.state.chronicle == legacy.chronicle, "migration preserves world with no retroactive opportunities")
	var bad = restored.state.duplicate(true)
	bad.rng_state = str(restored.rng.state)
	bad.frontier.opportunities[-1].contract.world_origin = -7
	fixture("user://phase2_bad.json", bad)
	before = restored.state.duplicate(true)
	check(restored.load_game("user://phase2_bad.json") == ERR_INVALID_DATA and restored.state == before, "invalid origin rejected without changing campaign")
	var long_run = Campaign.new()
	for day in range(1, 181):
		long_run.advance(1)
		check(long_run._valid_frontier(long_run.state), "consistent frontier on day %d" % day)
	check(long_run.state.day == 180, "six months reached")
	check(long_run.state.frontier.opportunities.size() <= 40, "bounded opportunity archive")
	print("Phase II: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
