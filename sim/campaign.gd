extends RefCounted
## Pure command-driven simulation. No scene tree or UI dependencies.
const VERSION = 25
const Story = preload("res://sim/story/memory.gd")
const CareerStart = preload("res://sim/career_start.gd")
const RPG = preload("res://sim/rpg/captain.gd")
const Travel = preload("res://sim/travel.gd")
const Missions = preload("res://sim/missions.gd")
const Universe = preload("res://sim/universe.gd")
const Lore = preload("res://sim/lore.gd")
const Battle = preload("res://sim/battle/engine.gd")
const Operations = preload("res://sim/operations.gd")
const World = preload("res://sim/world.gd")
const MAX_HANGAR = 8
const MAX_DEPLOYED = 4
# Deliberately compressed prototype prices, not canonical BattleTech valuations.
const Catalog = preload("res://sim/catalog.gd")
var MECH_CATALOG = Catalog.all()

const DEFAULT_COMPANY = "Compañía independiente"
const DEFAULT_CAPTAIN = "Comandante"
var state: Dictionary
var rng = RandomNumberGenerator.new()

func _init(campaign_seed: int = 3027, scenario_year: int = 3027, initial: Dictionary = {}):
	rng.seed = campaign_seed
	state = {"version": VERSION, "scenario_year": 3060 if scenario_year == 3060 else 3027, "company_name": DEFAULT_COMPANY, "captain_name": DEFAULT_CAPTAIN, "day": 0, "funds": 240000, "supplies": 90,
		"reputation": 0, "morale": 70, "arrears": 0, "ended": false,
		"mechs": [], "staff": [], "offers": [], "active": {}, "chronicle": []}
	var models = ["Locust LCT-1V", "Shadow Hawk SHD-2H", "Centurion CN9-A", "Vindicator VND-1R"]
	var names = ["Elena Voss", "Tomás Ríos", "Mara Chen", "Idris Vale"]
	for i in range(4):
		state.mechs.append({"name": models[i], "hp": 100, "repair": false})
		state.staff.append({"name": names[i], "role": "Piloto", "skill": 3 + i % 2, "injury": 0, "salary": 6000})
	state.staff.append({"name": "Ada Ferrer", "role": "Jefa técnica", "skill": 4, "injury": 0, "salary": 8000})
	state.staff.append({"name": "Jules Aran", "role": "Logística", "skill": 3, "injury": 0, "salary": 5000})
	state["career_start"] = initial.duplicate(true)
	if not initial.is_empty():
		assert(CareerStart.valid(initial, state.scenario_year))
		state.mechs.clear()
		for id in initial.units: state.mechs.append({"name": CareerStart.model(id).name, "hp": 100, "repair": false})
		state.staff = initial.people.duplicate(true)
	_init_personnel(state)
	_init_logistics(state)
	_init_contracts(state)
	_init_management(state)
	_init_hangar(state)
	_init_market(state, campaign_seed)
	_init_ownership(state)
	_init_careers(state)
	_init_relations(state)
	_init_stories(state)
	_init_world(state)
	_init_frontier(state)
	_init_lore(state)
	state["missions"] = Missions.create(campaign_seed)
	state["travel"] = {}
	state["lore_activity"] = Lore.activity(state.scenario_year)
	state["military"] = Operations.create(campaign_seed)
	state["rpg"] = RPG.create(campaign_seed)
	state["story"] = Story.create(0)
	Story.People.ensure(self)
	Story.Culture.ensure(self)
	log_event("Fundación", "La compañía recibe cuatro unidades en Galatea. El personal operativo queda asignado a su fuerza inicial.")
	_refresh_offers()
	Missions.generate(state)

func set_identity(company: String, captain: String) -> bool:
	company = company.strip_edges()
	captain = captain.strip_edges()
	if not _valid_name(company) or not _valid_name(captain): return false
	if state.company_name == company and state.captain_name == captain: return true
	state.company_name = company
	state.captain_name = captain
	log_event("Identidad", "%s queda al mando del capitán %s." % [company, captain])
	return true

func _valid_name(value: Variant) -> bool:
	if not value is String or value.strip_edges().is_empty() or value.length() > 48: return false
	for i in range(value.length()):
		if value.unicode_at(i) < 32 or value.unicode_at(i) == 127: return false
	return true

func date_text() -> String:
	return Time.get_date_string_from_unix_time(int(Time.get_unix_time_from_datetime_string("%d-05-17T00:00:00" % state.scenario_year)) + int(state.day) * 86400)

func log_event(kind: String, message: String, people: Array = [], units: Array = [], thread: String = "", parents: Array = []) -> int:
	var id = Story.capture(self,kind,message,people,units,thread,parents) if state.has("story") else 0
	state.chronicle.append({"day": state.day, "date": date_text(), "kind": kind, "text": message, "story_id": id})
	return id

func _refresh_offers():
	state.offers = []
	for i in range(3):
		var difficulty = 5 + i * 2 + mini(3, maxi(0, int(state.reputation / 3)))
		state.offers.append({"id": int(state.day) * 10 + i, "name": ["Escolta de convoy", "Patrulla fronteriza", "Incursión a depósito"][i],
			"employer": ["Liga comercial", "Milicia local", "Enlace de la Casa Davion"][i],
			"difficulty": difficulty, "days": 3 + i * 2, "pay": 45000 + i * 35000 + maxi(0, int(state.reputation)) * 2000,
			"expires": int(state.day) + 14, "intel": ["Contactos ligeros posibles", "Informes fragmentarios de fuerzas móviles", "Defensas preparadas probables"][i]})
	if int(state.day / 14) % 2 == 1:
		state.offers[2].employer = "Consorcio de talleres"
		state.offers[2].name = "Protección de instalaciones"
	if state.has("location_id") and state.location_id != Universe.galatea():
		if not local_services(): state.offers = []
		else:
			var pool = Missions.employers(state.scenario_year,Universe.system(state.location_id).affiliations[str(state.scenario_year)])
			for i in range(state.offers.size()): state.offers[i].employer = pool[i%pool.size()].name
	for offer in state.offers:
		offer["employer_id"] = World.id_for_name(offer.employer)
		_enrich_contract(offer)
		var relation = int(state.relationships.get(offer.employer, 0))
		offer.pay = maxi(10000, int(offer.pay) + relation * 3000)
		offer.advance = int(offer.pay * clampf(0.25 + relation * 0.02, 0.1, 0.4))
		offer.failure_pay = int(offer.pay * 0.15)
	log_event("Mercado", "Llegaron tres ofertas. Su remuneración refleja nuestra reputación; la inteligencia es estimativa.")

func deployed(index: int) -> bool:
	return not state.active.is_empty() and index in state.active.team

func dispatch(_offer_index: int, team: Array, doctrine: int, leader: int = -1) -> String:
	if RPG.waiting(self) or RPG.busy(self): return "Resuelva la escena o preparación del capitán antes de desplegar."
	if in_transit(): return "Acción local no disponible durante el traslado."
	if state.ended: return "La compañía ha cerrado operaciones."
	if not state.active.is_empty(): return "Ya hay una operación en curso."
	if state.ownership_debt > 0: return "Debe saldar el mantenimiento vencido antes de desplegar."
	if state.accepted.is_empty(): return "Acepte un contrato antes de desplegar."
	if team.size() > MAX_DEPLOYED: return "Máximo cuatro máquinas por operación."
	if doctrine < 0 or doctrine > 2 or team.is_empty(): return "Seleccione unidades y doctrina."
	var unique = []
	for i in team:
		if not (i is int) or i < 0 or i >= state.mechs.size() or i in unique: return "Asignación inválida."
		unique.append(i)
		if not mech_ready(i) or state.mechs[i].hp < 40 or state.mechs[i].repair or pilot_for(i).is_empty() or not person_available(pilot_for(i)): return "Una unidad no está disponible."
	for i in team:
		if _person_has_story(pilot_for(i).id): return "Resuelva el asunto personal pendiente antes de desplegar a ese piloto."
	if leader == -1: leader = int(state.mechs[team[0]].pilot_id)
	var leader_present = false
	for i in team:
		if state.mechs[i].pilot_id == leader: leader_present = true
	for issue in state.issues:
		if issue.kind == "salary":
			for i in team:
				if state.mechs[i].pilot_id == issue.person: return "Resuelva el reclamo salarial del piloto antes de desplegarlo."
	if not leader_present: return "El jefe debe ser un piloto del despliegue."
	var contract = state.accepted.duplicate(true)
	if state.day > contract.deadline: return "El plazo de despliegue venció."
	if team.size() < contract.min_force: return "El contrato exige al menos %d máquinas." % contract.min_force
	var cost = team.size() * (8 + doctrine * 2) + (4 if state.military.plan.approach == "recon" else 0)
	if state.supplies < cost: return "Suministros insuficientes."
	state.supplies -= cost
	state.issues = state.issues.filter(func(issue): return issue.kind != "deadline")
	state.active = {"contract": contract, "team": team.duplicate(), "doctrine": doctrine, "leader": leader, "remaining": contract.days + (1 if doctrine == 0 else 0)}
	RPG.Negotiation.begin(self)
	state.active["started"] = int(state.day)
	var story_people = []
	var story_units = []
	for i in team:
		story_people.append(int(state.mechs[i].pilot_id))
		story_units.append(int(state.mechs[i].uid))
	log_event("Orden de despliegue",state.active.contract.name,story_people,story_units,Story.operation_key(self))
	state.active["rpg_danger"] = int(state.rpg.arcs.settings.danger)
	state.active["rpg_support"] = state.rpg.workshop.support_until > state.day
	if contract.has("mission_type"):
		var profiles = []
		for index in team:
			var profile = _normalize_numbers(unit_profile(index).duplicate())
			profile["condition"] = clampi(int(state.mechs[index].hp * pilot_for(index).skill / 4.0 * (1.0-pilot_for(index).fatigue/200.0)),0,100)
			profiles.append(profile)
		state.active["objective"] = Missions.begin(contract,profiles,state.missions.tactic)
	state.active["equipment_power"] = equipment_power(team)
	_start_operation()
	log_event("Orden", "%s: %d unidades; doctrina %s. Consumo: %d suministros." % [contract.name, team.size(), ["cautelosa", "equilibrada", "agresiva"][doctrine], cost])
	return "Despliegue autorizado. Avance el calendario para recibir informes."

func buy_supplies() -> String:
	return order_supplies(true)

func repair(index: int) -> String:
	if in_transit(): return "El taller está cerrado durante el traslado."
	if state.ended or index < 0 or index >= state.mechs.size(): return "Orden no disponible."
	if deployed(index): return "Unidad desplegada."
	if not mech_ready(index): return "Reactive la máquina y espere su puesta en servicio antes de reparar."
	if state.mechs[index].hp >= 100: return "No requiere reparación."
	state.mechs[index].repair = not state.mechs[index].repair
	if state.mechs[index].repair:
		if not index in state.repair_queue: state.repair_queue.append(index)
	else:
		state.repair_queue.erase(index)
	log_event("Taller", "%s: reparación %s." % [state.mechs[index].name, "autorizada" if state.mechs[index].repair else "suspendida"],[],[state.mechs[index].uid],"unit:%d"%state.mechs[index].uid)
	return "Orden de taller actualizada. Cuesta 2 suministros y 1.000 C-bills por unidad/día."

func advance(days: int = 1):
	for _day in range(clampi(days, 0, 30)):
		if state.ended or not state.issues.is_empty() or military_waiting() or RPG.waiting(self): break
		state.day = int(state.day) + 1
		for person in state.staff:
			person.injury = maxi(0, int(person.injury) - 1)
		_recover_people()
		_travel_tick()
		RPG.tick(self)
		Story.People.tick(self)
		Story.Culture.tick(self)
		Story.Objectives.tick(self)
		Story.Society.tick(self)
		_receive_mechs()
		_accrue_ownership()
		_receive_orders()
		_workshop_tick()
		if not state.active.is_empty():
			var progress = _operation_tick()
			if progress and not state.active.is_empty() and RPG.operation_tick(self): progress = false
			if progress and not state.active.is_empty():
				if state.active.has("objective") and not state.military.current.has("battle"):
					Missions.tick(state.active.objective,state.active.contract,int(state.missions.seed),state.military.current.orders.priority == "preserve")
					_operation_report(Missions.report(state.active.objective))
				state.active.remaining -= 1
				if state.active.remaining == 1:
					log_event("Radio", "%s: entramos en la fase final. Sin confirmación del dispositivo enemigo." % person_by_id(state.active.leader).get("name", "Mando de campo"))
				if state.active.remaining <= 0: _resolve()
		if not state.accepted.is_empty() and state.active.is_empty() and state.day > state.accepted.deadline:
			cancel_contract("Plazo de despliegue incumplido")
		if state.day % 30 == 0:
			_payroll()
			_bill_ownership()
			_refresh_candidates()
		if state.day % 14 == 0:
			_refresh_offers()
			Missions.generate(state)
			_refresh_mech_market(state)
			log_event("Mercado de máquinas", "Nuevos lotes disponibles; las compras en tránsito conservan sus condiciones.")
		for bulletin in World.tick(state.world, int(state.day)):
			log_event("Mundo", "%s Fuente: %s." % [bulletin.text, bulletin.source])
		_frontier_tick()
		var local = Missions.region(state.missions,state.location_id)
		for bulletin in Lore.tick(state.lore_activity,state.scenario_year,int(state.day),int(state.missions.seed),Universe.system(state.location_id).affiliations[str(state.scenario_year)],local):
			log_event("Boletín regional", "%s: %s" % [bulletin.name,bulletin.text])
		_check_issues()

func _resolve():
	var op = state.active
	var battle = state.military.current.get("battle", {})
	if not battle.is_empty():
		Battle.run(battle)
		_battle_report()
	var power = 0.0
	for i in op.team:
		power += pilot_for(i).skill * state.mechs[i].hp / 100.0 * (1.0 - pilot_for(i).fatigue / 200.0)
	power += int(op.get("equipment_power",0))
	power += team_cohesion(op.team)
	if not state.military.current.is_empty(): power += int(state.military.current.private.bonus)
	var roll = rng.randi_range(1, 6) + rng.randi_range(1, 6)
	var success = power + roll + op.doctrine + (state.morale - 50) / 20.0 >= op.contract.difficulty + 10
	var result = "success" if success else "failure"
	if not battle.is_empty():
		result = battle.result
		success = result == "success"
	if op.has("objective"):
		if not battle.is_empty():
			op.objective.progress = battle.progress
			op.objective.integrity = battle.asset_hp
			op.objective.elapsed = maxi(1,int(battle.tick))
		result = battle.result if not battle.is_empty() else Missions.outcome(op.objective)
		success = result == "success"
		Missions.finish(state,op.contract,op.objective,result)
	var total_pay = int(op.contract.get("partial_pay",int(op.contract.pay*0.6)) if result == "partial" else op.contract.pay if success else op.contract.failure_pay)
	var payment = total_pay - int(op.contract.advance)
	_settle_contract(payment)
	_close_opportunity(op.contract, success)
	_change_relation(op.contract.employer, 0 if result == "partial" else 1 if success else -1)
	state.reputation += 0 if result == "partial" else 1 if success else -1
	state.morale = clampi(int(state.morale) + (4 if success else -2 if result == "partial" else -8), 0, 100)
	for i in op.team:
		var damage = rng.randi_range(6, 20) + op.doctrine * 5 + (0 if success else 10)
		if op.has("objective") and op.objective.tactic == "push": damage += 4
		if not state.military.current.is_empty(): damage = maxi(0, damage + int(state.military.current.private.damage))
		damage = int(damage * int(op.get("rpg_danger",100)) / 100.0)
		if op.get("rpg_support",false): damage = maxi(0,damage-2)
		if not battle.is_empty():
			for u in battle.units:
				if u.side == "own" and u.id == state.mechs[i].uid: damage = maxi(0,int(state.mechs[i].hp)-int(u.hp))
		state.mechs[i].hp = maxi(0, int(state.mechs[i].hp) - damage)
		if state.mechs[i].hp < 40:
			pilot_for(i).injury = rng.randi_range(5, 15)
			log_event("Bajas", "%s evacúa su máquina; recuperación estimada: %d días. Unidad recuperada por remolque." % [pilot_for(i).name, pilot_for(i).injury])
	log_event("Resultado", "%s: %s. Liquidación final: %+d C-bills (anticipo descontado). %s" % [op.contract.name, "cumplimiento parcial" if result == "partial" else "objetivo cumplido" if success else "retirada sin cumplir objetivo", payment, "El empleador recomienda a la compañía." if success else "El empleador cuestiona nuestra capacidad; cayó la moral."])
	if not battle.is_empty(): _battle_memories(battle)
	_award_operation(op, success)
	_operation_story(op)
	Story.operation(self,result)
	Story.Culture.operation(self,result)
	Story.Objectives.operation(self,result)
	Story.Society.operation(self,result)
	RPG.finish_operation(self,result)
	_finish_operation("Cumplimiento parcial" if result == "partial" else "Objetivo cumplido" if success else "Objetivo no cumplido")
	state.active = {}
	state.accepted = {}

func _payroll():
	var due = int(state.arrears)
	for person in state.staff: due += int(person.salary)
	var paid = mini(available_funds(), due)
	state.funds -= paid
	_record_transaction("Salarios", -paid, "Nómina mensual y deuda")
	state.arrears = due - paid
	if state.arrears > 0:
		state.missed_payrolls += 1
		state.morale = maxi(0, int(state.morale) - 20)
		log_event("Personal", "Salarios impagos: %d C-bills. El personal pierde confianza." % state.arrears)
	else:
		state.missed_payrolls = 0
		log_event("Finanzas", "Nómina pagada: %d C-bills." % paid)
	if state.morale == 0:
		state.ended = true
		log_event("Cierre", "El personal abandona la compañía. Fin de campaña; la crónica se conserva.")

func save_game(path: String = "user://campaign.json") -> Error:
	var payload = state.duplicate(true)
	payload["rng_state"] = str(rng.state)
	var file = FileAccess.open(path + ".tmp", FileAccess.WRITE)
	if file == null: return FileAccess.get_open_error()
	file.store_string(JSON.stringify(payload, "\t"))
	file.close()
	return DirAccess.rename_absolute(path + ".tmp", path)

func load_game(path: String = "user://campaign.json") -> Error:
	if not FileAccess.file_exists(path): return ERR_FILE_NOT_FOUND
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
	# Upgrade the original prototype saves without touching the file on disk.
	if parsed is Dictionary and parsed.get("version") == 1:
		parsed["version"] = 2
		parsed["company_name"] = DEFAULT_COMPANY
		parsed["captain_name"] = DEFAULT_CAPTAIN
	if parsed is Dictionary and parsed.get("version") == 2:
		if not parsed.get("staff") is Array or not parsed.get("mechs") is Array: return ERR_INVALID_DATA
		if parsed.staff.size() != 6 or parsed.mechs.size() != 4: return ERR_INVALID_DATA
		for item in parsed.staff + parsed.mechs:
			if not item is Dictionary: return ERR_INVALID_DATA
		_init_personnel(parsed)
		if parsed.get("active") is Dictionary and not parsed.active.is_empty():
			if not parsed.active.get("team") is Array or parsed.active.team.is_empty(): return ERR_INVALID_DATA
			var first = parsed.active.team[0]
			if not _number_between(first, 0, 3): return ERR_INVALID_DATA
			parsed.active["leader"] = int(first)
		parsed.version = 3
	if parsed is Dictionary and parsed.get("version") == 3:
		if not parsed.get("mechs") is Array: return ERR_INVALID_DATA
		for item in parsed.mechs:
			if not item is Dictionary: return ERR_INVALID_DATA
		_init_logistics(parsed)
		parsed.version = 4
	if parsed is Dictionary and parsed.get("version") == 4:
		if not parsed.get("offers") is Array or not parsed.get("active") is Dictionary: return ERR_INVALID_DATA
		for offer in parsed.offers:
			if not _valid_contract(offer): return ERR_INVALID_DATA
		if not parsed.active.is_empty() and not _valid_contract(parsed.active.get("contract")): return ERR_INVALID_DATA
		_init_contracts(parsed)
		parsed.version = 5
	if parsed is Dictionary and parsed.get("version") == 5:
		if not _number_between(parsed.get("funds"), 0, 1000000000): return ERR_INVALID_DATA
		_init_management(parsed)
		parsed.version = 6
	if parsed is Dictionary and parsed.get("version") == 6:
		if not parsed.get("mechs") is Array: return ERR_INVALID_DATA
		for mech in parsed.mechs:
			if not mech is Dictionary: return ERR_INVALID_DATA
		_init_hangar(parsed)
		parsed.version = 7
	if parsed is Dictionary and parsed.get("version") == 7:
		if not parsed.get("mechs") is Array or not _number_between(parsed.get("day"), 0, 1000000000): return ERR_INVALID_DATA
		for mech in parsed.mechs:
			if not mech is Dictionary or not mech.get("name") is String: return ERR_INVALID_DATA
		_init_market(parsed)
		parsed.version = 8
	if parsed is Dictionary and parsed.get("version") == 8:
		if not parsed.get("mechs") is Array or not parsed.get("mech_orders") is Array or not _number_between(parsed.get("day"), 0, 1e9): return ERR_INVALID_DATA
		for mech in parsed.mechs:
			if not mech is Dictionary: return ERR_INVALID_DATA
		for order in parsed.mech_orders:
			if not order is Dictionary or not order.get("mech") is Dictionary: return ERR_INVALID_DATA
		_init_ownership(parsed)
		parsed.version = 9
	if parsed is Dictionary and parsed.get("version") == 9:
		if not parsed.get("staff") is Array: return ERR_INVALID_DATA
		for person in parsed.staff:
			if not person is Dictionary: return ERR_INVALID_DATA
		_init_careers(parsed)
		parsed.version = 10
	if parsed is Dictionary and parsed.get("version") == 10:
		if not parsed.get("staff") is Array or not parsed.get("alumni") is Array: return ERR_INVALID_DATA
		for person in parsed.staff + parsed.alumni:
			if not person is Dictionary: return ERR_INVALID_DATA
		_init_relations(parsed)
		parsed.version = 11
	if parsed is Dictionary and parsed.get("version") == 11:
		if not parsed.get("staff") is Array or not parsed.get("alumni") is Array: return ERR_INVALID_DATA
		for person in parsed.staff + parsed.alumni:
			if not person is Dictionary: return ERR_INVALID_DATA
		_init_stories(parsed)
		parsed.version = 12
	if parsed is Dictionary and parsed.get("version") == 12:
		if not _number_between(parsed.get("day"), 0, 1e9) or not parsed.get("offers") is Array or not parsed.get("accepted") is Dictionary or not parsed.get("active") is Dictionary: return ERR_INVALID_DATA
		for offer in parsed.offers:
			if not _valid_contract(offer): return ERR_INVALID_DATA
		if not parsed.accepted.is_empty() and not _valid_contract(parsed.accepted): return ERR_INVALID_DATA
		if not parsed.active.is_empty() and not _valid_contract(parsed.active.get("contract")): return ERR_INVALID_DATA
		_init_world(parsed)
		parsed.version = 13
	if parsed is Dictionary and parsed.get("version") == 13:
		if not _number_between(parsed.get("day"), 0, 1e9) or not World.valid_base(parsed.get("world"), int(parsed.day)): return ERR_INVALID_DATA
		World.enable(parsed.world, int(parsed.day))
		parsed.version = 14
	if parsed is Dictionary and parsed.get("version") == 14:
		if not _number_between(parsed.get("day"), 0, 1e9) or not World.valid(parsed.get("world"), int(parsed.day)): return ERR_INVALID_DATA
		_init_frontier(parsed)
		parsed.version = 16
	if parsed is Dictionary and parsed.get("version") == 16:
		parsed["military"] = Operations.create(3027)
		parsed.version = 17
	if parsed is Dictionary and parsed.get("version") == 17:
		parsed["scenario_year"] = 3027
		if not _catalog_ids(parsed, true): return ERR_INVALID_DATA
		parsed.version = 18
	if parsed is Dictionary and parsed.get("version") == 18:
		_init_lore(parsed)
		parsed.version = 19
	if parsed is Dictionary and parsed.get("version") == 19:
		parsed.version = 20
	if parsed is Dictionary and parsed.get("version") == 20:
		parsed["missions"] = Missions.create(int(parsed.get("market_seed",3027)))
		parsed.version = 21
	if parsed is Dictionary and parsed.get("version") == 21:
		parsed["travel"] = {}
		parsed["lore_activity"] = Lore.activity(int(parsed.get("scenario_year",3027)))
		parsed.version = 22
	if parsed is Dictionary and parsed.get("version") == 22:
		parsed["rpg"] = RPG.create(int(parsed.get("market_seed",3027)))
		parsed.version = 23
	if parsed is Dictionary and parsed.get("version") == 23:
		parsed["career_start"] = {}
		parsed.version = 24
	if parsed is Dictionary and parsed.get("version") == 24:
		parsed["story"] = Story.create(int(parsed.get("day",0)))
		parsed.version = 25
	if parsed is Dictionary and parsed.get("rpg") is Dictionary: RPG.upgrade(parsed.rpg)
	if parsed is Dictionary and parsed.get("story") is Dictionary: Story.upgrade(parsed.story)
	if not _catalog_ids(parsed, false): return ERR_INVALID_DATA
	if not _valid_save(parsed): return ERR_INVALID_DATA
	state = _normalize_numbers(parsed)
	rng.state = int(state.rng_state)
	state.erase("rng_state")
	Story.People.ensure(self)
	Story.Culture.ensure(self)
	return OK

func _valid_save(value: Variant) -> bool:
	if not value is Dictionary: return false
	if not _valid_name(value.get("company_name")) or not _valid_name(value.get("captain_name")): return false
	for key in state.keys():
		if not value.has(key): return false
	if not (value.get("scenario_year") == 3027 or value.get("scenario_year") == 3060): return false
	if not CareerStart.valid(value.get("career_start"), int(value.scenario_year)): return false
	if value.version != VERSION or not value.get("rng_state", null) is String: return false
	for key in ["day", "funds", "supplies", "arrears", "morale", "reputation"]:
		if not (value[key] is float or value[key] is int): return false
	if value.day < 0 or value.funds < 0 or value.supplies < 0 or value.morale < 0 or value.morale > 100: return false
	if not value.ended is bool: return false
	if not value.mechs is Array or value.mechs.size() > MAX_HANGAR: return false
	if not value.staff is Array or value.staff.size() > 30: return false
	for mech in value.mechs:
		if not mech is Dictionary or not mech.get("name") is String or not mech.get("repair") is bool: return false
		if not _number_between(mech.get("hp"), 0, 100): return false
	for person in value.staff:
		if not person is Dictionary or not person.get("name") is String or not person.get("role") is String: return false
		for key in ["skill", "injury", "salary"]:
			if not _number_between(person.get(key), 0, 100000): return false
	if not value.offers is Array or not value.active is Dictionary or not value.chronicle is Array: return false
	for offer in value.offers:
		if not _valid_contract(offer): return false
	for event in value.chronicle:
		if not event is Dictionary: return false
		for key in ["date", "kind", "text"]:
			if not event.get(key) is String: return false
	if not value.active.is_empty():
		var op = value.active
		if not _valid_contract(op.get("contract")) or not op.get("team") is Array: return false
		if op.team.is_empty() or op.team.size() > MAX_DEPLOYED or not _number_between(op.get("doctrine"), 0, 2) or not _number_between(op.get("remaining"), 1, 30): return false
		var seen = []
		for i in op.team:
			if not _number_between(i, 0, value.mechs.size() - 1) or int(i) != i or i in seen: return false
			seen.append(i)
	return Story.valid(value.get("story"),int(value.day)) and _valid_personnel(value) and _valid_logistics(value) and _valid_contract_state(value) and _valid_management(value) and _valid_hangar(value) and _valid_market(value) and _valid_ownership(value) and _valid_careers(value) and _valid_relations(value) and _valid_stories(value) and _valid_world(value) and _valid_frontier(value) and _valid_lore(value) and _valid_missions(value) and _valid_travel(value) and RPG.valid(value.get("rpg"),int(value.day)) and RPG.valid_links(value) and Story.valid_links(value) and Operations.valid(value.get("military"), int(value.day), value.active)

func _number_between(value: Variant, low: float, high: float) -> bool:
	return (value is int or value is float) and is_finite(float(value)) and value >= low and value <= high

func _valid_contract(value: Variant) -> bool:
	if not value is Dictionary: return false
	for key in ["name", "employer", "intel"]:
		if not value.get(key) is String: return false
	for key in ["id", "difficulty", "days", "pay", "expires"]:
		if not _number_between(value.get(key), 0, 1000000000): return false
	return true

# All numeric campaign fields in schema v1 are integers; JSON reads them as floats.
func _normalize_numbers(value: Variant) -> Variant:
	if value is float: return int(value)
	if value is Array:
		var result = []
		for entry in value: result.append(_normalize_numbers(entry))
		return result
	if value is Dictionary:
		var result = {}
		for key in value: result[key] = _normalize_numbers(value[key])
		return result
	return value

# v0.2.1: stable personnel IDs keep chronicles and assignments valid after dismissal.
func _init_personnel(data: Dictionary):
	for i in range(data.staff.size()): data.staff[i]["id"] = i
	for i in range(data.mechs.size()): data.mechs[i]["pilot_id"] = i
	data["next_staff_id"] = data.staff.size()
	data["candidates"] = [
		{"name": "Lucía Serrano", "role": "Piloto", "skill": 4, "salary": 7000, "fee": 12000},
		{"name": "Pavel Ortiz", "role": "Técnico", "skill": 3, "salary": 6000, "fee": 9000},
		{"name": "Nadia Okafor", "role": "Logística", "skill": 4, "salary": 6000, "fee": 10000},
		{"name": "Dotación Vega", "role": "Dotación", "skill": 3, "salary": 9000, "fee": 16000}]

func person_by_id(id: int) -> Dictionary:
	for person in state.staff:
		if person.id == id: return person
	return {}

func pilot_for(mech: int) -> Dictionary:
	return person_by_id(int(state.mechs[mech].pilot_id))

func personnel_deployed(id: int) -> bool:
	for i in range(state.mechs.size()):
		if state.mechs[i].pilot_id == id and deployed(i): return true
	return false

func monthly_payroll() -> int:
	var total = 0
	for person in state.staff: total += int(person.salary)
	return total

func hire(candidate_index: int) -> String:
	if not local_services(): return "No hay servicios comerciales documentados en este sistema."
	if in_transit(): return "Acción local no disponible durante el traslado."
	if state.ended or candidate_index < 0 or candidate_index >= state.candidates.size(): return "Candidato no disponible."
	if state.staff.size() >= 30: return "Límite de plantilla: 30 personas."
	var candidate = state.candidates[candidate_index].duplicate(true)
	if available_funds() < candidate.fee: return "Fondos insuficientes para incorporar."
	state.funds -= candidate.fee
	_record_transaction("Incorporación", -int(candidate.fee), candidate.name)
	candidate["id"] = state.next_staff_id
	candidate["injury"] = 0
	state.next_staff_id += 1
	_init_person_career(candidate)
	_init_person_condition(candidate)
	candidate["last_care_event"] = -100
	state.staff.append(candidate)
	Story.People.ensure(self)
	Story.Culture.ensure(self)
	state.candidates.remove_at(candidate_index)
	log_event("Personal", "%s se incorpora como %s; salario mensual %d." % [candidate.name, candidate.role, candidate.salary])
	return "Incorporación completada."

func dismiss(id: int) -> String:
	var person = person_by_id(id)
	if state.ended or person.is_empty(): return "Empleado no disponible."
	if personnel_deployed(id): return "No puede despedir personal desplegado."
	if state.arrears > 0: return "Regularice la deuda salarial antes de despedir."
	if available_funds() < person.salary: return "La indemnización equivale a un salario mensual."
	state.funds -= person.salary
	_record_transaction("Indemnización", -int(person.salary), person.name)
	for mech in state.mechs:
		if mech.pilot_id == id: mech.pilot_id = -1
	_archive_person(person, "Baja con indemnización")
	state.staff.erase(person)
	log_event("Personal", "%s deja la compañía con indemnización de %d." % [person.name, person.salary])
	return "Baja tramitada."

func assign_pilot(mech: int, id: int) -> String:
	if state.ended or mech < 0 or mech >= state.mechs.size() or deployed(mech): return "Asignación no disponible."
	if state.mechs[mech].stored and id != -1: return "Reactive la máquina antes de asignar piloto."
	if id == -1:
		state.mechs[mech].pilot_id = -1
		return "Máquina sin piloto."
	var person = person_by_id(id)
	if person.is_empty() or person.role != required_role(state.mechs[mech]) or not person_available(person): return "Se requiere personal apto: " + required_role(state.mechs[mech])
	if personnel_deployed(id): return "Piloto desplegado."
	for i in range(state.mechs.size()):
		if i != mech and state.mechs[i].pilot_id == id: return "Desasigne al piloto de su máquina actual primero."
	state.mechs[mech].pilot_id = id
	log_event("Asignación", "%s recibe %s." % [person.name, state.mechs[mech].name],[id],[state.mechs[mech].uid],"unit:%d"%state.mechs[mech].uid)
	return "Asignación actualizada."

func _valid_personnel(data: Dictionary) -> bool:
	if not data.get("candidates") is Array or not _number_between(data.get("next_staff_id"), 0, 1000000): return false
	var ids = []
	for p in data.staff:
		if not _number_between(p.get("id"), 0, data.next_staff_id - 1) or p.id in ids: return false
		ids.append(p.id)
	var assigned = []
	for m in data.mechs:
		if m.get("pilot_id") == -1: continue
		if not m.get("pilot_id") in ids or m.pilot_id in assigned: return false
		for p in data.staff:
			if p.id == m.pilot_id and p.role != required_role(m): return false
		assigned.append(m.pilot_id)
	for p in data.candidates:
		if not p is Dictionary or not p.get("name") is String or not p.get("role") is String: return false
		for k in ["skill", "salary", "fee"]:
			if not _number_between(p.get(k), 0, 100000): return false
	if not data.active.is_empty():
		var deployed_ids = []
		for i in data.active.team:
			if data.mechs[int(i)].pilot_id == -1: return false
			deployed_ids.append(data.mechs[int(i)].pilot_id)
		if not data.active.get("leader") in deployed_ids: return false
	return true

# v0.2.2: resource commitments are reserved until delivery.
func _init_logistics(data: Dictionary):
	data["orders"] = []
	data["repair_queue"] = []
	data["next_order_id"] = 0
	for i in range(data.mechs.size()):
		if data.mechs[i].get("repair", false): data.repair_queue.append(i)

func _refresh_candidates():
	var cohort = int(state.day / 30)
	state.candidates = []
	for i in range(3):
		var skill = 2 + (cohort + i) % 4
		state.candidates.append({"name": ["Alex Duarte", "Samira Alves", "Ren Park"][(cohort + i) % 3] + " · " + str(cohort),
			"role": ["Piloto", "Técnico", "Logística"][i], "skill": skill, "salary": 3000 + skill * 1000, "fee": 5000 + skill * 2000})
	state.candidates.append({"name": "Dotación terrestre · %d" % cohort, "role": "Dotación", "skill": 3, "salary": 9000, "fee": 16000})
	log_event("Personal", "La bolsa de contratación publica nuevos candidatos.")

func committed_payments() -> int:
	var total = 0
	for order in state.orders: total += int(order.balance)
	return total

func available_funds() -> int:
	return maxi(0, int(state.funds) - committed_payments())

func supply_quote(urgent: bool) -> Dictionary:
	var skill = 0
	for p in state.staff:
		if p.role == "Logística" and person_available(p): skill += int(p.skill)
	var regional_supply = int(state.get("missions",{}).get("regions",{}).get(state.get("location_id",""),{}).get("supply",0))
	var discount = clampi(mini(15, skill * 2)+regional_supply*2,-10,25)
	return {"cost": int((15000 if urgent else 10000) * (100 - discount) / 100),
		"days": 1 if urgent else maxi(2, 4 - int(skill / 5)), "quantity": 30, "discount": discount}

func order_supplies(urgent: bool) -> String:
	if not local_services(): return "No hay servicios comerciales documentados en este sistema."
	if in_transit(): return "Acción local no disponible durante el traslado."
	if state.ended: return "La compañía ha cerrado operaciones."
	var quote = supply_quote(urgent)
	if available_funds() < quote.cost: return "Fondos libres insuficientes para el pedido completo."
	var deposit = int(quote.cost / 2)
	state.funds -= deposit
	_record_transaction("Abastecimiento", -deposit, "Anticipo de pedido")
	state.orders.append({"id": state.next_order_id, "quantity": quote.quantity, "due": int(state.day) + quote.days,
		"balance": quote.cost - deposit, "cost": quote.cost, "urgent": urgent})
	state.next_order_id += 1
	log_event("Abastecimiento", "Pedido de 30 suministros: %d C-bills; entrega en %d días. Anticipo %d; resto reservado." % [quote.cost, quote.days, deposit])
	return "Pedido confirmado; el saldo queda reservado hasta la entrega."

func _receive_orders():
	for order in state.orders.duplicate():
		if state.day >= order.due:
			state.funds -= order.balance
			_record_transaction("Abastecimiento", -int(order.balance), "Saldo de entrega")
			state.supplies += order.quantity
			state.orders.erase(order)
			for person in state.staff:
				if person.role == "Logística" and person_available(person):
					_gain_experience(person, 1, "Entrega de suministros completada")
					person.fatigue = mini(100, int(person.fatigue) + 5)
			log_event("Entrega", "Recibidos %d suministros; saldo pagado %d." % [order.quantity, order.balance])

func workshop_capacity() -> int:
	var skill = 0
	for p in state.staff:
		if p.role in ["Técnico", "Jefa técnica"] and person_available(p): skill += int(p.skill)
	return mini(4, int(skill / 3))

func prioritize_repair(index: int) -> String:
	if state.ended or not index in state.repair_queue: return "La unidad no está en la cola."
	state.repair_queue.erase(index)
	state.repair_queue.push_front(index)
	log_event("Taller", "%s recibe prioridad de taller." % state.mechs[index].name)
	return "Prioridad actualizada."

func _workshop_tick():
	var capacity = workshop_capacity()
	var worked = false
	for i in state.repair_queue.duplicate():
		var mech = state.mechs[i]
		if not mech.repair or mech.hp >= 100:
			state.repair_queue.erase(i)
			continue
		if capacity <= 0: break
		if deployed(i) or state.supplies < 2 or available_funds() < 1000: continue
		capacity -= 1
		worked = true
		state.supplies -= 2
		state.funds -= 1000
		_record_transaction("Taller", -1000, mech.name)
		mech.hp = mini(100, int(mech.hp) + 10)
		if mech.hp == 100:
			mech.repair = false
			state.repair_queue.erase(i)
			log_event("Taller", "%s vuelve a servicio." % mech.name,[],[mech.uid],"unit:%d"%mech.uid)
			for person in state.staff:
				if person.role in ["Técnico", "Jefa técnica"] and person_available(person): _gain_experience(person, 1, "Recuperación de " + mech.name)

	if worked:
		for person in state.staff:
			if person.role in ["Técnico", "Jefa técnica"] and person_available(person): person.fatigue = mini(100, int(person.fatigue) + 10)

func repair_estimates() -> Array:
	var result = []
	var lanes = []
	for i in range(workshop_capacity()): lanes.append(0)
	for index in state.repair_queue:
		var days = ceili((100 - state.mechs[index].hp) / 10.0)
		var finish = -1
		if not lanes.is_empty():
			var lane = lanes.find(lanes.min())
			lanes[lane] += days
			finish = lanes[lane]
		result.append({"mech": index, "days": finish, "cost": days * 1000, "supplies": days * 2})
	return result

func _valid_logistics(data: Dictionary) -> bool:
	if not data.get("orders") is Array or not data.get("repair_queue") is Array: return false
	if not _number_between(data.get("next_order_id"), 0, 1000000000): return false
	var seen = []
	for index in data.repair_queue:
		if not _number_between(index, 0, data.mechs.size() - 1) or int(index) != index or index in seen: return false
		seen.append(index)
	var reserved = 0
	var ids = []
	for order in data.orders:
		if not order is Dictionary or not order.get("urgent") is bool: return false
		for key in ["id", "quantity", "due", "balance", "cost"]:
			if not _number_between(order.get(key), 0, 1000000000): return false
		if order.id in ids or order.id >= data.next_order_id: return false
		ids.append(order.id)
		reserved += order.balance
	return reserved <= data.funds

# v0.2.3: acceptance and deployment are separate commitments.
func _enrich_contract(contract: Dictionary, legacy: bool = false):
	contract["advance"] = 0 if legacy else int(contract.pay * 0.25)
	contract["min_force"] = 1 if legacy else (2 if contract.difficulty <= 6 else 3)
	contract["deadline"] = int(contract.expires)
	contract["reliability"] = "Media" if contract.difficulty <= 7 else "Baja"
	contract["failure_pay"] = int(contract.pay * 0.15)

func _init_contracts(data: Dictionary):
	data["accepted"] = {}
	data["relationships"] = {}
	data["contract_debt"] = 0
	for offer in data.offers: _enrich_contract(offer)
	if not data.active.is_empty():
		_enrich_contract(data.active.contract, true)
		data.accepted = data.active.contract.duplicate(true)

func accept_contract(index: int) -> String:
	if in_transit(): return "Acción local no disponible durante el traslado."
	if state.ended or not state.accepted.is_empty() or not state.active.is_empty(): return "Solo puede mantener un contrato activo."
	if state.contract_debt > 0: return "Debe saldar la deuda contractual antes de aceptar otro contrato."
	if index < 0 or index >= state.offers.size(): return "Oferta no disponible."
	var contract = state.offers[index].duplicate(true)
	if state.day >= contract.expires: return "Oferta vencida."
	contract.deadline = int(state.day) + 5
	state.accepted = contract
	state.offers.remove_at(index)
	state.funds += contract.advance
	_record_transaction("Contratos", int(contract.advance), "Anticipo: " + contract.name)
	log_event("Contrato", "%s aceptado. Anticipo %d; desplegar %d máquinas en cinco días. Al incumplir se devuelve el anticipo." % [contract.name, contract.advance, contract.min_force])
	return "Contrato aceptado. Prepare la fuerza antes del plazo de despliegue."

func _settle_contract(amount: int):
	if amount >= 0:
		state.funds += amount
		_record_transaction("Contratos", amount, "Liquidación final")
	else:
		var paid = mini(available_funds(), -amount)
		state.funds -= paid
		_record_transaction("Contratos", -paid, "Devolución de anticipo")
		state.contract_debt += -amount - paid

func _change_relation(employer: String, delta: int):
	state.relationships[employer] = clampi(int(state.relationships.get(employer, 0)) + delta, -5, 5)
	log_event("Relación", "%s: confianza %+d. Las próximas ofertas reflejarán este historial." % [employer, state.relationships[employer]])

func cancel_contract(reason: String = "Retirada ordenada por el capitán") -> String:
	if state.ended or state.accepted.is_empty(): return "No hay contrato cancelable."
	var contract = state.accepted
	if contract.get("rpg_id","") == "cargo":
		state.rpg.cargo.stage = "debrief"
		state.rpg.cargo.outcome = "cancelled"
		state.rpg.scene = "debrief"
		state.rpg.jobs = state.rpg.jobs.filter(func(j):return not j.kind in ["transport","investigate","organize"])
	if state.active.has("objective"): Missions.finish(state,contract,state.active.objective,"failure")
	if not state.military.current.is_empty():
		if state.military.current.has("battle"):
			var b = state.military.current.battle
			for group in ["Alfa","Bravo"]:
				b.groups[group] = {"order":"withdraw","attitude":"careful","x":0,"y":12}
			b.pending = []
			Battle.run(b)
			_battle_report()
			for u in b.units:
				if u.side == "own":
					var index = mech_index(u.id)
					if index >= 0:
						state.mechs[index].hp = u.hp
						if u.hp < 40: pilot_for(index).injury = maxi(int(pilot_for(index).injury),5)
			_battle_memories(b)
		elif state.military.current.encountered:
			for index in state.active.team: state.mechs[index].hp = maxi(0, int(state.mechs[index].hp) - 3)
		Story.operation(self,"cancelled")
		_finish_operation("Retirada ordenada; contrato incumplido")
	_settle_contract(-int(contract.advance))
	_close_opportunity(contract, false)
	_change_relation(contract.employer, -2)
	state.reputation -= 1
	state.morale = maxi(0, int(state.morale) - 5)
	log_event("Incumplimiento", "%s: %s. Anticipo a devolver: %d; deuda contractual pendiente %d. Sin pago final." % [contract.name, reason, contract.advance, state.contract_debt])
	state.accepted = {}
	state.active = {}
	state.issues = state.issues.filter(func(issue): return issue.kind != "deadline")
	return "Contrato cerrado. Se devuelve el anticipo; reputación -1, confianza -2 y moral -5."

func settle_contract_debt() -> String:
	if state.ended: return "La compañía ha cerrado operaciones."
	var paid = mini(available_funds(), int(state.contract_debt))
	state.funds -= paid
	_record_transaction("Contratos", -paid, "Pago de deuda contractual")
	state.contract_debt -= paid
	log_event("Finanzas", "Deuda contractual abonada: %d; saldo %d." % [paid, state.contract_debt])
	return "Deuda contractual pendiente: %d." % state.contract_debt

func _valid_contract_state(data: Dictionary) -> bool:
	if not data.get("accepted") is Dictionary or not data.get("relationships") is Dictionary: return false
	if not _number_between(data.get("contract_debt"), 0, 1000000000): return false
	for employer in data.relationships:
		if not employer is String or not _number_between(data.relationships[employer], -5, 5): return false
	var contracts = data.offers.duplicate()
	if not data.accepted.is_empty(): contracts.append(data.accepted)
	if not data.active.is_empty():
		if data.accepted.is_empty() or data.active.contract != data.accepted: return false
		contracts.append(data.active.contract)
	for contract in contracts:
		if not _valid_contract(contract) or not contract.get("reliability") is String: return false
		for key in ["advance", "failure_pay", "deadline"]:
			if not _number_between(contract.get(key), 0, 1000000000): return false
		if not _number_between(contract.get("min_force"), 1, 4): return false
	return true

# v0.2.4: recorded cash flows and commander-facing decisions.
func _init_management(data: Dictionary):
	data["ledger"] = []
	data["opening_balance"] = data.funds
	data["issues"] = []
	data["next_issue_id"] = 0
	data["missed_payrolls"] = 0

func _record_transaction(category: String, amount: int, detail: String):
	if amount == 0: return
	state.ledger.append({"day": state.day, "category": category, "amount": amount, "detail": detail})

func financial_report() -> Dictionary:
	var categories = {}
	for entry in state.ledger:
		if not categories.has(entry.category): categories[entry.category] = {"income": 0, "expense": 0}
		if entry.amount > 0: categories[entry.category].income += entry.amount
		else: categories[entry.category].expense -= entry.amount
	var repairs = 0
	var repair_30 = 0
	for estimate in repair_estimates():
		repairs += estimate.cost
		if estimate.days >= 0:
			var duration = int(estimate.cost / 1000)
			var start = int(estimate.days) - duration
			repair_30 += clampi(30 - start, 0, duration) * 1000
	var ownership = ownership_forecast()
	var final_payment = 0
	if not state.accepted.is_empty(): final_payment = int(state.accepted.pay - state.accepted.advance)
	return {"categories": categories, "payroll": monthly_payroll(), "next_payroll": (int(state.day / 30) + 1) * 30,
		"reserved": committed_payments(), "free": available_funds(), "repairs": repairs, "repairs_30": repair_30,
		"ownership": ownership,
		"projected": int(state.funds) - committed_payments() - monthly_payroll() - int(state.arrears) - int(state.contract_debt) - repair_30 - ownership.next_bill,
		"conditional": final_payment}

func settle_arrears() -> String:
	if state.ended: return "La compañía ha cerrado operaciones."
	var paid = mini(available_funds(), int(state.arrears))
	state.funds -= paid
	state.arrears -= paid
	_record_transaction("Salarios", -paid, "Regularización de deuda")
	if state.arrears == 0:
		state.missed_payrolls = 0
		state.issues = state.issues.filter(func(issue): return issue.kind != "salary")
	log_event("Finanzas", "Deuda salarial abonada: %d; saldo %d." % [paid, state.arrears])
	return "Deuda salarial pendiente: %d." % state.arrears

func _add_issue(kind: String, person: int, description: String):
	state.issues.append({"id": state.next_issue_id, "kind": kind, "person": person, "text": description})
	state.next_issue_id += 1
	log_event("Decisión pendiente", description)

func _check_issues():
	if state.ended: return
	if not state.accepted.is_empty() and state.active.is_empty() and state.accepted.deadline - state.day <= 2 and not state.accepted.get("warning_sent", false):
		state.accepted["warning_sent"] = true
		_add_issue("deadline", -1, "El plazo para desplegar vence en dos días o menos. Revise taller y fuerzas: mantener el compromiso o cancelar devolviendo el anticipo.")
	if state.arrears > 0 and state.missed_payrolls >= 2:
		for issue in state.issues:
			if issue.kind == "salary": return
		for person in state.staff:
			if not personnel_deployed(person.id):
				_add_issue("salary", person.id, "%s exige regularizar la deuda salarial o dejará la compañía. Pagar toda la deuda o aceptar su salida (moral -5; la deuda sigue pendiente)." % person.name)
				state.missed_payrolls = 0
				break

func resolve_issue(id: int, choice: String) -> String:
	if state.ended: return "La compañía ha cerrado operaciones."
	var target = {}
	for issue in state.issues:
		if issue.id == id: target = issue
	if target.is_empty(): return "Asunto ya resuelto."
	if target.kind in ["medical", "team_conflict"]: return _resolve_person_story(target, choice)
	if target.kind == "deadline":
		if choice == "cancel": return cancel_contract("Cancelación tras revisión del plazo")
		if choice != "continue": return "Decisión no válida."
		log_event("Decisión", "El capitán mantiene el compromiso y el plazo de despliegue.")
	else:
		if choice == "pay":
			if available_funds() < state.arrears: return "No alcanza para regularizar toda la deuda. La decisión sigue pendiente."
			settle_arrears()
			log_event("Decisión", "Reclamo salarial resuelto mediante pago de la deuda.")
		elif choice == "release":
			if personnel_deployed(target.person): return "El empleado está desplegado; debe regresar antes de tramitar su salida."
			var person = person_by_id(target.person)
			if not person.is_empty():
				for mech in state.mechs:
					if mech.pilot_id == target.person: mech.pilot_id = -1
				_archive_person(person, "Salida por impagos")
				state.staff.erase(person)
				state.morale = maxi(0, int(state.morale) - 5)
				log_event("Baja voluntaria", "%s abandona la compañía por impagos. La deuda salarial se conserva." % person.name)
		else: return "Decisión no válida."
	state.issues.erase(target)
	return "Decisión registrada. Puede continuar el calendario."

func _valid_management(data: Dictionary) -> bool:
	if not data.get("ledger") is Array or not data.get("issues") is Array: return false
	for key in ["opening_balance", "next_issue_id", "missed_payrolls"]:
		if not _number_between(data.get(key), 0, 1000000000): return false
	for entry in data.ledger:
		if not entry is Dictionary: return false
		if not entry.get("category") is String or not entry.get("detail") is String: return false
		if not _number_between(entry.get("day"), 0, data.day) or not _number_between(entry.get("amount"), -1000000000, 1000000000): return false
	var ids = []
	for issue in data.issues:
		if not issue is Dictionary or not issue.get("text") is String: return false
		if not issue.get("kind") in ["deadline", "salary", "medical", "team_conflict"]: return false
		if not _number_between(issue.get("id"), 0, data.next_issue_id - 1) or issue.id in ids: return false
		if not _number_between(issue.get("person"), -1, data.next_staff_id): return false
		ids.append(issue.id)
	return true

# v0.3.1: serial numbers persist independently of the current roster position.
func _init_hangar(data: Dictionary):
	for i in range(data.mechs.size()): data.mechs[i]["uid"] = i
	data["next_mech_uid"] = data.mechs.size()

func mech_index(uid: int) -> int:
	for i in range(state.mechs.size()):
		if state.mechs[i].uid == uid: return i
	return -1

func _valid_hangar(data: Dictionary) -> bool:
	if not _number_between(data.get("next_mech_uid"), 0, 1000000000): return false
	var serials = []
	for mech in data.mechs:
		if not _number_between(mech.get("uid"), 0, data.next_mech_uid - 1) or int(mech.uid) != mech.uid or mech.uid in serials: return false
		serials.append(mech.uid)
	return true

# v0.3.2: listings and purchases use IDs so stale UI actions cannot buy another lot.
func _init_market(data: Dictionary, market_seed: int = 3027):
	data["market_seed"] = market_seed
	data["mech_market"] = []
	data["mech_orders"] = []
	data["next_market_id"] = 0
	for mech in data.mechs:
		mech["model"] = model_for_name(mech.name)
		mech["model_id"] = MECH_CATALOG[mech.model].id
	_refresh_mech_market(data)

func model_for_name(model_name: String) -> int:
	for i in range(MECH_CATALOG.size()):
		if MECH_CATALOG[i].name == model_name: return i
	return 0

func _refresh_mech_market(data: Dictionary):
	var market_rng = RandomNumberGenerator.new()
	market_rng.seed = int(data.market_seed) + int(data.day) * 7919
	data.mech_market = []
	if data.has("location_id") and Universe.system(data.location_id).affiliations[str(int(data.get("scenario_year",3027)))] in ["U","A","X",""]: return
	var available = Catalog.eligible(int(data.get("scenario_year",3027)))
	for i in range(4):
		var regional_offset = 0 if not data.has("location_id") or data.location_id == Universe.galatea() else posmod(str(data.location_id).hash(),available.size())
		var category = ["light","medium","heavy","ground"][i]
		var category_pool = available.filter(func(index): return MECH_CATALOG[index].class == category)
		var model = category_pool[(int(data.day / 14)+regional_offset)%category_pool.size()]
		var hp = [35, 65, 85, 100][i]
		var value = MECH_CATALOG[model].value
		var regional_supply = int(data.get("missions",{}).get("regions",{}).get(data.get("location_id",""),{}).get("supply",0))
		value = int(value * (100-regional_supply*2)/100.0)
		var price = int(value * (0.55 + 0.45 * hp / 100.0) * market_rng.randi_range(95, 105) / 100.0)
		data.mech_market.append({"id": data.next_market_id, "model": model, "model_id": MECH_CATALOG[model].id, "hp": hp, "price": price,
			"days": 4 if hp < 70 else 2, "expires": (int(data.day / 14) + 1) * 14})
		data.next_market_id += 1

func hangar_used() -> int:
	return state.mechs.size() + state.mech_orders.size()

func market_offer(id: int) -> Dictionary:
	for offer in state.mech_market:
		if offer.id == id: return offer
	return {}

func purchase_mech(id: int, expected_price: int = -1) -> String:
	if in_transit(): return "Acción local no disponible durante el traslado."
	if state.ownership_debt > 0: return "Debe saldar el mantenimiento vencido antes de comprar."
	if state.ended: return "La compañía ha cerrado operaciones."
	var offer = market_offer(id)
	if offer.is_empty() or state.day >= offer.expires: return "Lote ya vendido o vencido."
	if expected_price >= 0 and offer.price != expected_price: return "La cotización cambió; vuelva a revisarla."
	if MECH_CATALOG[offer.model].year > state.scenario_year: return "Modelo no disponible en este escenario."
	if hangar_used() >= MAX_HANGAR: return "Hangar completo: las máquinas en tránsito también reservan plaza."
	if available_funds() < offer.price: return "Fondos libres insuficientes."
	var mech = {"uid": state.next_mech_uid, "name": MECH_CATALOG[offer.model].name,
		"model": offer.model, "model_id": MECH_CATALOG[offer.model].id, "hp": offer.hp, "repair": false, "pilot_id": -1, "stored": false, "ready_day": int(state.day) + int(offer.days)}
	state.next_mech_uid += 1
	state.funds -= offer.price
	_record_transaction("Compra de máquinas", -int(offer.price), "%s #%d" % [mech.name, mech.uid])
	state.mech_orders.append({"mech": mech, "due": int(state.day) + int(offer.days), "price": offer.price, "lot": offer.id})
	state.mech_market.erase(offer)
	log_event("Compra", "%s #%d adquirido al %d%% por %d C-bills. Entrega en %d días; plaza reservada y sin piloto." % [mech.name, mech.uid, mech.hp, offer.price, offer.days])
	return "Compra pagada. La máquina estará disponible cuando llegue; asígnele un piloto."

func _receive_mechs():
	for order in state.mech_orders.duplicate():
		if state.day >= order.due:
			state.mechs.append(order.mech)
			Story.Culture.ensure(self)
			state.mech_orders.erase(order)
			log_event("Entrega de máquina", "%s #%d llega al hangar con %d%% de integridad, sin piloto asignado." % [order.mech.name, order.mech.uid, order.mech.hp])

func sale_quote(uid: int) -> int:
	var index = mech_index(uid)
	if index < 0: return 0
	var mech = state.mechs[index]
	# Dealer margin prevents profit from instant buy/repair/resale cycles.
	return int(MECH_CATALOG[mech.model].value * (0.10 + 0.40 * mech.hp / 100.0))

func sale_block_reason(uid: int) -> String:
	var index = mech_index(uid)
	if state.ended: return "La compañía ha cerrado operaciones."
	if index < 0: return "Máquina no disponible."
	if deployed(index): return "No se puede vender una máquina desplegada."
	if state.rpg.delegation.jobs.any(func(j):return j.uid==uid): return "Unidad comprometida en un encargo."
	if state.mechs[index].repair: return "Suspenda su reparación antes de vender."
	if state.rpg.workshop.jobs.any(func(j):return j.uid==uid): return "Espere el trabajo funcional de taller."
	return ""

func sell_mech(uid: int, expected_price: int = -1) -> String:
	if in_transit(): return "Acción local no disponible durante el traslado."
	var reason = sale_block_reason(uid)
	if not reason.is_empty(): return reason
	var price = sale_quote(uid)
	if expected_price >= 0 and expected_price != price: return "La cotización cambió; revise la venta."
	var index = mech_index(uid)
	var mech = state.mechs[index]
	state.funds += price
	_record_transaction("Venta de máquinas", price, "%s #%d" % [mech.name, uid])
	Story.Culture.sale(self,mech)
	state.mechs.remove_at(index)
	var queue = []
	for queued in state.repair_queue:
		if queued != index: queue.append(queued - 1 if queued > index else queued)
	state.repair_queue = queue
	if not state.active.is_empty():
		for i in range(state.active.team.size()):
			if state.active.team[i] > index: state.active.team[i] -= 1
	log_event("Venta", "%s #%d vendido por %d C-bills. Su piloto queda en reserva." % [mech.name, uid, price])
	return "Venta completada. El piloto permanece en la compañía."

func _valid_market(data: Dictionary) -> bool:
	if not data.get("mech_market") is Array or not data.get("mech_orders") is Array: return false
	if data.mechs.size() + data.mech_orders.size() > MAX_HANGAR: return false
	if not _number_between(data.get("market_seed"), -1e15, 1e15) or not _number_between(data.get("next_market_id"), 0, 1e9): return false
	var serials = []
	for mech in data.mechs:
		if not _number_between(mech.get("model"), 0, MECH_CATALOG.size() - 1) or int(mech.model) != mech.model: return false
		serials.append(mech.uid)
	var lots = []
	for offer in data.mech_market:
		if not offer is Dictionary: return false
		for key in ["id", "model", "hp", "price", "days", "expires"]:
			if not _number_between(offer.get(key), 0, 1e9) or int(offer[key]) != offer[key]: return false
		if offer.model >= MECH_CATALOG.size() or offer.hp > 100 or offer.days < 1 or offer.days > 30 or offer.id >= data.next_market_id or offer.id in lots: return false
		lots.append(offer.id)
	for order in data.mech_orders:
		if not order is Dictionary or not order.get("mech") is Dictionary: return false
		for key in ["due", "price", "lot"]:
			if not _number_between(order.get(key), 0, 1e9): return false
		if order.lot in lots or order.lot >= data.next_market_id: return false
		lots.append(order.lot)
		var mech = order.mech
		if not mech.get("name") is String or mech.get("repair") != false or mech.get("pilot_id") != -1: return false
		if not _number_between(mech.get("uid"), 0, data.next_mech_uid - 1) or mech.uid in serials: return false
		if not _number_between(mech.get("model"), 0, MECH_CATALOG.size() - 1) or int(mech.model) != mech.model: return false
		if not _number_between(mech.get("hp"), 0, 100): return false
		serials.append(mech.uid)
	return true

# v0.3.3: accrue per day; sell/store does not erase existing obligations.
func _init_ownership(data: Dictionary):
	data["ownership_due"] = 0
	data["ownership_debt"] = 0
	for mech in data.mechs:
		mech["stored"] = false
		mech["ready_day"] = int(data.day)
	for order in data.mech_orders:
		order.mech["stored"] = false
		order.mech["ready_day"] = int(data.day)

func mech_ready(index: int) -> bool:
	return index >= 0 and index < state.mechs.size() and not state.mechs[index].stored and state.day >= state.mechs[index].ready_day and not RPG.Workshop.blocked(self,int(state.mechs[index].uid))

func mech_daily_cost(mech: Dictionary) -> int:
	return int((10 + (0 if mech.stored else int(MECH_CATALOG[mech.model].maintenance))) * int(state.rpg.arcs.settings.economy) / 100.0)

func ownership_daily() -> int:
	var total = 0
	for mech in state.mechs: total += mech_daily_cost(mech)
	return total

func _accrue_ownership():
	state.ownership_due += ownership_daily()

func _bill_ownership():
	var due = int(state.ownership_due + state.ownership_debt)
	var paid = mini(available_funds(), due)
	state.funds -= paid
	state.ownership_due = 0
	state.ownership_debt = due - paid
	_record_transaction("Mantenimiento y hangar", -paid, "Liquidación mensual de costes devengados")
	log_event("Propiedad", "Mantenimiento y almacenamiento: %d abonados; %d vencidos. La deuda vencida impide comprar o desplegar nuevas operaciones." % [paid, state.ownership_debt])

func settle_ownership_debt() -> String:
	if state.ended: return "La compañía ha cerrado operaciones."
	var paid = mini(available_funds(), int(state.ownership_debt))
	state.funds -= paid
	state.ownership_debt -= paid
	_record_transaction("Mantenimiento y hangar", -paid, "Pago de deuda vencida")
	log_event("Propiedad", "Deuda de hangar pagada: %d; saldo %d." % [paid, state.ownership_debt])
	return "Mantenimiento vencido pendiente: %d." % state.ownership_debt

func set_stored(uid: int, stored: bool) -> String:
	if state.rpg.workshop.jobs.any(func(j):return j.uid==uid) or state.rpg.delegation.jobs.any(func(j):return j.uid==uid): return "Unidad comprometida; espere el cierre del trabajo."
	var index = mech_index(uid)
	if state.ended or index < 0: return "Máquina no disponible."
	var mech = state.mechs[index]
	if deployed(index) or mech.repair or state.day < mech.ready_day: return "Debe estar en base, fuera de taller y sin reactivación en curso."
	if mech.stored == stored: return "La máquina ya está en ese estado."
	if not stored:
		if available_funds() < 1000: return "Reactivar cuesta 1.000 C-bills."
		state.funds -= 1000
		_record_transaction("Reactivación", -1000, "%s #%d" % [mech.name, uid])
		mech.ready_day = int(state.day) + 2
	else:
		mech.pilot_id = -1
	mech.stored = stored
	log_event("Hangar", "%s #%d: %s." % [mech.name, uid, "almacenado, piloto en reserva; solo paga almacenamiento" if stored else "reactivación autorizada; disponible en dos días"])
	return "Estado actualizado. El gasto ya devengado se conserva."

func ownership_forecast() -> Dictionary:
	var until_bill = (int(state.day / 30) + 1) * 30 - int(state.day)
	var future = ownership_daily() * until_bill
	var horizon = ownership_daily() * 30
	for order in state.mech_orders:
		var wait_days = maxi(1, int(order.due - state.day))
		future += maxi(0, until_bill - wait_days + 1) * mech_daily_cost(order.mech)
		horizon += maxi(0, 30 - wait_days + 1) * mech_daily_cost(order.mech)
	return {"daily": ownership_daily(), "accrued": int(state.ownership_due), "debt": int(state.ownership_debt),
		"next_bill": int(state.ownership_due + state.ownership_debt) + future, "future_30": horizon, "days": until_bill}

func acquisition_estimate(id: int) -> Dictionary:
	var offer = market_offer(id)
	if offer.is_empty(): return {}
	var days = ceili((100 - offer.hp) / 10.0)
	var quote = supply_quote(false)
	var supplies = days * 2
	var supplies_value = ceili(supplies * quote.cost / 30.0)
	var upkeep = (10 + int(MECH_CATALOG[offer.model].maintenance)) * 30
	var resale = int(MECH_CATALOG[offer.model].value * (0.10 + 0.40 * offer.hp / 100.0))
	return {"purchase": offer.price, "repair": days * 1000, "supplies": supplies,
		"supplies_value": supplies_value, "work_days": days, "monthly": upkeep, "stored_monthly": 300,
		"total": int(offer.price) + days * 1000 + supplies_value + upkeep, "resale": resale}

func _valid_ownership(data: Dictionary) -> bool:
	for key in ["ownership_due", "ownership_debt"]:
		if not _number_between(data.get(key), 0, 1e9): return false
	var machines = data.mechs.duplicate()
	for order in data.mech_orders: machines.append(order.mech)
	for mech in machines:
		if not mech.get("stored") is bool or not _number_between(mech.get("ready_day"), 0, 1e9): return false
		if mech.stored and (mech.pilot_id != -1 or mech.repair): return false
	if not data.active.is_empty():
		for index in data.active.team:
			if data.mechs[int(index)].stored or data.mechs[int(index)].ready_day > data.day: return false
	return true

# v0.4.1: new records begin here; do not invent service history for old saves.
func _init_person_career(person: Dictionary):
	person["experience"] = 0
	person["promotions"] = 0
	person["missions"] = 0
	person["victories"] = 0
	person["memories"] = []

func _init_careers(data: Dictionary):
	data["alumni"] = []
	for person in data.staff: _init_person_career(person)

func _remember(person: Dictionary, text: String):
	person.memories.append({"day": int(state.day), "text": text})

func _gain_experience(person: Dictionary, amount: int, reason: String):
	var was_ready = promotion_eligible(person.id)
	person.experience += amount
	_remember(person, "%s (+%d experiencia)." % [reason, amount])
	if not was_ready and person.experience >= (person.promotions + 1) * 6 and person.promotions < 2 and person.skill < 5:
		log_event("Carrera", "%s reúne experiencia para un ascenso. Consulte su expediente." % person.name)

func _award_operation(op: Dictionary, success: bool):
	_update_bonds(op.team, success)
	for index in op.team:
		var person = pilot_for(index)
		person.fatigue = mini(100, int(person.fatigue) + 18 + op.doctrine * 6 + (0 if success else 8))
		person.missions += 1
		if success: person.victories += 1
		_gain_experience(person, 2 if success else 1, "%s: %s" % [op.contract.name, "objetivo cumplido" if success else "retirada"])

func career_rank(person: Dictionary) -> String:
	if person.role == "Piloto": return ["Piloto", "Veterano", "Instructor"][int(person.promotions)]
	return ["Especialista", "Especialista sénior", "Supervisor"][int(person.promotions)]

func promotion_eligible(id: int) -> bool:
	var person = person_by_id(id)
	return not person.is_empty() and person.promotions < 2 and person.skill < 5 and person.experience >= (person.promotions + 1) * 6

func promote(id: int) -> String:
	if state.ended or not promotion_eligible(id): return "No reúne los requisitos de ascenso (experiencia y habilidad inferior a 5)."
	if personnel_deployed(id): return "Espere al regreso para formalizar el ascenso."
	if available_funds() < 3000: return "El ascenso requiere 3.000 C-bills libres."
	var person = person_by_id(id)
	state.funds -= 3000
	_record_transaction("Personal", -3000, "Ascenso de " + person.name)
	person.promotions += 1
	person.skill += 1
	person.salary += 1000
	_remember(person, "Ascendido a %s por orden del capitán." % career_rank(person))
	log_event("Ascenso", "%s: %s, habilidad %d; salario mensual %d." % [person.name, career_rank(person), person.skill, person.salary],[id],[],"person:%d"%id)
	return "Ascenso formalizado: habilidad +1 y salario +1.000/mes."

func _archive_person(person: Dictionary, reason: String):
	_remember(person, reason)
	var record = person.duplicate(true)
	record["departure_day"] = int(state.day)
	record["departure_reason"] = reason
	state.alumni.append(record)
	for issue in state.issues.duplicate():
		if issue.kind in ["medical", "team_conflict"] and (issue.person == person.id or issue.get("other", -1) == person.id):
			state.issues.erase(issue)
			log_event("Asunto cerrado", "El asunto personal queda archivado por la salida de " + person.name)

func _valid_careers(data: Dictionary) -> bool:
	if not data.get("alumni") is Array: return false
	for person in data.staff + data.alumni:
		if not person is Dictionary: return false
		for key in ["experience", "missions", "victories"]:
			if not _number_between(person.get(key), 0, 1e9): return false
		if not _number_between(person.get("promotions"), 0, 2) or not person.get("memories") is Array: return false
		for memory in person.memories:
			if not memory is Dictionary or not memory.get("text") is String or not _number_between(memory.get("day"), 0, data.day): return false
	for person in data.alumni:
		if not person.get("name") is String or not person.get("role") is String or not person.get("departure_reason") is String: return false
		for key in ["id", "skill", "salary", "departure_day"]:
			if not _number_between(person.get(key), 0, 1e9): return false
	return true

# v0.4.2: availability and observable shared-service relationships.
func _init_person_condition(person: Dictionary):
	person["fatigue"] = 0
	person["rest_until"] = 0

func _init_relations(data: Dictionary):
	data["bonds"] = {}
	for person in data.staff + data.alumni: _init_person_condition(person)

func person_available(person: Dictionary) -> bool:
	if not person.is_empty() and RPG.person_busy(self,int(person.id)): return false
	return not person.is_empty() and person.injury == 0 and person.fatigue < 80 and state.day >= person.rest_until

func _recover_people():
	for person in state.staff:
		if not personnel_deployed(person.id):
			var recovery = 14 if person.rest_until >= state.day and person.rest_until > 0 else 6
			person.fatigue = maxi(0, int(person.fatigue) - recovery)

func grant_leave(id: int) -> String:
	var person = person_by_id(id)
	if state.ended or person.is_empty() or personnel_deployed(id): return "El empleado debe estar en base."
	if person.rest_until > state.day: return "Ya tiene un permiso en curso."
	person.rest_until = int(state.day) + 3
	Story.People.care(self,id)
	Story.Culture.care(self,id)
	_remember(person, "El capitán concede tres días de descanso protegido.")
	log_event("Descanso", "%s recibe tres días de permiso; no estará disponible. Recupera 14 de fatiga por día de permiso." % person.name,[id],[],"person:%d"%id)
	return "Permiso concedido. Se mantiene el salario; disponibilidad en tres días."

func _bond_key(a: int, b: int) -> String:
	return "%d:%d" % [mini(a, b), maxi(a, b)]

func _update_bonds(team: Array, success: bool):
	for i in range(team.size()):
		for j in range(i + 1, team.size()):
			var a = pilot_for(team[i])
			var b = pilot_for(team[j])
			var key = _bond_key(a.id, b.id)
			if not state.bonds.has(key):
				state.bonds[key] = {"a": mini(a.id, b.id), "b": maxi(a.id, b.id), "score": 0, "shared": 0, "last_conflict": -100}
			var bond = state.bonds[key]
			var before = int(bond.score)
			bond.shared += 1
			bond.score = clampi(int(bond.score) + (1 if success else -1), -5, 5)
			if (before < 3 and bond.score >= 3) or (before > -2 and bond.score <= -2):
				var report = "%s y %s: %s tras %d operaciones compartidas." % [a.name, b.name, bond_description(bond.score), bond.shared]
				log_event("Compañeros", report)
				_remember(a, report)
				_remember(b, report)

func bond_description(score: int) -> String:
	if score >= 3: return "confianza consolidada"
	if score <= -2: return "tensión en los informes de equipo"
	return "relación de trabajo"

func team_cohesion(team: Array) -> float:
	var total = 0.0
	var pairs = 0
	for i in range(team.size()):
		for j in range(i + 1, team.size()):
			var key = _bond_key(pilot_for(team[i]).id, pilot_for(team[j]).id)
			total += state.bonds.get(key, {}).get("score", 0)
			pairs += 1
	return clampf(total / maxf(1, pairs) / 3.0, -2.0, 2.0)

func person_name(id: int) -> String:
	var person = person_by_id(id)
	if not person.is_empty(): return person.name
	for record in state.alumni:
		if record.id == id: return record.name + " (baja)"
	return "Empleado #%d" % id

func _valid_relations(data: Dictionary) -> bool:
	if not data.get("bonds") is Dictionary: return false
	var known = []
	for person in data.staff + data.alumni:
		if person.id in known: return false
		known.append(person.id)
		if not _number_between(person.get("fatigue"), 0, 100) or not _number_between(person.get("rest_until"), 0, 1e9): return false
	for key in data.bonds:
		var bond = data.bonds[key]
		if not bond is Dictionary or not bond.get("a") in known or not bond.get("b") in known or bond.a >= bond.b: return false
		if key != _bond_key(int(bond.a), int(bond.b)): return false
		if not _number_between(bond.get("score"), -5, 5) or not _number_between(bond.get("shared"), 0, 1e9) or not _number_between(bond.get("last_conflict"), -100, 1e9): return false
	return true

# v0.4.3: one reported personal incident per operation, no hidden-motive narration.
func _init_stories(data: Dictionary):
	for person in data.staff + data.alumni: person["last_care_event"] = -100

func _person_has_story(id: int) -> bool:
	for issue in state.issues:
		if issue.kind in ["medical", "team_conflict"] and (issue.person == id or issue.get("other", -1) == id): return true
	return false

func _operation_story(op: Dictionary):
	for index in op.team:
		var person = pilot_for(index)
		if person.injury > 0 and state.day - person.last_care_event >= 30 and not _person_has_story(person.id):
			person.last_care_event = int(state.day)
			_add_issue("medical", person.id, "Sanidad informa: %s requiere %d días de recuperación. Una consulta especializada cuesta 2.000 C-bills, reduce la baja en tres días (mínimo uno restante) y mejora la moral en 2. Puede mantener el tratamiento habitual sin gasto adicional." % [person.name, person.injury])
			_remember(person, "Sanidad eleva al capitán una solicitud de atención especializada.")
			return
	for i in range(op.team.size()):
		for j in range(i + 1, op.team.size()):
			var a = pilot_for(op.team[i])
			var b = pilot_for(op.team[j])
			var key = _bond_key(a.id, b.id)
			var bond = state.bonds.get(key, {})
			if not bond.is_empty() and bond.score <= -2 and state.day - bond.last_conflict >= 30 and not _person_has_story(a.id) and not _person_has_story(b.id):
				bond.last_conflict = int(state.day)
				_add_issue("team_conflict", a.id, "%s y %s discrepan en los informes tras operaciones fallidas. Puede reunirlos durante dos días sin despliegue (vínculo +2), o separar sus asignaciones dejando al segundo en reserva (vínculo +1)." % [a.name, b.name])
				state.issues[-1]["other"] = b.id
				state.issues[-1]["bond"] = key
				return

func _resolve_person_story(issue: Dictionary, choice: String) -> String:
	var person = person_by_id(issue.person)
	if person.is_empty(): return "El empleado ya no está disponible."
	if personnel_deployed(person.id): return "El empleado debe regresar a base."
	var report = ""
	if issue.kind == "medical":
		if choice == "care":
			if available_funds() < 2000: return "Se requieren 2.000 C-bills libres; el asunto sigue pendiente."
			state.funds -= 2000
			_record_transaction("Sanidad", -2000, "Atención especializada de " + person.name)
			person.injury = maxi(1, int(person.injury) - 3)
			state.morale = mini(100, int(state.morale) + 2)
			report = "%s recibe atención especializada; baja restante %d días." % [person.name, person.injury]
		elif choice == "standard": report = "%s continúa su tratamiento habitual, sin gasto adicional." % person.name
		else: return "Decisión no válida."
	else:
		var other = person_by_id(issue.other)
		if other.is_empty() or personnel_deployed(other.id): return "Ambos empleados deben estar en base."
		var bond = state.bonds[issue.bond]
		if choice == "mediate":
			person.rest_until = maxi(int(person.rest_until), int(state.day) + 2)
			other.rest_until = maxi(int(other.rest_until), int(state.day) + 2)
			bond.score = mini(5, int(bond.score) + 2)
			report = "%s y %s reciben dos días para revisar juntos los incidentes con el mando. Vínculo +2." % [person.name, other.name]
		elif choice == "separate":
			for mech in state.mechs:
				if mech.pilot_id == other.id: mech.pilot_id = -1
			bond.score = mini(5, int(bond.score) + 1)
			report = "%s pasa a reserva para separar sus asignaciones de %s. Vínculo +1." % [other.name, person.name]
		else: return "Decisión no válida."
		_remember(other, report)
	_remember(person, report)
	log_event("Decisión personal", report)
	state.issues.erase(issue)
	return "Decisión registrada en la crónica y los expedientes."

func _valid_stories(data: Dictionary) -> bool:
	var employed = []
	for person in data.staff + data.alumni:
		if not _number_between(person.get("last_care_event"), -100, 1e9): return false
	for person in data.staff: employed.append(person.id)
	for issue in data.issues:
		if issue.kind in ["medical", "team_conflict"] and not issue.person in employed: return false
		if issue.kind == "team_conflict":
			if not issue.get("other") in employed or not data.bonds.has(issue.get("bond", "")): return false
			if issue.bond != _bond_key(int(issue.person), int(issue.other)): return false
	return true

# v0.5: world identity links; existing employer trust remains the only source of truth.
func _init_world(data: Dictionary):
	data["world"] = World.create(int(data.day))
	World.enable(data.world, int(data.day))
	for offer in data.offers: offer["employer_id"] = World.id_for_name(offer.employer)
	if not data.accepted.is_empty(): data.accepted["employer_id"] = World.id_for_name(data.accepted.employer)
	if not data.active.is_empty(): data.active.contract["employer_id"] = World.id_for_name(data.active.contract.employer)

func world_report() -> Dictionary:
	return World.public_report(state.world, state.relationships, int(state.reputation))

func establish_contact(id: String) -> String:
	if state.ended: return "La compañía ha cerrado operaciones."
	var actor = World.actor(state.world, id)
	if actor.is_empty(): return "Organización desconocida."
	if actor.contact_day >= 0: return "Ya existe un canal de contacto."
	if available_funds() < 1000: return "Se requieren 1.000 C-bills libres para registrar el canal."
	state.funds -= 1000
	_record_transaction("Contactos", -1000, actor.name)
	actor.contact_day = int(state.day)
	log_event("Contacto", "Canal abierto con %s. Es una presentación formal, no un acuerdo ni una mejora de confianza." % actor.name)
	return "Contacto registrado. No implica alianza, contrato ni aumento de confianza."

func _valid_world(data: Dictionary) -> bool:
	if not World.valid(data.get("world"), int(data.day)): return false
	var contracts = data.offers.duplicate()
	if not data.accepted.is_empty(): contracts.append(data.accepted)
	if not data.active.is_empty(): contracts.append(data.active.contract)
	for contract in contracts:
		if not contract.get("employer_id") is String or contract.employer_id != World.id_for_name(contract.employer): return false
	return true


# Phase II: causal opportunities and dated, attributed contact reports.
func _init_frontier(data: Dictionary):
	data["frontier"] = {"since": int(data.day), "next_id": 100000000, "opportunities": [], "cooldowns": {}, "reports": {}, "queries": {}}

func _frontier_tick():
	var f = state.frontier
	for id in f.queries.keys():
		var query = f.queries[id]
		if state.day < query.due: continue
		if f.reports.has(id) and f.reports[id].text != query.text:
			log_event("Inteligencia", "%s revisa su declaración anterior. Conservar ambas fechas: la situación puede haber cambiado; no implica corroboración." % World.actor(state.world, id).name)
		f.reports[id] = {"observed": query.observed, "received": int(state.day), "text": query.text, "source": query.source}
		f.queries.erase(id)
		log_event("Inteligencia", "%s: %s Información del día %d; recibida hoy. Fuente: %s. No confirma fuerzas enemigas." % [World.actor(state.world, id).name, query.text, query.observed, query.source])
	for opportunity in f.opportunities:
		if opportunity.status != "open": continue
		var employer = World.actor(state.world, opportunity.contract.employer_id)
		if state.day >= opportunity.contract.expires or employer.private.demand < 3:
			opportunity.status = "expired" if state.day >= opportunity.contract.expires else "withdrawn"
			log_event("Oportunidad", "%s: %s." % [opportunity.contract.name, "venció el plazo de oferta" if opportunity.status == "expired" else "el empleador retiró la solicitud tras reducirse su necesidad"])
	if (int(state.day) - int(f.since)) % 7 != 0: return
	for employer in state.world.actors:
		if employer.kind != "Contratante" or employer.private.demand < 4: continue
		if state.day < int(f.cooldowns.get(employer.id, 0)): continue
		var busy = false
		for opportunity in f.opportunities:
			if opportunity.contract.employer_id == employer.id and opportunity.status in ["open", "accepted"]: busy = true
		if busy: continue
		var contract = {"id": int(f.next_id), "name": "Refuerzo: " + employer.specialty,
			"employer": employer.name, "employer_id": employer.id, "difficulty": 6 + int(employer.private.demand) / 2,
			"days": 4, "pay": 65000 + int(state.relationships.get(employer.name, 0)) * 3000,
			"expires": int(state.day) + 7, "intel": "Solicitud del empleador: necesidades de protección pendientes. Dispositivo enemigo sin confirmar.", "world_origin": int(f.next_id)}
		_enrich_contract(contract)
		f.next_id += 1
		f.opportunities.append({"contract": contract, "status": "open", "created": int(state.day), "source": "Solicitud de " + employer.name, "cause": "El empleador comunica que su cobertura habitual no alcanza para atender sus necesidades actuales."})
		f.cooldowns[employer.id] = int(state.day) + 28
		log_event("Oportunidad", "%s solicita refuerzos. Oferta disponible siete días en Mundo; condiciones y procedencia en su ficha." % employer.name)
	# Keep active offers plus a bounded archive. The full narrative remains in chronicle.
	while f.opportunities.size() > 40:
		var removed = false
		for index in range(f.opportunities.size()):
			if not f.opportunities[index].status in ["open", "accepted"]:
				f.opportunities.remove_at(index)
				removed = true
				break
		if not removed: break

func accept_opportunity(id: int) -> String:
	if state.location_id != Universe.galatea(): return "Esta oportunidad corresponde a la red local de Galatea. Regrese antes de aceptarla."
	if in_transit(): return "Acción local no disponible durante el traslado."
	if state.ended or not state.accepted.is_empty() or not state.active.is_empty(): return "Solo puede mantener un contrato activo."
	if state.contract_debt > 0: return "Debe saldar la deuda contractual."
	for opportunity in state.frontier.opportunities:
		if opportunity.contract.id != id: continue
		if opportunity.status != "open" or state.day >= opportunity.contract.expires: return "La oportunidad ya no está disponible."
		# Reuse the existing acceptance transaction and preparation rules.
		state.offers.append(opportunity.contract.duplicate(true))
		var result = accept_contract(state.offers.size() - 1)
		opportunity.status = "accepted"
		return result
	return "Oportunidad desconocida."

func _close_opportunity(contract: Dictionary, success: bool):
	if not contract.has("world_origin"): return
	for opportunity in state.frontier.opportunities:
		if opportunity.contract.id != contract.world_origin or opportunity.status != "accepted": continue
		opportunity.status = "completed" if success else "failed"
		var employer = World.actor(state.world, contract.employer_id)
		employer.private.demand = clampi(int(employer.private.demand) + (-3 if success else 1), 0, 6)
		state.frontier.cooldowns[employer.id] = int(state.day) + 28
		log_event("Consecuencia", "%s comunica %s tras nuestra intervención. Esto afecta sus futuras solicitudes y la búsqueda de trabajo de otras compañías." % [employer.name, "una reducción de sus necesidades pendientes" if success else "que su necesidad de protección sigue sin resolverse"])

func request_world_report(id: String) -> String:
	if state.ended: return "La compañía ha cerrado operaciones."
	var actor = World.actor(state.world, id)
	if actor.is_empty() or actor.contact_day < 0: return "Primero establezca un contacto con esta organización."
	if state.frontier.queries.has(id): return "Ya hay una consulta en curso."
	if state.frontier.reports.has(id) and state.day < state.frontier.reports[id].received + 7: return "El contacto pide esperar siete días entre informes recibidos."
	if available_funds() < 500: return "Se requieren 500 C-bills libres."
	var report_text = "Declara estar preparando nuevas actividades; no confirma disponibilidad para terceros."
	if actor.kind == "Contratante":
		report_text = "Declara necesidades de protección pendientes." if actor.private.demand >= 4 else "Declara tener sus necesidades inmediatas parcialmente cubiertas."
	elif not actor.private.commitments.is_empty():
		report_text = "Declara estar cumpliendo un encargo; no comunica destino ni composición de fuerzas."
	state.funds -= 500
	_record_transaction("Inteligencia", -500, "Consulta: " + actor.name)
	state.frontier.queries[id] = {"observed": int(state.day), "due": int(state.day) + 2, "text": report_text, "source": "Enlace de " + actor.name + "; declaración interesada, sin corroboración independiente"}
	log_event("Inteligencia", "Consulta enviada a %s. Respuesta prevista en dos días." % actor.name)
	return "Consulta enviada. La información puede cambiar mientras llega la respuesta."

func frontier_report(id: String) -> Dictionary:
	var result = {"opportunities": [], "pending": state.frontier.queries.has(id), "report": {}}
	for opportunity in state.frontier.opportunities:
		if opportunity.contract.employer_id != id: continue
		var c = opportunity.contract
		result.opportunities.append({"id": c.id, "name": c.name, "pay": c.pay, "advance": c.advance, "min_force": c.min_force, "days": c.days, "expires": c.expires, "status": opportunity.status, "source": opportunity.source, "cause": opportunity.cause, "created": opportunity.created})
	if state.frontier.reports.has(id):
		var report = state.frontier.reports[id]
		result.report = {"observed": report.observed, "received": report.received, "text": report.text, "source": report.source, "stale": state.day - report.observed >= 7}
	return result

func _valid_frontier(data: Dictionary) -> bool:
	var f = data.get("frontier")
	if not f is Dictionary: return false
	if not World._integer(f.get("since"), 0, data.day) or not World._integer(f.get("next_id"), 100000000, 1000000000): return false
	for key in ["cooldowns", "reports", "queries"]:
		if not f.get(key) is Dictionary: return false
	if not f.get("opportunities") is Array or f.opportunities.size() > 40: return false
	var ids = []
	var accepted_ids = []
	for o in f.opportunities:
		if not o is Dictionary or not _valid_contract(o.get("contract")): return false
		var c = o.contract
		if not World._integer(c.id, 100000000, f.next_id - 1) or c.id in ids or c.get("world_origin") != c.id: return false
		ids.append(c.id)
		if not c.get("employer_id") is String or World.id_for_name(c.employer) != c.employer_id: return false
		var employer = World.actor(data.world, c.employer_id)
		if employer.is_empty() or employer.kind != "Contratante": return false
		if not o.get("status") in ["open", "accepted", "completed", "failed", "expired", "withdrawn"]: return false
		if not o.get("source") is String or not o.get("cause") is String or not World._integer(o.get("created"), f.since, data.day): return false
		for key in ["advance", "min_force", "failure_pay", "deadline"]:
			if not World._integer(c.get(key), 0, 1000000000): return false
		if c.advance > c.pay or c.failure_pay > c.pay or c.min_force < 1 or c.min_force > 4 or not c.get("reliability") is String: return false
		if o.status == "open" and c.expires <= data.day: return false
		if o.status == "accepted": accepted_ids.append(c.id)
	if data.accepted.has("world_origin"):
		if accepted_ids != [data.accepted.world_origin]: return false
		for o in f.opportunities:
			if o.contract.id != data.accepted.world_origin: continue
			var agreed = data.accepted.duplicate(true)
			agreed.deadline = o.contract.deadline
			if agreed != o.contract: return false
	elif not accepted_ids.is_empty(): return false
	for id in f.cooldowns:
		if World.actor(data.world, id).is_empty() or not World._integer(f.cooldowns[id], f.since, data.day + 28): return false
	for collection in ["reports", "queries"]:
		for id in f[collection]:
			var actor = World.actor(data.world, id)
			if actor.is_empty() or actor.contact_day < 0: return false
			var r = f[collection][id]
			if not r is Dictionary or not World._integer(r.get("observed"), f.since, data.day) or not r.get("text") is String or not r.get("source") is String: return false
			if collection == "reports":
				if not World._integer(r.get("received"), r.observed + 2, data.day): return false
			elif not World._integer(r.get("due"), data.day + 1, data.day + 2) or r.due != r.observed + 2: return false
	return true


# Phase III: orders, operational friction and subordinate initiative.
func configure_operation(approach: String, authority: String, priority: String) -> String:
	if state.ended or not state.active.is_empty(): return "Solo puede preparar órdenes antes de desplegar."
	var orders = {"approach": approach, "authority": authority, "priority": priority}
	if not Operations.valid_plan(orders): return "Órdenes inválidas."
	state.military.plan = orders
	return "Plan preparado. Reconocer añade un día y cuatro suministros; consultar detiene el calendario ante el contacto."

func _operation_report(message: String):
	var current = state.military.current
	Operations.add_report(current, int(state.day), message)
	log_event("Parte operacional", "%s: %s" % [current.leader, message],[int(state.active.leader)] if not state.active.is_empty() else [],[],Story.operation_key(self) if not state.active.is_empty() else "")

func _start_operation():
	var team = []
	for index in state.active.team:
		var mech = state.mechs[index]
		team.append({"uid": mech.uid, "name": mech.name, "hp": int(mech.hp)})
	var current = Operations.begin(state.military, int(state.day), person_by_id(state.active.leader).name, state.active.contract.name, team)
	if current.orders.approach == "recon": state.active.remaining += 1
	_operation_report("Órdenes recibidas. Iniciamos aproximación. El plazo es estimativo; fuerzas enemigas no confirmadas.")

func military_waiting() -> bool:
	return not state.military.current.is_empty() and state.military.current.decision

func send_operation_order(authority: String, priority: String) -> String:
	var c = state.military.current
	if state.ended or c.is_empty(): return "No hay operación con enlace operacional."
	if military_waiting(): return "Responda primero a la consulta del jefe."
	if not c.pending_order.is_empty(): return "Ya hay una orden en tránsito."
	var orders = {"approach": c.orders.approach, "authority": authority, "priority": priority}
	if not Operations.valid_plan(orders): return "Órdenes inválidas."
	c.pending_order = {"due": int(state.day) + 1, "orders": orders}
	_operation_report("Nueva directiva transmitida; recepción prevista mañana. Siguen vigentes las órdenes anteriores hasta su confirmación.")
	return "Orden en tránsito. No se aplica hasta el día siguiente."

func _operation_tick() -> bool:
	var c = state.military.current
	if c.is_empty(): return true # Preserve old in-flight operations exactly.
	if c.has("battle"):
		c.elapsed += 1
		c.phase = "Ejecución"
		return true
	c.elapsed += 1
	if not c.pending_order.is_empty() and state.day >= c.pending_order.due:
		c.orders = c.pending_order.orders.duplicate(true)
		c.pending_order = {}
		_operation_report("Nueva directiva recibida y vigente.")
	if c.elapsed == 1:
		c.phase = "Reconocimiento" if c.orders.approach == "recon" else "Aproximación"
		_operation_report("Exploramos accesos y rutas de extracción; no es una identificación completa del enemigo." if c.orders.approach == "recon" else "La fuerza avanza hacia el área asignada. Sin contacto confirmado todavía.")
		if c.orders.approach == "recon":
			var assessments = ["Los accesos parecen transitables; la exploración no garantiza ausencia de oposición.", "Las patrullas recomiendan cautela por accesos y señales incompletas.", "Las patrullas recomiendan una ruta alternativa por exposición probable; no confirman fuerzas enemigas."]
			_operation_report("Evaluación preliminar del reconocimiento: " + assessments[int(c.private.severity)])
	if c.elapsed == 2 and not c.encountered:
		c.encountered = true
		c.phase = "Contacto"
		var observations = ["El acceso previsto está obstaculizado; exponerse o buscar otra ruta tiene costes.", "La cobertura de radio es irregular; el jefe solicita confirmar prioridades ante señales sin identificar.", "Las patrullas observan movimiento no identificado cerca del objetivo; no pueden determinar composición ni intención."]
		_operation_report(observations[int(c.private.obstacle)])
		if c.orders.authority == "consult":
			c.decision = true
			_operation_report("Solicito decisión: continuar, maniobrar o retirar. La fuerza mantiene posición; el calendario se detiene en esta decisión.")
			return false
		var average_hp = 0.0
		for index in state.active.team: average_hp += state.mechs[index].hp
		average_hp /= state.active.team.size()
		if c.orders.priority == "preserve" and average_hp < 65:
			_operation_report("La integridad media propia es inferior al umbral de preservación del 65%. Ordeno retirada conforme a la directiva.")
			cancel_contract("Retirada autónoma autorizada por prioridad de preservación")
			return false
		var choice = "maneuver" if c.orders.priority == "preserve" and state.supplies >= 4 else "press"
		_operation_report("Resuelvo dentro de la autoridad delegada: %s." % ("maniobrar para reducir exposición" if choice == "maneuver" else "continuar el encargo con los medios disponibles"))
		_apply_operation_choice(choice)
	return true

func decide_operation(choice: String) -> String:
	if state.ended or not military_waiting(): return "No hay decisión operacional pendiente."
	if not choice in ["press", "maneuver", "withdraw"]: return "Decisión inválida."
	if choice == "maneuver" and state.supplies < 4: return "Maniobrar requiere cuatro suministros disponibles."
	if choice == "withdraw": return cancel_contract("Retirada del comandante tras el parte de contacto")
	_apply_operation_choice(choice)
	return "Decisión confirmada por el jefe de campo. Puede continuar el calendario."

func _apply_operation_choice(choice: String):
	var c = state.military.current
	c.decision = false
	c.response = choice
	c.phase = "Ejecución"
	if choice == "maneuver":
		state.supplies -= 4
		state.active.remaining += 1
		c.private.bonus += 2
		c.private.damage -= 2
		_operation_report("Maniobra autorizada: cuatro suministros consumidos y un día adicional previsto; buscamos mejorar la posición y reducir exposición. No garantiza el objetivo.")
	else:
		var mitigation = int(person_by_id(state.active.leader).skill) / 3
		var pressure = maxi(0, int(c.private.severity) - mitigation)
		c.private.bonus -= pressure
		c.private.damage += pressure * 2
		_operation_report("Continuamos hacia el objetivo. El jefe adapta el avance según su experiencia; la oposición sigue sin confirmarse por completo.")

func _finish_operation(outcome: String):
	var c = state.military.current
	if c.is_empty(): return
	if not c.pending_order.is_empty(): _operation_report("La directiva en tránsito queda sin efecto al cerrarse la operación.")
	_operation_report("Fin de operación: " + outcome + ". Se verifica el estado de las unidades al regreso.")
	var losses = []
	for member in c.team:
		var index = mech_index(int(member.uid))
		losses.append({"name": member.name, "damage": maxi(0, int(member.hp) - int(state.mechs[index].hp)) if index >= 0 else int(member.hp)})
	state.military.archive.append({"id": c.id, "started": c.started, "ended": int(state.day), "contract": c.contract,
		"leader": c.leader, "outcome": outcome, "orders": c.orders.duplicate(true), "reports": c.reports.duplicate(true), "losses": losses})
	if state.military.archive.size() > 30: state.military.archive.pop_front()
	state.military.current = {}

func operation_report() -> Dictionary:
	return Operations.public_report(state.military, int(state.day))


func _catalog_ids(data: Variant, migrate: bool) -> bool:
	if not data is Dictionary or not data.get("mechs") is Array or not data.get("mech_market") is Array or not data.get("mech_orders") is Array: return false
	var records = data.mechs + data.mech_market
	for order in data.mech_orders:
		if not order is Dictionary or not order.get("mech") is Dictionary: return false
		records.append(order.mech)
	for item in records:
		if not item is Dictionary: return false
		if migrate:
			if not Operations.integer(item.get("model"), 0, MECH_CATALOG.size() - 1): return false
			item["model_id"] = MECH_CATALOG[int(item.model)].id
		else:
			var index = -1
			for i in range(MECH_CATALOG.size()):
				if MECH_CATALOG[i].id == item.get("model_id"): index = i
			if index < 0: return false
			item.model = index
	return true


func _init_lore(data: Dictionary):
	data["location_id"] = Universe.galatea()
	data["lore_contacts"] = {}

func contact_lore(id: String) -> String:
	var actor = Lore.get_actor(id)
	if state.ended or actor.is_empty() or actor.known_from > state.scenario_year: return "Contacto no disponible en este escenario."
	if state.lore_contacts.has(id): return "Ya existe un canal con esta entidad."
	if available_funds() < 1000: return "Se requieren 1.000 C-bills libres."
	state.funds -= 1000
	state.lore_contacts[id] = int(state.day)
	_record_transaction("Contactos", -1000, actor.name)
	log_event("Contacto", "Presentación formal ante %s. No implica alianza ni acceso a información militar privada." % actor.name)
	return "Canal registrado con " + actor.name

func _valid_lore(data: Dictionary) -> bool:
	if not data.get("location_id") is String or Universe.system(data.location_id).is_empty() or not data.get("lore_contacts") is Dictionary: return false
	for id in data.lore_contacts:
		var actor = Lore.get_actor(id)
		if actor.is_empty() or actor.known_from > data.scenario_year or not Operations.integer(data.lore_contacts[id],0,data.day): return false
	return true

func required_role(mech: Dictionary) -> String:
	return "Dotación" if MECH_CATALOG[int(mech.model)].kind == "vehicle" else "Piloto"

func unit_profile(index: int) -> Dictionary:
	return MECH_CATALOG[state.mechs[index].model].profile

func equipment_power(team: Array) -> int:
	var score = 0
	for index in team:
		var profile = unit_profile(index)
		score += int(profile.firepower + profile.protection)
	return clampi(int(score / maxi(1,team.size())) - 9,-2,2)

func accept_mission(id: int) -> String:
	if in_transit(): return "Acción local no disponible durante el traslado."
	if state.ended or not state.accepted.is_empty() or not state.active.is_empty(): return "Solo puede mantener un contrato activo."
	if state.contract_debt > 0: return "Debe saldar la deuda contractual."
	for contract in state.missions.offers:
		if contract.id != id: continue
		if contract.system_id != state.location_id or state.day >= contract.expires: return "Oferta fuera de ubicación o vencida."
		state.offers.append(contract.duplicate(true))
		var message = accept_contract(state.offers.size()-1)
		if not state.accepted.is_empty(): state.missions.offers.erase(contract)
		return message
	return "Oferta no disponible."

func configure_mission(tactic: String) -> String:
	if not tactic in ["careful","push"] or not state.active.is_empty(): return "Configure la prioridad antes del despliegue."
	state.missions.tactic = tactic
	return "Prioridad de objetivo actualizada; se aplica al próximo despliegue."

func _valid_missions(data: Dictionary) -> bool:
	if not Missions.valid(data.get("missions"),data.active): return false
	var contracts = data.missions.offers.duplicate()
	if data.accepted.has("mission_type"): contracts.append(data.accepted)
	for c in contracts:
		if not _valid_contract(c) or not Missions.valid_contract(c): return false
		if World.id_for_name(c.employer) != c.get("employer_id"): return false
		var actor = Lore.get_actor(c.employer_id)
		if actor.is_empty() or actor.known_from > data.scenario_year or not actor.employer: return false
		for k in ["advance","partial_pay","failure_pay","min_force","deadline"]:
			if not _number_between(c.get(k),0,1000000000): return false
	if data.active.has("equipment_power") and not Operations.integer(data.active.equipment_power,-2,2): return false
	if data.active.get("contract",{}).has("mission_type") and not data.active.has("objective"): return false
	return true

func in_transit() -> bool:
	return not state.get("travel",{}).is_empty()

func travel_quote(destination: String) -> Dictionary:
	if RPG.waiting(self) or RPG.busy(self): return {"error":"Resuelva la escena o preparación del capitán antes de partir."}
	if state.ended: return {"error":"La compañía ha cerrado operaciones."}
	if in_transit(): return {"error":"Ya hay un traslado en curso."}
	if not state.accepted.is_empty() or not state.active.is_empty(): return {"error":"Complete o cancele el contrato antes de trasladarse."}
	if not state.orders.is_empty() or not state.mech_orders.is_empty(): return {"error":"Espere las entregas pendientes antes de partir."}
	if not state.rpg.agenda.jobs.is_empty() or not state.rpg.delegation.jobs.is_empty(): return {"error":"Espere o cancele los encargos locales antes de partir."}
	if not state.story.objectives.jobs.is_empty() or not state.story.people.jobs.is_empty(): return {"error":"Espere la formación o los trabajos de su iniciativa antes de partir."}
	if not state.rpg.workshop.jobs.is_empty(): return {"error":"Espere los trabajos funcionales de taller."}
	if not state.repair_queue.is_empty(): return {"error":"Suspenda las reparaciones antes de embarcar."}
	if not state.issues.is_empty(): return {"error":"Resuelva las decisiones pendientes antes de partir."}
	var mass = 0
	for mech in state.mechs: mass += int(MECH_CATALOG[mech.model].mass)
	return Travel.quote(state.location_id,destination,mass)

func start_travel(destination: String, expected_cost: int = -1) -> String:
	var quote = travel_quote(destination)
	if quote.has("error"): return quote.error
	if expected_cost >= 0 and quote.cost != expected_cost: return "La cotización cambió. Revísela antes de partir."
	if available_funds() < quote.cost: return "Fondos libres insuficientes para el transporte."
	state.funds -= quote.cost
	_record_transaction("Transporte",-quote.cost,"Traslado a " + Universe.system(destination).name)
	quote["started"] = int(state.day)
	quote["arrival"] = int(state.day)+quote.days
	state.travel = quote
	log_event("Traslado","Embarque hacia %s: %d saltos, %d días estimados, %d C-bills. Salarios y mantenimiento siguen corriendo." % [Universe.system(destination).name,quote.hops,quote.days,quote.cost])
	return "Traslado iniciado. Avance el calendario para viajar."

func _travel_tick():
	if not in_transit() or state.day < state.travel.arrival: return
	state.location_id = state.travel.destination
	state.travel = {}
	_refresh_mech_market(state)
	_refresh_candidates()
	_refresh_offers()
	Missions.generate(state)
	log_event("Llegada","La compañía desembarca en %s. Se actualizaron mercado y solicitudes locales." % Universe.system(state.location_id).name)

func _valid_travel(data: Dictionary) -> bool:
	if not Travel.valid(data.get("travel"),data.location_id,int(data.day)): return false
	if not Lore.valid_activity(data.get("lore_activity"),int(data.scenario_year),int(data.day)): return false
	if not data.travel.is_empty() and (not data.accepted.is_empty() or not data.active.is_empty() or not data.orders.is_empty() or not data.mech_orders.is_empty()): return false
	return true

func local_services() -> bool:
	return not Universe.system(state.location_id).affiliations[str(state.scenario_year)] in ["U","A","X",""]

func rpg_command(action: String, args: Dictionary = {}) -> String:
	return RPG.command(self,action,args)

# Map encounters opt in at deployment; legacy API/save operations remain unchanged.
func dispatch_battle(team: Array, doctrine: int, leader: int = -1) -> String:
	if not state.active.is_empty():return "Ya hay una operación en curso."
	var message = dispatch(0,team,doctrine,leader)
	if state.active.is_empty() or state.military.current.has("battle"):return message
	var roster=[]
	for n in range(state.active.team.size()):
		var i=int(state.active.team[n]);var m=state.mechs[i];var p=pilot_for(i);var profile=unit_profile(i)
		roster.append({"uid":m.uid,"name":m.name,"hp":int(m.hp),"model":m.model_id,"group":"Alfa" if n<2 else "Bravo",
			"fire":int(profile.firepower),"speed":int(profile.mobility),"sensor":int(profile.recon),"armor":int(profile.protection)+(4 if state.active.get("rpg_support",false) else 0),
			"pilot":int(p.id),"value":state.story.people.profiles.get(str(p.id),{}).get("value","duty"),"skill":int(p.skill),"fatigue":int(p.fatigue),"vehicle":MECH_CATALOG[int(m.model)].kind=="vehicle"})
	var c=state.military.current
	c["battle"]=Battle.create(int(state.military.seed)+int(c.id)*7919,roster,state.active.contract.get("mission_type", "recon" if state.active.contract.name.contains("Patrulla") else "recovery" if state.active.contract.name.contains("depósito") else "escort"),state.active.contract.get("terrain","llanura"),int(state.active.contract.difficulty),["careful","balanced","aggressive"][doctrine],int(state.active.get("rpg_danger",100)))
	c["battle_reported"]=false
	return "Despliegue autorizado. Abra el mapa o delegue el encuentro y avance el calendario para el regreso."

func battle_view() -> Dictionary:
	return Battle.public_view(state.military.current.get("battle",{}))

func battle_order(group: String, order: String, attitude: String, x: int, y: int) -> String:
	if state.ended or not state.military.current.has("battle"):return "No hay encuentro activo."
	return Battle.issue(state.military.current.battle,group,order,attitude,x,y)

func battle_step(steps: int = 1) -> void:
	if state.ended or not state.military.current.has("battle"):return
	var b=state.military.current.battle
	for i in range(clampi(steps,1,240)):
		Battle.tick(b)
		if b.done or not b.alert.is_empty():break
	if b.done:_battle_report()

func battle_delegate() -> String:
	if not state.military.current.has("battle"):return "No hay encuentro activo."
	Battle.run(state.military.current.battle)
	_battle_report()
	return "Encuentro resuelto según sus órdenes. Avance el calendario para el regreso y la liquidación."

func _battle_report():
	var c=state.military.current
	if not c.has("battle") or c.get("battle_reported",false):return
	c.battle_reported=true
	# Only commander-visible events enter the chronicle, linked to the operation.
	var events=c.battle.events
	for e in events.slice(maxi(0,events.size()-12)):
		_operation_report("T+%ds · %s"%[int(e.tick)*10,e.text])
	_operation_report("Balance de campo: %s; objetivo %d%%. Daños reales pendientes de registro al regreso."%[Battle.RESULT_LABELS[c.battle.result],c.battle.progress])

func _battle_memories(b: Dictionary):
	for u in b.units:
		if u.side != "own" or u.get("pilot",-1) < 0: continue
		var text = "Participó en el encuentro; el plan consiguió %d%% del objetivo." % b.progress
		if u.hp <= 0: text = "Su unidad quedó inmovilizada durante el encuentro y fue recuperada; necesita atención médica."
		elif u.escaped: text = "Alcanzó la extracción conforme a las órdenes de retirada; conserva el recuerdo del repliegue."
		elif u.hp < u.initial_hp: text = "Regresó del encuentro con %d puntos de daño en su unidad." % (u.initial_hp-u.hp)
		Story.People.remember(self,int(u.pilot),text)
