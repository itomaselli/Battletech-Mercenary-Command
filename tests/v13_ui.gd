extends SceneTree
func _initialize(): call_deferred("run")
func run():
 var screen = load("res://tests/fixtures/v025_main.tscn").instantiate()
 root.add_child(screen)
 await process_frame
 var dialog = load("res://ui/catalog.gd").new()
 dialog.sim = screen.sim
 screen.add_child(dialog)
 dialog.popup_centered(Vector2i(1000,680))
 await process_frame
 print("INITIAL ",dialog.listing.item_count," category ",dialog.category.selected," YEAR ",screen.sim.state.scenario_year)
 assert(dialog.listing.item_count > 20)
 dialog.category.select(4)
 dialog.refresh()
 print("VEHICLES ",dialog.listing.item_count)
 assert(dialog.listing.item_count == 8)
 dialog.query.text = "Vedette"
 dialog.refresh()
 assert(dialog.listing.item_count == 1)
 assert(dialog.details.text.contains("Dotación"))
 for button in dialog.find_children("*","Button",true,false):
  if button.text.begins_with("Fijar"): button.pressed.emit()
 assert(dialog.comparison.text.contains("Vedette"))
 await process_frame
 assert(dialog.size.y < 850)
 if DisplayServer.get_name() != "headless":
  await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png("res://docs/v13-catalog.png")
 print("v0.13 UI: filtros, ficha y dimensiones OK")
 quit()
