extends Control
const Campaign=preload("res://sim/campaign.gd")
const UI=preload("res://ui/components.gd")
const ROUTES={"Mando":["Bandeja","Agenda","Crónica"],"Compañía":["Personal","Hangar","Taller"],"Operaciones":["Resumen","Contratos","Plan","Batalla","Informe","Encargos"],"Mundo":["Atlas","Entorno","Región","Contactos"],"Mercado":["Unidades","Catálogo","Repuestos","Personal"],"Finanzas":["Previsión"],"Capitán":["Personaje","Asuntos","Legado"],"Campaña":["Partidas","Identidad","Opciones"]}
var sim=Campaign.new()
var library=preload("res://sim/campaign_library.gd").new()
var active_path=""
var has_campaign=false
var testing=false
var wizard

var route="Mando"
var section="Bandeja"
var history=[]
var preferences={}
var content: VBoxContainer
var scroll: ScrollContainer
var tabs: HFlowContainer
var sidebar: VBoxContainer
var status: Label
var stats: Label
var title: Label
var continue_button: Button
var one_day_button: Button
var save_button: Button
var adapters=[]
var admin
var operations_adapter
var rpg_adapter
var settings=preload("res://visual/settings.gd").new()
var terminal_material: ShaderMaterial
var selected=[]
var doctrine=1
var leader_id=-1
var atlas
var rendered_key=""
func _ready():
 theme=preload("res://visual/style.gd").build()
 settings.load_settings()
 get_viewport().gui_embed_subwindows=true
 var margin=MarginContainer.new()
 margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 for side in ["left","right","top","bottom"]:margin.add_theme_constant_override("margin_"+side,14)
 add_child(margin)
 var root=UI.column(margin)
 title=UI.text(root,"MERCENARY COMMAND · v0.44",true)
 stats=UI.text(root,"")
 var top=HFlowContainer.new();root.add_child(top)
 UI.muted(top,"CALENDARIO")
 UI.button(top,"← Volver",back)
 continue_button=UI.button(top,"Continuar · hasta 7 días",func():advance_days(7))
 one_day_button=UI.button(top,"+1 día",func():advance_days(1))
 save_button=UI.button(top,"Guardar",save_current)
 UI.button(top,"Campaña",func():navigate("Campaña","Partidas"))
 for button in top.get_children():
  if button is Button:button.custom_minimum_size.x=250 if button==continue_button else 110
 var body=HBoxContainer.new();body.size_flags_vertical=Control.SIZE_EXPAND_FILL;root.add_child(body)
 sidebar=UI.column(body);sidebar.custom_minimum_size.x=165;sidebar.size_flags_horizontal=Control.SIZE_FILL
 for key in ROUTES:
  if key=="Campaña":continue
  var b=UI.button(sidebar,key,func():navigate(key,ROUTES[key][0]));b.name=key
 var page=UI.column(body)
 tabs=HFlowContainer.new();page.add_child(tabs)
 scroll=ScrollContainer.new();scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL;page.add_child(scroll)
 content=UI.column(scroll)
 status=UI.text(root,"Seleccione una entrada para ver contexto y acciones.")
 admin=preload("res://ui/management.gd").new();admin.embedded=true;admin.sim=sim;admin.message=Label.new();admin.embed_refresh=render
 add_child(admin);admin.add_child(admin.message);admin.campaign_changed.connect(report)
 operations_adapter=preload("res://ui/operations.gd").new();operations_adapter.embedded=true;operations_adapter.sim=sim;add_child(operations_adapter);operations_adapter.campaign_changed.connect(report)
 rpg_adapter=preload("res://ui/rpg.gd").new();rpg_adapter.embedded=true;rpg_adapter.sim=sim;add_child(rpg_adapter);rpg_adapter.campaign_changed.connect(report)
 var layer=CanvasLayer.new();layer.layer=100;add_child(layer)
 var overlay=ColorRect.new();overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);overlay.mouse_filter=Control.MOUSE_FILTER_IGNORE;layer.add_child(overlay)
 terminal_material=ShaderMaterial.new();terminal_material.shader=preload("res://visual/terminal.gdshader");overlay.material=terminal_material
 apply_visual_settings()
 resized.connect(func():render.call_deferred())
 if not testing:
  route="Campaña";section="Partidas"
  library.import_legacy()
 else:has_campaign=true
 render()
func key() -> String:return route+"/"+section
func preference(name: String,fallback: Variant=null) -> Variant:return preferences.get(key(),{}).get(name,fallback)
func remember(name: String,value: Variant):
 if not preferences.has(key()):preferences[key()]={}
 preferences[key()][name]=value
func navigate(destination: String,tab: String="",record: bool=true):
 if destination=="Operaciones":tab={"Preparación":"Plan","En curso":"Batalla"}.get(tab,tab)
 if wizard!=null and (destination!="Campaña" or tab not in ["","Partidas"]):return
 if not destination in ROUTES or (not has_campaign and destination!="Campaña"):return
 remember("scroll",scroll.scroll_vertical)
 if record and (route!=destination or section!=tab):history.append({"route":route,"section":section})
 route=destination
 section=ROUTES[route][0] if tab.is_empty() else tab
 render()
func back():
 if wizard!=null:
  if wizard.step>0:wizard.step-=1
  else:wizard=null
  render();return
 if history.is_empty():return
 var old=history.pop_back();navigate(old.route,old.section,false)
func report(message: String):
 status.text=message
 remember("scroll",scroll.scroll_vertical)
 render.call_deferred()
func run(callback: Callable):report(str(callback.call()))
func action(parent: Node,caption: String,callback: Callable):UI.button(parent,caption,func():run(callback))
func confirm(caption: String,message: String,callback: Callable):
 var d=ConfirmationDialog.new();d.title=caption;d.dialog_text=message;d.dialog_autowrap=true
 d.confirmed.connect(func():run(callback));d.confirmed.connect(d.queue_free);d.canceled.connect(d.queue_free)
 add_child(d);d.popup_centered(Vector2i(650,250))
func render():
 if not is_instance_valid(content):return
 var focused=get_viewport().gui_get_focus_owner()
 var focus_text=str(focused.text) if focused is Button and content.is_ancestor_of(focused) else ""
 if rendered_key==key():remember("scroll",scroll.scroll_vertical)
 rendered_key=key()
 admin.sim=sim
 operations_adapter.sim=sim
 rpg_adapter.sim=sim
 stats.text="%s · %s · fondos libres %d · suministros %d"%[sim.date_text(),sim.Universe.system(sim.state.location_id).name,sim.available_funds(),sim.state.supplies]
 continue_button.disabled=not has_campaign or wizard!=null or (route=="Operaciones" and section=="Batalla" and not sim.battle_view().is_empty() and not sim.battle_view().done)
 continue_button.tooltip_text="Vuelva a Resumen para avanzar días y delegar el encuentro." if route=="Operaciones" and section=="Batalla" else "Avanza el calendario de campaña; se detiene ante informes o decisiones."
 one_day_button.disabled=continue_button.disabled
 save_button.disabled=not has_campaign or wizard!=null
 if not has_campaign:stats.text="Nueva carrera o cargar una partida · 3027 / 3060"
 continue_button.text="Revisar decisión →" if blocked() else "Continuar · hasta 7 días"
 for b in sidebar.get_children():b.toggle_mode=true;b.button_pressed=b.name==route;b.disabled=not has_campaign or wizard!=null
 UI.clear(tabs)
 for name in ROUTES[route]:
  if (not has_campaign and name=="Identidad") or (wizard!=null and name!="Partidas"):continue
  var b=UI.button(tabs,name,func():navigate(route,name));b.custom_minimum_size.x=110;b.toggle_mode=true;b.button_pressed=name==section
 UI.clear(content)
 var heading=UI.column(content)
 UI.text(heading,section_title(),true)
 UI.muted(heading,section_hint())
 match route:
  "Mando":mando()
  "Compañía":company()
  "Finanzas":admin.finance_page(content)
  "Campaña":campaign_page()
  "Operaciones":preload("res://ui/pages/operations.gd").draw(self)
  "Mercado":preload("res://ui/pages/market.gd").draw(self)
  "Mundo":preload("res://ui/pages/world.gd").draw(self)
  "Capitán":preload("res://ui/pages/captain.gd").draw(self)
 scroll.set_deferred("scroll_vertical",int(preference("scroll",0)))
 if not focus_text.is_empty():
  for b in content.find_children("*","Button",true,false):
   if b.text==focus_text:b.grab_focus.call_deferred();break
func blocked() -> bool:return not sim.state.issues.is_empty() or sim.military_waiting() or sim.RPG.waiting(sim)
func advance_days(count: int):
 if not has_campaign:return
 if blocked():navigate("Mando","Bandeja");report("Resuelva la decisión pendiente para continuar.");return
 var start=sim.state.day
 for i in range(count):
  var before=sim.state.chronicle.size();sim.advance(1)
  if blocked() or sim.state.ended or sim.state.chronicle.size()>before:break
 report("Avance de %d día(s). %s"%[sim.state.day-start,"Hay una decisión pendiente." if blocked() else "Revise los informes recibidos."])
func mando():
 if section=="Crónica":
  preload("res://ui/story.gd").history(self,UI.disclosure(content,"Explorar antecedentes y personas"))
  var search=LineEdit.new();search.placeholder_text="Filtrar por persona, fecha o acontecimiento";search.text=preference("query","");content.add_child(search)
  var entries=UI.column(content)
  var fill=func(query):
   UI.clear(entries)
   var logs=sim.state.chronicle.duplicate();logs.reverse()
   logs=logs.filter(func(e):return query.is_empty() or (e.date+" "+e.kind+" "+e.text).to_lower().contains(query.to_lower()))
   var interval=UI.pager(entries,logs.size(),int(preference("page",0)),8,func(page):remember("page",page);render())
   for e in logs.slice(interval[0],interval[1]):
    var card=UI.block(entries,e.kind,e.date);UI.text(card,e.text)
   if logs.is_empty():UI.text(entries,"No hay acontecimientos que coincidan con la búsqueda.")
  search.text_changed.connect(func(q):remember("query",q);remember("page",0);fill.call(q));fill.call(search.text)
  rpg_sections(UI.disclosure(content,"Memoria del capitán"),"Memoria")
 elif section=="Agenda":
  UI.text(content,"Próxima nómina: día %d"%sim.financial_report().next_payroll)
  for order in sim.state.orders:UI.text(content,"Día %d · entrega de %d suministros"%[order.due,order.quantity])
  if not sim.state.accepted.is_empty():UI.text(content,"Día %d · límite de despliegue"%sim.state.accepted.deadline)
  rpg_sections(content,"Agenda",func(e):return e.title=="Agenda y metas")
  for module in ["agenda","workshop","delegation"]:
   for job in sim.state.rpg[module].jobs:UI.text(content,"Día %d · %s · %s"%[job.due,module,sim.person_name(job.get("person",-1))])
 else:
  UI.text(content,sim.state.company_name+" · Capitán "+sim.state.captain_name)
  preload("res://ui/pages/inbox.gd").draw(self)
func company():
 preload("res://ui/pages/company.gd").draw(self)
func save_current():
 if not has_campaign:return
 if active_path.is_empty():active_path=library.create(sim)
 else:
  if sim.save_game(active_path)!=OK:report("No se pudo guardar.");return
 report("Campaña guardada." if not active_path.is_empty() else "No se pudo guardar.")
func preserve_current() -> bool:
 if not has_campaign:return true
 if active_path.is_empty():active_path=library.create(sim);return not active_path.is_empty()
 return sim.save_game(active_path)==OK
func finish_career():
 if wizard==null or wizard.confirming:return
 wizard.confirming=true
 var next=wizard.build()
 if next==null:wizard.confirming=false;report("Revise los nombres: entre 1 y 48 caracteres.");return
 if not preserve_current():wizard.confirming=false;report("No se pudo guardar la carrera actual. Inicio cancelado.");return
 var path=library.create(next)
 if path.is_empty():wizard.confirming=false;report("No se pudo crear el guardado. Carrera actual conservada.");return
 sim=next;active_path=path;has_campaign=true;wizard=null;preferences={};history=[];selected=[];leader_id=-1
 navigate("Mando","Bandeja",false);report("Carrera iniciada. La campaña anterior está guardada.")
func load_slot(path: String):
 var next=Campaign.new()
 if next.load_game(path)!=OK:report("Guardado inválido; la campaña actual se conserva.");return
 if path==active_path and has_campaign:
  if next.state!=sim.state:
   confirm("Recargar guardado","Se descartarán los cambios posteriores al último guardado de esta carrera.",func():return activate_loaded(next,path))
   return
 elif not preserve_current():report("No se pudo guardar la carrera actual; carga cancelada.");return
 report(activate_loaded(next,path))
func activate_loaded(next,path: String) -> String:
 sim=next;active_path=path;has_campaign=true;wizard=null;preferences={};history=[];selected=[];leader_id=-1
 navigate("Mando","Bandeja",false)
 return "Campaña cargada."
func campaign_page():
 if section=="Partidas":
  if wizard!=null:wizard.draw(self);return
  UI.button(content,"Nueva carrera",func():wizard=preload("res://ui/pages/new_career.gd").new();render())
  if has_campaign:UI.button(content,"Guardar campaña",save_current)
  UI.text(content,"Cada carrera tiene su propio guardado. Al cambiar, se guarda primero la carrera activa.")
  for slot in library.entries():
   UI.button(content,"%s · %d · día %d"%[slot.name,slot.year,slot.day],func():load_slot(slot.path))
 elif section=="Identidad":
  var company_name=LineEdit.new();company_name.text=sim.state.company_name;company_name.max_length=48;content.add_child(company_name)
  var captain_name=LineEdit.new();captain_name.text=sim.state.captain_name;captain_name.max_length=48;content.add_child(captain_name)
  action(content,"Aplicar nombres",func():return "Identidad actualizada." if sim.set_identity(company_name.text,captain_name.text) else "Revise los nombres.")
 else:
  var scale_picker=UI.picker(content,"Tamaño del texto",{16:"Normal",18:"Grande",20:"Muy grande"},settings.text_size)
  scale_picker.item_selected.connect(func(i):settings.text_size=int(scale_picker.get_item_metadata(i));settings.save_settings();apply_visual_settings())
  for spec in [["scanlines","Líneas de escaneo"],["vignette","Viñeta"],["animation","Animación del mapa local"]]:
   var toggle=CheckBox.new();toggle.text=spec[1];toggle.button_pressed=settings.get(spec[0]);content.add_child(toggle)
   toggle.toggled.connect(func(on):settings.set(spec[0],on);settings.save_settings();apply_visual_settings())
func apply_visual_settings():
 theme.default_font_size=settings.text_size
 terminal_material.set_shader_parameter("scanlines",settings.scanlines)
 terminal_material.set_shader_parameter("vignette",settings.vignette)
func _unhandled_key_input(event):
 if event.is_action_pressed("ui_cancel"):back();get_viewport().set_input_as_handled()

func rpg_sections(parent: Node,page: String,filter: Callable=Callable(),uid: int=-1):
 for entry in sim.RPG.view(sim):
  if entry.get("page","")!=page or filter.is_valid() and not filter.call(entry):continue
  if uid>=0 and not entry.actions.is_empty() and not entry.actions.any(func(c):return c.args.get("uid",uid)==uid):continue
  var body=UI.block(parent,entry.title);UI.text(body,entry.text)
  for choice in entry.actions:
   if uid>=0 and choice.args.get("uid",uid)!=uid:continue
   if choice.action=="workshop" and choice.args.get("action","")=="cannibalize":
    UI.button(body,choice.label,func():confirm("Canibalizar","La integridad pasa a CERO. Recibirá repuestos; reconstruir requiere trabajo y recursos.",func():return sim.rpg_command(choice.action,choice.args)))
   else:action(body,choice.label,func():return sim.rpg_command(choice.action,choice.args))

func cancel_contract():
 if sim.state.accepted.is_empty():return
 confirm("Cancelar contrato","Devolverá %d de anticipo; reputación −1, confianza −2 y moral −5. Tras contacto puede haber daño de extracción."%sim.state.accepted.advance,func():return sim.cancel_contract())

func section_title() -> String:
 if route=="Operaciones" and section in ["Resumen","Plan","Batalla"] and not sim.state.accepted.is_empty():return section+" · "+sim.state.accepted.name
 return route+" / "+section
func section_hint() -> String:
 var hints={"Operaciones/Resumen":"Estado del contrato y próximo paso.","Operaciones/Contratos":"Compare ofertas y abra una para decidir.","Operaciones/Plan":"Elija fuerza y mando antes de autorizar el despliegue.","Operaciones/Batalla":"Observe el encuentro y dé órdenes. Estos controles usan el reloj táctico, no el calendario.","Operaciones/Informe":"Resultados de las operaciones cerradas y sus partes.","Compañía/Personal":"Seleccione una persona para consultar su situación y actuar sobre su expediente.","Compañía/Hangar":"Seleccione una unidad para ver disponibilidad, asignación y mantenimiento.","Compañía/Taller":"Reparaciones por unidad y abastecimiento de la compañía.","Mando/Bandeja":"Filtre comunicaciones; abra una entrada para ver su contexto y acciones.","Mando/Crónica":"Archivo de acontecimientos de la compañía, del más reciente al más antiguo."}
 hints.merge({"Finanzas/Previsión":"Caja, compromisos y próximos vencimientos de la compañía.","Mando/Agenda":"Plazos y trabajos en curso; consulte cuándo vuelven a estar disponibles sus recursos.","Operaciones/Encargos":"Delegue objetivos y presupuesto en sus oficiales.","Mercado/Unidades":"Compare ofertas y seleccione una unidad antes de comprar.","Mercado/Catálogo":"Consulte variantes y características del equipamiento.","Mercado/Repuestos":"Abastecimiento y recursos para mantener la fuerza operativa.","Mercado/Personal":"Revise candidatos y condiciones de contratación.","Mundo/Atlas":"Seleccione un sistema para consultar su contexto y planificar un traslado.","Mundo/Entorno":"Información disponible sobre el sistema actual.","Mundo/Región":"Conflictos y acontecimientos regionales conocidos.","Mundo/Contactos":"Enlaces y relaciones disponibles para la compañía.","Capitán/Personaje":"Identidad, capacidades y vínculos de su personaje.","Capitán/Asuntos":"Investigaciones e iniciativas del capitán; cada bloque reúne sus propias acciones.","Capitán/Legado":"Trayectoria y decisiones sobre el futuro del mando.","Campaña/Partidas":"Cree una carrera o seleccione una partida guardada.","Campaña/Identidad":"Nombres de la compañía y del capitán.","Campaña/Opciones":"Legibilidad y efectos visuales del terminal."})
 return hints.get(key(),"Seleccione una entrada o una sección para consultar sus detalles.")
