class_name WhirlpoolArea
extends WaterCurrentArea

@export var radius: float = 125.0
@export var attraction: float = 100.0

func _ready() -> void:
	size = Vector2.ONE * radius * 2
	super._ready()
	var circle := CircleShape2D.new()
	circle.radius = radius
	get_child(0).shape = circle

func force_at(point: Vector2) -> Vector2:
	var inward := global_position - point
	var falloff := clampf(1.0 - inward.length() / radius, 0.0, 1.0)
	return (inward.normalized() * attraction + inward.normalized().orthogonal() * strength) * falloff

func _draw() -> void:
	draw_circle(Vector2.ZERO, radius, Color(0.01, 0.28, 0.45, 0.3))
	for ring in range(1, 5):
		draw_arc(Vector2.ZERO, ring * radius / 5, ring * 0.7, PI * 1.6 + ring * 0.7, 32, Color(0.6, 1, 1, 0.65), 3, true)
