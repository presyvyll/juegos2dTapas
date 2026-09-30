class_name RacingUI
extends RefCounted

static func box(color: Color, radius: int = 18) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(radius)
	style.border_color = Color("10283b")
	style.set_border_width_all(2)
	style.shadow_color = Color(0.01, 0.08, 0.14, 0.35)
	style.shadow_offset = Vector2(0, 4)
	style.shadow_size = 3
	style.content_margin_left = 20
	style.content_margin_right = 20
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	return style

static func theme() -> Theme:
	var result := Theme.new()
	result.default_font_size = 20
	result.set_color("font_color", "Label", Color("eefaf1"))
	result.set_stylebox("panel", "PanelContainer", box(Color("153e47"), 10))
	result.set_stylebox("normal", "Button", box(Color("ffce58"), 13))
	result.set_stylebox("hover", "Button", box(Color("ffe49a"), 13))
	result.set_stylebox("pressed", "Button", box(Color("d8af43"), 13))
	result.set_stylebox("disabled", "Button", box(Color("456669"), 13))
	result.set_stylebox("focus", "Button", box(Color(1, 1, 1, 0.18), 13))
	for state in ["font_color", "font_hover_color", "font_pressed_color"]:
		result.set_color(state, "Button", Color("153e47"))
	result.set_color("font_disabled_color", "Button", Color("a3b9b4"))
	result.set_constant("separation", "VBoxContainer", 12)
	result.set_constant("separation", "HBoxContainer", 16)
	for state in ["background", "fill"]:
		var bar := box(Color("102b3c") if state == "background" else Color("69e7d4"), 6)
		bar.content_margin_left = 0
		bar.content_margin_right = 0
		bar.content_margin_top = 0
		bar.content_margin_bottom = 0
		bar.shadow_size = 0
		result.set_stylebox(state, "ProgressBar", bar)
	return result

static func tropical_box(color: Color = Color("512812"), radius: int = 12, border: Color = Color("2a1208")) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = border
	style.set_border_width_all(4)
	style.set_corner_radius_all(radius)
	style.shadow_color = Color(0.05, 0.015, 0.0, 0.62)
	style.shadow_offset = Vector2(0, 6)
	style.shadow_size = 5
	style.content_margin_left = 18
	style.content_margin_right = 18
	style.content_margin_top = 11
	style.content_margin_bottom = 11
	return style

static func menu_theme() -> Theme:
	var result := Theme.new()
	result.default_font_size = 20
	result.set_color("font_color", "Label", Color("fff4d7"))
	result.set_color("font_shadow_color", "Label", Color(0.08, 0.02, 0.0, 0.75))
	result.set_constant("shadow_offset_x", "Label", 2)
	result.set_constant("shadow_offset_y", "Label", 3)
	result.set_stylebox("panel", "PanelContainer", tropical_box(Color(0.20, 0.075, 0.022, 0.91), 12))
	result.set_stylebox("normal", "Button", tropical_box(Color("f3aa21"), 10, Color("54240d")))
	result.set_stylebox("hover", "Button", tropical_box(Color("ffd35a"), 10, Color("6c310f")))
	result.set_stylebox("pressed", "Button", tropical_box(Color("cf7914"), 10, Color("3b1708")))
	result.set_stylebox("disabled", "Button", tropical_box(Color("777f80"), 10, Color("343b3d")))
	result.set_stylebox("focus", "Button", StyleBoxEmpty.new())
	for state in ["font_color", "font_hover_color", "font_pressed_color"]:
		result.set_color(state, "Button", Color("351506"))
	result.set_color("font_disabled_color", "Button", Color("d1d0c6"))
	result.set_color("font_color", "CheckButton", Color("fff4d7"))
	result.set_color("font_color", "OptionButton", Color("351506"))
	result.set_constant("separation", "VBoxContainer", 12)
	result.set_constant("separation", "HBoxContainer", 14)
	var bar_background := tropical_box(Color("28150f"), 7)
	var bar_fill := tropical_box(Color("39d9d0"), 7, Color("0c5d64"))
	for bar in [bar_background, bar_fill]:
		bar.content_margin_left = 0
		bar.content_margin_right = 0
		bar.content_margin_top = 0
		bar.content_margin_bottom = 0
		bar.shadow_size = 0
	result.set_stylebox("background", "ProgressBar", bar_background)
	result.set_stylebox("fill", "ProgressBar", bar_fill)
	result.set_stylebox("slider", "HSlider", tropical_box(Color("2a1710"), 5))
	result.set_stylebox("grabber_area", "HSlider", tropical_box(Color("2bbfc4"), 5, Color("0b565d")))
	result.set_stylebox("grabber_area_highlight", "HSlider", tropical_box(Color("70eee1"), 5, Color("0b565d")))
	return result

static func label(text: String, size: int = 20) -> Label:
	var node := Label.new()
	node.text = text
	node.add_theme_font_size_override("font_size", size)
	return node

static func button(text: String, action: Callable) -> Button:
	var node := preload("res://scripts/ui/animated_button.gd").new()
	node.text = text
	node.custom_minimum_size.y = 52
	node.pressed.connect(func() -> void:
		AudioManager.play("ui")
		action.call()
	)
	return node

static func set_primary(button: Button, enabled: bool = true) -> void:
	if not enabled:
		for state in ["normal", "hover", "pressed"]:
			button.remove_theme_stylebox_override(state)
		button.remove_theme_font_size_override("font_size")
		return
	button.add_theme_stylebox_override("normal", tropical_box(Color("ffd35a"), 10, Color("6c310f")))
	button.add_theme_stylebox_override("hover", tropical_box(Color("ffe58a"), 10, Color("7b3a12")))
	button.add_theme_stylebox_override("pressed", tropical_box(Color("df8d18"), 10, Color("4a1d08")))
	button.add_theme_font_size_override("font_size", 21)

static func expand(control: Control) -> void:
	control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	control.size_flags_vertical = Control.SIZE_EXPAND_FILL

static func safe_insets(viewport: Viewport) -> Vector4:
	var margins := Vector4(24, 24, 24, 24)
	if OS.get_name() not in ["Android", "iOS"]:
		return margins
	var safe := DisplayServer.get_display_safe_area()
	var pixels := Vector2(DisplayServer.window_get_size())
	if pixels.x <= 0 or pixels.y <= 0 or safe.size.x <= 0:
		return margins
	var ratio := viewport.get_visible_rect().size / pixels
	margins.x = maxf(24, safe.position.x * ratio.x + 12)
	margins.y = maxf(24, safe.position.y * ratio.y + 12)
	margins.z = maxf(24, (pixels.x - safe.end.x) * ratio.x + 12)
	margins.w = maxf(24, (pixels.y - safe.end.y) * ratio.y + 12)
	return margins
