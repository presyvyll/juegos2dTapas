extends Node2D
## Replace this child with a Sprite2D without touching movement.

@export var tint: Color = Color("ffce58")

func _draw() -> void:
	draw_circle(Vector2(3, 7), 24, Color(0.0, 0.22, 0.28, 0.3))
	for index in range(16):
		var angle := TAU * index / 16.0
		draw_circle(Vector2.from_angle(angle) * 20.0, 5.0, tint.darkened(0.18))
	draw_circle(Vector2.ZERO, 21.0, tint)
	draw_arc(Vector2.ZERO, 16.0, 0, TAU, 40, Color("fff0ab"), 2.0, true)
	draw_line(Vector2(-8, -7), Vector2(8, -7), Color("184953"), 4.0, true)
	draw_line(Vector2(0, -7), Vector2(0, 10), Color("184953"), 4.0, true)
