extends Camera2D

@export var target: RacingCap
@export var anticipation: float = 0.55
@export_range(0.0, 4.0) var shake_strength: float = 2.5
var shake_time := 0.0
var clock := 0.0
var entrance := 1.0
var shake_amount := 0.0
var finish_focus := false
var look_ahead := Vector2.ZERO
var power_focus := 0.0
var final_sprint := false
var overtake_focus := 0.0

func celebrate_finish() -> void:
	finish_focus = true
	shake_time = 0

func enter_final_sprint() -> void:
	final_sprint = true
	overtake_focus = maxf(overtake_focus, 0.45)

func celebrate_overtake() -> void:
	overtake_focus = 0.32
	shake_time = 0.08
	shake_amount = 0.12

func photo_finish() -> void:
	overtake_focus = 0.55
	shake_time = 0.12
	shake_amount = 0.18

func _ready() -> void:
	if is_instance_valid(target):
		target.race_power.activated.connect(func(_id: String) -> void:
			if enabled: power_focus = 0.3
		)
		target.impacted.connect(func(_point: Vector2, _normal: Vector2, force: float) -> void:
			if force > 120 and enabled:
				shake_time = 0.15
				shake_amount = clampf(force / 350, 0.35, 1.0)
		)
		target.boosted.connect(func() -> void:
			if not enabled: return
			shake_time = 0.11
			shake_amount = 0.24
		)

func _process(delta: float) -> void:
	if not enabled:
		return
	clock += delta
	power_focus = maxf(0, power_focus - delta)
	overtake_focus = maxf(0, overtake_focus - delta)
	entrance = maxf(0, entrance - delta / 2.5)
	shake_time = maxf(0, shake_time - delta)
	offset = Vector2(sin(clock * 72), cos(clock * 87)) * shake_strength * shake_amount * (shake_time / 0.15)
	if is_instance_valid(target):
		var lead_limit := clampf(target.motion.config.current_speed * 0.75, 180.0, 675.0)
		var desired_ahead := (target.velocity * anticipation).limit_length(lead_limit) if target.active and not finish_focus else Vector2.ZERO
		look_ahead = look_ahead.lerp(desired_ahead, 1.0 - exp(-3.5 * delta))
		var destination := target.global_position + look_ahead
		global_position = global_position.lerp(destination, 1.0 - exp(-5.0 * delta))
		var speed_zoom := lerpf(1.0, 0.96, clampf((target.velocity.length() - 280) / 200, 0, 1))
		var powered := target.race_power.remaining > 0 and target.race_power.current in ["turbo", "super", "dash", "recovery"]
		var desired_zoom := Vector2.ONE * (1.06 if finish_focus else (0.885 if final_sprint and target.active else (0.92 if overtake_focus > 0 else (0.94 if powered or power_focus > 0 else (0.90 if target.boost_time > 0 else speed_zoom + entrance * 0.12)))))
		zoom = zoom.lerp(desired_zoom, 1.0 - exp(-2.5 * delta))
