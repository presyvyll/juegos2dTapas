extends Camera2D

@export var target: RacingCap
@export var anticipation: float = 0.55
@export_range(0.0, 4.0) var shake_strength: float = 2.5
var shake_time := 0.0
var clock := 0.0
var entrance := 1.0
var impact_scale := 1.0
var finish_focus := false

func celebrate_finish() -> void:
	finish_focus = true
	shake_time = 0

func _ready() -> void:
	if is_instance_valid(target):
		target.impacted.connect(func(_point: Vector2, _normal: Vector2, force: float) -> void:
			if force > 120 and enabled:
				shake_time = 0.15
				impact_scale = clampf(force / 350, 0.35, 1.0)
		)

func _process(delta: float) -> void:
	if not enabled:
		return
	clock += delta
	entrance = maxf(0, entrance - delta / 2.5)
	shake_time = maxf(0, shake_time - delta)
	offset = Vector2(sin(clock * 72), cos(clock * 87)) * shake_strength * impact_scale * (shake_time / 0.15)
	if is_instance_valid(target):
		var destination := target.global_position + (target.velocity * anticipation).limit_length(180)
		global_position = global_position.lerp(destination, 1.0 - exp(-5.0 * delta))
		var speed_zoom := lerpf(1.0, 0.96, clampf((target.velocity.length() - 280) / 200, 0, 1))
		var desired_zoom := Vector2.ONE * (1.06 if finish_focus else (0.86 if target.boost_time > 0 else speed_zoom + entrance * 0.12))
		zoom = zoom.lerp(desired_zoom, 1.0 - exp(-2.5 * delta))
