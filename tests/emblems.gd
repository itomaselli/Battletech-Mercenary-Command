extends SceneTree
var failed=false
func check(ok,label):
 if not ok:failed=true;printerr("FAIL: "+label)
func _initialize():call_deferred("run")
func run():
 var E=load("res://visual/emblems.gd")
 check(E.NAMES.size()==50,"50 named emblems")
 var regions={}
 for i in range(50):
  var icon=E.texture(i);check(icon!=null and icon.atlas!=null,"Texture "+str(i))
  check(icon.region.end.x<=icon.atlas.get_width()+1 and icon.region.end.y<=icon.atlas.get_height()+1,"Atlas bounds")
  regions[str(icon.region)]=true
 check(regions.size()==50,"50 distinct atlas regions")
 var C=load("res://sim/campaign.gd");var sim=C.new(46);sim.state.emblem_id=49
 var path="user://emblem-test-%d.json"%Time.get_ticks_usec()
 check(sim.save_game(path)==OK,"Save emblem")
 var loaded=C.new();check(loaded.load_game(path)==OK and loaded.state.emblem_id==49,"Load emblem")
 var invalid=JSON.parse_string(FileAccess.get_file_as_string(path));invalid.emblem_id=50
 var file=FileAccess.open(path,FileAccess.WRITE);file.store_string(JSON.stringify(invalid));file.close()
 check(loaded.load_game(path)==ERR_INVALID_DATA,"Reject invalid emblem")
 DirAccess.remove_absolute(path)
 var wizard=load("res://ui/pages/new_career.gd").new();wizard.emblem_id=37
 check(wizard.build().state.emblem_id==37,"Career emblem")
 if not failed:print("EMBLEMS_PASS: 50 regions, save/load, validation, career")
 quit(1 if failed else 0)
