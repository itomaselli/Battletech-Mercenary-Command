extends SceneTree
const B=preload("res://sim/battle/engine.gd")
func _initialize():
 var roster=[]
 for i in range(4):roster.append({"uid":i,"name":"U%d"%i,"group":"Alfa" if i<2 else "Bravo","speed":5,"fire":5,"vehicle":i==3})
 var a=B.create(100,roster,"escort","llanura",8);var reserve=a.duplicate(true)
 for g in ["Alfa","Bravo"]:B.issue(reserve,g,"reserve","balanced",5,12)
 B.run(a);B.run(reserve)
 assert(a.progress>reserve.progress,"Orders must affect objective")
 var fog=B.create(1,roster,"escort","llanura",6)
 assert(B.public_view(fog).contacts.is_empty())
 var enemy=fog.units[4];enemy.x=7;enemy.y=12
 for i in range(B.W*B.H):fog.tiles[i]=0
 B.observe(fog);assert(not fog.contacts.is_empty())
 var reported=fog.contacts[str(enemy.id)].duplicate(true)
 enemy.x=79;enemy.y=24;fog.tick=1;B.observe(fog)
 assert(fog.contacts[str(enemy.id)]==reported,"Lost contact must not track hidden movement")
 var saved=B.canonical(JSON.parse_string(JSON.stringify(fog)))
 B.run(fog);B.run(saved);assert(fog==saved)
 var retreat=B.create(32,roster,"escort","llanura",9)
 for g in ["Alfa","Bravo"]:B.issue(retreat,g,"withdraw","careful",0,12)
 B.run(retreat)
 assert(retreat.units.filter(func(u):return u.side=="own").all(func(u):return u.escaped or u.hp==0))
 for seed_value in range(12):
  var kind=B.KINDS[seed_value%6]
  var b=B.create(seed_value*31,roster,kind,["urbano","colinas","llanura"][seed_value%3],6+seed_value%8)
  B.run(b);assert(B.valid(b),"Invalid final state for seed %d"%seed_value)
  assert(b.done)
  for u in b.units:
   if u.vehicle:assert(b.tiles[int(u.y)*B.W+int(u.x)]!=3)
 var malformed=a.duplicate(true);malformed.groups.Alfa.x=-1;assert(not B.valid(malformed))
 malformed=a.duplicate(true);malformed.units[1].id=malformed.units[0].id;assert(not B.valid(malformed))
 print("BATTLE_ORDERS_PASS: agency, fog, replay, withdrawal, 12 procedural encounters, corruption")
 quit()
