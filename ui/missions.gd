extends AcceptDialog
signal campaign_changed(message: String)
var sim
var content: VBoxContainer
func _ready():
 title = "Misiones locales · contratos procedurales"
 var scroll = ScrollContainer.new()
 scroll.custom_minimum_size = Vector2(900,600)
 add_child(scroll)
 content = VBoxContainer.new()
 content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 scroll.add_child(content)
 rebuild()
func line(message: String):
 var label = Label.new()
 label.custom_minimum_size.x = 860
 label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 label.text = message
 content.add_child(label)
func rebuild():
 for child in content.get_children():
  content.remove_child(child)
  child.queue_free()
 if sim.in_transit(): line("EN TRÁNSITO: solicitudes de la última base, disponibles para lectura. Nuevas ofertas al desembarcar.")
 line("Cinco objetivos distintos. Nuevas solicitudes cada 14 días. Elegí la prioridad en Mando de operaciones antes de desplegar.")
 for contract in sim.state.missions.offers:
  line("\n%s · %s · %s" % [contract.name,contract.employer,contract.terrain])
  line(contract.cause + ". " + contract.objective + ". " + contract.intel)
  line("%s\nPago total: completo %d / parcial %d / fallo %d. Anticipo %d. Mínimo %d elementos. Despliegue en 5 días; oferta vence en %d días." % [contract.briefing,contract.pay,contract.partial_pay,contract.failure_pay,contract.advance,contract.min_force,contract.expires-sim.state.day])
  var button = Button.new()
  button.text = "Aceptar · " + contract.name
  button.disabled = sim.in_transit() or not sim.state.accepted.is_empty() or sim.state.day >= contract.expires
  button.pressed.connect(func():
   var message = sim.accept_mission(contract.id)
   campaign_changed.emit(message)
   rebuild()
   line(message))
  content.add_child(button)
 if sim.state.missions.offers.is_empty(): line("No hay solicitudes nuevas. Espere al próximo boletín.")
