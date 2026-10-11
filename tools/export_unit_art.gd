extends SceneTree
const Art=preload("res://visual/art.gd")
const Catalog=preload("res://sim/catalog.gd")
func _initialize():
 DirAccess.make_dir_recursive_absolute("res://assets/units")
 for unit in Catalog.all():assert(Art.unit_sprite(unit.id).save_png("res://assets/units/"+unit.id+".png")==OK)
 print("56 PNG exportados desde las máscaras originales de visual/unit_sprites.json")
 quit()
