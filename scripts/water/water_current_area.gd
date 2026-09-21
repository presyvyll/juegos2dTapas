class_name WaterCurrentArea
extends Area2D
## Additive acceleration; overlapping currents are averaged by the cap.

@export var direction: Vector2 = Vector2.UP
@export var strength: float = 110.0
@export var turbulence: float = 12.0
@export_range(0.3, 2.0) var max_speed_modifier: float = 1.0
@export var size: Vector2 = Vector2(400, 260)
var elapsed: float = 0.0

func _ready() -> void:
	collision_layer = 0
	collision_mask = 1
	monitorable = false
	var shape := RectangleShape2D.new()
	shape.size = size
	var collider := CollisionShape2D.new()
	collider.shape = shape
	add_child(collider)
	body_entered.connect(_enter)
	body_exited.connect(_exit)
	queue_redraw()

func _physics_process(delta: float) -> void:
	elapsed += delta

func force_at(point: Vector2) -> Vector2:
	return direction.normalized() * strength + Vector2(sin(elapsed * 2.0 + point.y * 0.02), 0) * turbulence

func _enter(body: Node2D) -> void:
	if body is RacingCap:
		body.currents.append(self)
		body.trigger_ability("current_enter")

func _exit(body: Node2D) -> void:
	if body is RacingCap:
		body.currents.erase(self)

func visual_color() -> Color:
	if max_speed_modifier >= 1.15:
		return Color("69e7d4")
	if max_speed_modifier <= 0.95:
		return Color("ff9b78")
	return Color("b9fff3")

func _draw() -> void:
	var cue := visual_color()
	var fill := cue
	fill.a = 0.10
	draw_rect(Rect2(-size / 2, size), fill)
	var boundary := cue
	boundary.a = 0.58
	var entry_y := size.y * 0.5 + 18.0
	var dash_count := clampi(int(size.x / 70.0), 3, 8)
	var dash_width := size.x / float(dash_count)
	for index in range(dash_count):
		if index % 2 == 0:
			draw_line(Vector2(-size.x * 0.5 + index * dash_width, entry_y), Vector2(-size.x * 0.5 + (index + 1) * dash_width, entry_y), boundary, 4.0, true)
	var cue_count := 3 if size.x >= 220.0 else 1
	for index in range(cue_count):
		var x := (index - (cue_count - 1) * 0.5) * minf(90.0, size.x * 0.28)
		for row in range(2 if max_speed_modifier >= 1.15 else 1):
			var y := entry_y + 20.0 + row * 16.0
			draw_polyline(PackedVector2Array([Vector2(x - 11.0, y + 6.0), Vector2(x, y - 3.0), Vector2(x + 11.0, y + 6.0)]), boundary, 3.5, true)
	for offset in [-70, 0, 70]:
		var start := Vector2(offset, 25)
		var end := start + direction.normalized() * 55
		draw_line(start, end, boundary, 3, true)
		draw_circle(end, 4, boundary)
