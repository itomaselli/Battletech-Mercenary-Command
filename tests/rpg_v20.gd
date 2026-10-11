extends SceneTree
const C=preload("res://sim/campaign.gd")
func _initialize():
 for package in ["cash","pay","transport","insurance","salvage"]:
  var s=C.new(20)
  s.rpg_command("configure",{"origin":"mercenario","specialty":"trato","motivation":"independencia"})
  var id=s.state.offers[0].id
  assert(s.rpg_command("negotiation",{"action":"negotiate","id":id,"package":package}).contains("pactadas"))
  assert(s.rpg_command("negotiation",{"action":"accept","id":id}).contains("aceptado"))
  var frozen=s.state.accepted.duplicate(true)
  var funds=s.state.funds
  s.rpg_command("negotiation",{"action":"accept","id":id})
  assert(s.state.funds==funds and s.state.accepted==frozen)
  s.dispatch(0,[0,1,2,3],1)
  assert(not s.state.active.is_empty())
  assert(s.save_game("user://rpg20.json")==OK)
  var loaded=C.new()
  assert(loaded.load_game("user://rpg20.json")==OK and loaded.state==s.state)
  s.state.mechs[0].hp-=10
  s.RPG.Negotiation.finish(s,"success")
  var after=s.state.funds
  s.RPG.Negotiation.finish(s,"success")
  assert(s.state.funds==after)
  if package=="insurance":assert(after==funds+1000)
  if package=="salvage":assert(s.state.rpg.negotiation.salvage.size()==1)
 print("v0.20: cinco paquetes, congelación, exclusividad, cobertura, derechos y guardado OK")
 quit()
