extends VBoxContainer
const B=preload("res://sim/battle/engine.gd")
var sim
var map
var status:Label
var details:Label
var reports:Label
var feedback:Label
var clock_button:Button
var group:OptionButton
var order:OptionButton
var attitude:OptionButton
var speed:OptionButton
var auto_pause:CheckBox
var playing=false
var accumulated=0.0
var target=Vector2i(64,12)
const LABELS=["Avanzar","Reconocer","Defender","Presionar","Escoltar","Reserva","Retirar"]
func label_at(parent,text:String)->Label:
 var l=Label.new();l.text=text;l.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;parent.add_child(l);return l
func button_at(parent,text:String,callback:Callable)->Button:
 var b=Button.new();b.text=text;b.pressed.connect(callback);parent.add_child(b);return b
func picker_at(parent,items:Array)->OptionButton:
 var p=OptionButton.new()
 for item in items:p.add_item(item)
 parent.add_child(p);return p
func _ready():
 size_flags_horizontal=Control.SIZE_EXPAND_FILL
 label_at(self,"MAPA DE OPERACIONES · Órdenes de mando · 80 × 25")
 status=label_at(self,"")
 var bar=HFlowContainer.new();add_child(bar)
 clock_button=button_at(bar,"▶ Observar",func():playing=not playing;refresh())
 button_at(bar,"Paso · 10 s",func():playing=false;sim.battle_step();refresh())
 speed=picker_at(bar,["1×","4×","12×"])
 auto_pause=CheckBox.new();auto_pause.text="Pausa ante contacto o baja";auto_pause.button_pressed=true;bar.add_child(auto_pause)
 button_at(bar,"Delegar hasta el final",func():playing=false;feedback.text=sim.battle_delegate();refresh())
 map=preload("res://ui/battle_map.gd").new();add_child(map)
 map.sector_selected.connect(func(x,y):target=Vector2i(x,y);feedback.text="Sector %d,%d seleccionado. Elija orden y transmita."%[x,y])
 label_at(self,"Verde: fuerza propia · Rojo: contacto actual · ?: última posición conocida · Dorado: objetivo/convoy. Terreno: bosque verde, colina ocre, agua azul, edificios grises y caminos oscuros.")
 var commands=HFlowContainer.new();add_child(commands)
 group=picker_at(commands,["Alfa · primeras dos unidades","Bravo · restantes"])
 order=picker_at(commands,LABELS)
 attitude=picker_at(commands,["Cautelosa · preservación","Equilibrada","Agresiva"]);attitude.selected=1
 button_at(commands,"Transmitir al sector seleccionado",func():feedback.text=sim.battle_order(["Alfa","Bravo"][group.selected],B.ORDERS[order.selected],B.ATTITUDES[attitude.selected],target.x,target.y);refresh())
 feedback=label_at(self,"Seleccione un sector en el mapa. Las órdenes tardan dos ticks en llegar. Observar no avanza días de campaña.")
 details=label_at(self,"")
 reports=label_at(self,"")
 refresh()
func _process(delta):
 if not playing:return
 accumulated+=delta
 var delay=[0.8,0.2,0.066][speed.selected]
 if accumulated>=delay:
  accumulated=0
  sim.battle_step()
  if auto_pause.button_pressed and not sim.battle_view().get("alert","").is_empty():playing=false
  refresh()
func refresh():
 var v=sim.battle_view()
 if v.is_empty():playing=false;return
 if v.done:playing=false
 clock_button.text="Ⅱ Pausar" if playing else "▶ Observar"
 clock_button.disabled=v.done
 status.text="T+%ds · %s · Objetivo %d%% · %s %d%%\n%s"%[v.tick*10,{"escort":"Escolta","recon":"Reconocimiento","defense":"Defensa","interdiction":"Interdicción","extraction":"Extracción","recovery":"Recuperación"}[v.kind],v.progress,"Transportes hostiles" if v.kind=="interdiction" else "Elemento protegido",v.asset_hp,"Encuentro terminado: "+B.RESULT_LABELS[v.result]+". Avance el calendario para el regreso y la liquidación." if v.done else "Pausa" if not playing else "En vivo"]
 map.view=v;map.queue_redraw()
 var lines=[]
 for u in v.units:lines.append("%s · %s · %d%% · calor %d · munición %d · %s"%[u.group,u.name,u.hp,u.heat,u.ammo,"Extraído" if u.escaped else u.intent])
 for p in v.pending:lines.append("Orden en tránsito a %s · recepción T+%ds"%[p.group,p.due*10])
 details.text="\n".join(lines)
 lines=[]
 for e in v.events.slice(maxi(0,v.events.size()-6)):lines.append("T+%ds · %s"%[e.tick*10,e.text])
 reports.text="PARTES DE CAMPO\n"+"\n".join(lines)
