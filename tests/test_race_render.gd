extends SceneTree

func _initialize() -> void: call_deferred("run")

func run() -> void:
	if DisplayServer.get_name() == "headless":
		quit()
		return
	var save := root.get_node("SaveManager")
	save.save_path = "user://race_render_test.json"
	save.cup_race_requested = false
	save.selected_circuit = "fuente"
	save.settings.race_laps = 1
	save.settings.fps = 60
	save.apply_settings()
	root.size = Vector2i(1280, 720)
	for quality in ["low", "high"]:
		save.settings.quality = quality
		var race: Node2D = load("res://levels/race.tscn").instantiate()
		root.add_child(race)
		race.get_window().focus_exited.disconnect(race.pause_on_focus_loss)
		var ai := CapAIController.new()
		ai.cap = race.player
		ai.track = race.track
		ai.rng.seed = 997
		race.player.ai = ai
		race.player.add_child(ai)
		await create_timer(5.0).timeout
		for sample in range(4):
			await create_timer(1.2).timeout
			print("MOVING RACE ", quality, " fps=", Engine.get_frames_per_second(), " draws=", Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME), " pool=", race.vfx.capacity, " memory=", Performance.get_monitor(Performance.MEMORY_STATIC))
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("user://moving_race_%s.png" % quality)
		race.queue_free()
		await process_frame
	for player in root.get_node("AudioManager").players.values(): player.stop()
	for frame in range(10): await process_frame
	quit()
