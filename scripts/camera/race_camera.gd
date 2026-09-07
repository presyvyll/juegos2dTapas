extends Camera2D

@export var target: RacingCap
@export var anticipation: float = 0.55

func _process(delta: float) -> void:
	if is_instance_valid(target):
		var destination := target.global_position + target.velocity * anticipation
		global_position = global_position.lerp(destination, 1.0 - exp(-5.0 * delta))
		var desired_zoom := Vector2.ONE * (0.86 if target.boost_time > 0 else 1.0)
		zoom = zoom.lerp(desired_zoom, 1.0 - exp(-2.5 * delta))
