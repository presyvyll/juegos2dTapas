extends Button

var motion: Tween
var illustrated := false
var idle_pulse := false
var pulse_clock := 0.0

func _ready() -> void:
	resized.connect(func() -> void: pivot_offset = size / 2)
	button_down.connect(func() -> void: animate_scale(0.96, 0.10))
	button_up.connect(func() -> void: animate_scale(1.0, 0.25))
	focus_exited.connect(func() -> void: animate_scale(1.0, 0.20))
	set_process(idle_pulse)

func set_illustrated(enabled: bool) -> void:
	illustrated = enabled
	queue_redraw()

func set_idle_pulse(enabled: bool) -> void:
	idle_pulse = enabled
	pulse_clock = 0.0
	set_process(enabled)
	if not enabled:
		self_modulate = Color.WHITE

func _process(delta: float) -> void:
	if idle_pulse and is_visible_in_tree() and not button_pressed:
		pulse_clock += delta
		var glow := (sin(pulse_clock * 2.4) + 1.0) * 0.025
		self_modulate = Color(1.0, 0.95 + glow, 0.88 + glow * 2.0, 1.0)
	else:
		self_modulate = Color.WHITE

func _draw() -> void:
	if not illustrated:
		return
	for point in [Vector2(13, 13), Vector2(size.x - 13, 13), Vector2(13, size.y - 13), size - Vector2(13, 13)]:
		draw_circle(point, 3.4, Color(0.35, 0.14, 0.025, 0.8))
		draw_circle(point - Vector2(0.7, 0.7), 1.3, Color(1.0, 0.83, 0.35, 0.85))
	draw_line(Vector2(size.x * 0.16, 7), Vector2(size.x * 0.34, 7), Color(1.0, 0.9, 0.48, 0.45), 2.0, true)
	draw_line(Vector2(size.x * 0.68, size.y - 7), Vector2(size.x * 0.83, size.y - 7), Color(0.36, 0.14, 0.025, 0.4), 2.0, true)

func animate_scale(value: float, duration: float) -> void:
	if motion: motion.kill()
	pivot_offset = size / 2
	motion = create_tween()
	motion.set_trans(Tween.TRANS_BACK if value == 1.0 else Tween.TRANS_QUAD)
	motion.set_ease(Tween.EASE_OUT)
	motion.tween_property(self, "scale", Vector2.ONE * value, duration)
