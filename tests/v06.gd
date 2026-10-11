extends SceneTree
const Campaign = preload("res://sim/campaign.gd")
const World = preload("res://sim/world.gd")
var checks = 0
var failures = 0
func check(ok: bool, message: String):
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL v0.6: ", message)
func fixture(path: String, data):
	var file = FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(data))
func _initialize():
	var c = Campaign.new(71)
	var combat_rng = c.rng.state
	c.advance(7)
	var rival = World.actor(c.state.world, "grey_lances")
	check(rival.private.commitments.size() == 1, "rival takes autonomous work")
	check(rival.private.commitments[0].employer == "trade_league", "specialty influences choice")
	check(rival.private.funds == 153000, "operating and deployment expenses paid")
	check(World.actor(c.state.world, "ember_company").private.capacity == 3, "weak rival repairs before work")
	check(c.state.world.bulletins.is_empty(), "unreported assignment stays hidden")
	check(c.save_game("user://v06_active.json") == OK, "save active world jobs")
	var restored = Campaign.new()
	check(restored.load_game("user://v06_active.json") == OK, "load active world jobs")
	c.advance(7)
	restored.advance(7)
	check(c.state == restored.state, "world continues identically after load")
	check(c.state.world.bulletins.size() == 2, "two completed assignments reported once")
	check(rival.private.standing.trade_league == 1 and rival.private.capacity == 2, "success affects relations and strength")
	check(c.rng.state == combat_rng, "world does not consume combat RNG")
	check(c.state.relationships.is_empty(), "rival work does not alter player trust")
	var before = c.state.world.duplicate(true)
	World.tick(c.state.world, 14)
	check(c.state.world == before, "same date cannot resolve twice")
	var public = JSON.stringify(c.world_report())
	check(not public.contains("commitments") and not public.contains("difficulty") and not public.contains("funds"), "reports exclude exact internal facts")
	var paused = Campaign.new()
	paused.state.issues.append({"test": true})
	before = paused.state.world.duplicate(true)
	paused.advance(20)
	check(paused.state.world == before, "world respects decision pause")
	paused.state.issues.clear()
	paused.state.ended = true
	paused.advance(20)
	check(paused.state.world == before, "world stops with campaign")
	var legacy = restored.state.duplicate(true)
	legacy.version = 13
	legacy.rng_state = str(restored.rng.state)
	for key in ["activity_since", "last_day", "bulletins"]: legacy.world.erase(key)
	for item in legacy.world.actors:
		item.private.commitments.clear()
		for key in ["demand", "ready_day", "standing"]: item.private.erase(key)
	fixture("user://v06_legacy.json", legacy)
	var migrated = Campaign.new()
	check(migrated.load_game("user://v06_legacy.json") == OK, "migrate v0.5")
	check(migrated.state.world.activity_since == 14 and migrated.state.world.bulletins.is_empty() and migrated.state.chronicle == legacy.chronicle, "migration invents no past activity")
	var bad = restored.state.duplicate(true)
	bad.rng_state = str(restored.rng.state)
	bad.world.actors[6].private.commitments[0].due = -1
	fixture("user://v06_bad.json", bad)
	before = restored.state.duplicate(true)
	check(restored.load_game("user://v06_bad.json") == ERR_INVALID_DATA and restored.state == before, "bad job rejected atomically")
	var world = World.create(0)
	World.enable(world, 0)
	var saw_failure = false
	var recovered_success = false
	for day in range(1, 731):
		var news = World.tick(world, day)
		for bulletin in news:
			if saw_failure and bulletin.text.contains("completó"): recovered_success = true
			if bulletin.text.contains("no logró"): saw_failure = true
		check(World.valid(world, day), "world remains valid day %d" % day)
	check(saw_failure, "resource and demand pressure can cause failure")
	check(recovered_success, "rivals can prepare and succeed after setbacks")
	check(world.bulletins.size() <= 60, "directory history bounded")
	var broke = World.create(0)
	World.enable(broke, 0)
	World.actor(broke, "grey_lances").private.funds = 0
	for day in range(1, 8): World.tick(broke, day)
	check(World.actor(broke, "grey_lances").private.commitments.is_empty(), "insolvent rival cannot deploy")
	print("v0.6: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
