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
