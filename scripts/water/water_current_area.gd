class_name WaterCurrentArea
extends Area2D
## Additive acceleration; overlapping currents are averaged by the cap.

@export var direction: Vector2 = Vector2.UP
@export var strength: float = 110.0
@export var turbulence: float = 12.0
@export_range(0.3, 2.0) var max_speed_modifier: float = 1.0
@export var size: Vector2 = Vector2(400, 260)
var elapsed: float = 0.0

func _ready() -> void:
	collision_layer = 0
	collision_mask = 1
	monitorable = false
	var shape := RectangleShape2D.new()
	shape.size = size
	var collider := CollisionShape2D.new()
	collider.shape = shape
	add_child(collider)
	body_entered.connect(_enter)
	body_exited.connect(_exit)
	queue_redraw()

func _physics_process(delta: float) -> void:
	elapsed += delta

func force_at(point: Vector2) -> Vector2:
	return direction.normalized() * strength + Vector2(sin(elapsed * 2.0 + point.y * 0.02), 0) * turbulence

func _enter(body: Node2D) -> void:
	if body is RacingCap:
		body.currents.append(self)

func _exit(body: Node2D) -> void:
	if body is RacingCap:
		body.currents.erase(self)

func _draw() -> void:
	draw_rect(Rect2(-size / 2, size), Color(0.7, 1, 1, 0.10))
	for offset in [-70, 0, 70]:
		var start := Vector2(offset, 25)
		var end := start + direction.normalized() * 55
		draw_line(start, end, Color(0.85, 1, 1, 0.65), 3, true)
		draw_circle(end, 4, Color(0.85, 1, 1, 0.65))
