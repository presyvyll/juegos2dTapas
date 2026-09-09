extends SceneTree
## Course geometry and bounded content in both mobile quality modes.
var failures := 0
var measurements: Array[Dictionary] = []

func _initialize() -> void:
	call_deferred("run")

func check(value: bool, message: String) -> void:
	if not value:
		failures += 1
		print("FAIL: " + message)

func run() -> void:
	var save := root.get_node("SaveManager")
	save.save_path = "user://all_courses_test.json"
	save.settings.race_laps = 1
	check(RacingCatalog.circuits().size() == 15, "fifteen selectable courses")
	save.best_times = {"fuente_normal_1": 50.0, "cascada_normal_1": 52.0, "tropical_normal_1": 65.0}
	for definition in RacingCatalog.circuits():
		if definition.id in ["fuente", "cascada"]:
			check(not save.best_times.has(definition.record_key("normal", 1)), "redesigned course does not display the previous layout's record")
		if definition.id == "tropical":
			check(save.best_times.get(definition.record_key("normal", 1)) == 65.0, "unchanged circuit keeps its record")
	check(save.best_times.has("fuente_normal_1") and save.best_times.has("cascada_normal_1"), "legacy records remain stored")
	for quality in ["low", "high"]:
		save.settings.quality = quality
		for definition in RacingCatalog.circuits():
			save.selected_circuit = definition.id
			var started := Time.get_ticks_usec()
			var memory_before := OS.get_static_memory_usage()
			var race: Node2D = load("res://levels/race.tscn").instantiate()
			root.add_child(race)
			var construction_ms := (Time.get_ticks_usec() - started) / 1000.0
			await process_frame
			var track: RaceTrack = race.track
			check(track.definition.id == definition.id, "selected resource: " + definition.id)
			check(track.obstacles.size() <= 12 and track.definition.features.size() <= 32, "mobile content budget: " + definition.id)
			check(race.vfx.capacity == (48 if quality == "low" else 96), "VFX budget")
			for cap in race.session.caps:
				check(absf(cap.position.x - track.center_at(cap.position.y)) + 40 < track.width_at(cap.position.y) / 2, "spawn clearance: " + definition.id)
			for obstacle in track.obstacles:
				var lateral := absf(obstacle.position.x - track.center_at(obstacle.position.y))
				var travel: float = obstacle.travel if obstacle is MovingObstacle else 0.0
				check(track.width_at(obstacle.position.y) / 2 - lateral - obstacle.radius - travel > 75, "passage at maximum obstacle travel: " + definition.id)
			var ordered: Array[RaceCheckpoint] = []
			var finishes := 0
			var pickups := 0
			for child in race.get_children():
				if child is RacingPickup:
					pickups += 1
					check(track.pickup_clear(child.position), "accessible pickup including moving obstacle sweep: " + definition.id)
				if child is RaceCheckpoint:
					ordered.append(child)
					finishes += int(child.finish_line)
			check(ordered.size() == 12 and finishes == 1, "checkpoint count: " + definition.id)
			check(pickups == 8, "eight accessible pickups: " + definition.id)
			for index in range(ordered.size()):
				var cp := ordered[index]
				check(cp.index == index and is_equal_approx(cp.position.y, -definition.length * (index + 1) / 12), "checkpoint order and position")
				check(cp.width >= track.width_at(cp.position.y), "checkpoint spans both routes")
			# Invalid meta crossings cannot finish a race or grant a reward.
			race.session.running = true
			race.session.cross_checkpoint(race.player, 11)
			check(not race.player.finished and race.player.checkpoint_index == 0, "finish cannot bypass checkpoints")
			if DisplayServer.get_name() != "headless":
				root.size = Vector2i(1280, 720)
				race.hud.countdown_label.hide()
				var view_y: float = {"fuente": -1950.0, "tropical": -3650.0, "remolino": -1650.0, "cascada": -2300.0, "tormenta": -3000.0, "ojo": -2000.0, "eclipse": -800.0, "templo": -1350.0}.get(definition.id, -track.definition.features[0].distance + 350)
				for index in range(4):
					var cap: RacingCap = race.session.caps[index]
					cap.active = true
					cap.set_physics_process(false)
					if is_instance_valid(cap.ai):
						cap.ai.set_physics_process(false)
					cap.position = Vector2(track.center_at(view_y) + (index - 1.5) * 70, view_y - index * 45)
					cap.velocity = Vector2(0, -240)
				race.player.get_node("Camera2D").global_position = race.player.position
				for frame in range(20):
					await process_frame
				await RenderingServer.frame_post_draw
				root.get_texture().get_image().save_png("user://course_%s_%s.png" % [definition.id, quality])
			print("COURSE: %s/%s: %d features, %d solid obstacles" % [definition.id, quality, track.definition.features.size(), track.obstacles.size()])
			measurements.append({"circuit": definition.id, "quality": quality, "construction_ms": construction_ms, "static_memory_delta_bytes": OS.get_static_memory_usage() - memory_before, "features": track.definition.features.size(), "solids": track.obstacles.size()})
			race.queue_free()
			await process_frame
	for player in root.get_node("AudioManager").players.values():
		player.stop()
	for frame in range(10):
		await process_frame
	print("ALL COURSES: %d failures" % failures)
	var report := FileAccess.open("user://course_loading_metrics.json", FileAccess.WRITE)
	report.store_string(JSON.stringify({"platform": OS.get_name(), "renderer": DisplayServer.get_name(), "failures": failures, "measurements": measurements}, "  "))
	report.close()
	quit(failures)
