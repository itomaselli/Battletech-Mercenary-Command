extends RefCounted
const Art = preload("res://visual/art.gd")
static func build() -> Theme:
	var theme = Theme.new()
	theme.default_font_size = 16
	for type in ["Label", "Button", "CheckBox", "OptionButton", "TabContainer"]:
		theme.set_color("font_color", type, Art.color(5))
		theme.set_color("font_hover_color", type, Art.color(17))
	for name in ["normal", "hover", "pressed", "focus"]:
		var box = StyleBoxFlat.new()
		box.bg_color = Art.color(1 if name == "normal" else 2)
		box.border_color = Art.color(3)
		box.set_border_width_all(1)
		box.content_margin_left = 10
		box.content_margin_right = 10
		box.content_margin_top = 7
		box.content_margin_bottom = 7
		for type in ["Button", "OptionButton"]: theme.set_stylebox(name, type, box)
	var panel = StyleBoxFlat.new()
	panel.bg_color = Art.color(0)
	panel.border_color = Art.color(3)
	panel.set_border_width_all(1)
	panel.set_content_margin_all(12)
	theme.set_stylebox("panel", "TabContainer", panel)
	var dialog = panel.duplicate()
	dialog.bg_color = Art.color(1)
	theme.set_stylebox("panel", "AcceptDialog", dialog)
	return theme
