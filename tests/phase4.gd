extends SceneTree
const Art = preload("res://visual/art.gd")
const Campaign = preload("res://sim/campaign.gd")
const Settings = preload("res://visual/settings.gd")
var checks = 0
var failures = 0
func check(ok: bool, message: String):
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL Phase IV: ", message)
func verify_tile(image: Image) -> bool:
	if image.get_size() != Vector2i(16, 24): return false
	var colors = {}
	for y in range(24):
		for x in range(16): colors[image.get_pixel(x, y).to_html(false)] = true
	if colors.size() < 2 or colors.size() > 3: return false
	for value in colors:
		if not value in Art.PALETTE: return false
	return true
func _initialize():
	check(Art.PALETTE.size() == 18, "fixed eighteen color palette")
	var sheet = Image.create(12 * 16, 3 * 24, false, Image.FORMAT_RGB8)
	for kind in range(12):
		for variant in range(3):
			var tile = Art.tile(kind, variant)
			check(verify_tile(tile), "three color indexed tile %d/%d" % [kind, variant])
			sheet.blit_rect(tile, Rect2i(0, 0, 16, 24), Vector2i(kind * 16, variant * 24))
	sheet.save_png("res://assets/original-tiles.png")
	var portraits = Image.create(20 * 16, 5 * 24, false, Image.FORMAT_RGB8)
	var unique = {}
	for id in range(100):
		var portrait = Art.portrait(3027, id)
		check(verify_tile(portrait), "three color portrait %d" % id)
		unique[portrait.get_data().hex_encode()] = true
		portraits.blit_rect(portrait, Rect2i(0, 0, 16, 24), Vector2i((id % 20) * 16, (id / 20) * 24))
	portraits.save_png("res://assets/portrait-examples.png")
	check(unique.size() > 75, "meaningful portrait variety")
	check(Art.portrait(3027, 3).get_data() == Art.portrait(3027, 3).get_data(), "portrait reproducible")
	check(Art.portrait(3027, 3).get_data() != Art.portrait(62, 3).get_data(), "campaign seed varies portrait")
	for sector in range(3):
		var zone = Art.zone(3027, sector)
		check(zone.size() == 2000, "eighty by twenty five zone")
		check(zone == Art.zone(3027, sector), "zone reproducible")
		check(zone != Art.zone(735, sector), "zones vary with seed")
		var image = Art.map_image(3027, sector)
		check(image.get_size() == Vector2i(1280, 600), "native map dimensions")
		for y in range(25):
			for x in range(80):
				check(verify_tile(image.get_region(Rect2i(x * 16, y * 24, 16, 24))), "composed map cell respects palette")
	var c = Campaign.new(36)
	var rng_state = c.rng.state
	var state = c.state.duplicate(true)
	Art.map_image(c.state.military.seed, 0)
	Art.portrait(c.state.military.seed, c.state.staff[0].id)
	check(c.state == state and c.rng.state == rng_state, "graphics never mutate simulation")
	c.accept_contract(0)
	c.dispatch(0, [0, 1, 2, 3], 1)
	check(c.save_game("user://phase4_campaign.json") == OK, "save existing format unchanged")
	var restored = Campaign.new()
	check(restored.load_game("user://phase4_campaign.json") == OK, "load existing campaign")
	check(Art.map_image(c.state.military.seed, 0).get_data() == Art.map_image(restored.state.military.seed, 0).get_data(), "map persists via seed")
	c.advance(3)
	restored.advance(3)
	check(c.state == restored.state, "simulation outcomes unchanged by rendering")
	var options = Settings.new()
	options.path = "user://phase4_settings.cfg"
	options.scanlines = false
	options.vignette = false
	options.animation = false
	check(options.save_settings() == OK, "visual settings saved separately")
	var loaded = Settings.new()
	loaded.path = options.path
	loaded.load_settings()
	check(not loaded.scanlines and not loaded.vignette and not loaded.animation, "effect preferences persist")
	print("Phase IV: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
