class_name WhirlpoolArea
extends WaterCurrentArea

@export var radius: float = 125.0
@export var attraction: float = 100.0
@export_range(0, 0.8) var pulse_depth: float = 0.0
@export_range(1, 12) var pulse_period: float = 4.0
var pulse_time := 0.0
var visual_motion: AmbientMotion

func _physics_process(delta: float) -> void:
	pulse_time += delta

func pulse_multiplier() -> float:
	return 1.0 - pulse_depth * (0.5 + 0.5 * sin(TAU * pulse_time / maxf(pulse_period, 1.0)))

func _ready() -> void:
	size = Vector2.ONE * radius * 2
	super._ready()
	var circle := CircleShape2D.new()
	circle.radius = radius
	get_child(0).shape = circle
	visual_motion = AmbientMotion.new()
	add_child(visual_motion)
	set_physics_process(pulse_depth > 0)

func force_at(point: Vector2) -> Vector2:
	var inward := global_position - point
	var falloff := clampf(1.0 - inward.length() / radius, 0.0, 1.0)
	return (inward.normalized() * attraction + inward.normalized().orthogonal() * strength) * falloff * pulse_multiplier()

func _draw() -> void:
	draw_circle(Vector2.ZERO, radius, Color(0.01, 0.28, 0.45, 0.3))
	var phase := visual_motion.phase if is_instance_valid(visual_motion) else 0.0
	for ring in range(1, 5):
		var angle := ring * 0.7 + phase * (0.45 + ring * 0.08)
		draw_arc(Vector2.ZERO, ring * radius / 5 * (0.75 + 0.25 * pulse_multiplier()), angle, PI * 1.6 + angle, 24, Color(0.6, 1, 1, 0.35 + 0.3 * pulse_multiplier()), 3, true)
