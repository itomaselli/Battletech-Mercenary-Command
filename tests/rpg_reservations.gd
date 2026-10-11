extends SceneTree
const C=preload("res://sim/campaign.gd")
func _initialize():
 var s=C.new(77)
 s.rpg_command("configure",{"origin":"oficial","specialty":"mando","motivation":"proteccion"})
 var contact=s.RPG.Agenda.known(s)[0]
 var uid=s.state.mechs[0].uid
 s.rpg_command("delegation",{"action":"assign","person":4,"objective":"security","contact":contact,"uid":uid})
 assert(s.state.rpg.delegation.jobs.size()==1)
 var funds=s.state.funds
 s.person_by_id(4).rest_until=0
 assert(not s.person_available(s.person_by_id(4)))
 s.rpg_command("agenda",{"action":"visit","person":4,"contact":contact})
 s.rpg_command("workshop",{"action":"reserve","uid":uid})
 s.rpg_command("workshop",{"action":"cannibalize","uid":uid})
 s.sell_mech(uid)
 s.set_stored(uid,true)
 assert(s.state.mechs[0].hp==100 and not s.state.mechs[0].stored and not s.mech_ready(0))
 assert(s.state.funds==funds and s.state.rpg.agenda.jobs.is_empty())
 assert(s.travel_quote(s.Universe.galatea()).has("error"))
 var j=s.state.rpg.delegation.jobs[0]
 s.rpg_command("delegation",{"action":"cancel","id":j.id})
 assert(s.person_available(s.person_by_id(4)) and s.mech_ready(0))
 assert(s.state.funds==funds+8000)
 s.rpg_command("delegation",{"action":"cancel","id":j.id})
 assert(s.state.funds==funds+8000)
 print("RPG: reservas no eludibles, exclusión de tareas, cancelación y depósito único OK")
 quit()
