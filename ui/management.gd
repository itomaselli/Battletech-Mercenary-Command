extends AcceptDialog
signal campaign_changed(message: String)
var sim
var embedded=false
var selected_person=-1
var selected_unit=-1
var embed_refresh: Callable
var tabs: TabContainer
var message: Label
var dossier_id = -1
var world_actor_id = "trade_league"

func _ready():
	if embedded: return
	title = "Administración de la compañía"
	ok_button_text = "Cerrar"
	var box = VBoxContainer.new()
	box.custom_minimum_size = Vector2(850, 470)
	add_child(box)
	message = Label.new()
	message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(message)
	var navigation = HFlowContainer.new()
	box.add_child(navigation)
	for spec in [["Personal", 0], ["Expedientes", 6], ["Hangar", 4], ["Taller", 1], ["Asuntos", 3], ["Mercado", 5], ["Finanzas", 2], ["Relaciones", 7]]:
		var button = Button.new()
		button.text = spec[0]
		button.pressed.connect(func(): tabs.current_tab = spec[1])
		navigation.add_child(button)
	tabs = TabContainer.new()
	tabs.tabs_visible = false
	tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(tabs)
	rebuild()
	visibility_changed.connect(func():
		if not visible: queue_free())

func text_line(parent: Node, text: String):
	var label = Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	parent.add_child(label)

func action(parent: Node, caption: String, callback: Callable):
	var button = Button.new()
	button.text = caption
	button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	button.pressed.connect(func():
		var result = callback.call()
		message.text = result
		campaign_changed.emit(result)
		rebuild())
	parent.add_child(button)

func page(caption: String) -> VBoxContainer:
	var scroll = ScrollContainer.new()
	scroll.name = caption
	tabs.add_child(scroll)
	var content = VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 10)
	scroll.add_child(content)
	return content

func rebuild():
	if embedded:
		if embed_refresh.is_valid(): embed_refresh.call_deferred()
		return
	var current = maxi(0, tabs.current_tab)
	for child in tabs.get_children():
		tabs.remove_child(child)
		child.queue_free()
	personnel_page(page("Personal"))
	logistics_page(page("Taller y suministros"))
	finance_page(page("Finanzas"))
	issues_page(page("Asuntos y relaciones"))
	hangar_page(page("Hangar"))
	market_page(page("Mercado"))
	dossiers_page(page("Expedientes"))
	world_page(page("Mundo"))
	tabs.current_tab = mini(current, tabs.get_tab_count() - 1)

func personnel_page(parent: Node):
	text_line(parent, "Nómina mensual: %d C-bills. Despedir cuesta un salario y exige saldar deudas. Los desplegados no pueden cambiar de destino." % sim.monthly_payroll())
	for i in range(sim.state.mechs.size()):
		text_line(parent, sim.state.mechs[i].name)
		var picker = OptionButton.new()
		picker.add_item("Sin piloto", 0)
		var ids = [-1]
		for person in sim.state.staff:
			if person.role == sim.required_role(sim.state.mechs[i]):
				ids.append(int(person.id))
				picker.add_item("%s · habilidad %d · baja %d días" % [person.name, person.skill, person.injury])
		picker.selected = ids.find(int(sim.state.mechs[i].pilot_id))
		picker.disabled = sim.deployed(i) or sim.state.mechs[i].stored
		picker.item_selected.connect(func(index):
			var result = sim.assign_pilot(i, ids[index])
			message.text = result
			campaign_changed.emit(result)
			rebuild())
		parent.add_child(picker)
	text_line(parent, "PLANTILLA / RESERVAS")
	for person in sim.state.staff:
		var assignment = "Reserva" if person.role == "Piloto" else "Apoyo"
		for mech in sim.state.mechs:
			if mech.pilot_id == person.id: assignment = mech.name
		text_line(parent, "%s · %s · habilidad %d · %d/mes · %s\nFatiga %d/100 · experiencia %d · baja %d días · permiso restante %d días" % [person.name, person.role, person.skill, person.salary, assignment, person.fatigue, person.experience, person.injury, maxi(0, int(person.rest_until - sim.state.day))])
		action(parent, "Despedir a %s · indemnización %d" % [person.name, person.salary], func(): return sim.dismiss(person.id))
	text_line(parent, "CANDIDATOS · Nuevos cada 30 días")
	for i in range(sim.state.candidates.size()):
		var candidate = sim.state.candidates[i]
		text_line(parent, "%s · %s · habilidad %d · salario %d/mes" % [candidate.name, candidate.role, candidate.skill, candidate.salary])
		action(parent, "Contratar · incorporación %d" % candidate.fee, func(): return sim.hire(i))

func logistics_page(parent: Node):
	text_line(parent, "Taller: %d unidades por día. 10%% de integridad por unidad, 1.000 C-bills y 2 suministros. Estimaciones sujetas a recursos y personal disponible." % sim.workshop_capacity())
	for estimate in sim.repair_estimates():
		text_line(parent, "%s · plazo %s · coste restante %d · suministros %d" % [sim.state.mechs[estimate.mech].name, "%d días" % estimate.days if estimate.days >= 0 else "sin técnicos", estimate.cost, estimate.supplies])
		action(parent, "Dar prioridad", func(): return sim.prioritize_repair(estimate.mech))
	text_line(parent, "PEDIDOS · 50% al confirmar y 50% reservado hasta la entrega")
	for urgent in [false, true]:
		var quote = sim.supply_quote(urgent)
		action(parent, "%s: 30 suministros · %d C-bills · %d días · descuento %d%%" % ["Urgente" if urgent else "Normal", quote.cost, quote.days, quote.discount], func(): return sim.order_supplies(urgent))
	for order in sim.state.orders:
		text_line(parent, "Pedido #%d · %d suministros · llega en %d días · saldo reservado %d" % [order.id, order.quantity, order.due - sim.state.day, order.balance])

func finance_page(parent: Node):
	var report = sim.financial_report()
	text_line(parent, "Caja: %d · reservado para entregas: %d · libre: %d" % [sim.state.funds, report.reserved, report.free])
	text_line(parent, "Próxima nómina en %d días: %d. Deuda salarial: %d. Deuda contractual: %d." % [report.next_payroll - sim.state.day, report.payroll, sim.state.arrears, sim.state.contract_debt])
	text_line(parent, "Propiedad: %d/día · devengado %d · vencido %d · próxima factura estimada %d en %d días." % [report.ownership.daily, report.ownership.accrued, report.ownership.debt, report.ownership.next_bill, report.ownership.days])
	text_line(parent, "Taller autorizado: %d en total; estimado a 30 días: %d. Proyección de caja a 30 días: %d C-bills." % [report.repairs, report.repairs_30, report.projected])
	text_line(parent, "Cobro adicional condicionado al éxito: %d (excluido de la proyección). La previsión asume plantilla y taller actuales, recursos suficientes y ninguna compra nueva; descuenta deudas, entregas, nómina y la próxima factura de propiedad." % report.conditional)
	action(parent, "Pagar deuda salarial con fondos libres", func(): return sim.settle_arrears())
	action(parent, "Pagar deuda contractual con fondos libres", func(): return sim.settle_contract_debt())
	action(parent, "Pagar mantenimiento vencido", func(): return sim.settle_ownership_debt())
	text_line(parent, "INGRESOS / GASTOS desde el inicio de este registro")
	for category in report.categories:
		text_line(parent, "%s · ingresos %d · gastos %d" % [category, report.categories[category].income, report.categories[category].expense])
	text_line(parent, "MOVIMIENTOS (más recientes primero)")
	for i in range(sim.state.ledger.size() - 1, -1, -1):
		var entry = sim.state.ledger[i]
		text_line(parent, "Día %d · %s · %+d · %s" % [entry.day, entry.category, entry.amount, entry.detail])

func issues_page(parent: Node):
	text_line(parent, "ASUNTOS PENDIENTES · El calendario se detiene hasta que decida.")
	if sim.state.issues.is_empty(): text_line(parent, "No hay decisiones urgentes.")
	for issue in sim.state.issues:
		text_line(parent, issue.text)
		if issue.kind == "deadline":
			action(parent, "Mantener compromiso y plazo", func(): return sim.resolve_issue(issue.id, "continue"))
			action(parent, "Cancelar · devolver anticipo; reputación -1, confianza -2, moral -5", func(): return sim.resolve_issue(issue.id, "cancel"))
		elif issue.kind == "medical":
			action(parent, "Atención especializada · 2.000 · baja -3 días · moral +2", func(): return sim.resolve_issue(issue.id, "care"))
			action(parent, "Mantener tratamiento habitual · sin coste adicional", func(): return sim.resolve_issue(issue.id, "standard"))
		elif issue.kind == "team_conflict":
			action(parent, "Revisión conjunta · dos días sin despliegue · vínculo +2", func(): return sim.resolve_issue(issue.id, "mediate"))
			action(parent, "Separar asignaciones · segundo piloto a reserva · vínculo +1", func(): return sim.resolve_issue(issue.id, "separate"))
		else:
			action(parent, "Pagar toda la deuda salarial", func(): return sim.resolve_issue(issue.id, "pay"))
			action(parent, "Aceptar salida · moral -5; la deuda permanece", func(): return sim.resolve_issue(issue.id, "release"))
	text_line(parent, "RELACIONES CON EMPLEADORES · escala -5 a +5")
	for employer in sim.state.relationships:
		text_line(parent, "%s: %+d" % [employer, sim.state.relationships[employer]])
	text_line(parent, "El éxito aumenta confianza; el fracaso y el incumplimiento la reducen. Las próximas ofertas ajustan el pago y el porcentaje de anticipo.")

func confirm_action(parent: Node, caption: String, details: String, callback: Callable):
	var button = Button.new()
	button.text = caption
	button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	button.pressed.connect(func():
		var confirm = ConfirmationDialog.new()
		confirm.title = "Confirmar orden"
		confirm.dialog_text = details
		confirm.confirmed.connect(func():
			var result = callback.call()
			message.text = result
			campaign_changed.emit(result)
			rebuild())
		confirm.visibility_changed.connect(func():
			if not confirm.visible: confirm.queue_free())
		if embedded: get_parent().add_child(confirm)
		else: add_child(confirm)
		confirm.popup_centered(Vector2i(650, 220)))
	parent.add_child(button)

func hangar_page(parent: Node):
	text_line(parent, "HANGAR: %d/%d plazas ocupadas o reservadas. Máximo cuatro máquinas por operación." % [sim.hangar_used(), sim.MAX_HANGAR])
	text_line(parent, "Precios ajustados para el prototipo; no son cotizaciones oficiales de BattleTech. Los perfiles de cada modelo influyen en las operaciones y los objetivos de misión.")
	text_line(parent, "FLOTA EN PROPIEDAD")
	if sim.state.mechs.is_empty(): text_line(parent, "No hay máquinas. Puede comprar una en el mercado para volver a operar.")
	for mech in sim.state.mechs:
		if embedded and selected_unit>=0 and mech.uid!=selected_unit: continue
		unit_picture(parent,sim.MECH_CATALOG[mech.model])
		var index = sim.mech_index(mech.uid)
		var pilot = sim.pilot_for(index)
		var price = sim.sale_quote(mech.uid)
		text_line(parent, "#%d %s · integridad %d%% · %s" % [mech.uid, mech.name, mech.hp, "sin piloto" if pilot.is_empty() else pilot.name])
		var work = ceili((100 - mech.hp) / 10.0)
		text_line(parent, "Propiedad %d/30 días · reparar al 100%%: %d + %d suministros · venta actual %d" % [sim.mech_daily_cost(mech) * 30, work * 1000, work * 2, price])
		if mech.stored:
			action(parent, "Reactivar #%d · 1.000 C-bills · 2 días" % mech.uid, func(): return sim.set_stored(mech.uid, false))
		elif mech.ready_day > sim.state.day:
			text_line(parent, "Reactivación en curso: %d días." % (mech.ready_day - sim.state.day))
		elif not sim.deployed(index) and not mech.repair:
			confirm_action(parent, "Almacenar #%d · 300 C-bills/30 días" % mech.uid, "¿Almacenar %s? Su piloto queda en reserva.\nNo podrá desplegar ni reparar hasta reactivarlo: 1.000 C-bills y dos días.\nLos costes ya devengados siguen pendientes." % mech.name, func(): return sim.set_stored(mech.uid, true))
		var reason = sim.sale_block_reason(mech.uid)
		if reason.is_empty():
			confirm_action(parent, "Vender #%d · %d C-bills" % [mech.uid, price], "¿Vender %s #%d por %d C-bills?\nLa máquina deja la compañía; su piloto queda en reserva.\nLa venta puede reducir su capacidad de cumplir contratos.\nLos costes de propiedad ya devengados se conservan." % [mech.name, mech.uid, price], func(): return sim.sell_mech(mech.uid, price))
		else: text_line(parent, reason)
	text_line(parent, "EN TRÁNSITO · compras pagadas, entrega garantizada")
	for order in sim.state.mech_orders:
		text_line(parent, "#%d %s · %d%% · llega en %d días" % [order.mech.uid, order.mech.name, order.mech.hp, order.due - sim.state.day])
func market_page(parent: Node):
	action(parent, "Catálogo · filtros y comparación", func():
		var browser = preload("res://ui/catalog.gd").new()
		browser.sim = sim
		add_child(browser)
		browser.popup_centered(Vector2i(1000,680))
		return "Catálogo abierto.")
	text_line(parent, "Plazas ocupadas/reservadas: %d/%d · fondos libres %d C-bills" % [sim.hangar_used(), sim.MAX_HANGAR, sim.available_funds()])
	text_line(parent, "MERCADO · Ofertas nuevas cada 14 días")
	for offer in sim.state.mech_market:
		var model = sim.MECH_CATALOG[offer.model]
		unit_picture(parent,model)
		var work = ceili((100 - offer.hp) / 10.0)
		text_line(parent, "Lote #%d · %s · %d%% · %d C-bills\nEntrega %d días · oferta vence en %d días. Reparación al 100%%: %d C-bills + %d suministros, %d jornadas de taller." % [offer.id, model.name, offer.hp, offer.price, offer.days, offer.expires - sim.state.day, work * 1000, work * 2, work])
		var estimate = sim.acquisition_estimate(offer.id)
		text_line(parent, "Comparación: compra + reparación + valor de suministros + 30 días activo = %d. Propiedad activa: %d/30 días; almacenado: 300. Reventa en este estado: %d.\nLos suministros se venden por lotes de 30; el valor indicado es proporcional. La reparación usa la cola existente." % [estimate.total, estimate.monthly, estimate.resale])
		confirm_action(parent, "Comprar lote #%d · %d C-bills" % [offer.id, offer.price], "¿Comprar %s al %d%% por %d C-bills?\nPago completo ahora. Entrega en %d días; reserva una plaza.\nSin piloto incluido. Reparar requiere %d C-bills y %d suministros." % [model.name, offer.hp, offer.price, offer.days, work * 1000, work * 2], func(): return sim.purchase_mech(offer.id, offer.price))

func dossiers_page(parent: Node):
	text_line(parent, "EXPEDIENTES · Ascensos, descansos y recuerdos del personal.")
	var people = sim.state.staff + sim.state.alumni
	if people.is_empty():
		text_line(parent, "Todavía no hay expedientes.")
		return
	var ids = []
	var picker = OptionButton.new()
	for person in people:
		ids.append(int(person.id))
		picker.add_item(person.name + (" · baja" if person.has("departure_day") else ""))
	if not dossier_id in ids: dossier_id = ids[0]
	picker.selected = ids.find(dossier_id)
	picker.item_selected.connect(func(index):
		dossier_id = ids[index]
		rebuild())
	parent.add_child(picker)
	var person = people[ids.find(dossier_id)]
	parent.add_child(preload("res://visual/art.gd").portrait_view(int(sim.state.military.seed), int(person.id), 4))
	text_line(parent, "%s · %s · %s\nHabilidad %d · salario %d/mes · experiencia %d · operaciones %d · éxitos %d" % [person.name, person.role, sim.career_rank(person), person.skill, person.salary, person.experience, person.missions, person.victories])
	if person.has("departure_day"):
		text_line(parent, "Salida el día %d: %s. Expediente archivado; no recibe órdenes." % [person.departure_day, person.departure_reason])
	else:
		text_line(parent, "Fatiga %d/100 · lesión %d días · permiso %d días. Con fatiga 80 o más no puede trabajar ni desplegar. En base recupera 6/día; en permiso 14/día. La fatiga reduce la contribución al combate." % [person.fatigue, person.injury, maxi(0, int(person.rest_until - sim.state.day))])
		confirm_action(parent, "Conceder descanso a %s · 3 días" % person.name, "¿Conceder tres días de descanso a %s?\nNo estará disponible para operaciones o apoyo; conserva el salario." % person.name, func(): return sim.grant_leave(person.id))
		if sim.promotion_eligible(person.id):
			confirm_action(parent, "Ascender a %s · 3.000 C-bills" % person.name, "¿Ascender a %s?\nCoste 3.000, habilidad +1 y salario +1.000/mes." % person.name, func(): return sim.promote(person.id))
		else:
			text_line(parent, "Ascenso: requiere %d de experiencia y habilidad inferior a 5; máximo dos ascensos." % ((person.promotions + 1) * 6))
	text_line(parent, "COMPAÑEROS · Vínculos basados en operaciones compartidas; efecto de cohesión limitado.")
	for bond in sim.state.bonds.values():
		if bond.a == person.id or bond.b == person.id:
			var other = bond.b if bond.a == person.id else bond.a
			text_line(parent, "%s: %s (%+d), %d operaciones juntos." % [sim.person_name(other), sim.bond_description(bond.score), bond.score, bond.shared])
	text_line(parent, "HISTORIA PERSONAL · Más reciente primero")
	if person.memories.is_empty(): text_line(parent, "Sin acontecimientos registrados todavía.")
	for i in range(person.memories.size() - 1, -1, -1):
		var memory = person.memories[i]
		text_line(parent, "Día %d · %s" % [memory.day, memory.text])

func world_page(parent: Node):
	var report = sim.world_report()
	text_line(parent, "DIRECTORIO LOCAL · Galatea · Registro disponible desde el día %d. Reputación general de la compañía: %+d." % [report.introduced_day, report.reputation])
	var picker = OptionButton.new()
	var ids = []
	for actor in report.actors:
		ids.append(actor.id)
		picker.add_item(actor.name + " · " + actor.kind)
	if not world_actor_id in ids: world_actor_id = ids[0]
	picker.selected = ids.find(world_actor_id)
	picker.item_selected.connect(func(index):
		world_actor_id = ids[index]
		rebuild())
	if not embedded: parent.add_child(picker)
	else: picker.free()
	var actor = report.actors[ids.find(world_actor_id)]
	text_line(parent, "%s · %s\n%s\nEspecialidad declarada: %s\nInterés declarado: %s" % [actor.name, actor.kind, actor.affiliation, actor.specialty, actor.interest])
	text_line(parent, "Informe del día %d. %s\n%s" % [actor.reported_day, actor.source, actor.strength_report])
	text_line(parent, "Confianza hacia nuestra compañía: %+d · %s. Esta relación es distinta de la reputación general." % [actor.trust, "con antecedentes registrados" if actor.has_history else "sin antecedentes de trabajo registrados"])
	if actor.contact_day >= 0:
		text_line(parent, "Canal de contacto establecido el día %d." % actor.contact_day)
	else:
		confirm_action(parent, "Establecer contacto · 1.000 C-bills", "¿Registrar un canal con %s por 1.000 C-bills?\nEs una presentación formal. No aumenta confianza ni garantiza contratos." % actor.name, func(): return sim.establish_contact(actor.id))
	text_line(parent, "VÍNCULOS CONOCIDOS · Informes, no garantías de conducta")
	var found = false
	for link in report.links:
		if link.a == actor.id or link.b == actor.id:
			var other_id = link.b if link.a == actor.id else link.a
			var other_name = other_id
			for other in report.actors:
				if other.id == other_id: other_name = other.name
			text_line(parent, "%s: %s. Fuente: %s (día %d)." % [other_name, link.stance, link.source, link.reported_day])
			found = true
	if not found: text_line(parent, "No hay vínculos públicos registrados.")
	text_line(parent, "ACTIVIDAD COMUNICADA · Resultados declarados; no indican disponibilidad actual")
	var bulletins = report.bulletins.duplicate()
	bulletins.reverse()
	var shown = 0
	for bulletin in bulletins:
		if bulletin.actor_id != actor.id and bulletin.employer_id != actor.id: continue
		text_line(parent, "Día %d · %s\nFuente: %s." % [bulletin.day, bulletin.text, bulletin.source])
		shown += 1
		if shown >= 8: break
	if shown == 0: text_line(parent, "Sin comunicados recibidos de esta organización.")
	var frontier = sim.frontier_report(actor.id)
	text_line(parent, "INFORMES DEL CONTACTO")
	if frontier.pending: text_line(parent, "Consulta en curso; respuesta prevista dos días después del envío.")
	if not frontier.report.is_empty():
		var r = frontier.report
		text_line(parent, "Observado día %d · Recibido día %d · %s\n%s\nFuente: %s" % [r.observed, r.received, "Información antigua: solicitar actualización" if r.stale else "Información reciente; puede haber cambiado", r.text, r.source])
	if actor.contact_day >= 0:
		confirm_action(parent, "Solicitar informe · %d C-bills"%sim.HQ.price(sim,"intelligence",500), "¿Consultar al contacto? Coste: %d C-bills; demora: dos días. Es su declaración, no una verificación independiente."%sim.HQ.price(sim,"intelligence",500), func(): return sim.request_world_report(actor.id))
	text_line(parent, "OPORTUNIDADES DEL MUNDO")
	var statuses = {"open": "Disponible", "accepted": "Aceptada", "completed": "Cumplida", "failed": "Incumplida", "expired": "Vencida", "withdrawn": "Retirada"}
	if frontier.opportunities.is_empty(): text_line(parent, "No hay solicitudes extraordinarias registradas.")
	var recent = frontier.opportunities.duplicate()
	recent.reverse()
	for o in recent.slice(0, 8):
		text_line(parent, "%s · %s\n%s Fuente: %s (día %d).\nPago %d · Anticipo %d · Mínimo %d máquinas · Duración base %d días · Oferta hasta día %d (vence al comenzar ese día)." % [o.name, statuses[o.status], o.cause, o.source, o.created, o.pay, o.advance, o.min_force, o.days, o.expires])
		if o.status == "open":
			if embedded: continue
			confirm_action(parent, "Aceptar oportunidad #%d" % o.id, "¿Aceptar %s? Recibirá %d de anticipo y tendrá cinco días para desplegar. El incumplimiento exige devolver el anticipo y perjudica confianza, reputación y moral." % [o.name, o.advance], func(): return sim.accept_opportunity(o.id))
	text_line(parent, actor.fiction)

func unit_picture(parent: Node, model: Dictionary):
	var row = HBoxContainer.new()
	parent.add_child(row)
	var picture = TextureRect.new()
	picture.texture = ImageTexture.create_from_image(preload("res://visual/art.gd").unit_sprite(model.id))
	picture.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	picture.custom_minimum_size = Vector2(48,72)
	picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	picture.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	picture.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_theme_constant_override("separation", 12)
	row.add_child(picture)
	var description = Label.new()
	description.text = "%s · %d t · %d · %s" % [model.name,model.mass,model.year,"Dotación terrestre (4 integrantes)" if model.kind == "vehicle" else "MechWarrior"]
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	description.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(description)
