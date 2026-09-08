class_name LeafObstacle
extends WaterCurrentArea
var visual_motion: AmbientMotion

func _ready() -> void:
	size = Vector2(100, 120)
	strength = 80
	direction = Vector2.DOWN
	max_speed_modifier = 0.78
	super._ready()
	visual_motion = AmbientMotion.new()
	add_child(visual_motion)

func _draw() -> void:
	var phase := visual_motion.phase if is_instance_valid(visual_motion) else 0.0
	draw_set_transform(Vector2(0, sin(phase * 2) * 2), sin(phase * 1.3) * 0.035)
	draw_colored_polygon(PackedVector2Array([Vector2(0, -60), Vector2(48, -20), Vector2(35, 36), Vector2(0, 60), Vector2(-35, 25), Vector2(-42, -20)]), Color("78bc72"))
	draw_line(Vector2(0, -48), Vector2(0, 48), Color("d6e9a3"), 3, true)
