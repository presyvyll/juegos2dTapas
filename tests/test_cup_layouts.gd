extends "res://tests/test_android_layouts.gd"

func fixture(cup: ChampionshipDefinition) -> Array:
	var rows: Array = []
	var ids := CupProgress.participants(cup)
	for index in range(4):
		rows.append({"id": ids[index], "finished": true, "time": 65.0 + index, "progress": 12 * cup.laps})
	return rows

func run() -> void:
	var save := root.get_node("SaveManager")
	save.save_path = "user://cup_layout_test.json"
	var cups := RacingCatalog.championships()
	for resolution in [Vector2i(1280,720), Vector2i(1440,720), Vector2i(1560,720), Vector2i(1600,720), Vector2i(2340,1080)]:
		root.size = resolution
		save.championships = {"active": {}, "completed": {}}
		var menu: Control = load("res://ui/main_menu.tscn").instantiate()
		root.add_child(menu)
		await settle()
		check_controls(menu, root.get_visible_rect(), "cup home")
		menu.show_championships()
		var page: Control = menu.content.get_child(0)
		for index in range(5):
			page.index = index
			page.build()
			await settle()
			check_controls(menu, root.get_visible_rect(), "cup selection " + str(index))
		var cup := cups[0]
		for phase in ["ready", "racing", "results", "complete"]:
			var rounds: Array = []
			if phase == "results": rounds.append(fixture(cup))
			if phase == "complete":
				for index in range(3): rounds.append(fixture(cup))
			save.championships.active = {"cup_id": "bronce", "cap_id": "sol", "phase": phase, "rounds": rounds}
			page.build()
			await settle()
			check_controls(menu, root.get_visible_rect(), "cup phase " + phase)
		menu.queue_free()
		await process_frame
		save.championships.active = {"cup_id": "bronce", "cap_id": "sol", "phase": "racing", "rounds": [fixture(cup), fixture(cup)]}
		save.cup_race_requested = true
		var race: Node2D = load("res://levels/race.tscn").instantiate()
		root.add_child(race)
		if is_instance_valid(race.champion_intro):
			await race.champion_intro.completed
		await settle()
		race.on_finish(1, 65)
		await settle()
		check_controls(race.hud.root, root.get_visible_rect(), "waiting for rivals")
		race.session.running = true
		for index in range(4):
			var cap: RacingCap = race.session.caps[index]
			cap.finished = true
			cap.active = false
			cap.finish_time = 65 + index
			cap.checkpoint_index = 12
			race.session.finish_order.append(cap)
		await settle()
		check_controls(race.hud.root, root.get_visible_rect(), "cup results modal")
		if DisplayServer.get_name() != "headless":
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("user://cup_results_%dx%d.png" % [resolution.x, resolution.y])
		race.queue_free()
		await process_frame
		print("CUP LAYOUT: ", resolution)
	for player in root.get_node("AudioManager").players.values(): player.stop()
	for frame in range(10): await process_frame
	print("CUP LAYOUTS: %d failures" % failures)
	quit(failures)
