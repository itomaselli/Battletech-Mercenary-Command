extends SceneTree
const C=preload("res://sim/campaign.gd")
func _initialize():
 var s=C.new(44)
 s.rpg_command("configure",{"origin":"oficial","specialty":"mando","motivation":"deuda"})
 var original=s.state.duplicate(true)
 var errors=[]
 var b=original.duplicate(true)
 b.rpg.jobs=[{"kind":"conversation","due":1,"person":0,"topic":"bad"}];errors.append(b)
 b=original.duplicate(true);b.rpg.social.ties["0"].memories=[null];errors.append(b)
 b=original.duplicate(true);b.rpg.arcs.retired=true;errors.append(b)
 b=original.duplicate(true);b.rpg.arcs.settings.danger=1000;errors.append(b)
 b=original.duplicate(true);b.rpg.workshop.parts.mobility=-1;errors.append(b)
 b=original.duplicate(true);b.rpg.adventures.cooldowns["bad"]="invalid";errors.append(b)
 b=original.duplicate(true);b.rpg.social.perks=["analista","analista"];errors.append(b)
 for bad in errors:
  bad.rng_state=str(s.rng.state)
  var f=FileAccess.open("user://rpg-invalid.json",FileAccess.WRITE)
  f.store_string(JSON.stringify(bad));f.close()
  assert(s.load_game("user://rpg-invalid.json")==ERR_INVALID_DATA)
  assert(s.state==original)
 print("RPG: siete corrupciones rechazadas sin alterar campaña")
 quit()
