class_name CapAIController
extends Node
## Bounded 3–6.25 Hz decisions. Motion still goes through RacingCap and CapMotion.

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
var last_safe_position := Vector2.ZERO
var outside_time := 0.0
@export var profile: AIProfile
var rivals: Array[RacingCap] = []
var decision := "trazada"
var target_position := Vector2.ZERO
var desired_axis := 0.0
var tactical_offset := 0.0
var temperament := 1.0
var decision_count := 0
var recovery_count := 0
var overtake_count := 0
var defense_count := 0
var avoidance_count := 0

func _ready() -> void:
	if profile == null: profile = preload("res://data/ai_profiles/equilibrado.tres")
	lane = rng.randf_range(-0.5, 0.5)
	temperament = rng.randf_range(0.92, 1.08)
	think_timer = rng.randf_range(0.0, profile.reaction_interval)
	last_safe_position = cap.position

func _physics_process(delta: float) -> void:
	if not cap.active or cap.finished:
		boost_requested = false
		return
	axis = move_toward(axis, desired_axis, delta * 7.0)
	var bank_distance := absf(cap.position.x - track.center_at(cap.position.y))
	var bank_half := track.width_at(cap.position.y) / 2
	var next_checkpoint_y := -track.definition.length * (cap.checkpoint_index + 1) / track.checkpoint_count
	# Retain a point before the pending gate; re-entry downstream cannot skip it.
	if bank_distance < bank_half - 55 and cap.position.y >= next_checkpoint_y + 60 and cap.position.y <= 600:
		last_safe_position = cap.position
	if bank_distance > bank_half + 80 or cap.position.y < next_checkpoint_y - 150 or cap.position.y > 600:
		outside_time += delta
		if outside_time >= 1.0:
			cap.position = last_safe_position
			cap.velocity = Vector2.ZERO
			cap.currents.clear()
			outside_time = 0.0
			recovery_count += 1
			tactical_offset = 0
			desired_axis = 0
			axis = 0
			boost_requested = false
	else:
		outside_time = 0.0
	think_timer -= delta
	lane_timer -= delta
	if think_timer > 0:
		return
	var difficulty_reaction := 1.15 if difficulty == "easy" else (0.85 if difficulty == "expert" else 1.0)
	think_timer = clampf(profile.reaction_interval * difficulty_reaction, 0.16, 0.35)
	decision_count += 1
	decision = "recuperar" if outside_time > 0 else "trazada"
	if lane_timer <= 0:
		lane_timer = rng.randf_range(2.5, 5)
		lane = clampf(profile.preferred_line + rng.randf_range(-0.28, 0.28), -0.6, 0.6)
		var error_size: float = 50.0 if difficulty == "easy" else (8.0 if difficulty == "expert" else (15.0 if difficulty == "hard" else 30.0))
		var mistake_chance := profile.mistake_probability * (1.5 if difficulty == "easy" else (0.45 if difficulty == "expert" else 1.0))
		error = rng.randf_range(-error_size, error_size) * (1.0 if rng.randf() < mistake_chance else 0.25)
	var look_ahead := clampf(130 + cap.velocity.length() * 0.08, 140, 185) * profile.corner_anticipation
	var look_y := cap.position.y - look_ahead
	var curvature := absf(track.center_at(look_y - 180) - track.center_at(look_y)) / 180.0
	var target_x := track.center_at(look_y) + lane * track.width_at(look_y) * 0.5 + error
	var tactical_target := 0.0
	var ahead: RacingCap
	var behind: RacingCap
	var front_distance := 230.0
	var rear_distance := 120.0
	# The shared roster is passed at spawn; no global searches or physics queries.
	for rival in rivals:
		if rival == cap or not is_instance_valid(rival) or rival.finished or rival.lap != cap.lap: continue
		var distance := cap.position.y - rival.position.y
		if distance > 0 and distance < front_distance and absf(rival.position.x - cap.position.x) < 125:
			ahead = rival
			front_distance = distance
		elif distance < 0 and -distance < rear_distance and absf(rival.position.x - cap.position.x) < 145:
			behind = rival
			rear_distance = -distance
	var missed_opportunity := rng.randf() < profile.mistake_probability * (0.5 if difficulty in ["hard", "expert"] else 1.0)
	if ahead != null and not missed_opportunity and (cap.velocity.length() > ahead.velocity.length() - 15 or profile.aggression > 0.6):
		var clearance := 76.0
		var left := ahead.position.x - clearance
		var right := ahead.position.x + clearance
		var left_ok := lane_clear(left, look_y)
		var right_ok := lane_clear(right, look_y)
		if left_ok or right_ok:
			var passing_x: float = left if left_ok and (not right_ok or absf(left - target_x) < absf(right - target_x)) else right
			tactical_target = clampf(passing_x - target_x, -100, 100) * lerpf(0.65, 1.0, profile.overtake_skill)
			decision = "adelantar"
			overtake_count += 1
	elif behind != null and profile.defensive_skill >= 0.6 and curvature < 0.35 and not missed_opportunity:
		var defense_x := lerpf(target_x, behind.position.x, profile.defensive_skill * 0.35)
		if lane_clear(defense_x, look_y):
			tactical_target = clampf(defense_x - target_x, -38, 38)
			decision = "defender"
			defense_count += 1
	tactical_offset = move_toward(tactical_offset, tactical_target, think_timer * 110)
	target_x += tactical_offset
	var obstacle_risk := false
	for obstacle in track.obstacles:
		var distance := cap.position.y - obstacle.position.y
		if distance > -35 and distance < 310:
			var clearance: float = obstacle.radius + 65
			if absf(target_x - obstacle.position.x) < clearance:
				obstacle_risk = true
				decision = "evitar obstáculo"
				avoidance_count += 1
				var side := signf(cap.position.x - obstacle.position.x)
				if is_zero_approx(side):
					side = 1.0 if lane >= 0 else -1.0
				target_x = obstacle.position.x + side * clearance
	var half := track.width_at(look_y) / 2 - 60
	target_x = clampf(target_x, track.center_at(look_y) - half, track.center_at(look_y) + half)
	target_position = Vector2(target_x, look_y)
	desired_axis = clampf((target_x - cap.position.x) / 100 - cap.velocity.x / 330, -1, 1)
	var boost_chance: float = 0.035 if difficulty == "easy" else (0.16 if difficulty == "hard" else 0.08)
	if difficulty == "expert": boost_chance = 0.16
	boost_chance *= lerpf(0.6, 1.5, profile.boost_usage) * temperament
	var safe_boost := curvature < lerpf(0.20, 0.5, profile.risk_tolerance) and not obstacle_risk and absf(desired_axis) < 0.65 and ahead == null
	boost_requested = false
	if cap.can_boost() and cap.boost_energy > 0.6 and outside_time <= 0 and (safe_boost and rng.randf() < boost_chance or cap.velocity.length() < 75 and not obstacle_risk):
		boost_requested = true
		decision = "turbo"

func lane_clear(x: float, y: float) -> bool:
	if absf(x - track.center_at(y)) > track.width_at(y) / 2 - 70: return false
	for obstacle in track.obstacles:
		if absf(obstacle.position.y - y) < 180 and absf(obstacle.position.x - x) < obstacle.radius + 65: return false
	for rival in rivals:
		if rival == cap or not is_instance_valid(rival) or rival.finished or rival.lap != cap.lap: continue
		if absf(rival.position.y - y) < 65 and absf(rival.position.x - x) < 54: return false
	return true

func steering_axis() -> float:
	return axis

func consume_boost() -> bool:
	var result := boost_requested
	boost_requested = false
	return result
