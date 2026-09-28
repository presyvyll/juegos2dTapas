class_name CapArt
extends RefCounted
## Shared original artwork for race, portrait and podium. No gameplay decisions here.

const INK := Color("12283c")
const PAPER := Color("fff8dc")

static func draw_cap(canvas: CanvasItem, appearance: CapAppearance, tint: Color, mood: int = 0) -> void:
	if appearance.body_texture:
		canvas.draw_texture_rect(appearance.body_texture, Rect2(-32, -32, 64, 64), false)
		return
	var rim := PackedVector2Array()
	for point in range(48):
		var radius := 29.0 if point % 3 != 1 else 26.5
		rim.append(Vector2.from_angle(TAU * point / 48) * radius)
	canvas.draw_colored_polygon(rim, INK)
	canvas.draw_circle(Vector2.ZERO, 25.5, tint.darkened(0.3))
	canvas.draw_circle(Vector2(0, -2), 23, tint)
	canvas.draw_circle(Vector2(0, -3), 19.5, tint.darkened(0.08))
	canvas.draw_circle(Vector2(0, -4), 17.5, tint.lightened(0.12))
	canvas.draw_arc(Vector2(0, -2), 22, 3.35, 5.85, 28, tint.lightened(0.72), 2.5, true)
	canvas.draw_arc(Vector2(0, -2), 25, 3.45, 5.72, 28, appearance.accent.lightened(0.18), 1.4, true)
	# Keep the caller's portrait/race transform for every part of the cap.
	var highlight := PackedVector2Array()
	for point in range(32):
		var offset := Vector2.from_angle(TAU * point / 32) * 8.5 * Vector2(1.35, 0.38)
		highlight.append(Vector2(-9, -15) + offset.rotated(-0.55))
	canvas.draw_colored_polygon(highlight, Color(1.0, 0.98, 0.83, 0.58))
	var accent := appearance.accent
	draw_material_finish(canvas, appearance, tint)
	match appearance.style:
		CapAppearance.Style.BALANCED:
			for ray in range(7):
				var angle := PI + ray * PI / 6
				canvas.draw_line(Vector2.from_angle(angle) * 16, Vector2.from_angle(angle) * 22, accent, 3, true)
		CapAppearance.Style.BOLD:
			canvas.draw_line(Vector2(-21, -12), Vector2(22, -12), INK, 9, true)
			canvas.draw_line(Vector2(-21, -13), Vector2(22, -13), accent, 5, true)
			canvas.draw_colored_polygon(PackedVector2Array([Vector2(20, -15), Vector2(36, -22), Vector2(30, -9), Vector2(36, -5), Vector2(20, -8)]), accent)
		CapAppearance.Style.SWIFT:
			canvas.draw_colored_polygon(PackedVector2Array([Vector2(-2, -26), Vector2(10, -26), Vector2(2, -15), Vector2(10, -15), Vector2(-7, -2), Vector2(-2, -13), Vector2(-9, -13)]), accent)
		CapAppearance.Style.TECH:
			canvas.draw_rect(Rect2(-21, -10, 42, 17), INK)
			canvas.draw_rect(Rect2(-17, -7, 34, 9), accent)
			canvas.draw_line(Vector2(10, -23), Vector2(16, -34), INK, 3, true)
			canvas.draw_circle(Vector2(16, -34), 4, accent)
		CapAppearance.Style.ELEGANT:
			canvas.draw_colored_polygon(PackedVector2Array([Vector2(-16, -18), Vector2(-19, -32), Vector2(-6, -25), Vector2(0, -35), Vector2(6, -25), Vector2(19, -32), Vector2(16, -18)]), INK)
			canvas.draw_colored_polygon(PackedVector2Array([Vector2(-13, -21), Vector2(-15, -27), Vector2(-5, -23), Vector2(0, -30), Vector2(5, -23), Vector2(15, -27), Vector2(13, -21)]), accent)
		CapAppearance.Style.WILD:
			canvas.draw_circle(Vector2(-15, -13), 5, accent)
			canvas.draw_circle(Vector2(17, 9), 5, accent)
			canvas.draw_line(Vector2(-3, -22), Vector2(-9, -31), INK, 5, true)
			canvas.draw_line(Vector2(3, -22), Vector2(10, -32), INK, 5, true)
	if mood == 1:
		for side in [-1, 1]:
			var x: float = side * 9
			canvas.draw_line(Vector2(x - 4, -7), Vector2(x + 4, 1), INK, 3, true)
			canvas.draw_line(Vector2(x - 4, 1), Vector2(x + 4, -7), INK, 3, true)
	elif appearance.style != CapAppearance.Style.TECH:
		for side in [-1, 1]:
			var eye := Vector2(side * 9, -3)
			canvas.draw_circle(eye, 7, INK)
			canvas.draw_circle(eye + Vector2(0, -1), 5, PAPER)
			canvas.draw_circle(eye + Vector2(1, -1 if mood != 2 else -3), 2.8, INK)
		if appearance.style == CapAppearance.Style.BOLD or mood == 2:
			canvas.draw_line(Vector2(-15, -12), Vector2(-4, -8), INK, 3, true)
			canvas.draw_line(Vector2(4, -8), Vector2(15, -12), INK, 3, true)
	if mood == 1:
		canvas.draw_circle(Vector2(0, 11), 5, INK)
	else:
		canvas.draw_arc(Vector2(0, 6), 9, 0.15, PI - 0.15, 12, INK, 4, true)
		canvas.draw_line(Vector2(-5, 10), Vector2(5, 10), PAPER, 2, true)

static func draw_material_finish(canvas: CanvasItem, appearance: CapAppearance, tint: Color) -> void:
	match appearance.style:
		CapAppearance.Style.BALANCED:
			canvas.draw_arc(Vector2.ZERO, 18.5, 3.7, 5.65, 18, tint.lightened(0.5), 1.4, true)
		CapAppearance.Style.BOLD:
			canvas.draw_line(Vector2(-17, 15), Vector2(17, 15), tint.lightened(0.35), 2.0, true)
		CapAppearance.Style.SWIFT:
			canvas.draw_arc(Vector2(-2, -1), 16.0, 3.85, 5.35, 16, Color(1.0, 0.98, 0.88, 0.72), 2.0, true)
		CapAppearance.Style.TECH:
			for point in [Vector2(-19, -2), Vector2(19, -2), Vector2(-14, 16), Vector2(14, 16)]:
				canvas.draw_circle(point, 1.8, appearance.accent.lightened(0.25))
		CapAppearance.Style.ELEGANT:
			canvas.draw_arc(Vector2.ZERO, 24.0, 3.55, 5.8, 24, Color(0.94, 0.98, 1.0, 0.8), 1.8, true)
			canvas.draw_arc(Vector2.ZERO, 21.0, 3.72, 5.62, 20, Color(0.8, 0.92, 1.0, 0.45), 1.0, true)
		CapAppearance.Style.WILD:
			var glow := appearance.accent
			glow.a = 0.52
			canvas.draw_arc(Vector2.ZERO, 26.5, 3.45, 5.95, 24, glow, 2.0, true)
