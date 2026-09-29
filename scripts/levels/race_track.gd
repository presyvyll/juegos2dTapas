class_name RaceTrack
extends Node2D

const STEP: float = 120.0
const WATER_SHADER := preload("res://shaders/water_surface.gdshader")
const TRASH_CAN_OBSTACLE := preload("res://scripts/obstacles/trash_can_obstacle.gd")
const TIRE_OBSTACLE := preload("res://scripts/obstacles/tire_obstacle.gd")
const SHOPPING_BAG_OBSTACLE := preload("res://scripts/obstacles/shopping_bag_obstacle.gd")
@export var definition: CircuitDefinition
@export var high_quality := true
var obstacles: Array[Node2D] = []
var soft_obstacles: Array[Node2D] = []
var power_pickups: Array[RacingPickup] = []
var checkpoint_count := 12
var water_polygon := PackedVector2Array()
var left_edge := PackedVector2Array()
var right_edge := PackedVector2Array()

func center_at(y: float) -> float:
	return sin(-y / definition.curve_period) * definition.curve_amplitude + sin(-y / definition.secondary_curve_period) * definition.curve_amplitude * 0.22

func width_at(y: float) -> float:
	return definition.width + sin(-y / 1100.0) * definition.width_variation

func flow_at(y: float) -> Vector2:
	return Vector2(center_at(y - 80) - center_at(y), -80).normalized()

func starting_slot(index: int) -> Vector2:
	return Vector2((index - 1.5) * 85.0, 40.0)

func pickup_clear(point: Vector2) -> bool:
	if absf(point.x - center_at(point.y)) + 60 >= width_at(point.y) / 2:
		return false
	for obstacle in obstacles:
		var travel: float = obstacle.travel if obstacle is MovingObstacle else 0.0
		var closest := Vector2(clampf(point.x, obstacle.position.x - travel, obstacle.position.x + travel), obstacle.position.y)
		if point.distance_to(closest) < obstacle.radius + 60:
			return false
	for obstacle in soft_obstacles:
		if is_instance_valid(obstacle) and point.distance_to(obstacle.position) < obstacle.radius + 60:
			return false
	return true

func pickup_position(y: float, preferred_offset: float) -> Vector2:
	for shift in [0.0, -220.0, 220.0, -440.0, 440.0]:
		var candidate_y: float = y + shift
		var half_width := width_at(candidate_y) / 2
		for offset in [preferred_offset, -preferred_offset, 0.0, half_width * 0.55, -half_width * 0.55, half_width * 0.72, -half_width * 0.72]:
			var point := Vector2(center_at(candidate_y) + offset, candidate_y)
			if pickup_clear(point):
				return point
	push_error("No accessible pickup position in " + definition.id)
	return Vector2(center_at(y), y)

func _ready() -> void:
	build_banks()
	create_water_plane()
	var start_grid := preload("res://scripts/visuals/race_start_grid.gd").new()
	start_grid.track = self
	add_child(start_grid)
	populate()
	var course_moment := preload("res://scripts/visuals/course_moment.gd").new()
	course_moment.track = self
	course_moment.z_index = -1
	add_child(course_moment)
	if definition.id == "fuente":
		var environment := preload("res://scripts/visuals/fountain_environment.gd").new()
		environment.track = self
		environment.z_index = -1
		add_child(environment)
	if definition.ambient_profile:
		var ambient := preload("res://scripts/visuals/track_ambient_spawner.gd").new()
		ambient.name = "TrackAmbientSpawner"
		ambient.track = self
		ambient.profile = definition.ambient_profile
		ambient.z_index = -1
		add_child(ambient)
	queue_redraw()

func create_water_plane() -> void:
	var plane := Polygon2D.new()
	plane.name = "AnimatedWater"
	plane.polygon = water_polygon
	plane.uv = water_polygon
	plane.z_index = -5
	var water_material := ShaderMaterial.new()
	water_material.shader = WATER_SHADER
	water_material.set_shader_parameter("water_color", definition.water_color)
	water_material.set_shader_parameter("shimmer_strength", 1.0 if high_quality else 0.58)
	plane.material = water_material
	add_child(plane)

func build_banks() -> void:
	var walls := StaticBody2D.new()
	walls.name = "Banks"
	walls.add_to_group("channel_banks")
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
	if definition.authored_layout:
		populate_features()
		populate_debris()
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = definition.seed_value
	for fraction in [0.23, 0.60, 0.87]:
		var y: float = -definition.length * fraction
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
	populate_debris()

func populate_debris() -> void:
	# Add recognizable everyday debris without allowing solid hazards to seal the channel.
	var hard_specs: Array = [
		[TRASH_CAN_OBSTACLE, 0.33, -0.42],
		[BranchObstacle, 0.61, 0.38],
		[TIRE_OBSTACLE, 0.82, -0.24],
	]
	var hard_budget := maxi(0, 12 - obstacles.size())
	for index in range(mini(hard_budget, hard_specs.size())):
		var spec: Array = hard_specs[index]
		var obstacle := spec[0].new() as Node2D
		var radius_value: float = obstacle.radius
		obstacle.position = debris_position(definition.length * float(spec[1]), float(spec[2]), radius_value)
		add_child(obstacle)
		obstacles.append(obstacle)
	for spec in [[0.47, 0.18], [0.73, -0.52]]:
		var bag := SHOPPING_BAG_OBSTACLE.new() as Node2D
		bag.position = debris_position(definition.length * float(spec[0]), float(spec[1]), bag.radius)
		add_child(bag)
		soft_obstacles.append(bag)

func debris_position(distance: float, preferred_lane: float, radius_value: float) -> Vector2:
	for shift in [0.0, -130.0, 130.0, -260.0, 260.0]:
		var y := clampf(-distance + shift, -definition.length + 260.0, -340.0)
		for lane in [preferred_lane, -preferred_lane, 0.55, -0.55, 0.0]:
			var usable_half := width_at(y) * 0.5 - radius_value - 90.0
			var point := Vector2(center_at(y) + float(lane) * usable_half, y)
			if debris_clear(point, radius_value):
				return point
	var fallback_y := clampf(-distance, -definition.length + 260.0, -340.0)
	return Vector2(center_at(fallback_y), fallback_y)

func debris_clear(point: Vector2, radius_value: float) -> bool:
	if absf(point.x - center_at(point.y)) + radius_value + 80.0 >= width_at(point.y) * 0.5:
		return false
	for obstacle in obstacles:
		if not is_instance_valid(obstacle):
			continue
		var travel: float = obstacle.travel if obstacle is MovingObstacle else 0.0
		var closest := Vector2(clampf(point.x, obstacle.position.x - travel, obstacle.position.x + travel), obstacle.position.y)
		if point.distance_to(closest) < radius_value + obstacle.radius + 150.0:
			return false
	for obstacle in soft_obstacles:
		if is_instance_valid(obstacle) and point.distance_to(obstacle.position) < radius_value + obstacle.radius + 120.0:
			return false
	return true

func populate_features() -> void:
	for feature in definition.features:
		if not feature.scene or feature.distance <= 300 or feature.distance >= definition.length - 200:
			push_error("Invalid circuit feature in " + definition.id)
			continue
		var obstacle := feature.scene.instantiate() as Node2D
		var y := -feature.distance
		obstacle.position = Vector2(center_at(y) + feature.lane * width_at(y) / 2, y)
		if obstacle is RockObstacle and feature.rock_radius > 0:
			obstacle.radius = feature.rock_radius
		if obstacle is MovingObstacle:
			if feature.travel >= 0:
				obstacle.travel = feature.travel
			if feature.frequency > 0:
				obstacle.frequency = feature.frequency
		if obstacle is WhirlpoolArea:
			obstacle.pulse_depth = feature.pulse_depth
			obstacle.pulse_period = feature.pulse_period
			if feature.whirlpool_radius > 0:
				obstacle.radius = feature.whirlpool_radius
			if feature.attraction >= 0:
				obstacle.attraction = feature.attraction
		if obstacle is WaterCurrentArea:
			if feature.current_direction != Vector2.ZERO:
				obstacle.direction = feature.current_direction
			if feature.current_strength > 0:
				obstacle.strength = feature.current_strength
			if feature.speed_modifier > 0:
				obstacle.max_speed_modifier = feature.speed_modifier
			if feature.current_size != Vector2.ZERO:
				obstacle.size = feature.current_size
			if feature.turbulence >= 0:
				obstacle.turbulence = feature.turbulence
		add_child(obstacle)
		if obstacle is RockObstacle:
			obstacles.append(obstacle)

func _draw() -> void:
	# Static layers follow the existing banks; collision geometry is unchanged.
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
		# WaterSurface draws these wave marks only inside the current viewport.
		if index % (4 if high_quality else 8) == 0:
			for side in [-1, 1]:
				var spot := Vector2(center + side * (width_at(y) / 2 + 65), y)
				draw_bank_detail(spot, index)
	for index in range(mini(definition.section_distances.size(), definition.section_labels.size())):
		var y := -definition.section_distances[index]
		var spot := Vector2(center_at(y) + width_at(y) / 2 - 132, y)
		draw_style_box(section_sign_style(), Rect2(spot - Vector2(6, 24), Vector2(125, 32)))
		draw_string(ThemeDB.fallback_font, spot, definition.section_labels[index], HORIZONTAL_ALIGNMENT_CENTER, 113, 17, Color("fff0bf"))
	var finish_y := -definition.length
	for tile in range(20):
		var x := center_at(finish_y) - width_at(finish_y) / 2 + tile * width_at(finish_y) / 20
		for row in range(2):
			draw_rect(Rect2(x, finish_y + row * 22, width_at(finish_y) / 20, 22), Color.WHITE if (tile + row) % 2 == 0 else Color("184953"))

func draw_bank_detail(spot: Vector2, index: int) -> void:
	match definition.theme_id:
		"jardin":
			draw_circle(spot, 30, Color("407f60"))
			for petal in range(5):
				draw_circle(spot + Vector2.from_angle(petal * TAU / 5) * 14, 11, Color("ffaccf"))
			draw_circle(spot, 8, Color("ffe399"))
		"templo", "laberinto", "plaza":
			draw_rect(Rect2(spot - Vector2(23, 35), Vector2(46, 70)), Color("607c79"))
			draw_rect(Rect2(spot - Vector2(29, 35), Vector2(58, 12)), Color("c6c6a5"))
			draw_line(spot + Vector2(-10, -16), spot + Vector2(-10, 25), Color("abc0b1"), 5)
		"neon", "eclipse":
			var tint := Color("79f8ef") if index % 8 == 0 else Color("ef8cfa")
			draw_rect(Rect2(spot - Vector2(13, 40), Vector2(26, 80)), Color("26365f"))
			draw_line(spot - Vector2(0, 34), spot + Vector2(0, 34), tint, 6)
		_:
			if high_quality:
				draw_circle(spot, 28, Color("407f60"))
				draw_circle(spot + Vector2(12, -15), 22, Color("7cac69"))

func section_sign_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("26365f")
	style.set_corner_radius_all(6)
	return style
