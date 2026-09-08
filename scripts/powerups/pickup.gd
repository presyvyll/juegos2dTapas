class_name RacingPickup
extends Area2D

var definition: PowerUpDefinition
var cooldown := 0.0
var clock := 0.0

func _ready() -> void:
	collision_layer = 0
	collision_mask = 1
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 36
	shape.shape = circle
	add_child(shape)
	body_entered.connect(collect)

func collect(body: Node) -> void:
	if cooldown > 0 or not body is RacingCap or not body.active or body.finished:
		return
	cooldown = 8.0
	definition.apply(body)
	body.powerup_received.emit(definition)
	hide()

func _process(delta: float) -> void:
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
	draw_circle(bob, 32, Color("10283b"))
	draw_arc(bob, 28, 0, TAU, 24, definition.color, 4, true)
	if definition.id == "shield":
		draw_circle(bob, 17, Color(0.5, 0.9, 1, 0.4))
		draw_arc(bob, 17, PI, TAU, 12, Color.WHITE, 3, true)
	else:
		draw_colored_polygon(PackedVector2Array([bob + Vector2(4,-21), bob + Vector2(-13,3), bob, bob + Vector2(-4,21), bob + Vector2(14,-4), bob + Vector2(2,-4)]), definition.color)
