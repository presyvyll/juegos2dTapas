class_name CapAIController
extends Node
## Thinks at 5 Hz. All motion still goes through RacingCap and CapMotion.

var cap: RacingCap
var track: RaceTrack
var difficulty := "normal"
var rng := RandomNumberGenerator.new()
var lane := 0.0
var axis := 0.0
var boost_requested := false
var think_timer := 0.0
var lane_timer := 0.0
var error := 0.0

func _ready() -> void:
	lane = rng.randf_range(-0.5, 0.5)

func _physics_process(delta: float) -> void:
	if not cap.active or cap.finished:
		return
	think_timer -= delta
	lane_timer -= delta
	if think_timer > 0:
		return
	think_timer = 0.2
	if lane_timer <= 0:
		lane_timer = rng.randf_range(2.5, 5)
		lane = rng.randf_range(-0.6, 0.6)
		var error_size: float = 65.0 if difficulty == "easy" else (15.0 if difficulty == "hard" else 35.0)
		error = rng.randf_range(-error_size, error_size)
	var look_y := cap.position.y - 150
	var target_x := track.center_at(look_y) + lane * track.width_at(look_y) * 0.5 + error
	for obstacle in track.obstacles:
		var distance := cap.position.y - obstacle.position.y
		if distance > -35 and distance < 310:
			var clearance: float = obstacle.radius + 65
			if absf(target_x - obstacle.position.x) < clearance:
				var side := signf(cap.position.x - obstacle.position.x)
				if is_zero_approx(side):
					side = 1.0 if lane >= 0 else -1.0
				target_x = obstacle.position.x + side * clearance
	var half := track.width_at(look_y) / 2 - 60
	target_x = clampf(target_x, track.center_at(look_y) - half, track.center_at(look_y) + half)
	axis = clampf((target_x - cap.position.x) / 100 - cap.velocity.x / 330, -1, 1)
	var boost_chance: float = 0.035 if difficulty == "easy" else (0.16 if difficulty == "hard" else 0.08)
	if cap.boost_energy > 0.6 and (rng.randf() < boost_chance or cap.velocity.length() < 100):
		boost_requested = true

func steering_axis() -> float:
	return axis

func consume_boost() -> bool:
	var result := boost_requested
	boost_requested = false
	return result
