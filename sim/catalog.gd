extends RefCounted
static var records: Array = []
static func all() -> Array:
 if records.is_empty(): records = JSON.parse_string(FileAccess.get_file_as_string("res://data/units.json"))
 return records
static func eligible(year: int) -> Array:
 var result = []
 for i in range(all().size()):
  if all()[i].year <= year: result.append(i)
 return result
static func describe(unit: Dictionary) -> String:
 var p = unit.profile
 return "%s · %d t · introducción %d\n%s · %s · marcha %d / salto %d\nPerfil de juego: movilidad %d · protección %d · fuego %d · apoyo %d · reconocimiento %d · carga %d\nDotación de juego: %d · mantenimiento %d/día\nArmamento: %s" % [unit.name,unit.mass,unit.year,unit.tech,unit.motion,unit.walk,unit.jump,p.mobility,p.protection,p.firepower,p.support,p.recon,p.cargo,unit.crew,unit.maintenance,", ".join(unit.weapons)]
