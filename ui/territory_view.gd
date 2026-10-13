extends TextureRect
var host
func _ready():
 texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
 expand_mode=TextureRect.EXPAND_IGNORE_SIZE
 stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED
 size_flags_horizontal=Control.SIZE_EXPAND_FILL
func _process(_delta):
 if is_instance_valid(host):custom_minimum_size.y=maxf(150,host.scroll.size.y-96)
