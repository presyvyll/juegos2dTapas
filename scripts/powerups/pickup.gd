class_name RacingPickup
extends Area2D

var definition: PowerUpDefinition
var cooldown := 0.0
var clock := 0.0
var power_gate := -1
var required_lap := 1
var observer: RacingCap

func _ready() -> void:
	if power_gate < 0: add_to_group("race_rewards")
	collision_layer = 0
	collision_mask = 1
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 36
	shape.shape = circle
	add_child(shape)
	body_entered.connect(collect)

func collect(body: Node) -> void:
	if power_gate >= 0:
		if body is RacingCap and body.lap == required_lap:
			body.race_power.equip(definition.id, power_gate, global_position)
		return
	if cooldown > 0 or not body is RacingCap or not body.active or body.finished:
		return
	cooldown = 8.0
	definition.apply(body)
	body.powerup_received.emit(definition)
	hide()

func _process(delta: float) -> void:
	if power_gate >= 0:
		visible = is_instance_valid(observer) and not observer.finished and observer.lap == required_lap and not power_gate in observer.race_power.collected_gates
		if visible:
			clock += delta
			var screen := get_viewport().get_canvas_transform() * global_position
			if get_viewport_rect().grow(90).has_point(screen): queue_redraw()
		return
	cooldown = maxf(0, cooldown - delta)
	visible = cooldown <= 0
	if not visible:
		return
	clock += delta
	var screen := get_viewport().get_canvas_transform() * global_position
	if get_viewport_rect().grow(80).has_point(screen):
		queue_redraw()
	# A cap still overlapping when the pickup returns can collect it.
	for body in get_overlapping_bodies():
		collect(body)

func _draw() -> void:
	var bob := Vector2(0, sin(clock * 3) * 5)
	if power_gate >= 0:
		draw_set_transform(Vector2(0, 25), 0, Vector2(1, 0.35))
		draw_circle(Vector2.ZERO, 31, Color(0, 0.1, 0.15, 0.24))
		draw_set_transform(Vector2.ZERO)
		for ring in range(3): draw_circle(bob, 27 + ring * 7 + sin(clock * 3) * 2, Color(definition.color, 0.14 - ring * 0.035))
		draw_arc(bob, 30, clock, clock + PI * 1.4, 24, Color(definition.color, 0.65), 2, true)
		for index in range(4): draw_circle(bob + Vector2.from_angle(clock * 1.4 + index * PI / 2) * 37, 2.3, definition.color)
		PowerGlyph.paint(self, definition.id, bob, 0.85 + sin(clock * 3) * 0.035, clock)
		return
	draw_circle(bob, 32, Color("10283b"))
	draw_arc(bob, 28, 0, TAU, 24, definition.color, 4, true)
	if definition.id == "shield":
		draw_circle(bob, 17, Color(0.5, 0.9, 1, 0.4))
		draw_arc(bob, 17, PI, TAU, 12, Color.WHITE, 3, true)
	else:
		draw_colored_polygon(PackedVector2Array([bob + Vector2(4,-21), bob + Vector2(-13,3), bob, bob + Vector2(-4,21), bob + Vector2(14,-4), bob + Vector2(2,-4)]), definition.color)
