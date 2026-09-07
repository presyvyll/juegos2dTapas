class_name LeafObstacle
extends WaterCurrentArea

func _ready() -> void:
	size = Vector2(100, 120)
	strength = 80
	direction = Vector2.DOWN
	max_speed_modifier = 0.78
	super._ready()

func _draw() -> void:
	draw_colored_polygon(PackedVector2Array([Vector2(0, -60), Vector2(48, -20), Vector2(35, 36), Vector2(0, 60), Vector2(-35, 25), Vector2(-42, -20)]), Color("78bc72"))
	draw_line(Vector2(0, -48), Vector2(0, 48), Color("d6e9a3"), 3, true)
