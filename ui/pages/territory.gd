extends RefCounted
static func draw(host):
 var UI=host.UI;var sim=host.sim
 host.page_title.text=sim.Universe.system(sim.state.location_id).name.to_upper()+" · ZONA DE OPERACIONES"
 host.tabs.get_parent().hide()
 var terrain=preload("res://ui/territory_view.gd").new();terrain.host=host
 terrain.texture=ImageTexture.create_from_image(preload("res://visual/art.gd").map_image(int(sim.state.military.seed)+sim.state.location_id.hash(),0))
 host.content.add_child(terrain)
 var bar=HBoxContainer.new();host.content.add_child(bar)
 for spec in [["CONTRATOS","Operaciones","Contratos"],["RUTAS","Mundo","Atlas"],["INTELIGENCIA","Mundo","Región"]]:
  UI.button(bar,spec[0],func():host.navigate(spec[1],spec[2])).add_theme_font_size_override("font_size",13)
 UI.muted(host.content,"Entorno local ilustrativo · combate y posiciones confirmadas en Batalla").add_theme_font_size_override("font_size",12)
 host.set_task("PREPARAR OPERACIÓN →" if not sim.state.accepted.is_empty() else "REVISAR CONTRATO →",func():host.navigate("Operaciones","Plan" if not sim.state.accepted.is_empty() else "Contratos"))
