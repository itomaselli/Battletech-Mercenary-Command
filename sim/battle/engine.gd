extends RefCounted
## JSON-only state, deterministic ticks, no scene tree or campaign mutations.
const W = 80
const H = 25
const LIMIT = 240
const ORDERS = ["advance", "recon", "defend", "press", "escort", "reserve", "withdraw"]
const ORDER_LABELS = {"advance":"avanzar", "recon":"reconocer", "defend":"defender", "press":"presionar", "escort":"escoltar", "reserve":"reserva", "withdraw":"retirar"}
const RESULT_LABELS = {"success":"objetivo cumplido", "partial":"cumplimiento parcial", "failure":"objetivo no cumplido"}
const ATTITUDES = ["careful", "balanced", "aggressive"]
const KINDS = ["escort", "recon", "defense", "interdiction", "extraction", "recovery"]

static func distance(a: Dictionary, b: Dictionary) -> int:
 return maxi(absi(int(a.x)-int(b.x)), absi(int(a.y)-int(b.y)))

static func event(b: Dictionary, text: String, important: bool = false):
 b.events.append({"tick":int(b.tick), "text":text})
 if b.events.size()>100: b.events.pop_front()
 if important: b.alert = text

static func unit(id: int, side: String, x: int, y: int, source: Dictionary) -> Dictionary:
 return {"id":id,"side":side,"x":x,"y":y,"hp":int(source.get("hp",100)),"initial_hp":int(source.get("hp",100)),
  "name":source.get("name","Contacto"),"model":source.get("model",""),"group":source.get("group","Alfa"),
  "fire":int(source.get("fire",4)),"speed":int(source.get("speed",4)),"sensor":int(source.get("sensor",4)),
  "armor":int(source.get("armor",4)),"skill":int(source.get("skill",3)),"fatigue":int(source.get("fatigue",0)),
  "value":source.get("value","duty"),"pilot":source.get("pilot",-1),"vehicle":bool(source.get("vehicle",false)),"heat":0,"ammo":45,"escaped":false,"intent":"En posición"}

static func create(seed_value: int, roster: Array, kind: String, terrain: String, difficulty: int, attitude: String = "balanced", danger: int = 100) -> Dictionary:
 var b = {"version":1,"seed":seed_value,"tick":0,"kind":kind if kind in KINDS else "escort","terrain":terrain,
  "tiles":[],"units":[],"groups":{},"pending":[],"contacts":{},"events":[],"alert":"",
  "shots":[],"progress":0,"asset_hp":100,"done":false,"result":"","seen":[],"objective":{"x":64,"y":12},"convoy":{"x":5,"y":12}}
 var rng = RandomNumberGenerator.new();rng.seed=seed_value
 for y in range(H):
  for x in range(W):
   var tile = 0
   var roll = rng.randi_range(0,99)
   if roll<18:tile=1 # woods
   elif roll<(35 if terrain=="colinas" else 25):tile=2 # ridge
   elif roll<30:tile=3 # water (vehicles cannot cross)
   elif roll<37 and terrain=="urbano":tile=4 # buildings
   if y in [6,12,18] or x in [5,40,64,75]:tile=5 # connected guaranteed corridors
   b.tiles.append(tile)
 for i in range(roster.size()):
  var u=unit(int(roster[i].uid),"own",5,9+i*2,roster[i]);b.units.append(u)
 for group in ["Alfa","Bravo"]:
  b.groups[group]={"order":"defend" if kind=="defense" else "escort" if b.kind=="escort" else "advance","attitude":attitude,"x":25 if kind=="defense" else 64,"y":12}
 if kind=="defense":b.objective.x=25
 if kind=="interdiction":b.convoy={"x":64,"y":0}
 for i in range(clampi(2+int(difficulty/5),2,5)):
  b.units.append(unit(-1-i,"enemy",38+i*5,6+i*3,{"hp":clampi(60+difficulty*2,60,100),"fire":clampi(roundi((3+int(difficulty/5))*danger/100.0),1,20),"speed":3,"sensor":3,"armor":3}))
 event(b,"Enlace establecido. Objetivo marcado; fuerzas hostiles sin confirmar.")
 observe(b)
 return b

static func los(b: Dictionary, a: Dictionary, z: Dictionary) -> bool:
 var steps = distance(a,z)
 for i in range(1,steps):
  var x = roundi(lerpf(a.x,z.x,float(i)/steps));var y=roundi(lerpf(a.y,z.y,float(i)/steps))
  if b.tiles[y*W+x] in [2,4]:return false
 return true

static func observe(b: Dictionary):
 for enemy in b.units:
  if enemy.side!="enemy":continue
  var visible=false
  for own in b.units:
   if own.side=="own" and own.hp>0 and not own.escaped and distance(own,enemy)<=10+own.sensor-(3 if own.hp<40 else 0) and los(b,own,enemy):visible=true;break
  var key=str(enemy.id)
  if visible:
   if not b.contacts.has(key):event(b,"Contacto hostil avistado en sector %d,%d."%[enemy.x,enemy.y],true)
   b.contacts[key]={"id":enemy.id,"x":enemy.x,"y":enemy.y,"last_seen":int(b.tick),"disabled":enemy.hp<=0}

static func public_view(b: Dictionary) -> Dictionary:
 if b.is_empty():return {}
 var own=[]
 for u in b.units:
  if u.side=="own":own.append(u.duplicate(true))
 return {"tick":b.tick,"tiles":b.tiles.duplicate(),"units":own,"contacts":b.contacts.values().duplicate(true),
  "groups":b.groups.duplicate(true),"pending":b.pending.duplicate(true),"events":b.events.duplicate(true),"alert":b.alert,
  "progress":b.progress,"asset_hp":b.asset_hp,"done":b.done,"result":b.result,"kind":b.kind,
  "objective":b.objective.duplicate(),"convoy":b.convoy.duplicate(),"limit":LIMIT,"shots":b.get("shots",[]).duplicate(true)}

static func issue(b: Dictionary, group: String, order: String, attitude: String, x: int, y: int) -> String:
 if b.done:return "El encuentro ha terminado."
 if not b.groups.has(group) or not order in ORDERS or not attitude in ATTITUDES or x<0 or x>=W or y<0 or y>=H:return "Orden inválida."
 if not b.units.any(func(u):return u.side=="own" and u.group==group and u.hp>0 and not u.escaped):return "No hay unidades operativas en ese grupo."
 if b.pending.any(func(p):return p.group==group):return "Ese grupo ya tiene una orden en tránsito."
 b.pending.append({"group":group,"due":int(b.tick)+2,"order":order,"attitude":attitude,"x":x,"y":y})
 event(b,"%s: transmitida orden %s; recepción en 20 segundos."%[group,ORDER_LABELS[order]])
 return "Orden transmitida."

static func passable(b: Dictionary, u: Dictionary, x: int, y: int) -> bool:
 return x>=0 and x<W and y>=0 and y<H and (not u.vehicle or b.tiles[y*W+x]!=3)

static func move(b: Dictionary, u: Dictionary, target: Dictionary):
 if distance(u,target)==0:return
 # Breadth-first path avoids water cul-de-sacs; random maps always have connected roads.
 var start=int(u.y)*W+int(u.x);var goal=int(target.y)*W+int(target.x)
 var occupied={}
 for other in b.units:
  if other.id!=u.id and other.hp>0 and not other.escaped:occupied[int(other.y)*W+int(other.x)]=true
 if occupied.has(goal):
  var choices=[]
  for d in [[1,0],[0,1],[0,-1],[-1,0]]:
   var x=target.x+d[0];var y=target.y+d[1]
   if passable(b,u,x,y) and not occupied.has(y*W+x):choices.append({"x":x,"y":y})
  if choices.is_empty():return
  choices.sort_custom(func(a,z):return distance(u,a)<distance(u,z))
  goal=int(choices[0].y)*W+int(choices[0].x)
 if goal==start:return
 var queue=[start];var parents={start:-1};var head=0
 while head<queue.size() and not parents.has(goal):
  var cell=int(queue[head]);head+=1
  for delta in [[1,0],[0,1],[0,-1],[-1,0]]:
   var x=cell%W+delta[0];var y=int(cell/W)+delta[1];var next=y*W+x
   if not passable(b,u,x,y) or parents.has(next) or occupied.has(next):continue
   parents[next]=cell;queue.append(next)
 if not parents.has(goal):u.intent="Acceso bloqueado; marque una vía transitable";return
 var step=goal
 while parents[step]!=start and parents[step]!=-1:step=parents[step]
 u.x=step%W;u.y=int(step/W)

static func tick(b: Dictionary):
 if b.done:return
 b.tick+=1;b.alert="";b.shots=[]
 for p in b.pending.duplicate():
  if p.due<=b.tick:
   b.groups[p.group]={"order":p.order,"attitude":p.attitude,"x":p.x,"y":p.y};b.pending.erase(p)
   event(b,"%s confirma nueva directiva."%p.group)
 var rng=RandomNumberGenerator.new();rng.seed=int(b.seed)+int(b.tick)*7919
 for u in b.units:
  if u.hp<=0 or u.escaped:continue
  u.heat=maxi(0,u.heat-7)
  var own=u.side=="own"
  var g=b.groups[u.group] if own else {"order":"press","attitude":"balanced","x":b.objective.x,"y":b.objective.y}
  var order=g.order
  if own and g.attitude=="careful" and u.hp<maxi(20,int(u.initial_hp*(0.60 if u.get("value","duty")=="care" else 0.5 if u.get("value","duty")=="craft" else 0.4))) and order!="withdraw":
   order="withdraw"
   if u.intent!="Retirada por preservación":event(b,"%s inicia retirada por integridad crítica, conforme a la actitud cautelosa."%u.name,true)
  var target={"x":g.x,"y":g.y}
  if order=="withdraw":target={"x":0,"y":u.y};u.intent="Retirada por preservación"
  elif order=="escort":target={"x":mini(75,b.convoy.x+3),"y":clampi(b.convoy.y+(2 if u.id%2==0 else -2),0,H-1)};u.intent="Cubriendo convoy"
  else:u.intent={"advance":"Avanzando","press":"Presionando","recon":"Reconociendo","defend":"Defendiendo sector","reserve":"En reserva"}.get(order,"En posición")
  var enemies=[]
  for e in b.units:
   if e.side!=u.side and e.hp>0 and not e.escaped and distance(u,e)<=10+u.sensor and los(b,u,e):enemies.append(e)
  enemies.sort_custom(func(a,z):return distance(u,a)<distance(u,z))
  var contact={} if enemies.is_empty() else enemies[0]
  if not contact.is_empty() and order=="press":target=contact
  var mobile=order!="reserve" and (order!="defend" or distance(u,target)>1)
  if order=="recon" and not contact.is_empty() and distance(u,contact)<7:target={"x":maxi(0,u.x-3),"y":u.y}
  var cadence=1 if u.speed>=5 else 2
  if u.hp<30:cadence+=1
  var ground=int(b.tiles[int(u.y)*W+int(u.x)])
  if ground==5:cadence=maxi(1,cadence-1)
  elif ground in [1,2,3]:cadence+=1
  if mobile and b.tick%cadence==0:move(b,u,target)
  if order=="withdraw" and u.x==0:u.escaped=true;event(b,"%s alcanzó la extracción."%u.name,true);continue
  if not contact.is_empty() and order!="reserve" and distance(u,contact)<=9+int(u.fire/2) and los(b,u,contact) and u.heat<55:
   var tile=int(b.tiles[int(contact.y)*W+int(contact.x)])
   var chance=65+(8 if g.attitude=="aggressive" else -5 if g.attitude=="careful" else 0)+u.skill*4-int(u.fatigue/5)-(18 if tile in [1,2,4] else 0)-(15 if u.hp<40 else 0)
   u.heat+=(24 if g.attitude=="aggressive" else 14 if g.attitude=="careful" else 18) if not u.vehicle else 5
   var damage=maxi(1,u.fire+3-int(contact.armor/2))
   if u.ammo>0:u.ammo-=1
   else:damage=maxi(1,int(damage/2)) # energy fallback
   # Show fire only when both endpoints are known to the commander.
   if own and b.contacts.has(str(contact.id)) and b.contacts[str(contact.id)].last_seen>=b.tick-1:
    b.shots.append({"x":u.x,"y":u.y,"tx":contact.x,"ty":contact.y})
   if rng.randi_range(0,99)<chance:
    contact.hp=maxi(0,contact.hp+(-damage))
    if contact.hp==0 and contact.side=="own":event(b,"%s inmovilizado; dotación solicita recuperación."%contact.name,true)
 observe(b)
 objectives(b)
 if b.done:
  b.pending=[]
  return
 var alive=b.units.filter(func(u):return u.side=="own" and u.hp>0 and not u.escaped)
 if b.progress>=100 or b.tick>=LIMIT or alive.is_empty() or b.asset_hp<=0:
  b.done=true
  b.pending=[]
  b.result="success" if b.progress>=75 and b.asset_hp>0 else "partial" if b.progress>=35 else "failure"
  if alive.is_empty() and b.kind=="defense":b.result="failure"
  event(b,"Encuentro finalizado: %s. Progreso %d%%; regreso y liquidación al completar el plazo del contrato."%[RESULT_LABELS[b.result],b.progress],true)

static func objectives(b: Dictionary):
 var own=b.units.filter(func(u):return u.side=="own" and u.hp>0 and not u.escaped)
 var enemies=b.units.filter(func(u):return u.side=="enemy" and u.hp>0 and not u.escaped)
 var near=own.filter(func(u):return distance(u,b.objective)<=5).size()
 var hostile=enemies.filter(func(u):return distance(u,b.objective)<=7).size()
 match b.kind:
  "escort":
   var escorts=own.filter(func(u):return distance(u,b.convoy)<=9).size()
   var threats=enemies.filter(func(u):return distance(u,b.convoy)<=9).size()
   if escorts>0 and b.tick%2==0:b.convoy.x=mini(75,b.convoy.x+1)
   if threats>0:b.asset_hp=maxi(0,b.asset_hp-threats)
   b.progress=int((b.convoy.x-5)*100/70)
  "defense":
   if hostile>near:b.asset_hp=maxi(0,b.asset_hp-(hostile-near))
   b.progress=int(mini(100,b.asset_hp)*b.tick/LIMIT)
  "recon":
   for u in own:
    var sector=clampi(int(u.x/16),0,4)
    if not sector in b.seen:b.seen.append(sector)
   b.progress=mini(100,b.seen.size()*20)
  "interdiction":
   # Hostile transports cross the eastern corridor; deny escape before timeout.
   if b.tick>72 and b.tick%6==0:b.convoy.y=mini(24,b.convoy.y+1)
   var attackers=own.filter(func(u):return distance(u,b.convoy)<=10 and los(b,u,b.convoy)).size()
   if attackers>0:b.asset_hp=maxi(0,b.asset_hp-attackers*3)
   b.progress=100-b.asset_hp
   if b.convoy.y==24 and b.asset_hp>0:b.done=true;b.result="partial" if b.progress>=35 else "failure";event(b,"Transportes abandonaron el área.",true)
  "extraction", "recovery":
   if near>0 and hostile==0:b.progress=mini(100,b.progress+near*2)
 # Destroying the hostile convoy is the interdiction objective, not a friendly loss.
 if b.kind=="interdiction" and b.progress>=100:b.done=true;b.result="success";event(b,"Transportes detenidos.",true)

static func run(b: Dictionary):
 while not b.done:tick(b)

static func valid(value: Variant) -> bool:
 var b=canonical(value)
 if not b is Dictionary:return false
 for key in ["version","seed","tick","kind","terrain","tiles","units","groups","pending","contacts","events","alert","progress","asset_hp","done","result","seen","objective","convoy"]:
  if not b.has(key):return false
 if not b.get("shots",[]) is Array or b.get("shots",[]).size()>9:return false
 for shot in b.get("shots",[]):
  if not shot is Dictionary:return false
  for k in ["x","y","tx","ty"]:
   if not shot.get(k) is int or shot[k]<0 or shot[k]>=(W if k in ["x","tx"] else H):return false
 if not b.seed is int or not b.terrain is String or not b.alert is String:return false
 if b.version!=1 or not b.tick is int or b.tick<0 or b.tick>LIMIT or not b.kind in KINDS:return false
 if not b.tiles is Array or b.tiles.size()!=W*H or not b.units is Array or b.units.size()<3 or b.units.size()>9:return false
 for tile in b.tiles:
  if not tile is int or tile<0 or tile>5:return false
 var ids=[]
 var own_count=0
 for u in b.units:
  if not u is Dictionary:return false
  for key in ["id","side","x","y","hp","initial_hp","name","model","group","fire","speed","sensor","armor","skill","fatigue","vehicle","heat","ammo","escaped","intent"]:
   if not u.has(key):return false
  for key in ["id","x","y","hp","initial_hp","fire","speed","sensor","armor","skill","fatigue","heat","ammo"]:
   if not u[key] is int:return false
  if u.id in ids:return false
  ids.append(u.id)
  if u.side=="own":own_count+=1
  if not u.get("value","duty") in ["care","craft","duty"] or not u.get("pilot",-1) is int:return false
  if not u.name is String or not u.model is String or not u.intent is String or not u.escaped is bool or not u.vehicle is bool:return false
  if not u.group in ["Alfa","Bravo"] or u.initial_hp<0 or u.initial_hp>100 or u.hp>u.initial_hp or u.ammo<0 or u.ammo>45 or u.heat<0 or u.heat>100:return false
  for key in ["fire","speed","sensor","armor","skill"]:
   if u[key]<0 or u[key]>20:return false
  if u.fatigue<0 or u.fatigue>100:return false
  if u.x<0 or u.x>=W or u.y<0 or u.y>=H or u.hp<0 or u.hp>100 or not u.side in ["own","enemy"]:return false
 if own_count<1 or own_count>4:return false
 if not b.groups is Dictionary or not b.pending is Array or not b.contacts is Dictionary or not b.events is Array or not b.seen is Array:return false
 if b.pending.size()>2 or b.contacts.size()>5 or b.events.size()>100 or b.seen.size()>5:return false
 for n in b.seen:
  if not n is int or n<0 or n>4:return false
 for name in ["Alfa","Bravo"]:
  if not b.groups.has(name) or not valid_order(b.groups[name]):return false
 for p in b.pending:
  if not p is Dictionary or not valid_order(p) or not p.get("group") in ["Alfa","Bravo"] or not p.get("due") is int:return false
  if p.due<=b.tick or p.due>b.tick+2:return false
 for pos in [b.objective,b.convoy]:
  if not pos is Dictionary or not pos.get("x") is int or not pos.get("y") is int:return false
  if pos.x<0 or pos.x>=W or pos.y<0 or pos.y>=H:return false
 for c in b.contacts.values():
  if not c is Dictionary:return false
  for key in ["id","x","y","last_seen"]:
   if not c.get(key) is int:return false
  if not c.get("disabled") is bool or c.x<0 or c.x>=W or c.y<0 or c.y>=H or c.last_seen<0 or c.last_seen>b.tick:return false
 for e in b.events:
  if not e is Dictionary or not e.get("tick") is int or not e.get("text") is String:return false
 if b.done and b.result=="":return false
 if not b.done and b.result!="":return false
 return b.done is bool and b.result in ["","success","partial","failure"] and b.progress is int and b.progress>=0 and b.progress<=100 and b.asset_hp is int and b.asset_hp>=0 and b.asset_hp<=100

static func valid_order(g: Variant) -> bool:
 return g is Dictionary and g.get("order") in ORDERS and g.get("attitude") in ATTITUDES and g.get("x") is int and g.get("y") is int and g.x>=0 and g.x<W and g.y>=0 and g.y<H

static func canonical(value: Variant) -> Variant:
 if value is float and is_finite(value) and value==int(value):return int(value)
 if value is Array:
  var a=[]
  for v in value:a.append(canonical(v))
  return a
 if value is Dictionary:
  var d={}
  for k in value:d[k]=canonical(value[k])
  return d
 return value
