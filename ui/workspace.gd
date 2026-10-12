extends HBoxContainer
# Each pane scrolls independently; selection and context remain on screen.
var host
func _process(_delta):
 if not is_instance_valid(host):return
 var available=maxf(220,host.scroll.size.y-(global_position.y-host.content.global_position.y)-4)
 if absf(custom_minimum_size.y-available)>1:custom_minimum_size.y=available
