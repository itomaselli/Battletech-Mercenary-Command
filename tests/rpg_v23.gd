extends SceneTree
const C=preload("res://sim/campaign.gd")
func _initialize():
 var s=C.new(23)
 s.rpg_command("configure",{"origin":"oficial","specialty":"mando","motivation":"prestigio"})
 var contact=s.RPG.Agenda.known(s)[0]
 var initial=s.state.funds
 s.rpg_command("delegation",{"action":"assign","person":4,"objective":"supply","contact":contact})
 assert(s.state.funds==initial-8000 and not s.person_available(s.person_by_id(4)))
 s.advance(3)
 assert(s.RPG.waiting(s))
 var day=s.state.day
 s.advance(5)
 assert(s.state.day==day)
 assert(s.save_game("user://rpg23.json")==OK)
 var loaded=C.new()
 assert(loaded.load_game("user://rpg23.json")==OK and loaded.state==s.state)
 var j=s.state.rpg.delegation.jobs[0]
 var supplies=s.state.supplies
 s.rpg_command("delegation",{"action":"approve","id":j.id})
 s.advance(1)
 assert(s.state.supplies==supplies+10)
 assert(s.state.funds==initial-j.quote)
 var funds=s.state.funds
 s.rpg_command("delegation",{"action":"approve","id":j.id})
 assert(s.state.funds==funds)
 assert(s.state.rpg.delegation.reputation[contact].reliability==1)
 print("v0.23: depósito, disponibilidad, consulta, autorización, devolución y reputación OK")
 quit()
