extends Control
signal selected(id: String)
const U = preload("res://sim/universe.gd")
const Art = preload("res://visual/art.gd")
var year = 3027
var zoom = 0.42
var center = Vector2.ZERO
var selected_id = ""
var location_id = ""
var faction = ""
var dragging = false
func _ready():
 custom_minimum_size = Vector2(700, 450)
 clip_contents = true
 resized.connect(queue_redraw)
 mouse_filter = Control.MOUSE_FILTER_STOP
 queue_redraw()
func position_for(item: Dictionary) -> Vector2:
 return size / 2 + (Vector2(item.x, -item.y) - center) * zoom
func _draw():
 draw_rect(Rect2(Vector2.ZERO,size),Art.color(0))
 for item in U.load_data().systems:
  var code = str(item.affiliations[str(year)])
  if not faction.is_empty() and faction != code: continue
  var point = position_for(item)
  if not Rect2(Vector2.ZERO,size).has_point(point): continue
  draw_circle(point, 2.5 if item.id == selected_id else 1.5, Art.color(4 + posmod(code.hash(),14)))
  if item.id == selected_id or item.id == location_id:
   draw_arc(point, 7, 0, TAU, 20,Art.color(9))
   draw_string(ThemeDB.fallback_font,point + Vector2(10,-8),item.name,HORIZONTAL_ALIGNMENT_LEFT,-1,14,Art.color(5))
 draw_string(ThemeDB.fallback_font,Vector2(12,size.y-12),"Rueda: zoom · arrastrar: desplazar · clic: seleccionar",HORIZONTAL_ALIGNMENT_LEFT,-1,14,Art.color(5))
func focus(id: String):
 var item = U.system(id)
 if item.is_empty(): return
 selected_id = id
 center = Vector2(item.x,-item.y)
 zoom = maxf(zoom,1.0)
 queue_redraw()
func _gui_input(event):
 if event is InputEventMouseButton:
  if event.button_index == MOUSE_BUTTON_WHEEL_UP or event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
   zoom = clampf(zoom * (1.2 if event.button_index == MOUSE_BUTTON_WHEEL_UP else 0.83333),0.1,12)
   queue_redraw()
  elif event.button_index == MOUSE_BUTTON_LEFT:
   dragging = event.pressed
   if event.pressed:
    var best = 12.0
    var picked = ""
    for item in U.load_data().systems:
     if not faction.is_empty() and item.affiliations[str(year)] != faction: continue
     var distance = position_for(item).distance_to(event.position)
     if distance < best:
      best = distance
      picked = item.id
    if not picked.is_empty():
     selected_id = picked
     selected.emit(picked)
     queue_redraw()
 if event is InputEventMouseMotion and dragging:
  center -= event.relative / zoom
  queue_redraw()
