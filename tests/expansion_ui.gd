extends SceneTree
func _initialize(): call_deferred("run")
func run():
 var screen = load("res://tests/fixtures/v025_main.tscn").instantiate()
 root.add_child(screen)
 await process_frame
 screen.journal_filter.text = "Fundación"
 screen.refresh_journal()
 assert(screen.journal.get_parsed_text().contains("Fundación"))
 assert(not screen.journal.get_parsed_text().contains("Mercado"))
 screen.show_sphere()
 await process_frame
 var atlas = screen.get_child(screen.get_child_count()-1)
 assert(atlas.results.item_count == 30)
 screen.sim.Travel.build_graph()
 var destination = screen.sim.Travel.graph[screen.sim.state.location_id][0]
 atlas.select_system(destination)
 var funds = screen.sim.state.funds
 atlas.show_travel()
 await process_frame
 var confirm = atlas.get_child(atlas.get_child_count()-1)
 assert(confirm is ConfirmationDialog)
 assert(screen.sim.state.funds == funds and not screen.sim.in_transit())
 assert(confirm.dialog_text.contains("11 días"))
 if DisplayServer.get_name() != "headless":
  await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png("res://docs/v15-travel.png")
 confirm.confirmed.emit()
 await process_frame
 assert(screen.sim.in_transit())
 assert(screen.identity.text.contains("llegada"))
 atlas.hide()
 screen.show_missions()
 await process_frame
 assert(not screen.sim.state.missions.offers.is_empty())
 # A second viewport size checks responsive layout without touching user settings.
 root.size = Vector2i(1100,740)
 await process_frame
 if DisplayServer.get_name() != "headless":
  await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png("res://docs/v15-small.png")
 print("UI expansión: filtros, selección, cotización sin cargo, confirmación y tránsito OK")
 quit()
