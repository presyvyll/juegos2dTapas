extends "res://tests/test_android_layouts.gd"

func check(value: bool, message: String) -> void:
	if not value:
		failures += 1
		print("FAIL: " + message)

func fixture(cup: ChampionshipDefinition) -> Array:
	var rows: Array = []
	var ids := CupProgress.participants(cup)
	for index in range(4):
		rows.append({"id": ids[index], "finished": true, "time": 60.0 + index, "progress": 12 * cup.laps})
	return rows

func run() -> void:
	var save := root.get_node("SaveManager")
	save.save_path = "user://champion_presentation_test.json"
	save.selected_cap = "sol"
	var resolutions := [Vector2i(1280,720), Vector2i(1440,720), Vector2i(1560,720), Vector2i(1600,720), Vector2i(2340,1080)]
	var cups := RacingCatalog.championships()
	for quality in ["low", "high"]:
		save.settings.quality = quality
		for index in range(cups.size()):
			var cup: ChampionshipDefinition = cups[index]
			root.size = resolutions[index]
			save.championships = {"active": {}, "completed": {}}
			save.seen_champion_intros = []
			for previous in range(index): save.championships.completed[cups[previous].id] = 1
			var rounds: Array = []
			for round_index in range(cup.track_ids.size() - 1): rounds.append(fixture(cup))
			save.championships.active = {"cup_id": cup.id, "cap_id": "sol", "phase": "racing", "rounds": rounds}
			save.cup_race_requested = true
			var race: Node = load("res://levels/race.tscn").instantiate()
			root.add_child(race)
			var intro: Control = race.champion_intro
			check(is_instance_valid(intro) and not intro.can_skip, "first final presents champion")
			var expected: RacingCap = race.session.caps[cup.rival_ids.find(cup.champion_id) + 1]
			check(intro.appearance == expected.get_node("Visual").appearance, "portrait matches racing cap")
			for frame in range(35): await process_frame
			check(race.session.elapsed == 0 and race.session.countdown == 3 and not race.session.running, "intro excludes race and countdown time")
			for cap in race.session.caps: check(not cap.active, "all racers held equally")
			check_controls(intro, root.get_visible_rect(), cup.id + "/" + quality)
			var elapsed: float = intro.elapsed
			race.toggle_pause()
			for frame in range(12): await process_frame
			check(is_equal_approx(intro.elapsed, elapsed) and not intro.visible and race.hud.root.visible, "pause holds intro and exposes menu")
			race.toggle_pause()
			if DisplayServer.get_name() != "headless":
				await RenderingServer.frame_post_draw
				root.get_texture().get_image().save_png("user://champion_%s_%s.png" % [cup.id, quality])
			await intro.completed
			check(intro.elapsed <= 2.5 and race.session.is_physics_processing(), "intro ends within 2.5 seconds and restores countdown")
			check(race.player.get_node("Camera2D").target == race.player and race.hud.root.visible, "camera and HUD restored")
			check(save.read_save(save.save_path) and cup.champion_id in save.seen_champion_intros, "seen champion survives reload")
			race.queue_free()
			await process_frame
			race = load("res://levels/race.tscn").instantiate()
			root.add_child(race)
			intro = race.champion_intro
			check(intro.can_skip and is_instance_valid(intro.skip_button), "repeat final offers skip")
			intro.skip_button.pressed.emit()
			check(intro.finished and race.session.is_physics_processing(), "skip starts one normal countdown")
			race.queue_free()
			await process_frame
			print("CHAMPION: %s/%s checked" % [cup.id, quality])
	# Earlier rounds and free play never present a champion.
	save.championships.active = {"cup_id": "bronce", "cap_id": "sol", "phase": "racing", "rounds": []}
	var race: Node = load("res://levels/race.tscn").instantiate()
	root.add_child(race)
	check(not is_instance_valid(race.champion_intro), "no intro before the final")
	race.queue_free()
	await process_frame
	save.cup_race_requested = false
	race = load("res://levels/race.tscn").instantiate()
	root.add_child(race)
	check(not is_instance_valid(race.champion_intro), "no intro in free play")
	race.queue_free()
	await process_frame
	# A failed cosmetic-state write cannot falsely mark a presentation as persisted.
	save.seen_champion_intros = []
	var path: String = save.save_path
	save.save_path = "user://missing_champion_directory/save.json"
	check(not save.mark_champion_intro_seen("capitan_ola") and save.seen_champion_intros.is_empty(), "failed seen write rolls back")
	save.save_path = path
	check(not save.mark_champion_intro_seen("unknown"), "unknown champion rejected")
	for player in root.get_node("AudioManager").players.values(): player.stop()
	for frame in range(10): await process_frame
	print("CHAMPION PRESENTATIONS: %d failures" % failures)
	quit(failures)
