extends "res://tests/test_android_layouts.gd"

func run() -> void:
	var save := root.get_node("SaveManager")
	var original: Dictionary = save.snapshot().duplicate(true)
	for resolution in [Vector2i(1280,720), Vector2i(1440,720), Vector2i(1560,720), Vector2i(1600,720), Vector2i(2340,1080)]:
		root.size = resolution
		var menu: Control = load("res://ui/main_menu.tscn").instantiate()
		root.add_child(menu)
		await create_timer(0.35).timeout
		check_controls(menu, root.get_visible_rect(), str(resolution) + " home")
		var button: Button = menu.navigation.get_child(1)
		button.button_down.emit()
		await create_timer(0.12).timeout
		if button.scale.x >= 0.99: failures += 1
		button.button_up.emit()
		await create_timer(0.30).timeout
		if not button.scale.is_equal_approx(Vector2.ONE): failures += 1
		if DisplayServer.get_name() != "headless":
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("user://menu_modern_%d.png" % resolution.x)
		menu.show_rewards()
		await settle()
		check_controls(menu, root.get_visible_rect(), str(resolution) + " rewards")
		menu.show_selection("caps")
		await settle()
		var page: Control = menu.content.get_child(0)
		var previous: int = page.index
		var touch := InputEventScreenTouch.new()
		touch.index = 0
		touch.pressed = true
		touch.position = page.stage.get_global_rect().get_center()
		page._input(touch)
		touch = InputEventScreenTouch.new()
		touch.index = 0
		touch.position = page.stage.get_global_rect().get_center() - Vector2(110, 0)
		page._input(touch)
		if page.index != posmod(previous + 1, RacingCatalog.caps().size()):
			failures += 1
		for i in range(RacingCatalog.caps().size()):
			page.index = i
			page.build()
			await settle()
			check_controls(menu, root.get_visible_rect(), str(resolution) + " garage")
		if DisplayServer.get_name() != "headless":
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("user://garage_modern_%d.png" % resolution.x)
		menu.show_home()
		for quality in ["low", "high"]:
			save.settings.quality = quality
			await create_timer(2.2).timeout
			print("MENU PERF ", resolution, " ", quality, " fps=", Engine.get_frames_per_second(), " draws=", Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME), " texture_bytes=", Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED))
		menu.queue_free()
		await process_frame
	save.settings = original.settings
	if save.snapshot() != original:
		print("FAIL: presentation modified save state")
		failures += 1
	print("MENU PRESENTATION: %d failures" % failures)
	for player in root.get_node("AudioManager").players.values(): player.stop()
	await settle()
	quit(failures)
