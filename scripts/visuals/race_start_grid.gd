class_name RaceStartGrid
extends Node2D
## Static start markings in their own CanvasItem so they cull after launch.

var track


func _ready() -> void:
	queue_redraw()


func _draw() -> void:
	var start_y := 82.0
	var start_width: float = track.width_at(start_y)
	var start_left: float = track.center_at(start_y) - start_width * 0.5
	for tile in range(16):
		for row in range(2):
			var tile_width: float = start_width / 16.0
			var color := Color("fff2c6") if (tile + row) % 2 == 0 else Color("184953")
			draw_rect(Rect2(start_left + tile * tile_width, start_y + row * 10.0, tile_width, 10.0), color)
	var slot_color := Color("d7fff5")
	slot_color.a = 0.38
	for index in range(4):
		var slot: Vector2 = track.starting_slot(index)
		draw_arc(slot + Vector2(0.0, 5.0), 31.0, PI, TAU, 16, slot_color, 3.0, true)
		draw_line(slot + Vector2(-22.0, 18.0), slot + Vector2(22.0, 18.0), slot_color, 3.0, true)
	var guide := Color("ffdc6c")
	guide.a = 0.34
	var guide_points := PackedVector2Array()
	for step in range(5):
		var y := -20.0 - step * 70.0
		guide_points.append(Vector2(track.center_at(y), y))
	draw_polyline(guide_points, guide, 3.0, true)
	for y in [-70.0, -175.0, -280.0]:
		var center := Vector2(track.center_at(y), y)
		draw_polyline(PackedVector2Array([center + Vector2(-15.0, 9.0), center + Vector2(0.0, -4.0), center + Vector2(15.0, 9.0)]), guide, 4.0, true)
