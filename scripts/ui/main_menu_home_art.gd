extends Control

const DARK_WOOD := Color("32170e")
const MID_WOOD := Color("6f3616")
const LIGHT_WOOD := Color("a85b21")
const GOLD := Color("ffbd24")
const GOLD_LIGHT := Color("ffe25c")
const WATER := Color("28bfff")
const LOGO := preload("res://assets/ui/tapa_racing_logo.png")

var clock := 0.0
var redraw_elapsed := 0.0
var section_mode := false

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)

func restart() -> void:
	clock = 0.0
	redraw_elapsed = 0.0
	queue_redraw()

func set_section_mode(enabled: bool) -> void:
	section_mode = enabled
	restart()

func _process(delta: float) -> void:
	if not is_visible_in_tree():
		return
	clock += delta
	redraw_elapsed += delta
	var refresh := 1.0 / (20.0 if SaveManager.settings.quality == "low" else 30.0)
	if redraw_elapsed >= refresh:
		redraw_elapsed = 0.0
		queue_redraw()

func _draw() -> void:
	_draw_water_motion()
	_draw_profile_plank()
	_draw_corner_leaves()
	_draw_ambient_particles()
	if section_mode:
		_draw_section_title_plank()
	else:
		_draw_sun_glow()
		_draw_logo()
		_draw_bottom_wood()

func _draw_section_title_plank() -> void:
	var board := Rect2(22, 22, clampf(size.x * 0.30, 300.0, 470.0), 64)
	draw_style_box(_wood_box(), board)
	for index in range(4):
		var x := board.position.x + 40.0 + index * (board.size.x - 70.0) / 3.0
		draw_line(Vector2(x, board.position.y + 9), Vector2(x + 10, board.end.y - 9), Color(0.2, 0.07, 0.02, 0.25), 2.0, true)

func _draw_sun_glow() -> void:
	var center := Vector2(size.x * 0.5, size.y * 0.34)
	for ray in range(20):
		var angle := TAU * ray / 20.0 + clock * 0.025
		var length := 92.0 + sin(clock * 0.7 + ray) * 12.0
		draw_line(center + Vector2.from_angle(angle) * 55, center + Vector2.from_angle(angle) * length, Color(1.0, 0.88, 0.36, 0.11), 8.0, true)

func _draw_water_motion() -> void:
	var water_top := size.y * 0.50
	for band in range(10):
		var y := water_top + band * (size.y - water_top) / 10.0
		var points := PackedVector2Array()
		for sample in range(18):
			var x := sample * size.x / 17.0
			var wave := sin(sample * 0.9 + band * 1.4 + clock * (0.55 + band * 0.02)) * (2.5 + band * 0.18)
			points.append(Vector2(x, y + wave))
		draw_polyline(points, Color(0.75, 0.98, 1.0, 0.075 + band * 0.004), 2.2, true)

func _draw_profile_plank() -> void:
	var width := clampf(size.x * 0.29, 320.0, 470.0)
	var board := Rect2(size.x - width - 26.0, 22.0, width, 64.0)
	draw_style_box(_wood_box(), board)
	for index in range(4):
		var x := board.position.x + 45.0 + index * (board.size.x - 80.0) / 3.0
		draw_line(Vector2(x, board.position.y + 9), Vector2(x + 11, board.end.y - 9), Color(0.2, 0.07, 0.02, 0.25), 2.0, true)
	for point in [board.position + Vector2(15, 15), Vector2(board.end.x - 15, board.position.y + 15), Vector2(board.position.x + 15, board.end.y - 15), board.end - Vector2(15, 15)]:
		draw_circle(point, 3.5, Color("e7aa4b"))
		draw_circle(point, 1.8, Color("51250e"))

func _draw_logo() -> void:
	var width := clampf(size.x * 0.245, 295.0, 450.0)
	var ratio := float(LOGO.get_height()) / maxf(1.0, LOGO.get_width())
	var logo_size := Vector2(width, width * ratio)
	var progress := clampf(clock / 0.34, 0.0, 1.0)
	var eased := 1.0 - pow(1.0 - progress, 3.0)
	var scale_value := 0.88 + eased * 0.12
	var bob := sin(clock * 1.15) * 2.0
	var rect := Rect2(Vector2(12, 10 + bob), logo_size)
	var center := rect.get_center()
	draw_set_transform(center, -0.025, Vector2.ONE * scale_value)
	draw_texture_rect(LOGO, Rect2(-rect.size / 2.0, rect.size), false)
	draw_set_transform(Vector2.ZERO)

func _draw_corner_leaves() -> void:
	var clusters: Array[Vector2] = [Vector2(18, 15), Vector2(size.x - 20, size.y - 18)]
	for cluster in clusters:
		for index in range(5):
			var sway := sin(clock * 0.65 + index) * 0.035
			var direction := Vector2.from_angle(-2.4 + index * 0.34 + sway)
			if cluster.x > size.x * 0.5:
				direction = -direction
			var center := cluster + direction * (18.0 + index * 4.0)
			var leaf := PackedVector2Array([center + direction * 25, center + direction.orthogonal() * 9, center - direction * 9, center - direction.orthogonal() * 9])
			draw_colored_polygon(leaf, Color("2f9c35") if index % 2 == 0 else Color("65c83d"))

func _draw_ambient_particles() -> void:
	for index in range(14):
		var phase := fmod(clock * (7.0 + index % 4) + index * 71.0, size.y + 80.0)
		var point := Vector2(fmod(index * 157.0 + sin(clock * 0.23 + index) * 32.0, maxf(size.x, 1.0)), size.y + 30.0 - phase)
		var color := Color(0.84, 1.0, 0.92, 0.16 + (index % 3) * 0.05)
		draw_circle(point, 1.5 + index % 3, color)

func _draw_bottom_wood() -> void:
	var strip := Rect2(-10, size.y - 98, size.x + 20, 108)
	draw_rect(strip, Color(0.12, 0.045, 0.015, 0.84))
	draw_line(Vector2(0, strip.position.y), Vector2(size.x, strip.position.y), Color("7f421c"), 7.0, true)
	for index in range(12):
		var x := index * size.x / 11.0
		draw_line(Vector2(x, strip.position.y + 12), Vector2(x + 28, size.y), Color(0.32, 0.13, 0.035, 0.32), 2.0, true)

func _wood_box() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = MID_WOOD
	style.border_color = DARK_WOOD
	style.set_border_width_all(5)
	style.set_corner_radius_all(10)
	style.shadow_color = Color(0.08, 0.02, 0.0, 0.55)
	style.shadow_offset = Vector2(0, 7)
	style.shadow_size = 5
	return style
