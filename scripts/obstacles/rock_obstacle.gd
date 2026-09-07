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
	draw_circle(Vector2(3, 8), radius + 5, Color(0, 0.3, 0.35, 0.3))
	draw_circle(Vector2.ZERO, radius, tint)
	draw_arc(Vector2(-4, -4), radius * 0.7, PI, TAU * 0.95, 16, tint.lightened(0.25), 5, true)
