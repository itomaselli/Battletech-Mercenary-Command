extends RefCounted
const INK=Color("091c20")
const PANEL=Color("092328")
const LINE=Color("527474")
const PAPER=Color("e4e2cd")
const GOLD=Color("d4af55")
static func box(bg: Color,border: Color,padding: int=12) -> StyleBoxFlat:
 var style=StyleBoxFlat.new();style.bg_color=bg;style.border_color=border;style.set_border_width_all(1);style.set_content_margin_all(padding);return style
static func build() -> Theme:
 var t=Theme.new();t.default_font_size=16
 var font=SystemFont.new();font.font_names=PackedStringArray(["Menlo","Consolas","DejaVu Sans Mono"]);font.antialiasing=TextServer.FONT_ANTIALIASING_NONE;t.default_font=font
 for kind in ["Label","Button","CheckBox","OptionButton","LineEdit","ItemList"]:
  t.set_color("font_color",kind,PAPER)
  t.set_color("font_hover_color",kind,Color.WHITE)
  t.set_color("font_disabled_color",kind,Color("7f9492"))
 for kind in ["Button","OptionButton"]:
  t.set_stylebox("normal",kind,box(PANEL,LINE,10))
  t.set_stylebox("hover",kind,box(Color("214448"),GOLD,10))
  t.set_stylebox("pressed",kind,box(GOLD,GOLD,10))
  t.set_stylebox("disabled",kind,box(INK,Color("233e42"),10))
  t.set_color("font_pressed_color",kind,INK)
 var focus=box(Color.TRANSPARENT,GOLD,0);focus.set_border_width_all(2)
 for kind in ["Button","OptionButton","LineEdit","CheckBox"]:t.set_stylebox("focus",kind,focus)
 for kind in ["PanelContainer","TabContainer","AcceptDialog"]:t.set_stylebox("panel",kind,box(PANEL,LINE,10))
 for kind in ["LineEdit","ItemList"]:
  t.set_stylebox("normal" if kind=="LineEdit" else "panel",kind,box(INK,LINE,10))
  t.set_color("font_placeholder_color",kind,Color("96aaa5"))
 for kind in ["VBoxContainer","HBoxContainer"]:t.set_constant("separation",kind,12)
 for variant in ["PrimaryButton","NavigationButton","TabButton"]:t.set_type_variation(variant,"Button")
 t.set_stylebox("normal","PrimaryButton",box(GOLD,GOLD,12))
 t.set_stylebox("hover","PrimaryButton",box(Color("edd18a"),GOLD,12))
 t.set_color("font_color","PrimaryButton",INK);t.set_color("font_hover_color","PrimaryButton",INK)
 for state in ["normal","hover","pressed","disabled"]:
  var bg=GOLD if state=="pressed" else PANEL if state=="normal" else INK
  t.set_stylebox(state,"NavigationButton",box(bg,LINE,9))
  t.set_stylebox(state,"TabButton",box(bg,LINE,7))
 t.set_font_size("font_size","NavigationButton",14)
 t.set_font_size("font_size","TabButton",14)
 var heading=load("res://assets/fonts/VT323-Regular.ttf");heading.antialiasing=TextServer.FONT_ANTIALIASING_NONE
 t.set_type_variation("HeadingLabel","Label");t.set_font("font","HeadingLabel",heading)
 t.set_font_size("font_size","NavigationButton",18)
 t.set_font_size("font_size","PrimaryButton",22)
 t.set_font("font","NavigationButton",heading)
 t.set_font("font","PrimaryButton",heading)
 t.set_type_variation("GoldPanel","PanelContainer")
 t.set_stylebox("panel","GoldPanel",box(GOLD,GOLD,8))
 t.set_stylebox("background","ProgressBar",box(INK,LINE,0))
 t.set_stylebox("fill","ProgressBar",box(Color("77aa72"),Color("77aa72"),0))
 t.set_stylebox("normal","CheckBox",box(INK,LINE,8))
 t.set_stylebox("pressed","CheckBox",box(Color("345348"),GOLD,8))
 return t
