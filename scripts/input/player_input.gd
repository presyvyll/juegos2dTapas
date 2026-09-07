class_name CapPlayerInput
extends Node
## Input source is independent from movement; AI will provide the same axis.

var touches: Dictionary = {}
var swipe_origins: Dictionary = {}
var pending_swipe: float = 0.0
var boost_requested := false
var excluded_rects: Array[Rect2] = []
var boost_touch_rect := Rect2()
var boost_touch_enabled := false

func _ready() -> void:
	get_window().focus_exited.connect(clear)

func clear() -> void:
	touches.clear()
	swipe_origins.clear()
	pending_swipe = 0.0
	boost_requested = false

func _input(event: InputEvent) -> void:
	# Raw touch works for a second finger even when mouse emulation tracks the first.
	if event is InputEventScreenTouch and event.pressed and boost_touch_enabled and boost_touch_rect.has_point(event.position):
		boost_requested = true
	# Releases must be handled even when the finger ends over a UI button.
	if event is InputEventScreenTouch and not event.pressed:
		touches.erase(event.index)
		swipe_origins.erase(event.index)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_SPACE:
		boost_requested = true
	if event is InputEventScreenTouch:
		if event.pressed:
			for rect in excluded_rects:
				if rect.has_point(event.position):
					return
			touches[event.index] = event.position.x
			swipe_origins[event.index] = Vector3(event.position.x, event.position.y, Time.get_ticks_msec())
		else:
			touches.erase(event.index)
			swipe_origins.erase(event.index)
	if event is InputEventScreenDrag and touches.has(event.index):
		touches[event.index] = event.position.x
		var origin: Vector3 = swipe_origins[event.index]
		var distance: float = event.position.x - origin.x
		if absf(distance) > 65.0 and Time.get_ticks_msec() - origin.z < 300.0:
			pending_swipe = signf(distance)
			swipe_origins[event.index] = Vector3(event.position.x, event.position.y, -1000)

func consume_boost() -> bool:
	var result := boost_requested
	boost_requested = false
	return result

func consume_swipe() -> float:
	var result := pending_swipe
	pending_swipe = 0.0
	return result

func steering_axis() -> float:
	var left := Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT)
	var right := Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT)
	var axis := float(right) - float(left)
	for x in touches.values():
		axis += -1.0 if float(x) < get_viewport().get_visible_rect().size.x / 2 else 1.0
	return clampf(axis, -1.0, 1.0)
