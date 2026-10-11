extends SceneTree
const Art=preload("res://visual/art.gd")
func _initialize():call_deferred("run")
func run():
 var h=load("res://ui/main.tscn").instantiate();h.testing=true;h.sim=h.Campaign.new(42,3060);root.add_child(h);await process_frame
 var before=h.sim.state.duplicate(true)
 h.navigate("Mercado","Catálogo")
 for i in range(h.sim.MECH_CATALOG.size()):
  h.remember("offer",i);h.render();await process_frame
  var pictures=h.content.find_children("*","TextureRect",true,false)
  assert(pictures.size()==1)
  var image=pictures[0].texture.get_image();image.convert(Image.FORMAT_RGB8)
  assert(image.get_data()==Art.unit_sprite(h.sim.MECH_CATALOG[i].id).get_data(),"Wrong catalog image")
  assert(pictures[0].custom_minimum_size==Vector2(48,72))
 for route in ["Hangar","Taller"]:
  h.navigate("Compañía",route);await process_frame
  for m in h.sim.state.mechs:
   h.remember("uid",m.uid);h.render();await process_frame
   var pictures=h.content.find_children("*","TextureRect",true,false)
   var image=pictures[0].texture.get_image();image.convert(Image.FORMAT_RGB8)
   assert(image.get_data()==Art.unit_sprite(m.model_id).get_data())
 assert(before==h.sim.state)
 if DisplayServer.get_name()!="headless":
  h.navigate("Mercado","Catálogo");h.remember("offer",22);h.render()
  for f in range(5):await process_frame
  await RenderingServer.frame_post_draw;root.get_texture().get_image().save_png("res://docs/unit-art-in-game.png")
 print("v0.32: 56 fichas de catálogo y hangar/taller usan ID de modelo, proporción intacta y sin mutar campaña OK")
 quit()
