extends SceneTree
const C=preload("res://sim/campaign.gd")
func _initialize():
 var signatures={}
 for seed_value in range(8):
  var s=C.new(800+seed_value)
  s.rpg_command("configure",{"origin":"mercenario","specialty":"trato","motivation":"proteccion","bond":seed_value%4})
  s.rpg_command("story_objective",{"action":"choose","kind":"community" if seed_value%2==0 else "person","person":seed_value%4})
  var initial_rng=s.rng.state
  var signature=[]
  for profile in s.state.story.people.profiles.values():signature.append(profile.goal+profile.value)
  signatures["/".join(signature)]=true
  for day in range(90):
   for issue in s.state.issues.duplicate():s.resolve_issue(issue.id,"standard" if issue.kind=="medical" else "release" if issue.kind=="salary" else "separate" if issue.kind=="team_conflict" else "cancel")
   var g=s.Story.Objectives.current(s)
   if not g.is_empty() and s.state.story.objectives.jobs.is_empty():s.rpg_command("story_objective",{"action":"material"})
   for request in s.Story.People.pending(s):
    s.rpg_command("story_people",{"action":"support" if seed_value%2==0 else "decline","id":request.id})
   if not s.state.story.society.pending.is_empty():s.rpg_command("story_local",{"action":"accept"})
   s.advance(1)
   assert(s.Story.Society.load_count(s)<=2)
   assert(s.Story.valid(s.state.story,s.state.day) and s.Story.valid_links(s.state))
   if day%15==0:
    assert(s.save_game("user://story-campaigns.json")==OK)
    var copy=C.new()
    assert(copy.load_game("user://story-campaigns.json")==OK and copy.state==s.state)
    assert(copy.rng.state==s.rng.state)
    s=copy
  assert(s.state.day==90 and s.rng.state==initial_rng)
  assert(s.state.story.objectives.goals[0].status=="completed")
 assert(signatures.size()>=6)
 # Same starting world, different player decisions, no effect on tactical dice stream.
 var a=C.new(999);var b=C.new(999)
 for sim in [a,b]:
  sim.rpg_command("configure",{"origin":"oficial","specialty":"mando","motivation":"proteccion"})
  sim.state.story.people.profiles["0"].goal="security";sim.advance(7)
 a.rpg_command("story_people",{"action":"support","id":1})
 b.rpg_command("story_people",{"action":"decline","id":1})
 assert(a.state.funds==b.state.funds-4000)
 assert(a.state.rpg.social.ties["0"].trust>b.state.rpg.social.ties["0"].trust)
 assert(a.rng.state==b.rng.state)
 print("Story: 8 campañas × 90 días, 48 recargas, diversidad y decisiones contrafactuales OK")
 quit()
