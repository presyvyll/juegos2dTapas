extends SceneTree
## Geometry, catalog integration and physical recovery; separate test save.
var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(value: bool, message: String) -> void:
	print(("PASS: " if value else "FAIL: ") + message)
	if not value:
		failures += 1

func run() -> void:
	var save := root.get_node("SaveManager")
	save.save_path = "user://circuit_layout_test.json"
	save.coins = 500
	save.unlocked_circuits = ["fuente"]
	check(save.purchase("circuits", "tropical", 100), "new circuit unlocks through existing catalog")
	save.selected_circuit = "tropical"
	save.settings.race_laps = 1
	check(save.save() and save.read_save(save.save_path) and save.selected_circuit == "tropical", "new circuit selection survives save/load")
	var race: Node2D = load("res://levels/race.tscn").instantiate()
	root.add_child(race)
	await process_frame
	var track: RaceTrack = race.track
	check(track.definition.id == "tropical" and track.definition.authored_layout, "race builds selected authored course")
	check(track.obstacles.size() == 10 and track.definition.features.size() == 28, "course stays within ten solid obstacles and 28 features")
	for cap in race.session.caps:
		check(absf(cap.position.x - track.center_at(cap.position.y)) + 40 < track.width_at(cap.position.y) / 2, "racer spawns inside banks")
	var checkpoint_total := 0
	var finish_total := 0
	for child in race.get_children():
		if child is RaceCheckpoint:
			checkpoint_total += 1
			finish_total += int(child.finish_line)
			check(is_equal_approx(child.position.y, -track.definition.length * (child.index + 1) / race.session.checkpoint_count), "checkpoint follows ordered course distance")
	check(checkpoint_total == 12 and finish_total == 1, "twelve checkpoints and one finish")
	for obstacle in track.obstacles:
		var half := track.width_at(obstacle.position.y) / 2
		var lateral := absf(obstacle.position.x - track.center_at(obstacle.position.y))
		check(half - lateral - obstacle.radius > 100, "both sides of solid obstacle have racer clearance")
	var rival: RacingCap = race.session.caps[1]
	rival.active = true
	race.session.running = true
	await physics_frame
	var checkpoint_before := rival.checkpoint_index
	rival.position.x += 1200
	for frame in range(90):
		await physics_frame
	check(absf(rival.position.x - track.center_at(rival.position.y)) < track.width_at(rival.position.y) / 2, "AI physically returns inside after leaving course")
	check(rival.checkpoint_index == checkpoint_before and rival.lap == 1 and not rival.finished, "recovery does not grant checkpoint or lap progress")
	rival.position = Vector2(track.center_at(900), 900)
	for frame in range(90):
		await physics_frame
	check(rival.position.y < 600 and rival.checkpoint_index == checkpoint_before, "recovery also handles leaving behind the start without losing its safe position")
	# Enter the channel downstream of an unvisited gate: recovering to a newer
	# interior point would leave this AI circulating beyond the finish forever.
	var pending_y: float = -track.definition.length * (rival.checkpoint_index + 1) / track.checkpoint_count
	rival.position = Vector2(track.center_at(pending_y - 500), pending_y - 500)
	for frame in range(90):
		await physics_frame
	check(rival.position.y > pending_y and rival.checkpoint_index == checkpoint_before, "AI returns before a missed checkpoint instead of accepting a downstream safe point")
	# Capture the new island section using the real renderer when available.
	if DisplayServer.get_name() != "headless":
		root.size = Vector2i(1280, 720)
		race.hud.countdown_label.hide()
		for index in range(4):
			var cap: RacingCap = race.session.caps[index]
			cap.set_physics_process(false)
			if is_instance_valid(cap.ai):
				cap.ai.set_physics_process(false)
			cap.position = Vector2(track.center_at(-3650.0) + (index - 1.5) * 70, -3650 - index * 45)
		race.player.get_node("Camera2D").global_position = race.player.position
		for frame in range(20):
			await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("user://tropical.png")
	race.queue_free()
	for player in root.get_node("AudioManager").players.values():
		player.stop()
	for frame in range(10):
		await process_frame
	print("CIRCUIT LAYOUT: %d failures" % failures)
	quit(failures)
