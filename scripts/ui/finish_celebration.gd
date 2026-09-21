class_name FinishCelebration
extends Control
## Short procedural finish burst. One CanvasItem draws every ray and confetti piece.

var elapsed := 0.0
var duration := 0.85
var accent := Color("ffdc6c")
var intensity := 1.0
var piece_count := 20
var redraw_time := 0.0


func configure(place: int) -> void:
	accent = Color("ffdc6c") if place == 1 else Color("78f4e5")
	intensity = 1.0 if place == 1 else 0.68
	piece_count = (20 if place == 1 else 12) if SaveManager.settings.quality == "high" else (12 if place == 1 else 8)


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	queue_redraw()


func _process(delta: float) -> void:
	elapsed += delta
	if elapsed >= duration:
		queue_free()
		return
	redraw_time -= delta
	if redraw_time <= 0.0:
		redraw_time = 1.0 / (30.0 if SaveManager.settings.quality == "low" else 60.0)
		queue_redraw()


func _draw() -> void:
	var progress := clampf(elapsed / duration, 0.0, 1.0)
	var fade := minf(progress / 0.10, 1.0) * (1.0 - smoothstep(0.55, 1.0, progress)) * intensity
	var center := size * Vector2(0.5, 0.53)
	var wash := accent
	wash.a = 0.075 * fade
	draw_rect(Rect2(Vector2.ZERO, size), wash)
	var radius := lerpf(38.0, minf(size.x, size.y) * 0.34, ease(progress, -1.4))
	var ring := accent
	ring.a = 0.72 * fade
	draw_arc(center, radius, 0.0, TAU, 48, ring, 4.0, true)
	for index in range(piece_count):
		var angle := TAU * float(index) / float(piece_count) + 0.13
		var direction := Vector2.from_angle(angle)
		var phase := fposmod(progress * 1.35 + float(index) * 0.071, 1.0)
		var position := center + direction * lerpf(54.0, minf(size.x, size.y) * 0.48, phase)
		var color := accent.lightened(0.22 if index % 2 == 0 else 0.02)
		color.a = fade * (1.0 - phase * 0.55)
		draw_line(position, position + direction * (18.0 + 16.0 * intensity), color, 4.0, true)
		var fall := Vector2(fposmod(float(index * 83), size.x), fposmod(progress * size.y * 1.35 + float(index * 59), size.y + 80.0) - 40.0)
		draw_set_transform(fall, angle + progress * 5.0, Vector2.ONE)
		draw_rect(Rect2(Vector2(-4.0, -2.0), Vector2(8.0, 4.0)), color)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
