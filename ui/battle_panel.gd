extends VBoxContainer
signal encounter_status(done: bool)
const B=preload("res://sim/battle/engine.gd")
const UI=preload("res://ui/components.gd")
var sim
var command_parent: Node
var ui_state:Dictionary={}
var map
var status:Label
var details:Label
var reports:Label
var feedback:Label
var selection:Label
var clock_button:Button
var transmit:Button
var group:OptionButton
var order:OptionButton
var attitude:OptionButton
var speed:OptionButton
var auto_pause:CheckBox
var playing=false
var accumulated=0.0
var target=Vector2i(64,12)
var desired_height=450.0
const LABELS=["Avanzar","Reconocer","Defender","Presionar","Escoltar","Reserva","Retirar"]
func fit_height(value:float):
 desired_height=value;custom_minimum_size.y=value
func picker_at(parent,items:Array)->OptionButton:
 var p=OptionButton.new();p.fit_to_longest_item=false;p.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 for item in items:p.add_item(item)
 parent.add_child(p);return p
func _ready():
 size_flags_horizontal=Control.SIZE_EXPAND_FILL
 add_theme_constant_override("separation",8)
 status=UI.text(self,"")
 var bar=HFlowContainer.new();bar.add_theme_constant_override("h_separation",6);add_child(bar)
 clock_button=UI.button(bar,"▶ Observar",func():playing=not playing;refresh());clock_button.custom_minimum_size.x=140
 var step=UI.button(bar,"Paso · 10 s",func():playing=false;sim.battle_step();refresh());step.custom_minimum_size.x=140
 speed=picker_at(bar,["1×","4×","12×"]);speed.custom_minimum_size.x=65;speed.size_flags_horizontal=Control.SIZE_FILL
 auto_pause=CheckBox.new();auto_pause.text="Pausa por alerta";auto_pause.button_pressed=true;bar.add_child(auto_pause)
 var field=UI.column(self);field.size_flags_vertical=Control.SIZE_EXPAND_FILL
 map=preload("res://ui/battle_map.gd").new();field.add_child(map)
 map.sector_selected.connect(func(x,y):target=Vector2i(x,y);ui_state["x"]=x;ui_state["y"]=y;feedback.text="Sector elegido. Confirme la orden para transmitirla.";refresh())
 var legend=UI.muted(field,"■ Propios   □ Contacto   ? Última posición   ◇ Objetivo");legend.add_theme_font_size_override("font_size",13)
 var orders_frame=PanelContainer.new();(command_parent if command_parent!=null else self).add_child(orders_frame)
 var deck=UI.column(orders_frame);deck.add_theme_constant_override("separation",6)
 selection=UI.text(deck,"")
 var commands=VBoxContainer.new() if command_parent!=null else HBoxContainer.new();deck.add_child(commands)
 group=picker_at(commands,["Alfa","Bravo"]);group.custom_minimum_size.x=90;group.item_selected.connect(func(i):ui_state["group"]=i;refresh())
 order=picker_at(commands,LABELS);order.custom_minimum_size.x=150
 attitude=picker_at(commands,["Cautelosa","Equilibrada","Agresiva"]);attitude.selected=1;attitude.custom_minimum_size.x=150
 transmit=UI.primary(commands,"Transmitir orden",func():feedback.text=sim.battle_order(["Alfa","Bravo"][group.selected],B.ORDERS[order.selected],B.ATTITUDES[attitude.selected],target.x,target.y);refresh());transmit.custom_minimum_size.x=220
 UI.button(commands,"Delegar",func():playing=false;feedback.text=sim.battle_delegate();refresh()).custom_minimum_size.x=100
 feedback=UI.muted(deck,"Seleccione un sector en el mapa. Recepción en 20 segundos.");feedback.add_theme_font_size_override("font_size",13)
 var received=PanelContainer.new();received.custom_minimum_size.y=80;add_child(received)
 var received_row=HBoxContainer.new();received.add_child(received_row)
 var switches=HBoxContainer.new();received_row.add_child(switches);switches.size_flags_horizontal=Control.SIZE_FILL;switches.custom_minimum_size.x=150
 var report_body=UI.scroll_column(received_row)
 reports=UI.text(report_body,"");reports.add_theme_font_size_override("font_size",14)
 details=UI.text(report_body,"");details.add_theme_font_size_override("font_size",14);details.hide()
 UI.button(switches,"Partes",func():reports.show();details.hide()).custom_minimum_size.x=95
 UI.button(switches,"Fuerza",func():details.show();reports.hide()).custom_minimum_size.x=95
 custom_minimum_size.y=desired_height
 target=Vector2i(int(ui_state.get("x",64)),int(ui_state.get("y",12)));map.selected=target
 group.selected=int(ui_state.get("group",0));order.selected=int(ui_state.get("order",0));attitude.selected=int(ui_state.get("attitude",1))
 order.item_selected.connect(func(i):ui_state["order"]=i)
 attitude.item_selected.connect(func(i):ui_state["attitude"]=i)
 refresh()
func _process(delta):
 var outer=get_parent().get_parent()
 if outer is ScrollContainer:
  var available=maxf(280,outer.size.y-position.y)
  if absf(custom_minimum_size.y-available)>1:custom_minimum_size.y=available
 if not playing:return
 accumulated+=delta
 var delay=[0.8,0.2,0.066][speed.selected]
 if accumulated>=delay:
  accumulated=0;sim.battle_step()
  if auto_pause.button_pressed and not sim.battle_view().get("alert","").is_empty():playing=false
  refresh()
func refresh():
 var v=sim.battle_view()
 if v.is_empty():playing=false;return
 encounter_status.emit(bool(v.done))
 if v.done:playing=false
 clock_button.text="Ⅱ Pausar" if playing else "▶ Observar";clock_button.disabled=v.done
 status.text="T+%ds · Objetivo %d%% · %s"%[v.tick*10,v.progress,"Finalizado: "+B.RESULT_LABELS[v.result]+" · regreso pendiente" if v.done else "EN VIVO" if playing else "EN PAUSA"]
 map.view=v;map.queue_redraw()
 var name=["Alfa","Bravo"][group.selected]
 var units=v.units.filter(func(u):return u.group==name)
 var pending=v.pending.filter(func(p):return p.group==name)
 var current=v.groups[name]
 selection.text="%s · %d unidades\nVigente: %s"%[name,units.size(),B.ORDER_LABELS[current.order]]
 transmit.text="Encuentro finalizado" if v.done else "Orden en tránsito" if not pending.is_empty() else "Transmitir a %d,%d"%[target.x,target.y]
 transmit.disabled=v.done or not pending.is_empty() or units.all(func(u):return u.escaped or u.hp<=0)
 var lines=["Vigente: %s\nDestino: %d,%d · nuevo sector: %d,%d"%[B.ORDER_LABELS[current.order],current.x,current.y,target.x,target.y]]
 for p in pending:lines.append("EN TRÁNSITO · recepción T+%ds"%(p.due*10))
 for u in units:lines.append("%s · %d%%\nCalor %d · munición %d\n%s"%[u.name,u.hp,u.heat,u.ammo,"Extraído" if u.escaped else u.intent])
 details.text="\n\n".join(lines)
 lines=["INFORMES DE CAMPO · últimos acontecimientos"]
 var latest=v.events.slice(maxi(0,v.events.size()-6));latest.reverse()
 for e in latest:lines.append("T+%ds · %s"%[e.tick*10,e.text])
 reports.text="\n".join(lines)
