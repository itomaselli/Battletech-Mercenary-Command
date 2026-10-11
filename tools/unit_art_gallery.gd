extends SceneTree
func _initialize():call_deferred("run")
func run():
 var sample="--sample" in OS.get_cmdline_user_args()
 root.size=Vector2i(1000,240) if sample else Vector2i(1440,1360);root.content_scale_size=root.size
 var margin=MarginContainer.new();margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 for side in ["left","right","top","bottom"]:margin.add_theme_constant_override("margin_"+side,16)
 root.add_child(margin)
 var body=VBoxContainer.new();margin.add_child(body)
 var title=Label.new();title.text="MERCENARY COMMAND · 56 UNIDADES / 32 CHASIS · 16×24 · TRES COLORES";title.add_theme_font_size_override("font_size",22);body.add_child(title)
 var grid=GridContainer.new();grid.columns=6 if sample else 8;grid.add_theme_constant_override("h_separation",10);grid.add_theme_constant_override("v_separation",10);body.add_child(grid)
 var units=load("res://sim/catalog.gd").all().duplicate()
 units.sort_custom(func(a,b):return a.chassis+a.variant<b.chassis+b.variant)
 if sample:
  var ids=["locust-lct-1v","catapult-cplt-c1","hunchback-hbk-4g","hunchback-hbk-4p","marauder-mad-3r","demolisher-heavy-tank-mk-ii"]
  units=units.filter(func(u):return u.id in ids)
  units.sort_custom(func(a,b):return ids.find(a.id)<ids.find(b.id))
 for unit in units:
  var box=VBoxContainer.new();box.custom_minimum_size=Vector2(152 if sample else 166,170);grid.add_child(box)
  var pic=TextureRect.new();pic.texture=ImageTexture.create_from_image(load("res://visual/art.gd").unit_sprite(unit.id));pic.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST;pic.custom_minimum_size=Vector2(64,96);pic.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;pic.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;box.add_child(pic)
  var name_label=Label.new();name_label.text=unit.chassis+"\n"+unit.variant;name_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;name_label.add_theme_font_size_override("font_size",14);box.add_child(name_label)
 for i in range(6):await process_frame
 await RenderingServer.frame_post_draw
 assert(root.get_texture().get_image().save_png("res://docs/unit-art-sample.png" if sample else "res://docs/unit-art-v032.png")==OK)
 print("Galería de los 56 sprites renderizada")
 quit()
