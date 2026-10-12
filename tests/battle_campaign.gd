extends SceneTree
const C=preload("res://sim/campaign.gd")
func _initialize():
 var s=C.new(700)
 s.accept_contract(0);s.dispatch_battle([0,1,2,3],1)
 assert(s.state.military.current.has("battle"))
 for i in range(15):s.battle_step()
 var path="user://battle-integration-test.json"
 assert(s.save_game(path)==OK)
 var copy=C.new();assert(copy.load_game(path)==OK)
 assert(copy.state==s.state)
 s.battle_delegate();copy.battle_delegate()
 assert(copy.state==s.state)
 var hp={}
 for u in s.state.military.current.battle.units:
  if u.side=="own":hp[u.id]=u.hp
 for i in range(20):
  if s.state.active.is_empty():break
  s.advance(1)
 assert(s.state.active.is_empty())
 for m in s.state.mechs:assert(m.hp==hp[m.uid])
 assert(s.state.military.archive.size()==1)
 var funds=s.state.funds;s.battle_delegate();assert(s.state.funds==funds)
 assert(s.save_game(path)==OK and copy.load_game(path)==OK)
 DirAccess.remove_absolute(path)
 var r=C.new(701);r.accept_contract(0);r.dispatch_battle([0,1],0)
 r.battle_step(20);r.cancel_contract()
 assert(r.state.active.is_empty() and r.state.military.archive.size()==1)
 # Base contracts originally had no partial_pay; a map can produce partial success.
 var partial=C.new(703);partial.accept_contract(0);partial.dispatch_battle([0,1,2,3],1)
 var b=partial.state.military.current.battle
 b.done=true;b.result="partial";b.progress=50;b.tick=100
 var expected=int(partial.state.active.contract.pay*0.6)-int(partial.state.active.contract.advance)
 var before=int(partial.state.funds)
 partial._resolve()
 assert(partial.state.active.is_empty() and partial.state.funds==before+expected)
 assert(partial.save_game(path)==OK and copy.load_game(path)==OK)
 DirAccess.remove_absolute(path)
 print("BATTLE_CAMPAIGN_PASS")
 quit()
