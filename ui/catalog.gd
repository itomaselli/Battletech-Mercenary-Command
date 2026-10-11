extends AcceptDialog
const Catalog = preload("res://sim/catalog.gd")
const Art = preload("res://visual/art.gd")
var sim
var listing: ItemList
var details: Label
var comparison: Label
var picture: TextureRect
var query: LineEdit
var category: OptionButton
var selected = -1
func _ready():
 title = "Catálogo · disponibilidad por escenario · precios de juego"
 var scroll = ScrollContainer.new()
 scroll.custom_minimum_size = Vector2(940,560)
 add_child(scroll)
 var box = VBoxContainer.new()
 box.custom_minimum_size.x = 920
 scroll.add_child(box)
 query = LineEdit.new()
 query.placeholder_text = "Buscar chasis o variante"
 box.add_child(query)
 category = OptionButton.new()
 for caption in ["Todos", "Ligeros", "Medios", "Pesados", "Vehículos"]: category.add_item(caption)
 box.add_child(category)
 var row = HBoxContainer.new()
 box.add_child(row)
 listing = ItemList.new()
 listing.custom_minimum_size = Vector2(300,360)
 row.add_child(listing)
 var right = VBoxContainer.new()
 right.custom_minimum_size.x = 610
 row.add_child(right)
 picture = TextureRect.new()
 picture.custom_minimum_size = Vector2(32,48)
 picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
 picture.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
 right.add_child(picture)
 details = Label.new()
 details.custom_minimum_size.x = 610
 details.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 right.add_child(details)
 var pin = Button.new()
 pin.text = "Fijar como referencia de comparación"
 pin.pressed.connect(func():
  if selected >= 0: comparison.text = "Referencia: " + Catalog.describe(Catalog.all()[selected]))
 box.add_child(pin)
 comparison = Label.new()
 comparison.custom_minimum_size.x = 940
 comparison.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 box.add_child(comparison)
 query.text_changed.connect(func(_value): refresh())
 category.item_selected.connect(func(_value): refresh())
 listing.item_selected.connect(select)
 close_requested.connect(queue_free)
 confirmed.connect(queue_free)
 refresh()
func refresh():
 listing.clear()
 for i in Catalog.eligible(sim.state.scenario_year):
  var unit = Catalog.all()[i]
  if category.selected > 0 and unit.class != ["", "light", "medium", "heavy", "ground"][category.selected]: continue
  if not query.text.is_empty() and not unit.name.to_lower().contains(query.text.to_lower()): continue
  listing.add_item(unit.name)
  listing.set_item_metadata(listing.item_count-1,i)
 if listing.item_count > 0: listing.select(0); select(0)
 else: selected = -1; details.text = "Sin coincidencias."; picture.texture = null
func select(index: int):
 selected = listing.get_item_metadata(index)
 var unit = Catalog.all()[selected]
 picture.texture = ImageTexture.create_from_image(Art.unit_sprite(unit.id))
 details.text = Catalog.describe(unit) + "\nPrecio base del prototipo: %d C-bills. Compra en los lotes del mercado.\nFicha: %s" % [unit.value,unit.sarna]
