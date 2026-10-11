extends RefCounted
const U = preload("res://sim/universe.gd")
static var graph: Dictionary = {}
static func build_graph():
 if not graph.is_empty(): return
 var buckets = {}
 for item in U.load_data().systems:
  var cell = Vector2i(floori(item.x/30.0),floori(item.y/30.0))
  if not buckets.has(cell): buckets[cell] = []
  buckets[cell].append(item)
  graph[item.id] = []
 for cell in buckets:
  for item in buckets[cell]:
   for x in range(-1,2):
    for y in range(-1,2):
     for other in buckets.get(cell+Vector2i(x,y),[]):
      if item.id == other.id: continue
      if Vector2(item.x,item.y).distance_to(Vector2(other.x,other.y)) <= 30.0: graph[item.id].append(other.id)
static func route(origin: String, destination: String) -> Array:
 build_graph()
 if not graph.has(origin) or not graph.has(destination) or origin == destination: return []
 var queue = [origin]
 var previous = {origin:""}
 var cursor = 0
 while cursor < queue.size():
  var id = queue[cursor]
  cursor += 1
  if id == destination: break
  for next in graph[id]:
   if previous.has(next): continue
   previous[next] = id
   queue.append(next)
 if not previous.has(destination): return []
 var path = [destination]
 var current = destination
 while current != origin:
  current = previous[current]
  path.push_front(current)
 return path
static func quote(origin: String, destination: String, mass: int) -> Dictionary:
 var path = route(origin,destination)
 if path.is_empty(): return {"error":"Sin ruta de saltos de hasta 30 años luz, o destino igual al origen."}
 var hops = path.size()-1
 return {"origin":origin,"destination":destination,"route":path,"hops":hops,"days":4+hops*7,"cost":10000+hops*2500+mass*40,"mass":mass}
static func valid(value: Variant, location: String, day: int) -> bool:
 if not value is Dictionary: return false
 if value.is_empty(): return true
 for key in ["started","arrival","cost","hops","mass","days"]:
  if not preload("res://sim/operations.gd").integer(value.get(key),0,1000000000): return false
 if value.get("origin") != location or value.arrival <= day or value.started > day: return false
 if not value.get("route") is Array or value.route.size()<2: return false
 if value.route[0] != value.origin or value.route[-1] != value.get("destination"): return false
 if value.hops != value.route.size()-1 or value.days != 4+value.hops*7 or value.arrival != value.started+value.days: return false
 if value.cost != 10000+value.hops*2500+value.mass*40: return false
 var seen = []
 for i in range(value.route.size()):
  var item = U.system(str(value.route[i]))
  if item.is_empty() or item.id in seen: return false
  seen.append(item.id)
  if i>0:
   var before = U.system(value.route[i-1])
   if Vector2(item.x,item.y).distance_to(Vector2(before.x,before.y))>30.001: return false
 return true
