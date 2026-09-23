extends Node2D
## Decorative fountain promenade. No collision, gameplay state or random draws.
var track: RaceTrack
var clock := 0.0
var refresh := 0.0
var visible_rows := 0

func _process(delta: float) -> void:
	clock += delta
	refresh -= delta
	if refresh > 0.0: return
	refresh = 0.05 if track.high_quality else 0.1
	queue_redraw()

func _draw() -> void:
	var inverse := get_viewport().get_canvas_transform().affine_inverse()
	var bounds := Rect2(inverse * Vector2.ZERO, Vector2.ZERO)
	bounds = bounds.expand(inverse * get_viewport_rect().size).grow(220.0)
	var first := int(floor(bounds.position.y / 240.0))
	var last := int(ceil(bounds.end.y / 240.0))
	visible_rows = last - first
	for side in [-1.0, 1.0]:
		var paving := PackedVector2Array()
		var outer := PackedVector2Array()
		for row in range(first, last + 1):
			var y := row * 240.0
			var edge: float = track.center_at(y) + side * track.width_at(y) * 0.5
			paving.append(Vector2(edge + side * 20.0, y))
			outer.append(Vector2(edge + side * 210.0, y))
		outer.reverse()
		paving.append_array(outer)
		draw_colored_polygon(paving, Color("779a8b"))
		var seams := PackedVector2Array()
		var border := PackedVector2Array()
		for row in range(first, last + 1):
			var y := row * 240.0
			var edge: float = track.center_at(y) + side * track.width_at(y) * 0.5
			border.append(Vector2(edge + side * 205.0, y))
			if row == last: continue
			for seam in [0.0, 80.0, 160.0]:
				seams.append(Vector2(edge + side * 25.0, y + seam))
				seams.append(Vector2(edge + side * 205.0, y + seam))
		draw_multiline(seams, Color("91ad97"), 2.0)
		draw_polyline(border, Color("345e56"), 6.0)
		for row in range(first, last):
			var y := row * 240.0
			var edge: float = track.center_at(y) + side * track.width_at(y) * 0.5
			var spot := Vector2(edge + side * 120.0, y)
			if posmod(row, 5) == 2:
				draw_festival_banner(spot, side)
			if posmod(row, 3) == 0:
				draw_garden(spot, side, row)
			elif track.high_quality and posmod(row, 3) == 1:
				# Inlaid brass markers echo the warm rim and Sol's palette.
				draw_circle(spot, 12.0, Color("446e65"))
				draw_arc(spot, 8.0, 0.0, TAU, 12, Color("e2ce91"), 2.0, true)
			# Elevated outer canopy shifts a few pixels relative to the ground.
			# Bounded parallax never pushes decoration into the racing channel.
			if posmod(row, 6) == 0:
				var camera_y := (inverse * (get_viewport_rect().size * 0.5)).y
				var drift := clampf((y - camera_y) * 0.045, -24.0, 24.0)
				var crown := Vector2(edge + side * 280.0, y + drift)
				draw_circle(crown + Vector2(15, 24), 76.0, Color("123e3d"))
				draw_circle(crown, 72.0, Color("256254"))
				draw_circle(crown + Vector2(-22, -20), 46.0, Color("34765a"))

func draw_festival_banner(spot: Vector2, side: float) -> void:
	# Dominican colours on promenade pennants, always outside the racing surface.
	var base := spot + Vector2(side * 25, 0)
	draw_line(base + Vector2(4, 6), base + Vector2(4, 77), Color(0.03, 0.18, 0.22, 0.25), 6)
	draw_line(base, base + Vector2(0, 72), Color("e8d4a0"), 4)
	var flag := Rect2(base, Vector2(46, 28))
	draw_rect(flag, Color("f5f4dd"))
	draw_rect(Rect2(base, Vector2(20, 11)), Color("225eaa"))
	draw_rect(Rect2(base + Vector2(26, 0), Vector2(20, 11)), Color("ed6358"))
	draw_rect(Rect2(base + Vector2(0, 17), Vector2(20, 11)), Color("ed6358"))
	draw_rect(Rect2(base + Vector2(26, 17), Vector2(20, 11)), Color("225eaa"))

func draw_garden(spot: Vector2, side: float, row: int) -> void:
	draw_style_box(planter_shadow, Rect2(spot + Vector2(-43, -40), Vector2(102, 122)))
	draw_style_box(planter_rim, Rect2(spot + Vector2(-51, -60), Vector2(102, 122)))
	draw_style_box(planter_soil, Rect2(spot + Vector2(-42, -51), Vector2(84, 104)))
	var sway := sin(clock * 1.2 + row * 1.7) * 3.0
	for leaf in range(3 if track.high_quality else 2):
		var center := spot + Vector2(sway + (leaf - 1) * 21.0, -leaf * 19.0 + 15.0)
		draw_circle(center + Vector2(4, 8), 28.0, Color("245b4d"))
		draw_circle(center, 25.0, Color("4e9565"))
		draw_circle(center + Vector2(-7, -8), 15.0, Color("83b875"))
	if track.high_quality:
		for flower in range(3):
			var point := spot + Vector2(side * 24.0 + sway, flower * 20.0 - 28.0)
			draw_circle(point, 6.0, Color("ffcc85"))
			draw_circle(point, 2.0, Color("fff2c6"))

var planter_shadow := make_style(Color("204c48"), 14)
var planter_rim := make_style(Color("e2d2a3"), 12)
var planter_soil := make_style(Color("365e4d"), 8)

static func make_style(color: Color, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(radius)
	return style
