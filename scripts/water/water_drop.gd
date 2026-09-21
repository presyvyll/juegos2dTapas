class_name WaterDrop
extends WaterCurrentArea
## A shallow drop: brief visual lift with a forward push, no complex 3D physics.

@export var airtime: float = 0.65

func _init() -> void:
	size = Vector2(500, 90)
	strength = 260
	max_speed_modifier = 1.2

func _ready() -> void:
	super._ready()

func _enter(body: Node2D) -> void:
	super._enter(body)
	if body is RacingCap:
		body.jump_time = airtime
		body.jump_duration = airtime

func _draw() -> void:
	draw_rect(Rect2(-size / 2, size), Color(0.01, 0.4, 0.55, 0.4))
	var cue := Color("ffdc6c")
	cue.a = 0.72
	var entry_y := size.y * 0.5 + 20.0
	for x in [-150.0, 0.0, 150.0]:
		draw_polyline(PackedVector2Array([Vector2(x - 15.0, entry_y + 8.0), Vector2(x, entry_y - 5.0), Vector2(x + 15.0, entry_y + 8.0)]), cue, 4.0, true)
	for row in range(3):
		draw_line(Vector2(-size.x / 2, row * 22 - 25), Vector2(size.x / 2, row * 22 - 25), Color(0.8, 1, 1, 0.7), 7, true)
