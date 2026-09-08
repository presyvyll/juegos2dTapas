extends SceneTree

var failures := 0

func check(value: bool, message: String) -> void:
	print(("PASS: " if value else "FAIL: ") + message)
	if not value:
		failures += 1

func _initialize() -> void:
	call_deferred("run")

func touch(point: Vector2, index: int = 1) -> InputEventScreenTouch:
	var event := InputEventScreenTouch.new()
	event.position = point
	event.index = index
	event.pressed = true
	return event

func run() -> void:
	var race: Node2D = load("res://levels/race.tscn").instantiate()
	root.add_child(race)
	for frame in range(8):
		await process_frame
	race.player.set_physics_process(false)
	var controls: CapPlayerInput = race.player.controls
	var boost: InputEventScreenTouch = touch(race.hud.boost_button.get_global_rect().get_center())
	controls._input(boost)
	check(not controls.consume_boost(), "turbo blocked during countdown")
	race.player.active = true
	race.player.boost_energy = 0.1
	controls._input(boost)
	check(not controls.consume_boost(), "turbo checks current energy")
	race.player.boost_energy = 1
	controls._input(boost)
	check(controls.consume_boost(), "new energy responds before next HUD refresh")
	controls._unhandled_input(boost)
	check(controls.touches.is_empty(), "turbo touch cannot steer")
	controls._unhandled_input(touch(Vector2(80,400), 0))
	check(controls.steering_axis() == -1, "first finger steers")
	var pause_touch := touch(race.hud.pause_button.get_global_rect().get_center())
	check(race.hud.handle_pause_touch(pause_touch) and paused, "second finger pauses through raw touch handler")
	check(controls.touches.is_empty(), "pause clears held steering")
	controls._input(boost)
	check(not controls.consume_boost(), "paused turbo rejected")
	race.toggle_pause()
	check(not paused, "pause resumes")
	race.queue_free()
	await process_frame
	print("TOUCH HUD: %d failures" % failures)
	quit(failures)
