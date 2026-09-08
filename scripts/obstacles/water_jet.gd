class_name WaterJet
extends WaterCurrentArea
var visual_motion: AmbientMotion

func _ready() -> void:
	strength = 390
	max_speed_modifier = 1.3
	size = Vector2(130, 230)
	super._ready()
	visual_motion = AmbientMotion.new()
	add_child(visual_motion)

func _draw() -> void:
	super._draw()
	var phase := visual_motion.phase if is_instance_valid(visual_motion) else 0.0
	for offset in [-35, -15, 15, 35]:
		for dash in range(3):
			var y := 75.0 - fposmod(phase * 85 + dash * 60 + offset, 180)
			draw_line(Vector2(offset, y), Vector2(offset, y - 24), Color(0.85, 1, 1, 0.75), 4, true)
