extends Control

var clock := 0.0
var redraw_elapsed := 0.0

func _process(delta: float) -> void:
	clock += delta
	redraw_elapsed += delta
	if redraw_elapsed >= (1.0 / 20.0 if SaveManager.settings.quality == "low" else 1.0 / 30.0):
		redraw_elapsed = 0.0
		queue_redraw()

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("0b777e"))
	for index in range(14):
		var origin := Vector2(size.x * 0.12 + sin(index * 1.7 + clock * 0.12) * 140, index * 80.0 + sin(clock * 0.3 + index) * 12)
		draw_arc(origin, 150, 0.2, 2.8, 32, Color(0.3, 0.95, 0.9, 0.12), 12, true)
	for index in range(9):
		var x := size.x * 0.55 + index * 70
		draw_line(Vector2(x, 0), Vector2(x - 300, size.y), Color(0.6, 1, 0.85, 0.1), 18, true)
	draw_circle(Vector2(size.x + 50, -30), 300, Color("12535a"))
	draw_circle(Vector2(size.x - 60, size.y + 60), 180, Color("37896f"))
