class_name RaceCheckpoint
extends Area2D

signal crossed(cap: RacingCap, index: int)
@export var index: int = 0
@export var width: float = 900.0
@export var finish_line: bool = false

func _ready() -> void:
	collision_layer = 0
	collision_mask = 1
	var shape := RectangleShape2D.new()
	shape.size = Vector2(width, 8)
	var collision := CollisionShape2D.new()
	collision.shape = shape
	add_child(collision)
	body_entered.connect(func(body: Node2D) -> void:
		if body is RacingCap and body.velocity.y < 0 and body.active and not body.finished:
			crossed.emit(body, index)
	)

func _draw() -> void:
	if not finish_line:
		draw_line(Vector2(-width / 2 + 50, 0), Vector2(width / 2 - 50, 0), Color(1, 1, 1, 0.13), 2)
