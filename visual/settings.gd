extends RefCounted
var text_size=16
var scanlines = true
var vignette = true
var animation = true
var path = "user://visual_settings.cfg"
func load_settings():
	var config = ConfigFile.new()
	if config.load(path) != OK: return
	var size_value=config.get_value("display","text_size",16)
	if size_value in [16,18,20]:text_size=int(size_value)
	for key in ["scanlines", "vignette", "animation"]:
		var value = config.get_value("display", key, true)
		if value is bool: set(key, value)
func save_settings() -> Error:
	var config = ConfigFile.new()
	for key in ["scanlines", "vignette", "animation"]: config.set_value("display", key, get(key))
	config.set_value("display","text_size",text_size)
	return config.save(path)
