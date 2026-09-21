class_name CapPresentation
extends Node2D
## Combines visual poses; never changes the cap's physics transform or collision.

const HIT_FLASH_EFFECT := preload("res://scripts/vfx/hit_flash.gd")

var tint := Color("ffce58")
var appearance := CapAppearance.new()
var body: CapIllustration
var cap: RacingCap
var impact_time := 0.0
var landing_time := 0.0
var clock := 0.0
var victory := false
var had_shield := false
var wake_timer := 0.0
var fx: WaterVFXPool
var impact_strength := 0.0
var visual_stretch := 0.0
var trail_points: Array[Vector2] = []
var trail_ages: Array[float] = []
var trail_sample_time := 0.0
var trail_opacity := 0.0
var trail_limit := 12
var hit_flash := HIT_FLASH_EFFECT.new()
var bank_scrape_time := 0.0
var bank_scrape_strength := 0.0

func _ready() -> void:
	cap = get_parent() as RacingCap
	trail_limit = 16 if SaveManager.settings.quality == "high" else 9
	body = CapIllustration.new()
	body.appearance = appearance
	body.tint = tint
	add_child(body)
	hit_flash.attach(body)
	cap.impacted.connect(on_impact)
	cap.bank_contact.connect(on_bank_contact)
	cap.boosted.connect(on_boost)
	cap.landed.connect(on_landing)
	cap.swiped.connect(on_swipe)
	cap.ability_activated.connect(func(effect: CapAbilityDefinition) -> void:
		if is_instance_valid(fx): fx.burst(global_position, Vector2.UP, effect.feedback_color, 0.8)
	)
	cap.powerup_received.connect(func(effect: PowerUpDefinition) -> void:
		if is_instance_valid(fx):
			fx.burst(global_position, Vector2.UP, effect.color)
	)
	queue_redraw()

func configure(value: CapAppearance, color: Color) -> void:
	appearance = value if value else CapAppearance.new()
	tint = color
	if is_instance_valid(body):
		body.appearance = appearance
		body.tint = tint
		body.queue_redraw()

func _process(delta: float) -> void:
	clock += delta
	if (cap.shield_time > 0) != had_shield:
		queue_redraw()
	had_shield = cap.shield_time > 0
	impact_time = maxf(0, impact_time - delta)
	landing_time = maxf(0, landing_time - delta)
	bank_scrape_time = maxf(0, bank_scrape_time - delta)
	hit_flash.update(delta)
	var lift := sin(PI * cap.jump_time / maxf(0.01, cap.jump_duration))
	var squash := sin(impact_time / 0.25 * PI) * 0.23 * impact_strength + sin(landing_time / 0.25 * PI) * 0.16
	visual_stretch = lerpf(visual_stretch, 0.10 if cap.boost_time > 0 else 0.0, 1 - exp(-12 * delta))
	var stretch := visual_stretch
	body.scale = Vector2(1 + squash - stretch, 1 - squash + stretch) * (1 + lift * 0.2)
	var edge_jitter := sin(clock * 62.0) * 1.6 * bank_scrape_strength * clampf(bank_scrape_time / 0.14, 0.0, 1.0)
	body.position = Vector2(edge_jitter, -lift * 14 + sin(clock * 3) * 1.2)
	var tilt := clampf(cap.velocity.x / 600, -0.22, 0.22)
	body.rotation = lerp_angle(body.rotation, tilt, 1 - exp(-9 * delta))
	if victory:
		body.position.y -= absf(sin(clock * 5)) * 10
		body.rotation = sin(clock * 5) * 0.12
	body.set_mood(1 if impact_time > 0 else (2 if cap.boost_time > 0 else 0))
	update_boost_trail(delta)
	wake_timer -= delta
	if cap.active and cap.velocity.length() > 90 and wake_timer <= 0 and is_instance_valid(fx):
		wake_timer = 0.09 if cap.boost_time > 0 else lerpf(0.27, 0.14, clampf((cap.velocity.length() - 90) / 400, 0, 1))
		fx.wake(global_position + Vector2(0, 22), cap.velocity, appearance.trail_color if cap.boost_time > 0 else Color("b2fff4"), cap.boost_time > 0)

func update_boost_trail(delta: float) -> void:
	var changed := false
	for index in range(trail_ages.size()):
		trail_ages[index] += delta
	while not trail_ages.is_empty() and trail_ages[0] > 0.38:
		trail_ages.pop_front()
		trail_points.pop_front()
		changed = true
	trail_sample_time -= delta
	var boosting := cap.active and not cap.finished and cap.boost_time > 0 and cap.velocity.length() > 150.0
	if boosting:
		trail_opacity = minf(1.0, trail_opacity + delta * 9.0)
		if trail_sample_time <= 0.0:
			trail_sample_time = 0.035 if trail_limit > 9 else 0.065
			if trail_points.is_empty():
				trail_points.append(global_position - cap.velocity.normalized() * 38.0)
				trail_ages.append(0.06)
			trail_points.append(global_position)
			trail_ages.append(0.0)
			while trail_points.size() > trail_limit:
				trail_points.pop_front()
				trail_ages.pop_front()
			changed = true
	else:
		var previous_opacity := trail_opacity
		trail_opacity = maxf(0.0, trail_opacity - delta * 3.8)
		changed = changed or not is_equal_approx(previous_opacity, trail_opacity)
	if changed or not trail_points.is_empty():
		queue_redraw()

func on_impact(point: Vector2, normal: Vector2, strength: float) -> void:
	impact_time = 0.25
	impact_strength = clampf(strength / 300, 0.2, 1.0)
	hit_flash.trigger(strength)
	if is_instance_valid(fx):
		fx.burst(point, normal, Color("fff1b8"), clampf(strength / 250, 0.5, 1.4))
		if strength > 120:
			fx.spark(point)

func on_bank_contact(point: Vector2, normal: Vector2, motion: Vector2, strength: float, rebounded: bool) -> void:
	if rebounded:
		if is_instance_valid(fx): fx.edge_rebound(point, normal, strength)
		return
	bank_scrape_time = 0.14
	bank_scrape_strength = clampf(strength / 75.0, 0.18, 1.0)
	if is_instance_valid(fx): fx.edge_scrape(point, normal, motion, strength)

func on_boost() -> void:
	if is_instance_valid(fx):
		fx.burst(global_position, Vector2.DOWN, appearance.trail_color, 1.0)

func on_landing() -> void:
	landing_time = 0.25
	if is_instance_valid(fx):
		fx.burst(global_position, Vector2.UP, Color("b2fff4"), 0.7)

func on_swipe(direction: float) -> void:
	landing_time = 0.18
	if is_instance_valid(fx):
		var perfect := cap.controls.consumed_shot_grade == PerfectShotConfig.Grade.PERFECT
		fx.burst(global_position, Vector2(-direction, 0), Color("ffdc6c") if perfect else Color("b2fff4"), 0.8 if perfect else 0.55)

func _draw() -> void:
	if trail_points.size() >= 2 and trail_opacity > 0.01:
		var local_points := PackedVector2Array()
		for point in trail_points:
			local_points.append(to_local(point))
		var outer := appearance.trail_color.darkened(0.22)
		outer.a = 0.24 * trail_opacity
		var core := appearance.trail_color.lightened(0.28)
		core.a = 0.72 * trail_opacity
		draw_polyline(local_points, outer, 16.0, true)
		draw_polyline(local_points, core, 5.0, true)
	if is_instance_valid(cap) and cap.shield_time > 0:
		draw_circle(Vector2.ZERO, 36, Color(0.5, 0.9, 1, 0.18))
		draw_arc(Vector2.ZERO, 36, 0, TAU, 32, Color(0.7, 1, 1, 0.8), 2, true)
	draw_set_transform(Vector2(2, 7), 0, Vector2(1.1, 0.8))
	draw_circle(Vector2.ZERO, 27, Color(0.01, 0.2, 0.3, 0.3))
