class_name TireObstacle
extends RockObstacle

var spin := 0.0
var spin_speed := 0.0

func _init() -> void:
	radius = 38.0
	tint = Color("27343a")

func _ready() -> void:
	super._ready()
	set_process(false)

func on_cap_collision(cap: RacingCap, normal: Vector2, impact: float) -> void:
	# The rubber tire returns energy: a stronger elastic rebound with a small sideways kick.
	var tangent := normal.orthogonal() * (-1.0 if cap.velocity.dot(normal.orthogonal()) < 0 else 1.0)
	cap.velocity += normal * clampf(impact * 0.72, 55.0, 155.0) + tangent * 34.0
	cap.race_power.disruption = maxf(cap.race_power.disruption, 0.24)
	spin_speed = clampf(impact * 0.035, 2.5, 8.0)
	set_process(true)

func _process(delta: float) -> void:
	spin += spin_speed * delta
	spin_speed = move_toward(spin_speed, 0.0, delta * 3.0)
	queue_redraw()
	if spin_speed <= 0.01:
		set_process(false)

func _draw() -> void:
	draw_set_transform(Vector2(6, 9), 0.0, Vector2(1.0, 0.55))
	draw_circle(Vector2.ZERO, radius + 5, Color(0.01, 0.10, 0.13, 0.30))
	draw_set_transform(Vector2.ZERO)
	draw_set_transform(Vector2.ZERO, spin)
	draw_circle(Vector2.ZERO, radius, Color("182326"))
	draw_circle(Vector2.ZERO, radius - 8, Color("405054"))
	draw_circle(Vector2.ZERO, radius - 18, Color("112126"))
	draw_circle(Vector2.ZERO, radius - 25, Color("7d9290"))
	for index in range(10):
		var angle := TAU * index / 10.0
		draw_line(Vector2.from_angle(angle) * (radius - 6), Vector2.from_angle(angle) * radius, Color("657174"), 4, true)
	draw_set_transform(Vector2.ZERO)
