class_name RaceTrack
extends Node2D

const STEP: float = 120.0
@export var definition: CircuitDefinition
@export var high_quality := true
var obstacles: Array[Node2D] = []
var water_polygon := PackedVector2Array()
var left_edge := PackedVector2Array()
var right_edge := PackedVector2Array()

func center_at(y: float) -> float:
	return sin(-y / 1450.0) * definition.curve_amplitude + sin(-y / 630.0) * definition.curve_amplitude * 0.22

func width_at(y: float) -> float:
	return definition.width + sin(-y / 1100.0) * 85.0

func flow_at(y: float) -> Vector2:
	return Vector2(center_at(y - 80) - center_at(y), -80).normalized()

func _ready() -> void:
	build_banks()
	populate()
	queue_redraw()

func build_banks() -> void:
	var walls := StaticBody2D.new()
	walls.collision_layer = 2
	walls.collision_mask = 1
	add_child(walls)
	var samples := int((definition.length + 1200) / STEP) + 1
	for index in range(samples):
		var y := 600 - index * STEP
		left_edge.append(Vector2(center_at(y) - width_at(y) / 2, y))
		right_edge.append(Vector2(center_at(y) + width_at(y) / 2, y))
	for index in range(samples - 1):
		for edge in [left_edge, right_edge]:
			var shape := SegmentShape2D.new()
			shape.a = edge[index]
			shape.b = edge[index + 1]
			var collider := CollisionShape2D.new()
			collider.shape = shape
			walls.add_child(collider)
	water_polygon.append_array(left_edge)
	var reverse := right_edge.duplicate()
	reverse.reverse()
	water_polygon.append_array(reverse)

func populate() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = definition.seed_value
	for y in [-4200.0, -10800.0, -15700.0]:
		var drop := WaterDrop.new()
		drop.position = Vector2(center_at(y), y)
		add_child(drop)
	for index in range(1, int(definition.length / 650) - 1):
		var y := -index * 650.0
		var obstacle: Node2D
		match index % 5:
			0:
				obstacle = MovingObstacle.new()
			1:
				obstacle = RockObstacle.new()
			2:
				obstacle = BranchObstacle.new()
			3:
				obstacle = LeafObstacle.new()
			_:
				obstacle = RockObstacle.new()
				obstacle.radius = 95.0 # Island: two navigable routes.
		var lane: float = 0.0 if index % 5 == 4 else rng.randf_range(-0.55, 0.55)
		obstacle.position = Vector2(center_at(y) + lane * width_at(y) / 2, y)
		add_child(obstacle)
		if obstacle is RockObstacle:
			obstacles.append(obstacle)
		if index % 3 == 0:
			var whirlpool := WhirlpoolArea.new()
			whirlpool.position = Vector2(center_at(y - 240) - 145, y - 240)
			whirlpool.strength = 330
			add_child(whirlpool)
		elif index % 3 == 1:
			var jet := WaterJet.new()
			jet.position = Vector2(center_at(y - 250) + 150, y - 250)
			add_child(jet)
		else:
			var current := WaterCurrentArea.new()
			current.position = Vector2(center_at(y - 280), y - 280)
			current.size = Vector2(width_at(y) - 80, 180)
			current.direction = Vector2(0.4 if index % 2 == 0 else -0.4, -1)
			current.max_speed_modifier = 1.15
			add_child(current)

func _draw() -> void:
	# Static layers follow the existing banks; collision geometry is unchanged.
	draw_colored_polygon(water_polygon, Color("18b6c4"))
	for edge in [left_edge, right_edge]:
		# Dark shallow-water band and a narrow outline give the rim depth.
		draw_polyline(edge, Color("168594"), 65, true)
		draw_polyline(edge, Color("315d60"), 41, true)
		draw_polyline(edge, Color("d9c894"), 35, true)
		draw_set_transform(Vector2(-5, -3))
		draw_polyline(edge, Color("fff0bf"), 9, true)
		draw_set_transform(Vector2.ZERO)
	for index in range(int(definition.length / 180)):
		var y := -index * 180.0
		var center := center_at(y)
		for lane in [-1, 0, 1]:
			var x: float = center + lane * 150
			draw_arc(Vector2(x, y), 22, 0.2, 2.8, 8, Color(0.7, 1, 1, 0.24), 2, true)
		if index % 4 == 0 and high_quality:
			for side in [-1, 1]:
				var spot := Vector2(center + side * (width_at(y) / 2 + 65), y)
				draw_circle(spot, 28, Color("407f60"))
				draw_circle(spot + Vector2(12, -15), 22, Color("7cac69"))
	draw_line(Vector2(-300, 90), Vector2(300, 90), Color("fff2c6"), 7)
	var finish_y := -definition.length
	for tile in range(20):
		var x := center_at(finish_y) - width_at(finish_y) / 2 + tile * width_at(finish_y) / 20
		for row in range(2):
			draw_rect(Rect2(x, finish_y + row * 22, width_at(finish_y) / 20, 22), Color.WHITE if (tile + row) % 2 == 0 else Color("184953"))
