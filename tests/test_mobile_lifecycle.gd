extends SceneTree

var failures := 0

func _init() -> void:
	call_deferred("run")

func check(value: bool, description: String) -> void:
	if not value:
		failures += 1
		push_error(description)
	else:
		print("PASS: " + description)

func run() -> void:
	var save := root.get_node("SaveManager")
	save.save_path = "user://lifecycle_test_save.json"
	save.selected_circuit = "fuente"
	save.selected_cap = "sol"
	save.settings.fps = 30
	save.apply_settings()
	check(Engine.max_fps == 30 and Engine.physics_ticks_per_second == 60, "30 FPS keeps physics at 60 Hz")
	save.settings.fps = 60
	save.apply_settings()
	check(Engine.max_fps == 60, "60 FPS can be restored")
	var race: Node2D = load("res://levels/race.tscn").instantiate()
	root.add_child(race)
	await process_frame
	race.session.running = true
	race.player.active = true
	race.player.controls.touches[0] = 20
	race.notification(MainLoop.NOTIFICATION_APPLICATION_PAUSED)
	check(paused and race.player.controls.touches.is_empty(), "backgrounding pauses and clears input")
	var position: Vector2 = race.player.position
	for frame in range(10):
		await process_frame
	check(race.player.position == position, "paused physics does not advance")
	race.notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	check(not paused, "Android Back resumes the pause menu")
	save.coins = 123
	save.notification(MainLoop.NOTIFICATION_APPLICATION_PAUSED)
	save.coins = 0
	save.load_save()
	check(save.coins == 123, "backgrounding persists progress")
	race.queue_free()
	await process_frame
	print("LIFECYCLE: %d failures" % failures)
	quit(1 if failures else 0)
