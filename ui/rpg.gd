extends AcceptDialog
signal campaign_changed(message: String)
var sim
var embedded=false
var content: VBoxContainer
var message = ""
var page = "Escena"
var custom_delegation=false
func _ready():
 if embedded:return
 title = "Capitán · escenas y diario"
 ok_button_text = "Volver al mando"
 var scroll = ScrollContainer.new()
 scroll.custom_minimum_size = Vector2(940,620)
 add_child(scroll)
 content = VBoxContainer.new()
 content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 content.add_theme_constant_override("separation",12)
 scroll.add_child(content)
 if sim.RPG.Delegation.waiting(sim):page="Oficiales"
 if sim.state.rpg.arcs.retired:page="Legado"
 rebuild()
 close_requested.connect(queue_free)
 confirmed.connect(queue_free)
func line(text: String):
 var label = Label.new()
 label.custom_minimum_size.x = 0 if embedded else 900
 label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 label.text = text
 content.add_child(label)
func picker(caption: String, values: Dictionary) -> OptionButton:
 line(caption)
 var control = OptionButton.new()
 control.fit_to_longest_item=not embedded
 for key in values:
  control.add_item(str(values[key]))
  control.set_item_metadata(control.item_count-1,key)
 content.add_child(control)
 return control
func act(label: String, action: String, args: Dictionary = {}):
 var button = Button.new()
 button.text = label
 button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 button.pressed.connect(func(): execute(action,args))
 content.add_child(button)
func execute(action: String, args: Dictionary):
 message = sim.rpg_command(action,args)
 campaign_changed.emit(message)
 rebuild()
func rebuild():
 if embedded:return
 for child in content.get_children():
  content.remove_child(child)
  child.queue_free()
 if sim.state.rpg.captain.configured:
  var tabs=HFlowContainer.new()
  content.add_child(tabs)
  for name in ["Escena","Personaje","Asuntos","Agenda","Contratos","Taller","Región","Oficiales","Memoria","Legado"]:
   var tab=Button.new()
   tab.text=name
   tab.toggle_mode=true
   tab.button_pressed=page==name
   tab.pressed.connect(func():page=name;rebuild())
   tabs.add_child(tab)
 if not message.is_empty(): line(message)
 if not sim.state.rpg.captain.configured:
  line("El nombre se cambia desde Campaña. El trasfondo se establece una sola vez; las competencias iniciales parten de 2, con +1 por origen y +1 por especialidad. No altera su nómina ni las operaciones existentes.")
  var origin = picker("Origen: oficial → Mando; familia mercenaria → Trato; técnico → Investigación",sim.RPG.ORIGINS)
  var specialty = picker("Especialidad",sim.RPG.SKILLS)
  var motive = picker("Motivación",sim.RPG.MOTIVES)
  var people = {-1:"Sin vínculo inicial"}
  for person in sim.state.staff: people[person.id] = person.name
  var bond = picker("Vínculo inicial: una persona apta facilita transporte auxiliar",people)
  var button = Button.new()
  button.text = "Establecer trasfondo"
  button.pressed.connect(func(): execute("configure",{"origin":origin.get_item_metadata(origin.selected),"specialty":specialty.get_item_metadata(specialty.selected),"motivation":motive.get_item_metadata(motive.selected),"bond":bond.get_item_metadata(bond.selected)}))
  content.add_child(button)
 if page=="Oficiales" and sim.state.rpg.captain.configured:
  var toggle=Button.new()
  toggle.text="Ocultar encargo a medida" if custom_delegation else "Configurar encargo: elegir oficial, enlace, presupuesto, plazo y autoridad"
  toggle.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
  toggle.pressed.connect(func():custom_delegation=not custom_delegation;rebuild())
  content.add_child(toggle)
  if custom_delegation:delegation_form()
 for section in sim.RPG.view(sim):
  if sim.state.rpg.captain.configured and section.get("page","Escena")!=page:continue
  line(section.title.to_upper())
  line(section.text)
  for choice in section.actions: act(choice.label,choice.action,choice.args)
func amount(caption: String,low: int,high: int,value: int,step: int=1) -> SpinBox:
 line(caption)
 var box=SpinBox.new()
 box.min_value=low
 box.max_value=high
 box.step=step
 box.value=value
 content.add_child(box)
 return box
func delegation_form():
 line("ENCARGO A MEDIDA")
 var people={}
 for p in sim.state.staff:people[p.id]=p.name+" · "+p.role
 var contacts={}
 for name in sim.RPG.Agenda.known(sim):contacts[name]=name
 if people.is_empty() or contacts.is_empty():line("Se necesita personal y un enlace conocido.");return
 var person=picker("Oficial",people)
 var contact=picker("Enlace",contacts)
 var objective=picker("Objetivo",sim.RPG.Delegation.OBJECTIVES)
 var authority=picker("Autoridad",{"consult":"Consultar al superar el umbral","delegate":"Resolver dentro del presupuesto máximo"})
 var units={-1:"Sin unidad (solo suministro o representación)"}
 for m in sim.state.mechs:units[m.uid]=m.name+" #"+str(m.uid)
 var unit=picker("Unidad reservada para apoyo de seguridad",units)
 var budget=amount("Presupuesto máximo en depósito (C-bills)",3000,20000,8000,1000)
 var threshold=amount("Consultar por encima de (C-bills)",0,20000,3000,1000)
 var days=amount("Plazo (días)",4,14,5)
 var button=Button.new()
 button.text="Autorizar encargo con estas condiciones"
 button.pressed.connect(func():execute("delegation",{"action":"assign","person":person.get_item_metadata(person.selected),"contact":contact.get_item_metadata(contact.selected),"objective":objective.get_item_metadata(objective.selected),"authority":authority.get_item_metadata(authority.selected),"uid":unit.get_item_metadata(unit.selected),"budget":int(budget.value),"threshold":int(threshold.value),"days":int(days.value)}))
 content.add_child(button)
