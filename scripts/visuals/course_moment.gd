extends Node2D
## One brief, course-specific set piece, drawn only while it is near the camera.
var track: RaceTrack
var moment_distance := 0.0
var color := Color.WHITE
var title := ""
var clock := 0.0
var refresh := 0.0

func _ready() -> void:
	var sections := track.definition.section_distances
	moment_distance = sections[1] if sections.size() > 1 else track.definition.length * 0.62
	moment_distance = clampf(moment_distance, track.definition.length * 0.3, track.definition.length * 0.75)
	match track.definition.theme_id:
		"cascada":
			title = "CORTINA DE AGUA"
			color = Color("a5f7ff")
		"remolino", "ojo":
			title = "EL OJO DEL CANAL"
			color = Color("74efff")
		"neon", "eclipse":
			title = "ARCO DE LUZ"
			color = Color("ef8cff")
		"tormenta":
			title = "RELAMPAGO"
			color = Color("e2f4ff")
		"jardin", "tropical":
			title = "JARDIN FLOTANTE"
			color = Color("ffce9f")
		"templo", "laberinto", "titan":
			title = "PORTAL ANTIGUO"
			color = Color("f6d68f")
		"plaza", "fuente":
			title = "FUENTE CENTRAL"
			color = Color("affff1")
		"canal_turbo", "express":
			title = "SALTO DE CORRIENTE"
			color = Color("fff0ae")
		_:
			title = "RAPIDOS DEL CANAL"
			color = Color("a5f7ff")
	position = Vector2(track.center_at(-moment_distance), -moment_distance)

func _process(delta: float) -> void:
	clock += delta
	refresh -= delta
	if refresh > 0.0:
		return
	refresh = 0.1 if track.high_quality else 0.2
	var inverse := get_viewport().get_canvas_transform().affine_inverse()
	var camera_y := (inverse * (get_viewport_rect().size * 0.5)).y
	if absf(camera_y - global_position.y) > 1300.0:
		visible = false
		return
	visible = true
	queue_redraw()

func _draw() -> void:
	var pulse := 0.78 + 0.22 * sin(clock * 2.6)
	var half := track.width_at(position.y) * 0.5
	match track.definition.theme_id:
		"cascada":
			for side in [-1.0, 1.0]:
				var x: float = side * (half + 60.0)
				draw_arc(Vector2(x, 0), 100, 0.2, 2.8, 20, Color(color, 0.7 * pulse), 12, true)
				for drop in range(4 if track.high_quality else 2):
					var dy := fposmod(clock * 240.0 + drop * 90.0, 300.0) - 150.0
					draw_line(Vector2(x, dy), Vector2(x - side * 25.0, dy + 70.0), Color(color, 0.44), 4, true)
		"remolino", "ojo":
			for ring in range(3):
				draw_arc(Vector2.ZERO, 100.0 + ring * 46.0, clock * 0.4 + ring, clock * 0.4 + ring + TAU * 0.82, 28, Color(color, 0.43 - ring * 0.08), 5, true)
		"neon", "eclipse":
			for side in [-1.0, 1.0]:
				var x: float = side * (half + 72.0)
				draw_line(Vector2(x, -245), Vector2(x, 245), Color(color, 0.18), 30, true)
				draw_line(Vector2(x, -245), Vector2(x, 245), Color(color, pulse), 5, true)
		"tormenta":
			var flash := maxf(0.0, sin(clock * 1.7))
			if flash > 0.72:
				var bolt := PackedVector2Array([Vector2(-half - 60, -220), Vector2(-half * 0.35, -80), Vector2(-half * 0.48, -35), Vector2(half * 0.1, 110)])
				draw_polyline(bolt, Color(color, (flash - 0.72) * 1.5), 8, true)
		"jardin", "tropical":
			for side in [-1.0, 1.0]:
				var x: float = side * (half + 110.0)
				for leaf in range(5):
					var angle := leaf * TAU / 5.0 + clock * 0.25
					draw_colored_polygon(PackedVector2Array([Vector2(x, 0), Vector2(x + cos(angle) * 72, sin(angle) * 54), Vector2(x + cos(angle + 0.6) * 52, sin(angle + 0.6) * 42)]), Color(color, 0.62))
		"templo", "laberinto", "titan":
			for side in [-1.0, 1.0]:
				var x: float = side * (half + 125.0)
				draw_rect(Rect2(Vector2(x - 30, -170), Vector2(60, 340)), Color("1a494b"))
				draw_line(Vector2(x - 20, -145), Vector2(x + 20, -145), Color(color, pulse), 6)
				draw_line(Vector2(x - 20, 145), Vector2(x + 20, 145), Color(color, pulse), 6)
		"plaza", "fuente":
			for side in [-1.0, 1.0]:
				var x: float = side * (half + 65.0)
				for jet in range(3):
					var h := 85.0 + 35.0 * sin(clock * 3.0 + jet)
					draw_line(Vector2(x + jet * 18.0, 40), Vector2(x + jet * 18.0, 40 - h), Color(color, 0.65), 6, true)
		_:
			for side in [-1.0, 1.0]:
				var x: float = side * (half + 60.0)
				draw_arc(Vector2(x, 0), 84, 0, TAU, 24, Color(color, 0.65 * pulse), 8, true)
	# Course name is placed well above the hazard line, never over the play lane.
	draw_string(ThemeDB.fallback_font, Vector2(-100, -205), title, HORIZONTAL_ALIGNMENT_CENTER, 200, 15, Color(color, 0.84 * pulse))
