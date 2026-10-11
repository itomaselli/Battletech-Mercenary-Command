extends RefCounted
static var records = []
static func all() -> Array:
 if records.is_empty(): records = JSON.parse_string(FileAccess.get_file_as_string("res://data/factions.json"))
 return records
static func available(year: int) -> Array:
 return all().filter(func(item): return item.known_from <= year)
static func get_actor(id: String) -> Dictionary:
 for item in all():
  if item.id == id: return item
 return {}
static func id_for_name(name: String) -> String:
 for item in all():
  if item.name == name: return item.id
 return ""
static func activity(year: int) -> Dictionary:
 var result = {}
 for actor in available(year): result[actor.id] = {"day":0,"text":"Sin boletín reciente.","cycles":0}
 return result
static func tick(records_state: Dictionary, year: int, day: int, seed_value: int, code: String, region: Dictionary) -> Array:
 var reports = []
 if day % 7 != 0: return reports
 for actor in available(year):
  var entry = records_state[actor.id]
  entry.cycles += 1
  entry.day = day
  var dice = RandomNumberGenerator.new()
  dice.seed = seed_value + day*3571 + actor.id.hash()
  var outcome = dice.randi_range(0,2)
  var local = code in actor.codes
  if actor.kind == "Clan":
   entry.text = ["Fuentes fronterizas informan actividad de patrullas; capacidad sin confirmar.","El boletín comercial advierte controles de paso en su zona.","Fuentes de tránsito comunican menor actividad observada; no confirma retirada."][outcome]
   if local: region.pressure = clampi(int(region.pressure)+(1 if outcome<2 else -1),0,8)
  elif actor.kind == "Mercenarios":
   entry.text = ["La oficina de enlace anuncia un nuevo encargo; destino reservado.","Su enlace comunica cierre de un contrato y disponibilidad limitada.","La oficina informa un período de reorganización y mantenimiento."][outcome]
  else:
   entry.text = ["La oficina comercial solicita cobertura adicional para sus servicios.","El enlace informa finalización de contratos de seguridad.","El boletín de proveedores anuncia una entrega de repuestos."][outcome]
   if local:
    if outcome == 0: region.pressure = mini(8,int(region.pressure)+1)
    elif outcome == 1: region.pressure = maxi(0,int(region.pressure)-1)
    else: region.supply = mini(5,int(region.supply)+1)
  if local: reports.append({"name":actor.name,"text":entry.text})
 return reports
static func valid_activity(value: Variant, year: int, day: int) -> bool:
 if not value is Dictionary or value.size() != available(year).size(): return false
 for actor in available(year):
  var entry = value.get(actor.id)
  if not entry is Dictionary or not entry.get("text") is String: return false
  if not preload("res://sim/operations.gd").integer(entry.get("day"),0,day) or not preload("res://sim/operations.gd").integer(entry.get("cycles"),0,day): return false
 return true
