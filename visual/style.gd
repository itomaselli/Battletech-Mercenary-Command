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
	# Semantic styles shared across pages, without relying on color alone.
	theme.set_stylebox("panel", "PanelContainer", panel)
	theme.set_constant("separation", "VBoxContainer", 10)
	theme.set_constant("separation", "HBoxContainer", 12)
	var chosen = panel.duplicate()
	chosen.bg_color = Color("294d4e")
	chosen.border_color = Color("d9b56f")
	chosen.set_border_width_all(2)
	chosen.content_margin_left=10;chosen.content_margin_right=10
	chosen.content_margin_top=7;chosen.content_margin_bottom=7
	theme.set_stylebox("pressed", "Button", chosen)
	theme.set_color("font_pressed_color", "Button", Color("fff1be"))
	var focus = StyleBoxFlat.new()
	focus.bg_color = Color.TRANSPARENT
	focus.border_color = Color("e4cd6a")
	focus.set_border_width_all(2)
	for type in ["Button","OptionButton","LineEdit"]:theme.set_stylebox("focus",type,focus)
	theme.set_type_variation("PrimaryButton","Button")
	var primary = chosen.duplicate()
	primary.bg_color = Color("375e55")
	theme.set_stylebox("normal","PrimaryButton",primary)
	theme.set_stylebox("hover","PrimaryButton",chosen)
	theme.set_color("font_color","PrimaryButton",Color("fff1be"))
	theme.set_color("font_disabled_color","Button",Color("758681"))
	return theme
