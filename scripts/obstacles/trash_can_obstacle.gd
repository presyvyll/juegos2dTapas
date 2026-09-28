class_name TrashCanObstacle
extends RockObstacle

var wobble := 0.0
var wobble_velocity := 0.0

func _init() -> void:
	radius = 43.0
	tint = Color("6f8586")

func _ready() -> void:
	super._ready()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(62, 76)
	get_child(0).shape = shape
	set_process(false)

func on_cap_collision(cap: RacingCap, normal: Vector2, impact: float) -> void:
	# Heavy metal absorbs speed, then kicks the cap away with a short steering shake.
	cap.velocity *= 0.60
	cap.velocity += normal * clampf(impact * 0.42, 35.0, 105.0)
	cap.race_power.slow_time = maxf(cap.race_power.slow_time, 0.55)
	cap.race_power.disruption = maxf(cap.race_power.disruption, 0.45)
	wobble_velocity = clampf(impact * 0.0018, 0.12, 0.42) * (-1.0 if normal.x < 0 else 1.0)
	set_process(true)

func _process(delta: float) -> void:
	wobble_velocity = move_toward(wobble_velocity, 0.0, delta * 0.75)
	wobble = lerpf(wobble, wobble_velocity, minf(1.0, delta * 12.0))
	queue_redraw()
	if absf(wobble_velocity) < 0.01 and absf(wobble) < 0.01:
		wobble = 0.0
		set_process(false)

func _draw() -> void:
	draw_set_transform(Vector2(6, 12), 0.0, Vector2(1.05, 0.42))
	draw_circle(Vector2.ZERO, 39, Color(0.01, 0.12, 0.14, 0.32))
	draw_set_transform(Vector2.ZERO)
	draw_set_transform(Vector2.ZERO, wobble)
	draw_colored_polygon(PackedVector2Array([Vector2(-27, -32), Vector2(27, -32), Vector2(23, 34), Vector2(-23, 34)]), Color("526b6d"))
	draw_rect(Rect2(-31, -37, 62, 11), Color("263e42"), true)
	draw_rect(Rect2(-25, -28, 50, 7), Color("8fa7a2"), true)
	draw_line(Vector2(-14, -18), Vector2(-12, 25), Color("93aaa4"), 4, true)
	draw_line(Vector2(13, -18), Vector2(11, 25), Color("334e51"), 4, true)
	for side in [-1.0, 1.0]:
		draw_circle(Vector2(side * 17, 36), 7, Color("1c292c"))
		draw_circle(Vector2(side * 17, 36), 3, Color("839393"))
	draw_set_transform(Vector2.ZERO)
