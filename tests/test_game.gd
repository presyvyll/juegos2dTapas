extends SceneTree

var failures := 0
var save: Node

func _init() -> void:
	call_deferred("run")

func check(condition: bool, description: String) -> void:
	if not condition:
		failures += 1
		push_error("FAIL: " + description)
	else:
		print("PASS: " + description)

func run() -> void:
	save = root.get_node("SaveManager")
	save.save_path = "user://automated_test_save.json"
	save.coins = 500
	save.unlocked_caps = ["sol", "coral"]
	save.unlocked_circuits = ["fuente"]
	save.unlocked_skins = ["original"]
	save.best_times = {}
	save.selected_cap = "sol"
	save.selected_circuit = "fuente"
	check(save.purchase("caps", "menta", 100), "purchase succeeds with sufficient balance")
	check(save.coins == 400, "purchase charges exactly once")
	check(save.purchase("caps", "menta", 100) and save.coins == 400, "owned item is not charged twice")
	check(not save.purchase("caps", "uva", 9999), "insufficient balance rejected")
	check(save.save(), "save replaces existing file")
	save.coins = 0
	save.load_save()
	check(save.coins == 400 and "menta" in save.unlocked_caps, "save round trip")
	var file := FileAccess.open(save.save_path, FileAccess.WRITE)
	file.store_string("broken JSON")
	file.close()
	save.load_save()
	check(save.coins == 400, "corrupt primary recovers backup")
	file = FileAccess.open(save.save_path, FileAccess.WRITE)
	file.store_string('{"version":1,"coins":{"invalid":true}}')
	file.close()
	save.load_save()
	check(save.coins == 400, "invalid balance type recovers backup without conversion errors")
	var backup_before := FileAccess.get_file_as_string(save.save_path + ".bak")
	save.save()
	check(FileAccess.get_file_as_string(save.save_path + ".bak") == backup_before, "recovery save preserves healthy backup")
	var original_path: String = save.save_path
	save.save_path = "user://missing_test_directory/save.json"
	check(not save.purchase("caps", "uva", 150) and save.coins == 400 and "uva" not in save.unlocked_caps, "failed save rolls purchase back")
	save.save_path = original_path
	save.save()
	var touch := CapPlayerInput.new()
	root.add_child(touch)
	var event := InputEventScreenTouch.new()
	event.index = 1
	event.pressed = true
	event.position = Vector2(10, 300)
	touch._unhandled_input(event)
	check(touch.steering_axis() == -1, "left touch steers left")
	event.pressed = false
	touch._input(event)
	check(is_zero_approx(touch.steering_axis()), "UI-covered release clears steering")
	event.pressed = true
	touch.excluded_rects = [Rect2(0, 200, 100, 200)]
	touch._unhandled_input(event)
	check(touch.touches.is_empty(), "touching UI does not steer")
	touch.excluded_rects = []
	touch._unhandled_input(event)
	var drag := InputEventScreenDrag.new()
	drag.index = 1
	drag.position = Vector2(110, 300)
	touch._unhandled_input(drag)
	check(touch.consume_swipe() == 1 and touch.consume_swipe() == 0, "swipe is consumed once")
	touch.boost_touch_rect = Rect2(800, 500, 200, 100)
	touch.excluded_rects = [touch.boost_touch_rect]
	touch.boost_touch_enabled = true
	event.index = 2
	event.position = Vector2(850, 550)
	touch._input(event)
	touch._unhandled_input(event)
	check(touch.consume_boost() and touch.touches.size() == 1, "second finger boosts while first keeps steering")
	touch.clear()
	touch.free()
	var menu: Control = load("res://ui/main_menu.tscn").instantiate()
	root.add_child(menu)
	menu.show_selection("caps")
	await process_frame
	menu.show_selection("circuits")
	await process_frame
	menu.show_settings()
	await process_frame
	menu.show_home()
	await process_frame
	check(menu.content.get_child_count() >= 6, "all menu pages build and return")
	menu.queue_free()
	await process_frame
	for circuit_id in ["fuente", "cascada"]:
		save.selected_circuit = circuit_id
		save.settings.difficulty = "normal"
		var race: Node2D = load("res://levels/race.tscn").instantiate()
		root.add_child(race)
		await process_frame
		Engine.max_fps = 0
		var session: RaceSession = race.session
		var player: RacingCap = race.player
		race.toggle_pause()
		check(paused, "race pauses")
		race.toggle_pause()
		check(not paused, "race resumes")
		check(session.caps.size() == 4, circuit_id + ": four racers")
		session.running = true
		session.cross_checkpoint(player, 5)
		check(player.checkpoint_index == 0, "out-of-order checkpoint rejected")
		for cap in session.caps:
			cap.active = true
		# Replace the human input source for a deterministic end-to-end simulation.
		var autopilot := CapAIController.new()
		autopilot.cap = player
		autopilot.track = race.track
		autopilot.rng.seed = 997
		player.ai = autopilot
		player.add_child(autopilot)
		for frame in range(9000):
			await physics_frame
			if session.finish_order.size() == 4:
				break
		for cap in session.caps:
			check(cap.finished, "%s: %s finishes (%.2f s, checkpoint %d, y %.0f)" % [circuit_id, cap.racer_name, cap.finish_time, cap.checkpoint_index, cap.position.y])
		check(player.finish_time >= 55 and player.finish_time <= 100, "race duration near target")
		var balance: int = save.coins
		race.on_finish(1, 80)
		check(save.coins == balance, "reward cannot be duplicated")
		# Ordered checkpoint/lap transitions, independent from the full-course drive.
		var lap_session := RaceSession.new()
		lap_session.circuit = session.circuit.duplicate() as CircuitDefinition
		lap_session.circuit.laps = 3
		lap_session.caps = [player]
		lap_session.running = true
		player.finished = false
		player.lap = 1
		player.checkpoint_index = 0
		for lap_number in range(3):
			for checkpoint in range(lap_session.checkpoint_count):
				lap_session.cross_checkpoint(player, checkpoint)
		check(player.finished and player.lap == 3 and lap_session.finish_order.size() == 1, "three laps require all ordered checkpoints")
		lap_session.free()
		race.queue_free()
		await process_frame
	print("RESULT: %d failures" % failures)
	quit(1 if failures else 0)
