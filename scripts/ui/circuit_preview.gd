extends Control

var circuit: CircuitDefinition

func _ready() -> void:
	custom_minimum_size = Vector2(220, 100)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)

func _draw() -> void:
	if circuit == null: return
	if circuit.thumbnail:
		draw_texture_rect(circuit.thumbnail, Rect2(Vector2.ZERO, size), false)
		return
	draw_style_box(RacingUI.box(Color("102e39"), 12), Rect2(Vector2.ZERO, size))
	var points := PackedVector2Array()
	for i in range(49):
		var t := float(i) / 48
		points.append(Vector2(18 + t * (size.x - 36), size.y / 2 + sin(t * TAU * 1.3 + circuit.seed_value) * size.y * 0.22))
	draw_polyline(points, circuit.water_color.darkened(0.3), 32, true)
	draw_polyline(points, circuit.water_color, 23, true)
	draw_polyline(points, Color(0.8, 1, 1, 0.5), 2, true)
