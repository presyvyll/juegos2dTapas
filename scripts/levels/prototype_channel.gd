extends Node2D
## Phase 2 test channel. Geometry is built once, with static collisions.

const CHANNEL_LENGTH: float = 18000.0
const HALF_WIDTH: float = 300.0
const WALL_WIDTH: float = 48.0
@onready var player: RacingCap = $PlayerCap
@onready var status: Label = $Interface/Panel/Margin/Content/Status
var complete := false

func _ready() -> void:
	create_wall(Vector2(-HALF_WIDTH - WALL_WIDTH / 2, -CHANNEL_LENGTH / 2), Vector2(WALL_WIDTH, CHANNEL_LENGTH + 600))
	create_wall(Vector2(HALF_WIDTH + WALL_WIDTH / 2, -CHANNEL_LENGTH / 2), Vector2(WALL_WIDTH, CHANNEL_LENGTH + 600))
	queue_redraw()

func create_wall(center: Vector2, size: Vector2) -> void:
	var body := StaticBody2D.new()
	body.position = center
	var collider := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = size
	collider.shape = shape
	body.add_child(collider)
	add_child(body)

func _process(_delta: float) -> void:
	if not complete and player.position.y <= -CHANNEL_LENGTH:
		complete = true
		player.set_physics_process(false)
		player.velocity = Vector2.ZERO
	if complete:
		status.text = "Canal completado · Reinicia para volver a probar"
	else:
		status.text = "Velocidad: %d  ·  Canal: %d%%" % [player.velocity.length(), clampf(-player.position.y / CHANNEL_LENGTH * 100.0, 0, 100)]
	if Input.is_physical_key_pressed(KEY_R):
		restart()

func restart() -> void:
	get_tree().reload_current_scene()

func _draw() -> void:
	draw_rect(Rect2(-HALF_WIDTH, -CHANNEL_LENGTH - 500, HALF_WIDTH * 2, CHANNEL_LENGTH + 1000), Color("16b8bd"))
	for side in [-1, 1]:
		var x: float = side * (HALF_WIDTH + WALL_WIDTH / 2)
		draw_rect(Rect2(x - WALL_WIDTH / 2, -CHANNEL_LENGTH - 300, WALL_WIDTH, CHANNEL_LENGTH + 600), Color("ded7ab"))
	for index in range(150):
		var y := -float(index) * 120.0
		for lane in [-1, 0, 1]:
			var x := float(lane) * 170.0
			draw_line(Vector2(x - 10, y + 10), Vector2(x, y), Color(0.6, 1, 1, 0.35), 2.0)
			draw_line(Vector2(x, y), Vector2(x + 10, y + 10), Color(0.6, 1, 1, 0.35), 2.0)
	draw_line(Vector2(-HALF_WIDTH, -CHANNEL_LENGTH), Vector2(HALF_WIDTH, -CHANNEL_LENGTH), Color.WHITE, 12.0)
