extends RefCounted
## Operational facts and commander-visible reports are deliberately separate.
const APPROACHES = ["direct", "recon"]
const AUTHORITIES = ["delegate", "consult"]
const PRIORITIES = ["objective", "preserve"]

static func plan() -> Dictionary:
	return {"approach": "direct", "authority": "delegate", "priority": "objective"}

static func create(seed_value: int) -> Dictionary:
	return {"seed": seed_value, "sequence": 0, "plan": plan(), "current": {}, "archive": []}

static func valid_plan(value: Variant) -> bool:
	return value is Dictionary and value.get("approach") in APPROACHES and value.get("authority") in AUTHORITIES and value.get("priority") in PRIORITIES

static func begin(data: Dictionary, day: int, leader: String, contract: String, team: Array) -> Dictionary:
	data.sequence += 1
	var dice = RandomNumberGenerator.new()
	dice.seed = int(data.seed) + int(data.sequence) * 7919
	var orders = data.plan.duplicate(true)
	var current = {"id": int(data.sequence), "started": day, "elapsed": 0, "phase": "Salida",
		"leader": leader, "contract": contract, "orders": orders, "pending_order": {}, "decision": false,
		"encountered": false, "response": "", "reports": [], "team": team.duplicate(true),
		"private": {"severity": dice.randi_range(0, 2), "obstacle": dice.randi_range(0, 2),
			"bonus": 2 if orders.approach == "recon" else 0, "damage": -2 if orders.approach == "recon" else 0}}
	data.current = current
	return current

static func add_report(current: Dictionary, day: int, message: String):
	current.reports.append({"day": day, "source": current.leader, "text": message})

static func public_orders(orders: Dictionary) -> Dictionary:
	return {"approach": orders.approach, "authority": orders.authority, "priority": orders.priority}

static func public_reports(reports: Array) -> Array:
	var result = []
	for report in reports: result.append({"day": report.day, "source": report.source, "text": report.text})
	return result

static func public_report(data: Dictionary, day: int) -> Dictionary:
	var archive = []
	for entry in data.archive:
		var losses = []
		for loss in entry.losses: losses.append({"name": loss.name, "damage": loss.damage})
		archive.append({"id": entry.id, "started": entry.started, "ended": entry.ended, "leader": entry.leader,
			"contract": entry.contract, "outcome": entry.outcome, "orders": public_orders(entry.orders), "reports": public_reports(entry.reports), "losses": losses})
	var result = {"plan": public_orders(data.plan), "current": {}, "archive": archive}
	if data.current.is_empty(): return result
	var c = data.current
	var reports = []
	for report in c.reports:
		reports.append({"day": report.day, "source": report.source, "text": report.text})
	result.current = {"id": c.id, "started": c.started, "phase": c.phase, "leader": c.leader,
		"contract": c.contract, "orders": public_orders(c.orders), "decision": c.decision, "response": c.response,
		"order_pending": not c.pending_order.is_empty(), "reports": reports,
		"age": day - int(reports[-1].day) if not reports.is_empty() else 0}
	return result

static func integer(value: Variant, low: int, high: int) -> bool:
	return (value is int or value is float) and is_finite(float(value)) and int(value) == value and value >= low and value <= high

static func valid_reports(reports: Variant, start: int, day: int) -> bool:
	if not reports is Array or reports.size() > 60: return false
	var last = start
	for report in reports:
		if not report is Dictionary or not integer(report.get("day"), last, day): return false
		if not report.get("source") is String or not report.get("text") is String: return false
		last = int(report.day)
	return true

static func valid(data: Variant, day: int, active: Dictionary) -> bool:
	if not data is Dictionary or not valid_plan(data.get("plan")): return false
	if not integer(data.get("seed"), -9007199254740991, 9007199254740991) or not integer(data.get("sequence"), 0, 1000000): return false
	if not data.get("current") is Dictionary or not data.get("archive") is Array or data.archive.size() > 30: return false
	var c = data.current
	if not c.is_empty():
		if active.is_empty() or not integer(c.get("id"), 1, data.sequence) or not integer(c.get("started"), 0, day): return false
		if c.id != data.sequence or not integer(c.get("elapsed"), 0, day - c.started): return false
		if not c.get("phase") in ["Salida", "Aproximación", "Reconocimiento", "Contacto", "Ejecución"]: return false
		if not c.get("leader") is String or c.get("contract") != active.contract.name: return false
		if not valid_plan(c.get("orders")) or not c.get("decision") is bool or not c.get("encountered") is bool: return false
		if not c.get("response") in ["", "press", "maneuver"]: return false
		if c.decision and (not c.encountered or c.response != ""): return false
		if not c.get("team") is Array or c.team.size() != active.team.size(): return false
		for member in c.team:
			if not member is Dictionary or not member.get("name") is String or not integer(member.get("uid"), 0, 1000000000) or not integer(member.get("hp"), 0, 100): return false
		if not c.get("private") is Dictionary: return false
		var internal = c.private
		if not integer(internal.get("severity"), 0, 2) or not integer(internal.get("obstacle"), 0, 2) or not integer(internal.get("bonus"), -2, 4) or not integer(internal.get("damage"), -4, 4): return false
		if not valid_reports(c.get("reports"), c.started, day) or not c.get("pending_order") is Dictionary: return false
		if not c.pending_order.is_empty():
			if not integer(c.pending_order.get("due"), day + 1, day + 1) or not valid_plan(c.pending_order.get("orders")): return false
			if c.pending_order.orders.approach != c.orders.approach: return false
	var ids = []
	for entry in data.archive:
		if not entry is Dictionary or not integer(entry.get("id"), 1, data.sequence) or entry.id in ids: return false
		ids.append(entry.id)
		if not c.is_empty() and entry.id == c.id: return false
		if not integer(entry.get("started"), 0, day) or not integer(entry.get("ended"), entry.started, day): return false
		for key in ["contract", "leader", "outcome"]:
			if not entry.get(key) is String: return false
		if not valid_plan(entry.get("orders")) or not valid_reports(entry.get("reports"), entry.started, entry.ended): return false
		if not entry.get("losses") is Array or entry.losses.size() > 4: return false
		for loss in entry.losses:
			if not loss is Dictionary or not loss.get("name") is String or not integer(loss.get("damage"), 0, 100): return false
	return true
