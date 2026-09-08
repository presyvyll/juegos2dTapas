class_name RockObstacle
extends AnimatableBody2D

@export var radius: float = 43.0
@export var tint: Color = Color("778e85")

func _ready() -> void:
	sync_to_physics = false
	collision_layer = 2
	collision_mask = 1
	add_to_group("obstacles")
	var shape := CircleShape2D.new()
	shape.radius = radius
	var collider := CollisionShape2D.new()
	collider.shape = shape
	add_child(collider)
	queue_redraw()

func _draw() -> void:
	# Baked-looking volume, also reused by moving rocks. No lights or per-frame redraw.
	draw_set_transform(Vector2(7, 10), 0, Vector2(1.0, 0.88))
	draw_circle(Vector2.ZERO, radius + 6, Color(0.02, 0.22, 0.27, 0.3))
	draw_set_transform(Vector2.ZERO)
	draw_circle(Vector2.ZERO, radius, tint.darkened(0.48))
	draw_circle(Vector2(0, -2), radius - 3, tint.darkened(0.12))
	var facet := PackedVector2Array([
		Vector2(-0.73, -0.28), Vector2(-0.32, -0.77),
		Vector2(0.28, -0.74), Vector2(0.65, -0.3),
		Vector2(0.32, 0.22), Vector2(-0.42, 0.3)
	])
	for index in range(facet.size()):
		facet[index] *= radius
	draw_colored_polygon(facet, tint.lightened(0.16))
	draw_arc(Vector2(-2, -3), radius * 0.76, PI * 1.08, PI * 1.72, 12, tint.lightened(0.48), 3, true)
	draw_arc(Vector2.ZERO, radius - 5, 0.2, PI * 0.8, 12, tint.darkened(0.32), 3, true)
