class_name CapPresentation
extends Node2D
## Combines visual poses; never changes the cap's physics transform or collision.

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

func _ready() -> void:
	cap = get_parent() as RacingCap
	body = CapIllustration.new()
	body.appearance = appearance
	body.tint = tint
	add_child(body)
	cap.impacted.connect(on_impact)
	cap.boosted.connect(on_boost)
	cap.landed.connect(on_landing)
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
	var lift := sin(PI * cap.jump_time / maxf(0.01, cap.jump_duration))
	var squash := sin(impact_time / 0.25 * PI) * 0.23 + sin(landing_time / 0.25 * PI) * 0.16
	var stretch := 0.10 if cap.boost_time > 0 else 0.0
	body.scale = Vector2(1 + squash - stretch, 1 - squash + stretch) * (1 + lift * 0.2)
	body.position = Vector2(0, -lift * 14 + sin(clock * 3) * 1.2)
	var tilt := clampf(cap.velocity.x / 600, -0.22, 0.22)
	body.rotation = lerp_angle(body.rotation, tilt, 1 - exp(-9 * delta))
	if victory:
		body.position.y -= absf(sin(clock * 5)) * 10
		body.rotation = sin(clock * 5) * 0.12
	body.set_mood(1 if impact_time > 0 else (2 if cap.boost_time > 0 else 0))
	wake_timer -= delta
	if cap.active and cap.velocity.length() > 90 and wake_timer <= 0 and is_instance_valid(fx):
		wake_timer = 0.09 if cap.boost_time > 0 else 0.22
		fx.wake(global_position + Vector2(0, 22), cap.velocity, appearance.trail_color if cap.boost_time > 0 else Color("b2fff4"), cap.boost_time > 0)

func on_impact(point: Vector2, normal: Vector2, strength: float) -> void:
	impact_time = 0.25
	if is_instance_valid(fx):
		fx.burst(point, normal, Color("fff1b8"), clampf(strength / 250, 0.5, 1.4))
		if strength > 120:
			fx.spark(point)

func on_boost() -> void:
	if is_instance_valid(fx):
		fx.burst(global_position, Vector2.DOWN, appearance.trail_color, 1.0)

func on_landing() -> void:
	landing_time = 0.25
	if is_instance_valid(fx):
		fx.burst(global_position, Vector2.UP, Color("b2fff4"), 0.7)

func _draw() -> void:
	if is_instance_valid(cap) and cap.shield_time > 0:
		draw_circle(Vector2.ZERO, 36, Color(0.5, 0.9, 1, 0.18))
		draw_arc(Vector2.ZERO, 36, 0, TAU, 32, Color(0.7, 1, 1, 0.8), 2, true)
	draw_set_transform(Vector2(2, 7), 0, Vector2(1.1, 0.8))
	draw_circle(Vector2.ZERO, 27, Color(0.01, 0.2, 0.3, 0.3))
