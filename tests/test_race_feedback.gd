extends "res://tests/test_android_layouts.gd"

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		print("FAIL: " + message)

func run() -> void:
	var save := root.get_node("SaveManager")
	save.save_path = "user://race_feedback_test.json"
	save.selected_circuit = "fuente"
	save.cup_race_requested = false
	save.settings.race_laps = 3
	for resolution in [Vector2i(1280,720), Vector2i(1440,720), Vector2i(1560,720), Vector2i(1600,720), Vector2i(2340,1080)]:
		print("FEEDBACK: ", resolution)
		root.size = resolution
		var race: Node2D = load("res://levels/race.tscn").instantiate()
		root.add_child(race)
		race.get_window().focus_exited.disconnect(race.pause_on_focus_loss)
		race.session.set_physics_process(false)
		var start: Vector2 = race.player.position
		await settle()
		check(race.player.position == start and not race.player.active, "countdown blocks movement")
		var numbers: Array[int] = []
		race.session.countdown_changed.connect(func(number: int) -> void: numbers.append(number))
		for i in range(4): race.session._physics_process(0.01 if i == 0 else 1.0)
		check(numbers == [3, 2, 1, 0] and race.player.active, "ordered countdown enables at zero")
		check(race.hud.countdown_label.text == "¡YA!", "start caption")
		for cap in race.session.caps: cap.set_physics_process(false)
		var velocity: Vector2 = race.player.velocity
		race.player.impacted.emit(race.player.position, Vector2.LEFT, 300.0)
		check(race.player.velocity == velocity, "impact feedback preserves physics")
		check(race.player.get_node("Camera2D").shake_time <= 0.15, "bounded impact shake")
		race.session.running = true
		race.session.elapsed = 8
		race.hud.last_place = 3
		race.hud.last_progress = race.session.progress(race.player)
		race.hud.update_race_feedback(2)
		check(race.hud.notice.text == "¡ADELANTAMIENTO!", "overtake feedback")
		var cooldown: float = race.hud.pass_cooldown
		race.hud.update_race_feedback(1)
		check(race.hud.pass_cooldown == cooldown, "overtake cooldown")
		race.player.lap = 3
		race.hud.update_race_feedback(1)
		check(race.hud.notice.text == "ÚLTIMA VUELTA", "last lap has priority")
		race.toggle_pause()
		var scale_before: Vector2 = race.hud.notice.scale
		await settle()
		check(race.hud.notice.scale == scale_before and race.player.velocity == velocity, "pause freezes presentation")
		race.toggle_pause()
		await settle()
		race.player.boosted.emit()
		race.player.velocity = Vector2(0, -440)
		for quality in ["low", "high"]:
			save.settings.quality = quality
			if DisplayServer.get_name() != "headless":
				await create_timer(2.2).timeout
				print("RACE FEEDBACK PERF ", resolution, " ", quality, " fps=", Engine.get_frames_per_second(), " draws=", Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
		check(race.vfx.capacity <= 96, "pool remains bounded")
		var balance: int = save.coins
		race.player.finished = true
		race.player.active = false
		race.player.finish_time = 70
		race.session.finish_order.append(race.player)
		race.on_finish(1, 70)
		check(save.coins == balance + 80 and not is_instance_valid(race.hud.overlay), "save before result transition")
		race.on_finish(1, 70)
		check(save.coins == balance + 80, "finish remains idempotent")
		await create_timer(0.8).timeout
		check(is_instance_valid(race.hud.overlay), "results appear after finish feedback")
		check_controls(race.hud.root, root.get_visible_rect(), str(resolution) + " results")
		if DisplayServer.get_name() != "headless":
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("user://race_feedback_%d.png" % resolution.x)
		race.hud.show_results(4, 85, 15)
		await create_timer(0.4).timeout
		check_controls(race.hud.root, root.get_visible_rect(), str(resolution) + " fourth place")
		race.queue_free()
		await process_frame
	print("RACE FEEDBACK: %d failures" % failures)
	for player in root.get_node("AudioManager").players.values(): player.stop()
	await settle()
	quit(failures)
