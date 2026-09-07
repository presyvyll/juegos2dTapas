extends Control

var tint: Color = Color("ffce58")

func _ready() -> void:
	custom_minimum_size = Vector2(180, 160)
	resized.connect(queue_redraw)

func _draw() -> void:
	var center := size / 2
	draw_circle(center + Vector2(3, 10), 64, Color(0, 0.1, 0.15, 0.3))
	for index in range(20):
		draw_circle(center + Vector2.from_angle(TAU * index / 20) * 58, 9, tint.darkened(0.2))
	draw_circle(center, 60, tint)
	draw_arc(center, 46, 0, TAU, 48, tint.lightened(0.45), 4, true)
	draw_line(center + Vector2(-22, -18), center + Vector2(22, -18), Color("153e47"), 9, true)
	draw_line(center + Vector2(0, -18), center + Vector2(0, 25), Color("153e47"), 9, true)
