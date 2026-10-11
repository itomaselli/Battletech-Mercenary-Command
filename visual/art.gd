extends RefCounted
## Original indexed artwork. Only 0/background, 1/main, 2/detail are rasterized.
const WIDTH = 80
const HEIGHT = 25
const TILE = Vector2i(16, 24)
const GENERATOR_VERSION = 1
const PALETTE = ["0d282b", "193c40", "305658", "527474", "9cbab0", "e0e5cd", "697344", "95a35c", "c9bb75", "dba950", "8c533e", "cb7050", "744553", "b57786", "4e638c", "849bbc", "378c8b", "70c7b0"]
static var cache = {}

static func color(index: int) -> Color:
	return Color(PALETTE[index])

static func mask() -> PackedByteArray:
	var data = PackedByteArray()
	data.resize(16 * 24)
	return data

static func rect(data: PackedByteArray, x: int, y: int, w: int, h: int, value: int):
	for yy in range(maxi(0, y), mini(24, y + h)):
		for xx in range(maxi(0, x), mini(16, x + w)): data[yy * 16 + xx] = value

static func raster(data: PackedByteArray, primary: int, detail: int) -> Image:
	var image = Image.create(16, 24, false, Image.FORMAT_RGB8)
	var colors = [color(0), color(primary), color(detail)]
	for y in range(24):
		for x in range(16): image.set_pixel(x, y, colors[data[y * 16 + x]])
	return image

static func tile(kind: int, variant: int = 0) -> Image:
	var key = "%d/%d" % [kind, variant]
	if cache.has(key): return cache[key]
	var data = mask()
	var primary = 2
	var detail = 3
	match kind:
		0: # Open ground: scattered grasses
			for n in range(4): rect(data, (n * 7 + variant * 3) % 14, (n * 5 + variant * 7) % 22, 1, 2, 1)
			for n in range(2): rect(data, (n * 9 + variant) % 15, 7 + n * 9, 2, 1, 2)
		1: # Trees with tiered crown
			primary = 6
			detail = 7
			rect(data, 7, 15, 2, 6, 1)
			for n in range(5): rect(data, 7 - n, 3 + n * 3, 2 + n * 2, 3, 1)
			rect(data, 6, 8 + variant, 2, 7, 2)
		2: # Rock strata
			primary = 3
			detail = 4
			for n in range(6): rect(data, 6 - n, 7 + n * 2, 3 + n * 2, 2, 1)
			rect(data, 5, 9, 2, 7, 2)
			rect(data, 8, 16 + variant, 5, 1, 2)
		3: # Water, two-tone wave bands
			primary = 1
			detail = 16
			rect(data, 0, 0, 16, 24, 1)
			for n in range(3): rect(data, (n * 3 + variant * 2) % 9, 4 + n * 7, 6, 1, 2)
		4: # East-west road
			primary = 3
			detail = 8
			rect(data, 0, 8, 16, 9, 1)
			rect(data, 2 + variant, 12, 6, 1, 2)
		5: # North-south road
			primary = 3
			detail = 8
			rect(data, 5, 0, 6, 24, 1)
			rect(data, 7, 4 + variant, 1, 7, 2)
		6: # Depot
			primary = 4
			detail = 9
			rect(data, 2, 7, 12, 14, 1)
			rect(data, 4, 4, 8, 3, 1)
			rect(data, 5, 13, 6, 8, 0)
			rect(data, 4, 9, 8, 2, 2)
		7: # Radar tower
			primary = 4
			detail = 17
			rect(data, 7, 6, 2, 16, 1)
			rect(data, 4, 19, 8, 3, 1)
			for n in range(4): rect(data, 3 + n, 3 + n, 10 - n * 2, 1, 2)
		8: # Settlement
			primary = 8
			detail = 9
			rect(data, 2, 8, 6, 12, 1)
			rect(data, 9, 4, 5, 16, 1)
			for n in range(3): rect(data, 10, 6 + n * 4, 2, 2, 2)
			rect(data, 4, 11, 2, 2, 2)
		9: # Mech silhouette, original schematic
			primary = 4
			detail = 17
			rect(data, 6, 2, 4, 4, 1)
			rect(data, 4, 6, 8, 8, 1)
			rect(data, 1, 7, 3, 10, 1)
			rect(data, 12, 7, 3, 10, 1)
			rect(data, 4, 14, 3, 8, 1)
			rect(data, 9, 14, 3, 8, 1)
			rect(data, 6, 7, 4, 2, 2)
		10: # Landing pad
			primary = 3
			detail = 9
			rect(data, 1, 3, 14, 19, 1)
			rect(data, 3, 5, 10, 15, 0)
			rect(data, 5, 8, 2, 9, 2)
			rect(data, 9, 8, 2, 9, 2)
			rect(data, 7, 11, 2, 2, 2)
		11: # Industrial stack
			primary = 10
			detail = 8
			rect(data, 3, 10, 11, 12, 1)
			rect(data, 4, 2, 3, 10, 1)
			rect(data, 10, 5, 2, 7, 1)
			rect(data, 5, 14, 7, 2, 2)
	var image = raster(data, primary, detail)
	cache[key] = image
	return image

static func zone(seed_value: int, sector: int) -> PackedInt32Array:
	var rng = RandomNumberGenerator.new()
	rng.seed = seed_value + sector * 104729
	var cells = PackedInt32Array()
	cells.resize(WIDTH * HEIGHT)
	# Clustered terrain assembled from the small reusable tileset.
	for n in range(20):
		var cx = rng.randi_range(0, 79)
		var cy = rng.randi_range(0, 24)
		var radius = rng.randi_range(2, 6)
		var kind = 1 if n % 3 else 2
		for y in range(maxi(0, cy - radius), mini(25, cy + radius)):
			for x in range(maxi(0, cx - radius * 2), mini(80, cx + radius * 2)):
				if Vector2((x - cx) / 2.0, y - cy).length() < radius and rng.randf() > 0.16: cells[y * 80 + x] = kind
	var river = rng.randi_range(48, 64)
	for y in range(25):
		var center = river + int(sin(y * 0.3 + sector) * 4)
		for x in range(center - 2, center + 3): cells[y * 80 + x] = 3
	for x in range(80): cells[12 * 80 + x] = 4
	for y in range(25): cells[y * 80 + 25] = 5
	for n in range(16):
		var x = rng.randi_range(8, 43)
		var y = rng.randi_range(8, 17)
		if y == 12 or x == 25: continue
		cells[y * 80 + x] = 11 if sector == 2 else 8
	cells[11 * 80 + 24] = 6
	cells[11 * 80 + 26] = 7
	cells[13 * 80 + 24] = 10
	cells[13 * 80 + 26] = 9
	return cells

static func map_image(seed_value: int, sector: int) -> Image:
	var cells = zone(seed_value, sector)
	var image = Image.create(1280, 600, false, Image.FORMAT_RGB8)
	for y in range(25):
		for x in range(80): image.blit_rect(tile(cells[y * 80 + x], (x + y) % 3), Rect2i(0, 0, 16, 24), Vector2i(x * 16, y * 24))
	return image

static func portrait(seed_value: int, person_id: int) -> Image:
	var rng = RandomNumberGenerator.new()
	rng.seed = seed_value + (person_id + 100) * 65537
	var data = mask()
	# Reusable layers: shoulders, head, hair, eyes, uniform and accessory.
	var head = rng.randi_range(0, 2)
	var hair = rng.randi_range(0, 3)
	var accessory = rng.randi_range(0, 3)
	rect(data, 1, 18, 14, 6, 1)
	rect(data, 4, 16, 8, 4, 1)
	rect(data, 6, 14, 4, 5, 2)
	rect(data, 4 + head % 2, 4, 8 - head % 2, 11, 1)
	rect(data, 5, 6, 6, 8, 2)
	if hair == 0: rect(data, 4, 3, 8, 4, 1)
	elif hair == 1:
		rect(data, 3, 3, 10, 4, 1)
		rect(data, 3, 7, 2, 8, 1)
	elif hair == 2:
		rect(data, 3, 4, 10, 3, 1)
		rect(data, 11, 5, 2, 10, 1)
	rect(data, 5, 9, 2, 1, 0)
	rect(data, 9, 9, 2, 1, 0)
	rect(data, 7, 13, 3, 1, 1)
	rect(data, 7, 19, 2, 5, 0)
	rect(data, 11, 20, 2, 1, 2)
	if accessory == 1: rect(data, 4, 8, 8, 2, 1)
	elif accessory == 2:
		rect(data, 2, 7, 2, 7, 1)
		rect(data, 3, 13, 3, 1, 1)
	elif accessory == 3: rect(data, 9, 10, 1, 3, 1)
	var primary = [3, 6, 10, 12, 14, 16][rng.randi_range(0, 5)]
	var detail = [4, 5, 8, 9, 13, 15, 17][rng.randi_range(0, 6)]
	return raster(data, primary, detail)

static func portrait_view(seed_value: int, person_id: int, scale_value: int = 3) -> TextureRect:
	var view = TextureRect.new()
	view.texture = ImageTexture.create_from_image(portrait(seed_value, person_id))
	view.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	view.custom_minimum_size = Vector2(16, 24) * scale_value
	view.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	view.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	return view

# Catalog artwork is keyed by stable model ID, independently of save state.
static var unit_registry: Dictionary = {}
static var unit_cache: Dictionary = {}
static func unit_sprite(identifier: Variant) -> Image:
	# Historical callers use the seven family indices. Current UI always uses IDs.
	if identifier is int: return _legacy_unit_sprite(identifier)
	var id = str(identifier)
	if unit_cache.has(id): return unit_cache[id]
	if unit_registry.is_empty():
		unit_registry = JSON.parse_string(FileAccess.get_file_as_string("res://visual/unit_sprites.json"))
	if not unit_registry.units.has(id):
		push_warning("No unit artwork registered for " + id)
		return _legacy_unit_sprite(0)
	var entry = unit_registry.units[id]
	var data = mask()
	for y in range(24):
		for x in range(16): data[y * 16 + x] = {".":0,"#":1,"+":2}[entry.rows[y][x]]
	var result = raster(data, int(entry.palette[0]), int(entry.palette[1]))
	unit_cache[id] = result
	return result

# Preserved for compatibility with historical UI fixtures and external callers.
static func _legacy_unit_sprite(family: int) -> Image:
	var data = mask()
	family = clampi(family,0,6)
	if family == 6:
		rect(data,2,8,12,13,1)
		rect(data,4,10,8,9,2)
		rect(data,6,7,5,7,1)
		rect(data,8,2,2,9,2)
		for y in [9,13,17]:
			rect(data,2,y,2,1,2)
			rect(data,12,y,2,1,2)
	else:
		var wide = family / 2
		rect(data,6,2,4,4,1)
		rect(data,7,3,2,1,2)
		rect(data,4-wide,7,8+wide*2,7,1)
		rect(data,6,8,4,3,2)
		rect(data,4,14,3,7,1)
		rect(data,9,14,3,7,1)
		rect(data,3,21,4,2,2)
		rect(data,9,21,4,2,2)
		if family % 2 == 0:
			rect(data,1,7,2,10,1)
			rect(data,13,7,2,10,1)
			rect(data,1,15,2,2,2)
		else:
			rect(data,0,5,4,9,1)
			rect(data,12,5,4,9,1)
			rect(data,1,5,2,4,2)
			rect(data,13,5,2,4,2)
			rect(data,5,14,2,3,2)
	return raster(data, [7,16,4,14,12,10,6][family], [8,17,5,15,13,11,9][family])
