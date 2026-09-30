class_name RacePowerHUD
extends Control
## A single thumb target; selection happens exclusively in the world.
var power: RacePower
var activate_button: Button
var clock := 0.0

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	activate_button = RacingUI.button("", func() -> void: power.use_prepared())
	activate_button.custom_minimum_size = Vector2(72, 68)
	activate_button.focus_mode = Control.FOCUS_NONE
	activate_button.action_mode = BaseButton.ACTION_MODE_BUTTON_PRESS
	activate_button.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	add_child(activate_button)
	var style := RacingUI.box(Color(0.04, 0.16, 0.20, 0.78), 32)
	style.set_content_margin_all(6)
	for state in ["normal", "hover", "pressed", "disabled"]: activate_button.add_theme_stylebox_override(state, style)
	activate_button.draw.connect(draw_power)
	get_viewport().size_changed.connect(update_margins)
	update_margins()
	refresh()

func update_margins() -> void:
	var safe := RacingUI.safe_insets(get_viewport())
	activate_button.offset_right = -safe.z - 100
	activate_button.offset_left = -safe.z - 172
	activate_button.offset_top = -safe.w - 68
	activate_button.offset_bottom = -safe.w

func hit(point: Vector2) -> bool:
	return visible and activate_button.visible and activate_button.get_global_rect().has_point(point)

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch and event.pressed and hit(event.position):
		power.use_prepared()
		refresh()
		get_viewport().set_input_as_handled()

func _process(delta: float) -> void:
	clock += delta
	refresh()

func refresh() -> void:
	visible = power.cap.active and not power.cap.finished
	activate_button.visible = not power.prepared.is_empty()
	activate_button.disabled = power.remaining > 0 or power.cooldown > 0
	if activate_button.visible:
		activate_button.tooltip_text = str(RacePower.POWERS[power.prepared][0])
		activate_button.queue_redraw()

func draw_power() -> void:
	if not power.prepared.is_empty():
		PowerGlyph.paint(activate_button, power.prepared, activate_button.size / 2, 0.7, clock)
