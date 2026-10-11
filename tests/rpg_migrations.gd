extends SceneTree
const C=preload("res://sim/campaign.gd")
func _initialize():
 for revision in range(16,25):
  var path="user://actual-rpg-%d.json"%revision
  if not FileAccess.file_exists(path):print("SKIP RPG fixture ",revision);continue
  var s=C.new()
  assert(s.load_game(path)==OK)
  assert(s.state.rpg.revision==25 and s.state.rpg.scene=="briefing")
  assert(s.state.company_name=="Continuidad RPG" and s.state.captain_name=="Capitana Histórica")
  assert(s.state.rpg.captain.bond==0 and s.state.rpg.captain.skills.trato==3)
  var funds=s.state.funds
  s.rpg_command("choose",{"choice":"professional"})
  assert(s.state.rpg.scene=="" and s.state.funds==funds)
  s.dispatch(0,[0,1,2,3],1)
  assert(not s.state.active.is_empty())
  assert(s.save_game("user://rpg-migrated.json")==OK)
  var loaded=C.new()
  assert(loaded.load_game("user://rpg-migrated.json")==OK and loaded.state==s.state)
  print("Migración RPG ",revision," → 25 conserva identidad, escena, fondos y operación")
 quit()
