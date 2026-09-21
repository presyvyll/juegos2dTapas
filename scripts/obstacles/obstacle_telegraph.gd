class_name ObstacleTelegraph
extends Node2D
## Readability layer only; never changes obstacle transforms or collision shapes.

var obstacle: Node2D
var obstacle_radius := 43.0
var moving := false


func configure(target: Node2D, radius: float, is_moving: bool) -> void:
	obstacle = target
	obstacle_radius = radius
	moving = is_moving
	show_behind_parent = true
	if moving:
		add_child(AmbientMotion.new())
	queue_redraw()


func _draw() -> void:
	var foam := Color("b9fff3")
	foam.a = 0.30
	draw_set_transform(Vector2(0.0, 8.0), 0.0, Vector2(1.15, 0.48))
	draw_arc(Vector2.ZERO, obstacle_radius + 10.0, 0.12, PI - 0.12, 20, foam, 5.0, true)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	var warning := Color("ffdc6c")
	warning.a = 0.58
	for index in range(2):
		var y := obstacle_radius + 54.0 + index * 29.0
		draw_polyline(PackedVector2Array([Vector2(-13.0, y + 7.0), Vector2(0.0, y - 4.0), Vector2(13.0, y + 7.0)]), warning, 4.0, true)
	if not moving or not is_instance_valid(obstacle):
		return
	var state: Vector3 = obstacle.call("telegraph_state")
	var origin_offset := state.x - obstacle.position.x
	var travel := state.y
	var direction := signf(state.z)
	var route := Color("d9fff7")
	route.a = 0.34
	var segment_length := travel * 2.0 / 8.0
	for index in range(0, 8, 2):
		var start_x := origin_offset - travel + index * segment_length
		draw_line(Vector2(start_x, 0.0), Vector2(start_x + segment_length, 0.0), route, 3.0, true)
	for side in [-1.0, 1.0]:
		draw_arc(Vector2(origin_offset + side * travel, 0.0), 9.0, 0.0, TAU, 16, route, 3.0, true)
	var wake := Color("fff0b8")
	wake.a = 0.48
	for index in range(3):
		var x := -direction * (obstacle_radius + 14.0 + index * 13.0)
		draw_line(Vector2(x, -8.0 + index * 5.0), Vector2(x - direction * 16.0, -8.0 + index * 5.0), wake, 3.0, true)
