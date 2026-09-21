class_name WaterSurface
extends Node2D

var track: RaceTrack
var target: RacingCap
var clock := 0.0
var refresh := 0.0
var visible_wave_rows := 0

func wave_row_range() -> Vector2i:
	var inverse := get_viewport().get_canvas_transform().affine_inverse()
	var top_y := (inverse * Vector2.ZERO).y
	var bottom_y := (inverse * get_viewport_rect().size).y
	var total := int(track.definition.length / 180)
	# One-row margin prevents popping while the existing 10/20 Hz refresh catches up.
	return Vector2i(clampi(int(floor(-bottom_y / 180)) - 1, 0, total), clampi(int(ceil(-top_y / 180)) + 2, 0, total))

func _process(delta: float) -> void:
	clock += delta
	refresh -= delta
	if refresh > 0 or not is_instance_valid(target):
		return
	refresh = 0.05 if track.high_quality else 0.1
	position.y = floorf(target.global_position.y / 180) * 180
	queue_redraw()

func _draw() -> void:
	var rows := wave_row_range()
	visible_wave_rows = maxi(0, rows.y - rows.x)
	draw_depth(rows)
	for index in range(rows.x, rows.y):
		var world_y := -index * 180.0
		var center := track.center_at(world_y)
		for lane in [-1, 0, 1]:
			var spot := to_local(track.to_global(Vector2(center + lane * 150, world_y)))
			draw_arc(spot, 22, 0.2, 2.8, 8, Color(0.7, 1, 1, 0.24), 2, true)
	for row in range(-5, 5):
		var y := row * 180.0 + fmod(clock * 38, 180)
		var world_y := position.y + y
		var center := track.center_at(world_y)
		for side in [-1, 1]:
			var x: float = center + side * (track.width_at(world_y) / 2 - 32)
			draw_line(Vector2(x,y), Vector2(x + sin(clock + row) * 5,y + 32), Color(0.75,1,0.95,0.45), 3, true)
		# Short highlights in the visible patch; no screen texture or distortion pass.
		if track.high_quality or row % 2 == 0:
			var lane := sin(row * 2.3) * 0.55
			var x := center + lane * track.width_at(world_y) / 2
			var glint := 0.12 + 0.09 * sin(clock * 1.6 + row)
			draw_arc(Vector2(x, y), 18 + 5 * sin(row), 0.2, 2.3, 8, Color(0.8, 1, 0.95, glint), 2, true)
	if track.definition.storm:
		# Rain is bounded to this camera-following patch and shares its 10/20 Hz redraw.
		var count := 36 if track.high_quality else 16
		for index in range(count):
			var y := fposmod(index * 137.0 + clock * 520, 1800) - 900
			var world_y := position.y + y
			var lane := sin(index * 7.13) * 0.88
			var x := track.center_at(world_y) + lane * track.width_at(world_y) / 2
			draw_line(Vector2(x, y), Vector2(x - 12, y + 27), Color(0.78, 0.91, 1, 0.42), 2, true)

func draw_depth(rows: Vector2i) -> void:
	# A few broad translucent shapes give the water volume without obscuring
	# rocks, pickups or racers. Geometry is limited to the same visible rows.
	var deep_left := PackedVector2Array()
	var deep_right := PackedVector2Array()
	var shallow_left := PackedVector2Array()
	var shallow_right := PackedVector2Array()
	var flow_left := PackedVector2Array()
	var flow_right := PackedVector2Array()
	for index in range(rows.x, rows.y + 1):
		var world_y := -index * 180.0
		var center := track.center_at(world_y)
		var half_width := track.width_at(world_y) * 0.5
		var local_y := to_local(track.to_global(Vector2(center, world_y))).y
		deep_left.append(Vector2(center - half_width * 0.34, local_y))
		deep_right.append(Vector2(center + half_width * 0.34, local_y))
		shallow_left.append(Vector2(center - half_width + 54.0, local_y))
		shallow_right.append(Vector2(center + half_width - 54.0, local_y))
		var current_sway := sin(clock * 0.7 + index * 0.9) * 9.0
		flow_left.append(Vector2(center - half_width * 0.18 + current_sway, local_y))
		flow_right.append(Vector2(center + half_width * 0.18 + current_sway, local_y))
	var deep_polygon := deep_left.duplicate()
	deep_right.reverse()
	deep_polygon.append_array(deep_right)
	var deep_color := track.definition.water_color.darkened(0.32)
	deep_color.a = 0.13 if track.high_quality else 0.1
	draw_colored_polygon(deep_polygon, deep_color)
	draw_polyline(shallow_left, Color(0.75, 1.0, 0.92, 0.09), 54.0, true)
	draw_polyline(shallow_right, Color(0.75, 1.0, 0.92, 0.09), 54.0, true)
	var flow_color := Color(0.78, 1.0, 0.96, 0.13 if track.high_quality else 0.09)
	draw_polyline(flow_left, flow_color, 3.0, true)
	draw_polyline(flow_right, flow_color, 3.0, true)
