extends SceneTree
func _initialize(): call_deferred("run")
func run():
 var screen = load("res://tests/fixtures/v025_main.tscn").instantiate()
 root.add_child(screen)
 await process_frame
 screen.show_management(4)
 await process_frame
 var dialog = screen.get_child(screen.get_child_count()-1)
 for viewport_size in [Vector2i(1224,864),Vector2i(1100,740)]:
  root.size = viewport_size
  for tab in [4,5]:
   dialog.tabs.current_tab = tab
   for frame in range(4): await process_frame
   var pictures = dialog.tabs.get_child(tab).find_children("*","TextureRect",true,false)
   assert(pictures.size() == 4)
   for picture in pictures:
    var description = picture.get_parent().get_child(1)
    assert(picture.size == Vector2(48,72))
    assert(description.size.x > 400)
    assert(description.size.y < 100)
    assert(picture.stretch_mode == TextureRect.STRETCH_KEEP_ASPECT_CENTERED)
   if DisplayServer.get_name() != "headless":
    await RenderingServer.frame_post_draw
    root.get_texture().get_image().save_png("res://docs/unit-cards-%d-%d.png" % [tab,viewport_size.x])
 print("Fichas: Hangar y Mercado, dos tamaños; sprites 48×72 y texto con ancho disponible OK")
 quit()
