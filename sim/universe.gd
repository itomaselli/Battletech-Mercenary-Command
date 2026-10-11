extends RefCounted
static var database: Dictionary = {}
static var by_id: Dictionary = {}
static func load_data() -> Dictionary:
 if database.is_empty():
  database = JSON.parse_string(FileAccess.get_file_as_string("res://data/atlas.json"))
  for system in database.systems: by_id[system.id] = system
 return database
static func system(id: String) -> Dictionary:
 load_data()
 return by_id.get(id, {})
static func galatea() -> String:
 for item in load_data().systems:
  if item.name == "Galatea": return item.id
 return ""
static func find_systems(query: String, year: int, faction: String = "") -> Array:
 var result = []
 for item in load_data().systems:
  if not faction.is_empty() and item.affiliations[str(year)] != faction: continue
  if query.is_empty() or (item.name + " " + item.aliases).to_lower().contains(query.to_lower()): result.append(item)
 return result
static func faction_name(code: String) -> String:
 return load_data().factions.get(code, {}).get("name", code)
