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
