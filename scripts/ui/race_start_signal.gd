class_name RaceStartSignal
extends Control
## HUD-only start lights driven by RaceSession.countdown_changed.

var value := 3
var panel_style: StyleBoxFlat


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel_style = RacingUI.box(Color("102f3a"), 22)
	panel_style.content_margin_left = 0
	panel_style.content_margin_right = 0
	panel_style.content_margin_top = 0
	panel_style.content_margin_bottom = 0
	panel_style.shadow_size = 2
	queue_redraw()


func set_value(next_value: int) -> void:
	value = clampi(next_value, 0, 3)
	queue_redraw()


func _draw() -> void:
	draw_style_box(panel_style, Rect2(Vector2.ZERO, size))
	var lit_count := 3 if value == 0 else 4 - value
	for index in range(3):
		var center := Vector2(size.x * 0.5 + (index - 1) * 55.0, size.y * 0.5)
		var lit := index < lit_count
		var color: Color
		if value == 0:
			color = Color("69e7d4")
		elif lit:
			color = [Color("ff806d"), Color("ffbd69"), Color("ffdc6c")][index]
		else:
			color = Color("31545a")
		if lit:
			var glow: Color = color
			glow.a = 0.22
			draw_circle(center, 22.0, glow)
		draw_circle(center, 14.0, Color("0b2530"))
		draw_circle(center, 10.0, color)
		draw_circle(center + Vector2(-3.0, -3.0), 3.0, color.lightened(0.42))
