extends RefCounted
static func clear(node: Node):
 for child in node.get_children():node.remove_child(child);child.queue_free()
static func text(parent: Node,value: String,heading: bool=false) -> Label:
 var l=Label.new()
 l.text=value
 l.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 l.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 if heading:l.add_theme_color_override("font_color",Color("d9b56f"));l.add_theme_font_size_override("font_size",20)
 parent.add_child(l)
 return l
static func button(parent: Node,caption: String,callback: Callable) -> Button:
 var b=Button.new()
 b.text=caption
 b.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 if parent is FlowContainer:b.custom_minimum_size.x=clampf(caption.length()*13+40,145,400)
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
