class_name ShoppingBagObstacle
extends Area2D

var radius := 42.0
var visual_motion: AmbientMotion
var hit_flash := 0.0

func _ready() -> void:
	collision_layer = 0
	collision_mask = 1
	monitorable = false
	add_to_group("soft_obstacles")
	var shape := RectangleShape2D.new()
	shape.size = Vector2(74, 82)
	var collider := CollisionShape2D.new()
	collider.shape = shape
	add_child(collider)
	body_entered.connect(_on_body_entered)
	visual_motion = AmbientMotion.new()
	add_child(visual_motion)

func _on_body_entered(body: Node2D) -> void:
	if not body is RacingCap:
		return
	var cap := body as RacingCap
	if cap.race_power.block_attack():
		return
	# The bag clings briefly: pronounced drag with a mild steering disturbance.
	cap.velocity *= 0.62
	cap.race_power.slow_time = maxf(cap.race_power.slow_time, 1.35)
	cap.race_power.disruption = maxf(cap.race_power.disruption, 0.30)
	cap.trigger_ability("light_obstacle")
	cap.impacted.emit(global_position, Vector2.UP, 58.0)
	hit_flash = 1.0
	queue_redraw()

func _process(delta: float) -> void:
	hit_flash = maxf(0.0, hit_flash - delta * 2.8)

func _draw() -> void:
	var phase := visual_motion.phase if is_instance_valid(visual_motion) else 0.0
	var bob := sin(phase * 1.8) * 4.0
	draw_set_transform(Vector2(5, 17), 0.0, Vector2(1.05, 0.42))
	draw_circle(Vector2.ZERO, 39, Color(0.01, 0.13, 0.16, 0.25))
	draw_set_transform(Vector2(0, bob), sin(phase * 1.25) * 0.08)
	var bag_color := Color("fff1ce").lightened(hit_flash * 0.18)
	draw_colored_polygon(PackedVector2Array([Vector2(-31, -23), Vector2(31, -23), Vector2(26, 34), Vector2(-25, 34)]), bag_color)
	draw_arc(Vector2(-16, -21), 15, PI, TAU, 12, Color("d5b98d"), 5, true)
	draw_arc(Vector2(16, -21), 15, PI, TAU, 12, Color("d5b98d"), 5, true)
	draw_circle(Vector2.ZERO, 12, Color("52ad67"))
	draw_polyline(PackedVector2Array([Vector2(-8, 2), Vector2(0, -8), Vector2(9, 3)]), Color("e9fff0"), 3, true)
	draw_set_transform(Vector2.ZERO)
	var warning := Color(1.0, 0.72, 0.30, 0.58)
	for index in range(2):
		var y := radius + 45.0 + index * 25.0
		draw_polyline(PackedVector2Array([Vector2(-11, y + 6), Vector2(0, y - 3), Vector2(11, y + 6)]), warning, 3.5, true)
