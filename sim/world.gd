extends RefCounted
## Phase II foundation. Public reports are an allowlist; internal state never goes to UI.
const DEFINITIONS = [
	{"id": "trade_league", "name": "Liga comercial", "kind": "Contratante", "specialty": "Protección de rutas", "interest": "Mantener entregas y reducir interrupciones comerciales.", "affiliation": "Asociación comercial local", "priority": "secure_routes", "funds": 450000, "capacity": 3},
	{"id": "local_militia", "name": "Milicia local", "kind": "Contratante", "specialty": "Seguridad territorial", "interest": "Proteger instalaciones y sostener presencia en zonas periféricas.", "affiliation": "Autoridad local de la campaña", "priority": "secure_facilities", "funds": 350000, "capacity": 4},
	{"id": "davion_liaison", "name": "Enlace de la Casa Davion", "kind": "Contratante", "specialty": "Contratación militar", "interest": "Contratar fuerzas independientes para encargos concretos.", "affiliation": "Oficina ficticia vinculada a la Casa Davion", "priority": "build_influence", "funds": 600000, "capacity": 4},
	{"id": "workshop_consortium", "name": "Consorcio de talleres", "kind": "Contratante", "specialty": "Protección industrial", "interest": "Proteger depósitos y mantener acceso a suministros y reparaciones.", "affiliation": "Cooperativa industrial local", "priority": "protect_supply", "funds": 300000, "capacity": 2},
	{"id": "grey_lances", "name": "Lanzas Grises", "kind": "Compañía rival", "specialty": "Escoltas y seguridad de convoyes", "interest": "Conseguir contratos de protección de rutas.", "affiliation": "Mercenarios independientes", "priority": "seek_escort", "funds": 160000, "capacity": 3},
	{"id": "iron_watch", "name": "Guardia de Hierro", "kind": "Compañía rival", "specialty": "Guarnición y protección de instalaciones", "interest": "Buscar encargos de seguridad de larga duración.", "affiliation": "Mercenarios independientes", "priority": "seek_garrison", "funds": 220000, "capacity": 4},
	{"id": "ember_company", "name": "Compañía Ascua", "kind": "Compañía rival", "specialty": "Incursiones y operaciones breves", "interest": "Priorizar trabajos cortos y de mayor remuneración.", "affiliation": "Mercenarios independientes", "priority": "seek_raids", "funds": 130000, "capacity": 2}
]

static func create(day: int) -> Dictionary:
	var actors = []
	for definition in DEFINITIONS:
		actors.append({"id": definition.id, "name": definition.name, "kind": definition.kind,
			"specialty": definition.specialty, "interest": definition.interest, "affiliation": definition.affiliation,
			"source": "Registro local: especialidad e intereses declarados; no verificados independientemente.",
			"reported_day": day, "contact_day": -1,
			"private": {"funds": definition.funds, "capacity": definition.capacity, "priority": definition.priority, "commitments": []}})
	return {"introduced_day": day, "actors": actors, "links": [
		{"a": "trade_league", "b": "workshop_consortium", "stance": "Cooperación comercial", "source": "Declaración conjunta registrada", "reported_day": day, "public": true},
		{"a": "local_militia", "b": "iron_watch", "stance": "Antecedentes de contratación", "source": "Referencias declaradas por Guardia de Hierro", "reported_day": day, "public": true},
		{"a": "grey_lances", "b": "ember_company", "stance": "Competencia por encargos", "source": "Evaluación inicial de la oficina de contratación", "reported_day": day, "public": true}
	]}

static func actor(data: Dictionary, id: String) -> Dictionary:
	for item in data.actors:
		if item.id == id: return item
	return {}

static func id_for_name(name: String) -> String:
	for definition in DEFINITIONS:
		if definition.name == name: return definition.id
	return preload("res://sim/lore.gd").id_for_name(name)

static func public_report(data: Dictionary, trust: Dictionary, reputation: int) -> Dictionary:
	var cards = []
	for item in data.actors:
		cards.append({"id": item.id, "name": item.name, "kind": item.kind, "specialty": item.specialty,
			"interest": item.interest, "affiliation": item.affiliation, "source": item.source,
			"reported_day": item.reported_day, "contact_day": item.contact_day,
			"trust": int(trust.get(item.name, 0)), "has_history": trust.has(item.name),
			"strength_report": "Fuerza y disponibilidad actuales no confirmadas.",
			"fiction": "Actor ficticio de esta campaña; no constituye un acontecimiento oficial de BattleTech."})
	var links = []
	for link in data.links:
		if link.public:
			links.append({"a": link.a, "b": link.b, "stance": link.stance, "source": link.source, "reported_day": link.reported_day})
	var bulletins = []
	for bulletin in data.get("bulletins", []):
		bulletins.append({"day": bulletin.day, "actor_id": bulletin.actor_id, "employer_id": bulletin.employer_id, "source": bulletin.source, "text": bulletin.text})
	return {"introduced_day": data.introduced_day, "actors": cards, "links": links, "reputation": reputation, "bulletins": bulletins}

static func _integer(value: Variant, low: int, high: int) -> bool:
	return (value is int or value is float) and is_finite(float(value)) and value >= low and value <= high and int(value) == value

static func valid_base(data: Variant, day: int) -> bool:
	if not data is Dictionary or not _integer(data.get("introduced_day"), 0, day): return false
	if not data.get("actors") is Array or data.actors.size() != DEFINITIONS.size() or not data.get("links") is Array: return false
	var ids = []
	for item in data.actors:
		if not item is Dictionary: return false
		for key in ["id", "name", "kind", "specialty", "interest", "affiliation", "source"]:
			if not item.get(key) is String or item[key].is_empty(): return false
		if item.id in ids or id_for_name(item.name) != item.id or item.id.is_empty(): return false
		if not item.kind in ["Contratante", "Compañía rival"]: return false
		for definition in DEFINITIONS:
			if definition.id == item.id and definition.kind != item.kind: return false
		ids.append(item.id)
		if not _integer(item.get("reported_day"), data.introduced_day, day) or not _integer(item.get("contact_day"), -1, day): return false
		if item.contact_day != -1 and item.contact_day < data.introduced_day: return false
		var internal = item.get("private")
		if not internal is Dictionary or not _integer(internal.get("funds"), 0, 1000000000) or not _integer(internal.get("capacity"), 0, 100): return false
		if not internal.get("priority") is String or not internal.get("commitments") is Array: return false
	for link in data.links:
		if not link is Dictionary or not link.get("a") in ids or not link.get("b") in ids or link.a == link.b: return false
		if not link.get("stance") is String or not link.get("source") is String or not link.get("public") is bool: return false
		if not _integer(link.get("reported_day"), data.introduced_day, day): return false
	return true


# Autonomous work has its own clock and no access to campaign/combat randomness.
static func enable(data: Dictionary, day: int):
	data["activity_since"] = day
	data["last_day"] = day
	data["bulletins"] = []
	for item in data.actors:
		item.private["demand"] = 2 if item.kind == "Contratante" else 0
		item.private["ready_day"] = day
		item.private["standing"] = {}

static func tick(data: Dictionary, day: int) -> Array:
	var news = []
	if day <= int(data.last_day): return news
	data.last_day = day
	for rival in data.actors:
		var internal = rival.private
		if internal.commitments.is_empty(): continue
		var job = internal.commitments[0]
		if day < int(job.due): continue
		var employer = actor(data, job.employer)
		var success = int(internal.capacity) >= int(job.difficulty)
		if success:
			employer.private.demand = maxi(0, int(employer.private.demand) - 3)
			internal.funds += int(job.reward)
		else:
			# Escrow is returned when the agreed objective is not achieved.
			employer.private.funds += int(job.reward)
		internal.capacity = maxi(0, int(internal.capacity) - (1 if success else 2))
		internal.standing[job.employer] = clampi(int(internal.standing.get(job.employer, 0)) + (1 if success else -1), -5, 5)
		internal.ready_day = day + 4
		internal.commitments.clear()
		var bulletin = {"day": day, "actor_id": rival.id, "employer_id": employer.id,
			"source": "Comunicado de %s; sin verificación independiente" % employer.name,
			"text": "%s informa que %s %s un encargo de %s. No confirma bajas ni disponibilidad posterior." % [employer.name, rival.name, "completó" if success else "no logró completar", employer.specialty.to_lower()]}
		# Only the declared work result updates the public relationship record.
		var known_link = {}
		for link in data.links:
			if link.a == employer.id and link.b == rival.id:
				known_link = link
				break
		if known_link.is_empty():
			known_link = {"a": employer.id, "b": rival.id, "public": true}
			data.links.append(known_link)
		known_link.stance = "Último encargo declarado: cumplido" if success else "Último encargo declarado: incumplido"
		known_link.source = bulletin.source
		known_link.reported_day = day
		data.bulletins.append(bulletin)
		news.append(bulletin.duplicate(true))
		if data.bulletins.size() > 60: data.bulletins.pop_front()
	if (day - int(data.activity_since)) % 7 != 0: return news
	for employer in data.actors:
		if employer.kind != "Contratante": continue
		employer.private.funds = mini(1000000, int(employer.private.funds) + 18000)
		employer.private.demand = mini(6, int(employer.private.demand) + 1)
	for rival in data.actors:
		if rival.kind != "Compañía rival": continue
		var internal = rival.private
		if not internal.commitments.is_empty() or day < int(internal.ready_day): continue
		internal.funds = maxi(0, int(internal.funds) - 3000)
		var readiness_target = 3
		# An adverse work record prompts more preparation before accepting again.
		for standing in internal.standing.values():
			if int(standing) < 0: readiness_target = 5
		if int(internal.capacity) < readiness_target:
			if int(internal.funds) >= 6000:
				internal.funds -= 6000
				internal.capacity += 1
			continue
		var chosen = {}
		var best = -100
		var preferred = {"seek_escort": "secure_routes", "seek_garrison": "secure_facilities", "seek_raids": "build_influence"}.get(internal.priority, "")
		for employer in data.actors:
			if employer.kind != "Contratante" or int(employer.private.demand) < 2 or int(employer.private.funds) < 24000: continue
			var occupied = false
			for other in data.actors:
				for job in other.private.commitments:
					if job.employer == employer.id: occupied = true
			if occupied: continue
			var score = int(employer.private.demand) * 2 + (3 if employer.private.priority == preferred else 0) + int(internal.standing.get(employer.id, 0))
			if score > best:
				best = score
				chosen = employer
		if chosen.is_empty() or int(internal.funds) < 4000: continue
		internal.funds -= 4000
		chosen.private.funds -= 24000
		internal.commitments.append({"employer": chosen.id, "started": day, "due": day + 7,
			"difficulty": 2 + int(chosen.private.demand) / 2, "reward": 24000})
	return news

static func valid(data: Variant, day: int) -> bool:
	if not valid_base(data, day): return false
	if not _integer(data.get("activity_since"), data.introduced_day, day) or not _integer(data.get("last_day"), data.activity_since, day): return false
	if int(data.last_day) != day or not data.get("bulletins") is Array or data.bulletins.size() > 60: return false
	var occupied = []
	for item in data.actors:
		var internal = item.private
		if not _integer(internal.get("demand"), 0, 6) or not _integer(internal.get("ready_day"), data.activity_since, day + 4): return false
		if not internal.get("standing") is Dictionary or internal.commitments.size() > 1: return false
		for id in internal.standing:
			var target = actor(data, id)
			if target.is_empty() or target.kind != "Contratante" or not _integer(internal.standing[id], -5, 5): return false
		for job in internal.commitments:
			if item.kind != "Compañía rival" or not job is Dictionary: return false
			if not job.get("employer") is String: return false
			var target = actor(data, job.employer)
			if target.is_empty() or target.kind != "Contratante" or job.employer in occupied: return false
			occupied.append(job.employer)
			if not _integer(job.get("started"), data.activity_since, day) or not _integer(job.get("due"), day + 1, day + 7): return false
			if job.due != job.started + 7 or not _integer(job.get("difficulty"), 2, 5) or job.get("reward") != 24000: return false
	var previous_day = int(data.activity_since)
	for bulletin in data.bulletins:
		if not bulletin is Dictionary or bulletin.size() != 5: return false
		if not _integer(bulletin.get("day"), previous_day, day): return false
		previous_day = int(bulletin.day)
		if not bulletin.get("actor_id") is String or not bulletin.get("employer_id") is String: return false
		var rival = actor(data, bulletin.actor_id)
		var employer = actor(data, bulletin.employer_id)
		if rival.is_empty() or employer.is_empty() or rival.kind != "Compañía rival" or employer.kind != "Contratante": return false
		if not bulletin.get("source") is String or not bulletin.get("text") is String: return false
	return true
