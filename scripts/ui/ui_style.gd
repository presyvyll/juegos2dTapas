class_name RacingUI
extends RefCounted

static func box(color: Color, radius: int = 18) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(radius)
	style.content_margin_left = 20
	style.content_margin_right = 20
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	return style

static func theme() -> Theme:
	var result := Theme.new()
	result.default_font_size = 20
	result.set_color("font_color", "Label", Color("eefaf1"))
	result.set_stylebox("panel", "PanelContainer", box(Color("153e47")))
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
	return result

static func label(text: String, size: int = 20) -> Label:
	var node := Label.new()
	node.text = text
	node.add_theme_font_size_override("font_size", size)
	return node

static func button(text: String, action: Callable) -> Button:
	var node := Button.new()
	node.text = text
	node.custom_minimum_size.y = 52
	node.pressed.connect(func() -> void:
		AudioManager.play("ui")
		action.call()
	)
	return node

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
