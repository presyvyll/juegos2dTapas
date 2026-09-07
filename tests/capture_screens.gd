extends SceneTree

func _init() -> void:
	call_deferred("run")

func capture(path: String) -> void:
	for frame in range(8):
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(path)

func run() -> void:
	root.size = Vector2i(1280, 720)
	var menu: Control = load("res://ui/main_menu.tscn").instantiate()
	root.add_child(menu)
	await capture("user://menu.png")
	menu.show_selection("caps")
	await capture("user://caps.png")
	menu.show_settings()
	await capture("user://settings.png")
	root.size = Vector2i(1024, 768)
	await capture("user://settings_tablet.png")
	root.size = Vector2i(1280, 720)
	menu.queue_free()
	await process_frame
	var race: Node2D = load("res://levels/race.tscn").instantiate()
	root.add_child(race)
	race.session.running = true
	race.hud.countdown_label.hide()
	for index in range(4):
		var cap: RacingCap = race.session.caps[index]
		cap.active = true
		cap.set_physics_process(false)
		if is_instance_valid(cap.ai):
			cap.ai.set_physics_process(false)
		cap.position.y = -2450 - index * 65
		cap.position.x = race.track.center_at(cap.position.y) + (-150 if index % 2 == 0 else 160)
		cap.velocity = Vector2(0, -240)
	race.player.get_node("Camera2D").global_position = race.player.position
	await capture("user://race.png")
	race.player.finished = true
	race.player.finish_time = 78.4
	race.session.caps[1].finished = true
	race.session.caps[1].finish_time = 77.1
	race.session.elapsed = 78.4
	race.hud.show_results(2, 78.4, 45)
	await capture("user://results.png")
	print("CAPTURES: ", ProjectSettings.globalize_path("user://"))
	root.get_node("AudioManager").set_racing(false)
	for player in root.get_node("AudioManager").players.values():
		player.stop()
	for frame in range(10):
		await process_frame
	quit()
