extends RefCounted
const NAMES=["Lobo","León","Águila","Cuervo","Oso","Dragón","Grifo","Ciervo","Jabalí","Serpiente","Espadas cruzadas","Espada larga","Hachas","Lanza y pendón","Martillo","Maza","Arco","Alabarda","Lanza y escudo","Sables","Torre","Fortaleza","Almenas","Corona","Escudo redondo","Escudo cometa","Caballero","Yelmo nórdico","Gran yelmo","Puño de hierro","Espada alada","Antorcha","Fénix","Sol naciente","Luna","Rosa de los vientos","Montaña","Roble","Ancla","Drakkar","Blindado","Casco mecánico","Engranaje","Galones","Laurel","Tres flechas","Llave","Cadenas rotas","Reloj de arena","Calavera"]
static var atlas: Texture2D
static func texture(index: int) -> AtlasTexture:
 if atlas==null:
  atlas=load("res://assets/emblems/company-emblems.png")
  if atlas==null:atlas=ImageTexture.create_from_image(Image.load_from_file("res://assets/emblems/company-emblems.png"))
 var tile=AtlasTexture.new();tile.atlas=atlas
 var cell=Vector2(atlas.get_width()/10.0,atlas.get_height()/5.0)
 index=clampi(index,0,49);tile.region=Rect2(Vector2(index%10,int(index/10))*cell,cell);tile.filter_clip=true
 return tile
static func view(index: int,pixels: int=80) -> TextureRect:
 var icon=TextureRect.new();icon.texture=texture(index);icon.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
 icon.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;icon.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;icon.custom_minimum_size=Vector2(pixels,pixels)
 return icon
static func selector(host,parent: Node,current: int,change: Callable):
 var UI=host.UI
 UI.text(parent,"EMBLEMA DE LA COMPAÑÍA",true)
 UI.muted(parent,"50 insignias · "+NAMES[clampi(current,0,49)])
 var grid=GridContainer.new();grid.columns=10 if host.scroll.size.x>=780 else 6 if host.scroll.size.x>=500 else 4;grid.add_theme_constant_override("h_separation",8);grid.add_theme_constant_override("v_separation",8);parent.add_child(grid)
 for i in range(50):
  var b=Button.new();b.custom_minimum_size=Vector2(68,68);b.size_flags_horizontal=Control.SIZE_EXPAND_FILL;b.toggle_mode=true;b.button_pressed=i==current;b.tooltip_text="%02d · %s"%[i+1,NAMES[i]]
  b.icon=texture(i);b.expand_icon=true;b.add_theme_constant_override("icon_max_width",56);b.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
  b.pressed.connect(func():change.call(i));grid.add_child(b)
