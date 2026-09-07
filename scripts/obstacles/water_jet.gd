class_name WaterJet
extends WaterCurrentArea

func _ready() -> void:
	strength = 390
	max_speed_modifier = 1.3
	size = Vector2(130, 230)
	super._ready()

func _draw() -> void:
	super._draw()
	for offset in [-35, -15, 15, 35]:
		draw_line(Vector2(offset, 80), Vector2(offset, -80), Color(0.85, 1, 1, 0.75), 5, true)
