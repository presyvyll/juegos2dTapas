extends Control

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("0b777e"))
	for index in range(14):
		var origin := Vector2(size.x * 0.12 + sin(index * 1.7) * 140, index * 80.0)
		draw_arc(origin, 150, 0.2, 2.8, 32, Color(0.3, 0.95, 0.9, 0.12), 12, true)
	draw_circle(Vector2(size.x + 50, -30), 300, Color("12535a"))
	draw_circle(Vector2(size.x - 60, size.y + 60), 180, Color("37896f"))
