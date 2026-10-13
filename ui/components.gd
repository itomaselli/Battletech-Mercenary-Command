extends RefCounted
static var expanded:Dictionary={}
static func clear(node: Node):
 for child in node.get_children():node.remove_child(child);child.queue_free()
static func text(parent: Node,value: String,heading: bool=false) -> Label:
 var l=Label.new()
 l.text=value
 l.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 l.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 if parent is FlowContainer:
  l.autowrap_mode=TextServer.AUTOWRAP_OFF
  l.size_flags_horizontal=Control.SIZE_FILL
 if heading:l.theme_type_variation="HeadingLabel";l.add_theme_color_override("font_color",Color("e4e2cd"));l.add_theme_font_size_override("font_size",26)
 parent.add_child(l)
 return l
static func button(parent: Node,caption: String,callback: Callable) -> Button:
 var b=Button.new()
 b.text=caption
 b.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 if parent is FlowContainer:b.custom_minimum_size.x=clampf(caption.length()*9+32,120,320)
 if parent is HBoxContainer:
  b.size_flags_horizontal=Control.SIZE_EXPAND_FILL
  b.custom_minimum_size.x=65
 b.pressed.connect(callback)
 parent.add_child(b)
 return b
static func column(parent: Node) -> VBoxContainer:
 var c=VBoxContainer.new()
 c.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 c.add_theme_constant_override("separation",10)
 parent.add_child(c)
 return c
static func picker(parent: Node,caption: String,items: Dictionary,selected: Variant=null) -> OptionButton:
 text(parent,caption)
 var p=OptionButton.new()
 p.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 p.fit_to_longest_item=false
 for key in items:
  p.add_item(str(items[key]));p.set_item_metadata(p.item_count-1,key)
  if key==selected:p.select(p.item_count-1)
 parent.add_child(p)
 return p
static func split(parent: Node,width: float) -> Array:
 var row=HBoxContainer.new() if width>850 else VBoxContainer.new()
 row.add_theme_constant_override("separation",20)
 parent.add_child(row)
 var list=column(row)
 list.size_flags_stretch_ratio=0.9
 var detail=column(row)
 detail.size_flags_stretch_ratio=1.2
 return [list,detail]

# Shared hierarchy. Sections own their padding; nested detail never reads as another page.
static func block(parent: Node,caption: String,hint: String="") -> VBoxContainer:
 var panel=PanelContainer.new();panel.size_flags_horizontal=Control.SIZE_EXPAND_FILL;parent.add_child(panel)
 var body=column(panel)
 text(body,caption,true)
 if not hint.is_empty():muted(body,hint)
 return body
static func muted(parent: Node,value: String) -> Label:
 var label=text(parent,value);label.add_theme_color_override("font_color",Color("97aaa6"));return label
static func primary(parent: Node,caption: String,callback: Callable) -> Button:
 var b=button(parent,caption,callback);b.theme_type_variation="PrimaryButton";return b
static func disclosure(parent: Node,caption: String) -> VBoxContainer:
 var wrapper=column(parent)
 var toggle=button(wrapper,"▸ "+caption,func():pass)
 toggle.toggle_mode=true
 var body=block(wrapper,caption);var frame=body.get_parent();frame.visible=expanded.get(caption,false);toggle.button_pressed=frame.visible
 toggle.text=("▾ " if frame.visible else "▸ ")+caption
 toggle.toggled.connect(func(on):frame.visible=on;expanded[caption]=on;toggle.text=("▾ " if on else "▸ ")+caption)
 return body
static func pager(parent: Node,total: int,page: int,limit: int,change: Callable) -> Array:
 var pages=maxi(1,ceili(float(total)/limit));page=clampi(page,0,pages-1)
 var bar=HBoxContainer.new();bar.add_theme_constant_override("separation",4);parent.add_child(bar)
 var prev=button(bar,"‹",func():change.call(page-1));prev.custom_minimum_size.x=36;prev.disabled=page==0
 text(bar,"%d / %d · %d entradas"%[page+1,pages,total])
 var next=button(bar,"Siguiente ›",func():change.call(page+1));next.custom_minimum_size.x=122;next.disabled=page>=pages-1
 return [page*limit,mini(total,(page+1)*limit)]
static func scroll_column(parent: Node) -> VBoxContainer:
 var scroll=ScrollContainer.new();scroll.size_flags_horizontal=Control.SIZE_EXPAND_FILL;scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL
 scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
 parent.add_child(scroll)
 return column(scroll)

static func workspace(parent: Node,host,left_ratio: float=1.0,right_ratio: float=1.2) -> Array:
 var row=preload("res://ui/workspace.gd").new();row.host=host;row.add_theme_constant_override("separation",14);parent.add_child(row)
 var left=scroll_column(row);left.get_parent().size_flags_stretch_ratio=left_ratio
 var right=scroll_column(row);right.get_parent().size_flags_stretch_ratio=right_ratio
 return [left,right]
static func unit_icon(parent: Node,model: Dictionary):
 var icon=TextureRect.new();icon.texture=ImageTexture.create_from_image(preload("res://visual/art.gd").unit_sprite(model.id))
 icon.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST;icon.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;icon.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
 icon.custom_minimum_size=Vector2(48,72);parent.add_child(icon)
 return icon
