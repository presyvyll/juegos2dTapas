extends Button

var motion: Tween

func _ready() -> void:
	resized.connect(func() -> void: pivot_offset = size / 2)
	button_down.connect(func() -> void: animate_scale(0.96, 0.10))
	button_up.connect(func() -> void: animate_scale(1.0, 0.25))
	focus_exited.connect(func() -> void: animate_scale(1.0, 0.20))

func animate_scale(value: float, duration: float) -> void:
	if motion: motion.kill()
	pivot_offset = size / 2
	motion = create_tween()
	motion.set_trans(Tween.TRANS_BACK if value == 1.0 else Tween.TRANS_QUAD)
	motion.set_ease(Tween.EASE_OUT)
	motion.tween_property(self, "scale", Vector2.ONE * value, duration)
