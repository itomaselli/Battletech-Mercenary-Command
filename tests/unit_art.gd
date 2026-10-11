extends SceneTree
const Art=preload("res://visual/art.gd")
const Catalog=preload("res://sim/catalog.gd")
func _initialize():
 var registry=JSON.parse_string(FileAccess.get_file_as_string("res://visual/unit_sprites.json"))
 assert(registry.units.size()==Catalog.all().size())
 var hashes={};var masks={};var chassis={}
 for unit in Catalog.all():
  assert(registry.units.has(unit.id))
  var entry=registry.units[unit.id];assert(entry.chassis==unit.chassis)
  var img=Art.unit_sprite(unit.id);assert(img.get_size()==Vector2i(16,24))
  var colors={};var nonempty=0
  for y in range(24):
   assert(entry.rows[y].length()==16)
   for x in range(16):
    var c=img.get_pixel(x,y);colors[c]=true
    assert(c in [Art.color(0),Art.color(int(entry.palette[0])),Art.color(int(entry.palette[1]))])
    if c!=Art.color(0):nonempty+=1
  assert(colors.size()==3 and nonempty>60)
  var digest=img.get_data().hex_encode();assert(not hashes.has(digest),"Duplicate sprite: "+unit.id);hashes[digest]=true
  var mask="".join(entry.rows);assert(not masks.has(mask),"Only recolored: "+unit.id);masks[mask]=true
  chassis[unit.chassis]=true
  var png=Image.load_from_file("res://assets/units/"+unit.id+".png");png.convert(Image.FORMAT_RGB8);assert(png.get_data()==img.get_data())
 assert(chassis.size()==32 and hashes.size()==56)
 var sim=load("res://sim/campaign.gd").new();var state=sim.state.duplicate(true);var rng=sim.rng.state
 for unit in Catalog.all():Art.unit_sprite(unit.id)
 assert(state==sim.state and rng==sim.rng.state)
 assert(sim.load_game("res://tests/fixtures/campaign-v025.json")==OK)
 for unit in sim.state.mechs:assert(registry.units.has(unit.model_id));assert(Art.unit_sprite(unit.model_id)!=null)
 print("v0.32: 56 imágenes y máscaras únicas, 32 chasis, paleta estricta, PNG fieles y guardado antiguo OK")
 quit()
