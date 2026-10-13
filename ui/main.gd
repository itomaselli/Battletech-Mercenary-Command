extends Control
const Campaign=preload("res://sim/campaign.gd")
const UI=preload("res://ui/components.gd")
const ROUTES={"Mando":["Bandeja","Agenda","Crónica","Capitán"],"Compañía":["Personal","Hangar","Taller"],"Operaciones":["Territorio","Resumen","Contratos","Plan","Batalla","Informe","Encargos"],"Mundo":["Atlas","Entorno","Región","Contactos"],"Mercado":["Unidades","Catálogo","Repuestos","Personal"],"Finanzas":["Previsión"],"Capitán":["Personaje","Asuntos","Legado"],"Campaña":["Partidas","Identidad","Opciones"]}
var sim=Campaign.new()
var library=preload("res://sim/campaign_library.gd").new()
var active_path=""
var has_campaign=false
var testing=false
var wizard

var route="Operaciones"
var section="Territorio"
var history=[]
var preferences={}
var content: VBoxContainer
var scroll: ScrollContainer
var tabs: HBoxContainer
var sidebar: VBoxContainer
var emblem: TextureRect
var roster: HBoxContainer
var context: VBoxContainer
var context_title: Label
var date_label: Label
var right_frame: PanelContainer
var footer: HBoxContainer
var task_button: Button
var task_callback: Callable
var resource_labels=[]
var page_title: Label
var page_hint: Label
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
 var root=UI.column(margin);root.add_theme_constant_override("separation",10)
 var header=HBoxContainer.new();header.add_theme_constant_override("separation",10);root.add_child(header)
 var company_frame=PanelContainer.new();company_frame.size_flags_horizontal=Control.SIZE_EXPAND_FILL;company_frame.size_flags_stretch_ratio=1.5;header.add_child(company_frame)
 var company_row=HBoxContainer.new();company_frame.add_child(company_row)
 emblem=preload("res://visual/emblems.gd").view(0,80);company_row.add_child(emblem)
 var company=UI.column(company_row)
 title=UI.text(company,"MERCENARY COMMAND",true);title.add_theme_font_size_override("font_size",32)
 stats=UI.muted(company,"COMPAÑÍA MERCENARIA");stats.add_theme_font_size_override("font_size",13)
 var center=UI.column(header);center.size_flags_stretch_ratio=2.5;center.add_theme_constant_override("separation",8)
 var metrics=HBoxContainer.new();center.add_child(metrics)
 for caption in ["FONDOS LIBRES","DISPONIBLES","TALLER"]:
  var metric=UI.block(metrics,"","")
  metric.get_child(0).queue_free()
  resource_labels.append(UI.text(metric,"—",true))
  UI.muted(metric,caption).add_theme_font_size_override("font_size",12)
 roster=HBoxContainer.new();roster.add_theme_constant_override("separation",5);center.add_child(roster)
 var clock_frame=PanelContainer.new();clock_frame.size_flags_horizontal=Control.SIZE_EXPAND_FILL;clock_frame.size_flags_stretch_ratio=1.05;header.add_child(clock_frame)
 var clock=UI.column(clock_frame)
 date_label=UI.text(clock,"",true)
 continue_button=UI.primary(clock,"AVANZAR DÍA",func():advance_days(1));continue_button.custom_minimum_size.y=48
 one_day_button=UI.button(clock,"Hasta 7 días →",func():advance_days(7))
 var body=HBoxContainer.new();body.size_flags_vertical=Control.SIZE_EXPAND_FILL;body.add_theme_constant_override("separation",10);root.add_child(body)
 sidebar=VBoxContainer.new();sidebar.custom_minimum_size.x=172;sidebar.add_theme_constant_override("separation",6);body.add_child(sidebar)
 for spec in [["OPERACIONES","Operaciones","Territorio",36],["COMPAÑÍA","Mando","Bandeja",23],["MECHS","Compañía","Hangar",41],["VEHÍCULOS","Compañía","Hangar",40],["PERSONAL","Compañía","Personal",26],["CONTRATOS","Operaciones","Contratos",46],["INTELIGENCIA","Mundo","Atlas",35],["MERCADO","Mercado","Unidades",42],["FINANZAS","Finanzas","Previsión",44],["SISTEMA","Campaña","Partidas",42]]:
  var b=UI.button(sidebar,spec[0],func():
   if spec[0] in ["MECHS","VEHÍCULOS"]:
    if not preferences.has("Compañía/Hangar"):preferences["Compañía/Hangar"]={}
    preferences["Compañía/Hangar"]["kind"]="vehicle" if spec[0]=="VEHÍCULOS" else "mech"
    preferences["Compañía/Hangar"]["sheet"]=false
   navigate(spec[1],spec[2]))
  b.set_meta("destination",spec);b.theme_type_variation="NavigationButton";b.size_flags_vertical=Control.SIZE_EXPAND_FILL
  b.icon=preload("res://visual/emblems.gd").texture(spec[3]);b.expand_icon=true;b.add_theme_constant_override("icon_max_width",32);b.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST;b.alignment=HORIZONTAL_ALIGNMENT_LEFT
 var main_frame=PanelContainer.new();main_frame.size_flags_horizontal=Control.SIZE_EXPAND_FILL;main_frame.size_flags_stretch_ratio=2.2;body.add_child(main_frame)
 var page=UI.column(main_frame)
 page_title=UI.text(page,"",true);page_title.add_theme_font_size_override("font_size",28)
 page_hint=UI.muted(page,"");page_hint.hide()
 var tab_scroll=ScrollContainer.new();tab_scroll.custom_minimum_size.y=48;tab_scroll.vertical_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;page.add_child(tab_scroll)
 tabs=HBoxContainer.new();tab_scroll.add_child(tabs)
 scroll=ScrollContainer.new();scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL;scroll.size_flags_horizontal=Control.SIZE_EXPAND_FILL;scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;page.add_child(scroll)
 content=UI.column(scroll)
 right_frame=PanelContainer.new();right_frame.size_flags_horizontal=Control.SIZE_EXPAND_FILL;right_frame.size_flags_stretch_ratio=1.0;right_frame.custom_minimum_size.x=280;body.add_child(right_frame)
 var right=UI.column(right_frame)
 var banner=PanelContainer.new();banner.theme_type_variation="GoldPanel";right.add_child(banner)
 context_title=UI.text(banner,"INFORME DE COMPAÑÍA",true);context_title.add_theme_color_override("font_color",Color("091c20"))
 context=UI.scroll_column(right)
 task_button=UI.primary(right,"CONTINUAR →",func():
  if task_callback.is_valid():task_callback.call())
 task_button.custom_minimum_size.y=52
 footer=HBoxContainer.new();root.add_child(footer)
 var previous=UI.button(footer,"← Volver",back);previous.custom_minimum_size.x=110;previous.size_flags_horizontal=Control.SIZE_FILL
 status=UI.muted(footer,"Órdenes, informes e historias de su compañía.");status.add_theme_font_size_override("font_size",12)
 save_button=UI.button(footer,"Guardar",save_current);save_button.custom_minimum_size.x=100;save_button.size_flags_horizontal=Control.SIZE_FILL
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
 if route=="Compañía" and name in ["id","uid"]:
  preferences[key()]["sheet"]=true
  if name=="uid":
   var index=sim.mech_index(int(value))
   if index>=0:preferences[key()]["kind"]=sim.MECH_CATALOG[sim.state.mechs[index].model].kind
func navigate(destination: String,tab: String="",record: bool=true):
 if destination=="Mando" and tab=="Capitán":destination="Capitán";tab="Personaje"
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
 title.text=sim.state.company_name.to_upper() if has_campaign else "MERCENARY COMMAND"
 stats.text="COMPAÑÍA MERCENARIA" if has_campaign else "NUEVA CARRERA"
 emblem.texture=preload("res://visual/emblems.gd").texture(int(sim.state.get("emblem_id",0)))
 date_label.text=sim.date_text() if has_campaign else "3027 / 3060"
 var ready=0;var repairs=0
 for m in sim.state.mechs:
  if preload("res://ui/pages/operations.gd").eligible(sim,m.uid):ready+=1
  if m.repair:repairs+=1
 resource_labels[0].text=str(sim.available_funds())+" C-B"
 resource_labels[1].text="%d / %d"%[ready,sim.state.mechs.size()]
 resource_labels[2].text="%d reparación"%repairs
 if not has_campaign:
  for label in resource_labels:label.text="—"
 draw_header_force()
 UI.clear(context)
 draw_context()
 continue_button.disabled=not has_campaign or wizard!=null or (route=="Operaciones" and section=="Batalla" and not sim.battle_view().is_empty() and not sim.battle_view().done)
 continue_button.tooltip_text="Vuelva a Resumen para avanzar días y delegar el encuentro." if route=="Operaciones" and section=="Batalla" else "Avanza el calendario de campaña; se detiene ante informes o decisiones."
 one_day_button.disabled=continue_button.disabled
 save_button.disabled=not has_campaign or wizard!=null
 if not has_campaign:stats.text="Nueva carrera o cargar una partida · 3027 / 3060"
 continue_button.text="REVISAR DECISIÓN" if blocked() else "AVANZAR DÍA"
 for b in sidebar.get_children():
  var dest=b.get_meta("destination")
  b.toggle_mode=true;b.button_pressed=dest[1]==route and (route!="Compañía" or dest[2]==section) and (dest[0] not in ["MECHS","VEHÍCULOS"] or preference("kind","mech")==("vehicle" if dest[0]=="VEHÍCULOS" else "mech")) and (route!="Operaciones" or (dest[2]=="Contratos")== (section=="Contratos"));b.disabled=(not has_campaign and dest[1]!="Campaña") or wizard!=null
 UI.clear(tabs)
 tabs.show();tabs.get_parent().show()
 for name in ROUTES[route]:
  if (not has_campaign and name=="Identidad") or (wizard!=null and name!="Partidas"):continue
  var b=UI.button(tabs,name,func():navigate(route,name));b.custom_minimum_size.x=100;b.theme_type_variation="TabButton";b.toggle_mode=true;b.button_pressed=name==section
 UI.clear(content)
 page_title.text={"Mando":"BASE DE OPERACIONES","Compañía":"PERSONAL" if section=="Personal" else "FUERZA DE COMBATE","Operaciones":"OPERACIONES","Mundo":"MUNDO E INTELIGENCIA","Mercado":"MERCADO","Finanzas":"ECONOMÍA Y LOGÍSTICA","Capitán":"EL CAPITÁN","Campaña":"CAMPAÑA"}.get(route,route)
 page_hint.text=section_hint()
 task_callback=Callable();task_button.hide()
 configure_task()
 match route:
  "Mando":mando()
  "Compañía":company()
  "Finanzas":preload("res://ui/pages/finance.gd").draw(self)
  "Campaña":campaign_page()
  "Operaciones":
   if section=="Territorio":preload("res://ui/pages/territory.gd").draw(self)
   else:preload("res://ui/pages/operations.gd").draw(self)
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
  preload("res://ui/pages/desk.gd").draw(self)
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
 navigate("Operaciones","Territorio",false);report("Carrera iniciada. La campaña anterior está guardada.")
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
 navigate("Operaciones","Territorio",false)
 return "Campaña cargada."
func campaign_page():
 if section=="Partidas":
  if wizard!=null:wizard.draw(self);return
  var intro=UI.block(content,"SU PRÓXIMA HISTORIA","Dirija una compañía. Conozca a su gente. Viva con las consecuencias de sus órdenes.")
  UI.text(intro,"Cree una carrera independiente o retome una existente. Al cambiar se guarda primero la campaña activa.")
  var entries=library.entries()
  var span=UI.pager(content,entries.size(),int(preference("slot_page",0)),4,func(page):remember("slot_page",page);render())
  var grid=GridContainer.new();grid.columns=2;grid.add_theme_constant_override("h_separation",16);grid.add_theme_constant_override("v_separation",16);content.add_child(grid)
  for slot in entries.slice(span[0],span[1]):
   var card=UI.block(grid,slot.name,"%d · día %d"%[slot.year,slot.day])
   UI.primary(card,"CONTINUAR CARRERA →",func():load_slot(slot.path))
  if entries.is_empty():UI.text(content,"Todavía no hay carreras. Empiece con NUEVA CARRERA.")
 elif section=="Identidad":
  UI.text(content,"NOMBRE DE LA COMPAÑÍA")
  var company_name=LineEdit.new();company_name.text=sim.state.company_name;company_name.max_length=48;content.add_child(company_name)
  UI.text(content,"NOMBRE DEL CAPITÁN")
  var captain_name=LineEdit.new();captain_name.text=sim.state.captain_name;captain_name.max_length=48;content.add_child(captain_name)
  action(content,"Aplicar nombres",func():return "Identidad actualizada." if sim.set_identity(company_name.text,captain_name.text) else "Revise los nombres.")
  preload("res://visual/emblems.gd").selector(self,content,int(sim.state.get("emblem_id",0)),func(i):sim.state.emblem_id=i;report("Emblema actualizado. Guarde la campaña para conservarlo."))
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
 var entries=sim.RPG.view(sim).filter(func(e):return e.get("page","")==page and (not filter.is_valid() or filter.call(e)))
 if entries.size()>1:
  var options={}
  for i in range(entries.size()):options[i]=entries[i].title
  var selected_entry=clampi(int(preference("rpg_"+page,0)),0,entries.size()-1)
  var selector=UI.picker(parent,"Expediente · "+page,options,selected_entry)
  selector.item_selected.connect(func(i):remember("rpg_"+page,i);render())
  entries=[entries[selected_entry]]
 for entry in entries:
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
 var hints={"Operaciones/Resumen":"Estado del contrato y próximo paso.","Operaciones/Contratos":"Compare ofertas y abra una para decidir.","Operaciones/Plan":"Elija fuerza y mando antes de autorizar el despliegue.","Operaciones/Batalla":"Observe el encuentro y dé órdenes. Estos controles usan el reloj táctico, no el calendario.","Operaciones/Informe":"Resultados de las operaciones cerradas y sus partes.","Compañía/Personal":"Seleccione una persona para consultar su situación y actuar sobre su expediente.","Compañía/Hangar":"Seleccione una unidad para ver disponibilidad, asignación y mantenimiento.","Compañía/Taller":"Reparaciones por unidad y abastecimiento de la compañía.","Mando/Bandeja":"Escritorio del comandante · comunicaciones, compromisos y próximos pasos.","Mando/Crónica":"Archivo de acontecimientos de la compañía, del más reciente al más antiguo."}
 hints.merge({"Finanzas/Previsión":"Caja, compromisos y próximos vencimientos de la compañía.","Mando/Agenda":"Plazos y trabajos en curso; consulte cuándo vuelven a estar disponibles sus recursos.","Operaciones/Encargos":"Delegue objetivos y presupuesto en sus oficiales.","Mercado/Unidades":"Compare ofertas y seleccione una unidad antes de comprar.","Mercado/Catálogo":"Consulte variantes y características del equipamiento.","Mercado/Repuestos":"Abastecimiento y recursos para mantener la fuerza operativa.","Mercado/Personal":"Revise candidatos y condiciones de contratación.","Mundo/Atlas":"Seleccione un sistema para consultar su contexto y planificar un traslado.","Mundo/Entorno":"Información disponible sobre el sistema actual.","Mundo/Región":"Conflictos y acontecimientos regionales conocidos.","Mundo/Contactos":"Enlaces y relaciones disponibles para la compañía.","Capitán/Personaje":"Identidad, capacidades y vínculos de su personaje.","Capitán/Asuntos":"Investigaciones e iniciativas del capitán; cada bloque reúne sus propias acciones.","Capitán/Legado":"Trayectoria y decisiones sobre el futuro del mando.","Campaña/Partidas":"Cree una carrera o seleccione una partida guardada.","Campaña/Identidad":"Nombres de la compañía y del capitán.","Campaña/Opciones":"Legibilidad y efectos visuales del terminal."})
 return hints.get(key(),"Seleccione una entrada o una sección para consultar sus detalles.")

func set_task(caption: String,callback: Callable,enabled: bool=true):
 task_button.text=caption;task_callback=callback;task_button.disabled=not enabled;task_button.show()
func configure_task():
 if wizard!=null:return
 match route:
  "Mando":
   set_task("REVISAR OPERACIÓN →",func():navigate("Operaciones","Resumen"))
  "Compañía":
   set_task("CONTRATAR PERSONAL →" if section=="Personal" else "PREPARAR FUERZA →",func():navigate("Mercado" if section=="Personal" else "Operaciones","Personal" if section=="Personal" else "Plan"))
  "Operaciones":
   if section=="Resumen":set_task("PREPARAR OPERACIÓN →" if not sim.state.accepted.is_empty() else "BUSCAR CONTRATO →",func():navigate("Operaciones","Plan" if not sim.state.accepted.is_empty() else "Contratos"))
  "Mundo":set_task("VER CONTRATOS →",func():navigate("Operaciones","Contratos"))
  "Finanzas":set_task("REVISAR TALLER →",func():navigate("Compañía","Taller"))
  "Capitán":set_task("ASUNTOS DEL CAPITÁN →",func():navigate("Capitán","Asuntos"))
  "Campaña":
   if section=="Partidas":set_task("NUEVA CARRERA →",func():wizard=preload("res://ui/pages/new_career.gd").new();render())

func draw_header_force():
 UI.clear(roster)
 if not has_campaign:return
 for m in sim.state.mechs.slice(0,4):
  var card=PanelContainer.new();card.size_flags_horizontal=Control.SIZE_EXPAND_FILL;roster.add_child(card)
  var row=HBoxContainer.new();card.add_child(row)
  var icon=UI.unit_icon(row,sim.MECH_CATALOG[m.model]);icon.custom_minimum_size=Vector2(24,36)
  var unit=UI.column(row);unit.add_theme_constant_override("separation",3)
  var label=UI.text(unit,m.name.split(" ")[0].to_upper()+"\n"+("TALLER" if m.repair else "%d%%"%m.hp));label.add_theme_font_size_override("font_size",11)
  var health=ProgressBar.new();health.value=m.hp;health.show_percentage=false;health.custom_minimum_size.y=5;unit.add_child(health)
 if sim.state.mechs.is_empty():UI.muted(roster,"SIN UNIDADES")
func draw_context():
 if route=="Campaña":
  context_title.text="IDENTIDAD DE COMPAÑÍA" if section=="Identidad" else "ARCHIVO DE CAMPAÑAS"
  var emblem_index=int(sim.state.get("emblem_id",0)) if wizard==null else wizard.emblem_id
  context.add_child(preload("res://visual/emblems.gd").view(emblem_index,128))
  UI.text(context,sim.state.company_name if wizard==null else wizard.company,true)
  UI.text(context,preload("res://visual/emblems.gd").NAMES[emblem_index])
  UI.muted(context,"La identidad, el emblema y la crónica se conservan con cada carrera. Los cambios no afectan las reglas de la compañía.")
  return
 var contract=sim.state.accepted
 if contract.is_empty() and not sim.state.offers.is_empty():contract=sim.state.offers[0]
 context_title.text="CONTRATO ACTIVO" if not sim.state.accepted.is_empty() else "CONTRATO DISPONIBLE"
 if not contract.is_empty():
  UI.text(context,contract.name.to_upper(),true)
  UI.muted(context,"EMPLEADOR")
  UI.text(context,contract.employer)
  UI.muted(context,"PAGO / DURACIÓN")
  UI.text(context,"%d C-B · %d días"%[contract.pay,contract.days])
  UI.muted(context,"OBJETIVO E INTELIGENCIA")
  UI.text(context,contract.get("objective",contract.get("intel","Sin parte disponible.")))
 else:UI.text(context,"No hay contratos disponibles. Consulte el mercado de contratos al avanzar la campaña.")
 var reports=preload("res://ui/pages/inbox.gd").entries(sim)
 if not reports.is_empty():
  var entry=reports[0]
  var message=UI.block(context,"EVENTO DE COMPAÑÍA",entry.source)
  UI.text(message,entry.body)
  UI.button(message,"IR A LA COMPAÑÍA →",func():navigate("Mando","Bandeja");remember("entry",entry.id);render())
 UI.button(context,"IDENTIDAD Y EMBLEMA →",func():navigate("Campaña","Identidad"))

func contextual(caption: String) -> VBoxContainer:
 UI.clear(context);context_title.text=caption
 return context
