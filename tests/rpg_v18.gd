extends SceneTree
const C=preload("res://sim/campaign.gd")
func _initialize():
 var s=C.new(18)
 s.rpg_command("configure",{"origin":"tecnico","specialty":"investigacion","motivation":"proteccion"})
 for family in ["sabotage","mediation","asylum"]:
  assert(s.rpg_command("adventure",{"action":"open","family":family}).contains("abierto"))
  var c=s.state.rpg.adventures.cases.back()
  s.rpg_command("adventure",{"action":"approach","id":c.id,"approach":"records"})
  var funds=s.state.funds
  s.rpg_command("adventure",{"action":"approach","id":c.id,"approach":"records"})
  assert(s.state.funds==funds)
  s.advance(1)
  assert(c.clues.back().kind=="observación")
  assert(s.rpg_command("adventure",{"action":"resolve","id":c.id,"choice":"evidence"}).contains("resuelto"))
 assert(s.state.rpg.social.xp==3)
 assert(s.save_game("user://rpg18.json")==OK)
 var loaded=C.new()
 assert(loaded.load_game("user://rpg18.json")==OK and loaded.state==s.state)
 print("v0.18: tres familias, fuentes, coste único, alternativa segura y persistencia OK")
 quit()
