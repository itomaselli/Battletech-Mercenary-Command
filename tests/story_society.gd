extends SceneTree
const C=preload("res://sim/campaign.gd")
func _initialize():
 var s=C.new(37)
 s.rpg_command("configure",{"origin":"oficial","specialty":"mando","motivation":"proteccion"})
 s.rpg_command("story_objective",{"action":"choose","kind":"community"})
 for i in range(3):
  s.rpg_command("story_objective",{"action":"material"})
  if i<2:s.advance(7)
 assert(s.Story.Objectives.current(s).is_empty())
 var local=s.state.story.society.locals[s.state.location_id]
 assert(local.credits==1 and local.standing==2)
 # Let optional requests expire naturally; pacing must never exceed two.
 for i in range(90):
  for issue in s.state.issues.duplicate():
   s.resolve_issue(issue.id,"standard" if issue.kind=="medical" else "release" if issue.kind=="salary" else "separate" if issue.kind=="team_conflict" else "cancel")
  s.advance(1)
  assert(s.Story.Society.load_count(s)<=2)
  var p=s.state.story.society.pending
  if not p.is_empty() and p.kind=="aid":
   var supply=s.state.supplies
   s.rpg_command("story_local",{"action":"accept"})
   assert(s.state.supplies==supply+10 and local.credits==0)
 assert(s.state.day==104 and local.credits==0)
 assert(s.save_game("user://story37.json")==OK)
 var loaded=C.new()
 assert(loaded.load_game("user://story37.json")==OK and loaded.state==s.state)
 s.advance(1);loaded.advance(1)
 assert(s.state==loaded.state)
 print("v0.37: comunidad, reciprocidad causal, 90 días, carga máxima y continuidad OK")
 quit()
