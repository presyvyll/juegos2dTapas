class_name WaterSurface
extends Node2D

var track: RaceTrack
var target: RacingCap
var clock := 0.0
var refresh := 0.0

func _process(delta: float) -> void:
	clock += delta
	refresh -= delta
	if refresh > 0 or not is_instance_valid(target):
		return
	refresh = 0.05 if track.high_quality else 0.1
	position.y = floorf(target.global_position.y / 180) * 180
	queue_redraw()

func _draw() -> void:
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
