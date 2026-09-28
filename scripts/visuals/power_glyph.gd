class_name PowerGlyph
extends RefCounted
## Shared vector silhouettes: pickups, equipped aura and the thumb control.
static func paint(canvas: CanvasItem, id: String, point: Vector2, scale_value: float, time: float) -> void:
	var color := Color(RacePower.POWERS[id][3])
	canvas.draw_set_transform(point, 0, Vector2.ONE * scale_value)
	match id:
		"turbo", "super", "recovery":
			if id == "super":
				canvas.draw_colored_polygon(PackedVector2Array([Vector2(-17, 12), Vector2(-12, -8), Vector2(-4, -1), Vector2(4, -25), Vector2(18, 6), Vector2(10, 20), Vector2(-7, 20)]), color)
			else:
				canvas.draw_colored_polygon(PackedVector2Array([Vector2(4, -23), Vector2(-15, 3), Vector2(-2, 3), Vector2(-6, 23), Vector2(16, -5), Vector2(3, -5)]), color)
			if id == "recovery": canvas.draw_arc(Vector2.ZERO, 27, -time, TAU - 0.8 - time, 20, color, 3, true)
		"shield":
			var shape := PackedVector2Array([Vector2(-19, -17), Vector2(0, -23), Vector2(19, -17), Vector2(15, 8), Vector2(0, 24), Vector2(-15, 8), Vector2(-19, -17)])
			canvas.draw_colored_polygon(shape, Color(color, 0.25))
			canvas.draw_polyline(shape, color, 3, true)
			canvas.draw_line(Vector2(0, -12), Vector2(0, 13), Color.WHITE, 2, true)
		"wave":
			canvas.draw_circle(Vector2.ZERO, 20, Color(color, 0.2))
			for row in range(3):
				var points := PackedVector2Array()
				for index in range(9): points.append(Vector2(-22 + index * 5.5, (row - 1) * 11 + sin(index * 0.65 + time * 3) * 4))
				canvas.draw_polyline(points, color, 3, true)
		"whirlpool":
			for ring in range(3): canvas.draw_arc(Vector2.ZERO, 8 + ring * 7, time * 2 + ring, time * 2 + ring + PI * 1.6, 16, color, 3, true)
		"magnet":
			canvas.draw_arc(Vector2(0, -5), 15, 0, PI, 14, color, 8, true)
			for side in [-1, 1]:
				canvas.draw_line(Vector2(side * 15, -18), Vector2(side * 15, -5), Color.WHITE, 8, true)
		"dash":
			for side in [-1, 1]: canvas.draw_polyline(PackedVector2Array([Vector2(side * 10 - 9, 13), Vector2(side * 10, -15), Vector2(side * 10 + 9, 13)]), color, 4, true)
		"ghost":
			canvas.draw_circle(Vector2(0, -7), 16, Color(color, 0.55))
			canvas.draw_colored_polygon(PackedVector2Array([Vector2(-16, -7), Vector2(16, -7), Vector2(18, 20), Vector2(6, 12), Vector2(0, 21), Vector2(-7, 13), Vector2(-18, 20)]), Color(color, 0.55))
			for side in [-1, 1]: canvas.draw_circle(Vector2(side * 6, -7), 3, Color("183542"))
		"heavy":
			canvas.draw_arc(Vector2(0, -12), 8, PI, TAU, 10, color, 5, true)
			canvas.draw_colored_polygon(PackedVector2Array([Vector2(-12, -10), Vector2(12, -10), Vector2(21, 19), Vector2(-21, 19)]), color)
	canvas.draw_set_transform(Vector2.ZERO)
