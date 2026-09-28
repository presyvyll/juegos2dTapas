class_name BranchObstacle
extends RockObstacle

func _ready() -> void:
	radius = 65
	super._ready()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(130, 22)
	get_child(0).shape = shape

func _draw() -> void:
	draw_line(Vector2(-65, 0), Vector2(65, 0), Color("75513b"), 22, true)
	draw_line(Vector2(-60, -5), Vector2(60, -5), Color("b78a58"), 4, true)
	draw_line(Vector2(-20, 0), Vector2(-42, -27), Color("75513b"), 8, true)
	for leaf in [Vector2(-45, -24), Vector2(-34, -34), Vector2(43, -8)]:
		draw_circle(leaf, 10, Color("3f8e46"))
		draw_circle(leaf + Vector2(-2, -2), 6, Color("72bd58"))

func on_cap_collision(cap: RacingCap, normal: Vector2, impact: float) -> void:
	# The branch catches the rim and twists the trajectory instead of stopping it dead.
	var side := signf(cap.position.x - position.x)
	if is_zero_approx(side):
		side = signf(normal.x) if not is_zero_approx(normal.x) else 1.0
	cap.velocity *= 0.78
	cap.velocity.x += side * clampf(impact * 0.48, 45.0, 105.0)
	cap.race_power.disruption = maxf(cap.race_power.disruption, 0.70)
	cap.trigger_ability("light_obstacle")
