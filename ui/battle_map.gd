extends Control
signal sector_selected(x: int, y: int)
const Art=preload("res://visual/art.gd")
var view:Dictionary={}
var textures:Dictionary={}
var selected=Vector2i(64,12)
const COLORS=[Color("173c40"),Color("427050"),Color("8b885a"),Color("345c79"),Color("797b70"),Color("465152")]
func _ready():
 custom_minimum_size=Vector2(200,130)
 size_flags_horizontal=Control.SIZE_EXPAND_FILL
 size_flags_vertical=Control.SIZE_EXPAND_FILL
 resized.connect(queue_redraw)
 mouse_filter=Control.MOUSE_FILTER_STOP
 tooltip_text="Clic: seleccionar sector para la próxima orden. No mueve unidades directamente."
func _gui_input(e):
 if e is InputEventMouseButton and e.pressed and e.button_index==MOUSE_BUTTON_LEFT:
  var rect=map_rect()
  if not rect.has_point(e.position):return
  var point=e.position-rect.position
  selected=Vector2i(clampi(int(point.x/rect.size.x*80),0,79),clampi(int(point.y/rect.size.y*25),0,24))
  sector_selected.emit(selected.x,selected.y);queue_redraw();accept_event()
func _draw():
 if view.is_empty():return
 var area=map_rect()
 draw_set_transform(area.position)
 var cell=Vector2(area.size.x/80,area.size.y/25)
 for y in range(25):
  for x in range(80):
   var tile=int(view.tiles[y*80+x]);var rect=Rect2(Vector2(x,y)*cell,cell)
   draw_rect(rect,COLORS[tile])
   if tile in [1,2,4]:draw_rect(Rect2(rect.position+cell*0.3,cell*0.35),Color("a1ae88"))
 var objective=Vector2(view.objective.x,view.objective.y)*cell
 draw_rect(Rect2(objective-cell,cell*3),Color("efd474"),false,2)
 for group in view.groups.values():draw_circle(Vector2(group.x+0.5,group.y+0.5)*cell,3,Color("84c6b0"))
 if view.kind in ["escort","interdiction"]:
  draw_rect(Rect2(Vector2(view.convoy.x,view.convoy.y)*cell,cell),Color("e4cd6a"))
 for shot in view.get("shots",[]):
  draw_line(Vector2(shot.x+0.5,shot.y+0.5)*cell,Vector2(shot.tx+0.5,shot.ty+0.5)*cell,Color("efd474"),1)
 for u in view.units:
  if u.escaped:continue
  var pos=Vector2(u.x,u.y)*cell
  if not textures.has(u.model) and not u.model.is_empty():textures[u.model]=ImageTexture.create_from_image(Art.unit_sprite(u.model))
  if textures.has(u.model):draw_texture_rect(textures[u.model],Rect2(pos,cell),false,Color.WHITE if u.hp>0 else Color("666666"))
  else:draw_rect(Rect2(pos,cell),Color("84d5bb"))
  draw_line(pos+Vector2(0,cell.y),pos+Vector2(cell.x*float(u.hp)/100,cell.y),Color("92ef9a"),2)
 for c in view.contacts:
  var pos=Vector2(c.x,c.y)*cell
  var fresh=c.last_seen==view.tick
  draw_rect(Rect2(pos,cell),Color("ed8371") if fresh else Color("986e66"),false,2)
  draw_string(ThemeDB.fallback_font,pos+Vector2(0,cell.y),"×" if c.disabled else "!" if fresh else "?",HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color("ed8371"))
 draw_rect(Rect2(Vector2(selected)*cell,cell),Color.WHITE,false,1)

func map_rect() -> Rect2:
 var scale_value=minf(size.x/1280.0,size.y/600.0)
 var dimensions=Vector2(1280,600)*scale_value
 return Rect2((size-dimensions)/2,dimensions)
