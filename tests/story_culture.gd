extends SceneTree
const C=preload("res://sim/campaign.gd")
func _initialize():
 var s=C.new(35)
 var cash=s.state.funds
 s.rpg_command("story_culture",{"action":"bonus"})
 assert(s.state.funds==cash-6000 and s.state.story.culture.practices.sharing==1)
 var unchanged=s.state.duplicate(true)
 s.rpg_command("story_culture",{"action":"bonus"})
 assert(s.state==unchanged)
 s.grant_leave(0)
 assert(s.state.story.culture.practices.care==1)
 var uid=s.state.mechs[0].uid
 s.state.story.culture.units[str(uid)].pilots={"0":2}
 var trust=s.state.rpg.social.ties["0"].trust
 assert(not s.Story.Culture.sale_warning(s,uid).is_empty())
 s.sell_mech(uid)
 assert(s.state.story.culture.units[str(uid)].sold)
 assert(s.state.rpg.social.ties["0"].trust==trust-1)
 assert(s.save_game("user://story35.json")==OK)
 var loaded=C.new()
 assert(loaded.load_game("user://story35.json")==OK and loaded.state==s.state)
 print("v0.35: reparto, coste real, cooldown, cuidado, vínculo y venta persistente OK")
 quit()
