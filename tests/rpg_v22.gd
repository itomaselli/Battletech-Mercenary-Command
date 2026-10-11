extends SceneTree
const C=preload("res://sim/campaign.gd")
func setup():
 var s=C.new(22)
 s.rpg_command("configure",{"origin":"oficial","specialty":"trato","motivation":"proteccion"})
 s.RPG.Conflicts.ensure(s)
 return s
func _initialize():
 var a=setup()
 var b=setup()
 a.rpg_command("conflict",{"action":"supply"})
 var ca=a.state.rpg.conflicts.regions[a.state.location_id]
 var cb=b.state.rpg.conflicts.regions[b.state.location_id]
 assert(ca.tension<cb.tension and ca.resources>cb.resources)
 var stock=a.state.supplies
 a.rpg_command("conflict",{"action":"supply"})
 assert(a.state.supplies==stock)
 a.advance(7)
 b.advance(7)
 assert(ca.tension<cb.tension)
 a.RPG.Conflicts.affect(a,a.state.location_id,-10,"Acuerdo de prueba")
 assert(ca.status=="settled")
 assert(a.save_game("user://rpg22.json")==OK)
 var loaded=C.new()
 assert(loaded.load_game("user://rpg22.json")==OK and loaded.state==a.state)
 assert(b.state.rpg.conflicts.regions.size()==1)
 print("v0.22: contrafactual regional, cooldown, consecuencias, cierre y persistencia OK")
 quit()
