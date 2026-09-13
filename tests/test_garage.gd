extends "res://tests/test_android_layouts.gd"

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		print("FAIL: " + message)

func swipe(page: Control, offset: Vector2, canceled := false) -> void:
	var event := InputEventScreenTouch.new()
	event.pressed = true
	event.position = page.stage.get_global_rect().get_center()
	page._input(event)
	var end := InputEventScreenTouch.new()
	end.position = event.position + offset
	end.canceled = canceled
	page._input(end)

func run() -> void:
	var save := root.get_node("SaveManager")
	save.save_path = "user://garage_test.json"
	save.selected_cap = "sol"
	save.unlocked_caps = ["sol", "coral"]
	save.coins = 500
	save.save()
	for resolution in [Vector2i(1280,720), Vector2i(1440,720), Vector2i(1560,720), Vector2i(1600,720), Vector2i(2340,1080)]:
		print("GARAGE CHECK: ", resolution)
		root.size = resolution
		var menu: Control = load("res://ui/main_menu.tscn").instantiate()
		root.add_child(menu)
		menu.show_selection("caps")
		await settle()
		var page: Control = menu.content.get_child(0)
		for i in range(RacingCatalog.caps().size()):
			page.index = i
			page.build()
			await create_timer(0.4).timeout
			check_controls(menu, root.get_visible_rect(), str(resolution) + " garage " + str(i))
			check(absf(page.bars[0].value - RacingCatalog.caps()[i].speed * 100) < 0.1, "speed matches definition")
			var cap := RacingCatalog.caps()[i]
			check(absf(page.bars[1].value - cap.acceleration * 100) < 0.1 and absf(page.bars[2].value - cap.handling * 100) < 0.1 and absf(page.bars[3].value - cap.weight * 100) < 0.1, "other bars match definition")
			check(page.values[4].text == "N/D", "no invented resistance")
			check(page.equip.disabled == (RacingCatalog.caps()[i].id not in save.unlocked_caps or RacingCatalog.caps()[i].id == save.selected_cap), "equip guard")
			for button in page.find_children("*", "Button", true, false):
				if button.text == "HABILIDAD": button.pressed.emit()
			await settle()
			check_controls(menu, root.get_visible_rect(), str(resolution) + " ability detail")
		if DisplayServer.get_name() != "headless":
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("user://garage_final_%d.png" % resolution.x)
		page.index = 0
		page.build()
		swipe(page, Vector2(-110, 0))
		check(page.index == 1, "horizontal swipe")
		for i in range(25): page.change_cap(1)
		await create_timer(0.65).timeout
		check(page.shown_index == page.index and not page.busy, "rapid changes settle on latest cap")
		check(page.portrait.scale.is_equal_approx(Vector2.ONE), "scale restored")
		var selected: int = page.index
		swipe(page, Vector2(0, 110))
		swipe(page, Vector2(-110, 0), true)
		check(page.index == selected, "vertical and canceled gestures ignored")
		page.index = 1
		page.build()
		page.equip.pressed.emit()
		check(save.selected_cap == "coral", "equip owned cap")
		print("GARAGE: validating persistence")
		save.load_save()
		check(save.selected_cap == "coral", "equipped cap persisted")
		page.index = 0
		page.build()
		save.save_path = "user://missing_garage_folder/save.json"
		page.equip.pressed.emit()
		check(save.selected_cap == "coral", "failed equip save rolls back")
		save.save_path = "user://garage_test.json"
		save.save()
		page.index = 2
		var coins: int = save.coins
		save.coins = 0
		page.build()
		check(page.unlock.disabled, "insufficient coins disables purchase")
		page.purchase_cap()
		check(save.coins == 0 and RacingCatalog.caps()[2].id not in save.unlocked_caps, "insufficient coins preserves inventory")
		save.coins = coins
		page.index = 5
		page.build()
		if RacingCatalog.caps()[5].id not in save.unlocked_caps:
			var balance: int = save.coins
			page.unlock.pressed.emit()
			check(save.coins == balance - RacingCatalog.caps()[5].price, "existing purchase deducted once")
			check(save.selected_cap == RacingCatalog.caps()[5].id, "purchase equips cap")
		var nodes := page.find_children("*", "", true, false).size()
		for i in range(100): page.change_cap(1)
		await create_timer(0.65).timeout
		check(page.find_children("*", "", true, false).size() == nodes, "persistent controls do not accumulate")
		for quality in ["low", "high"]:
			if DisplayServer.get_name() == "headless": continue
			save.settings.quality = quality
			await create_timer(2.2).timeout
			print("GARAGE PERF ", resolution, " ", quality, " fps=", Engine.get_frames_per_second(), " draws=", Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME), " memory=", Performance.get_monitor(Performance.MEMORY_STATIC))
		menu._notification(Control.NOTIFICATION_WM_GO_BACK_REQUEST)
		await settle()
		check(menu.heading.text == "TAPA RACING", "Android back returns home")
		menu.queue_free()
		await process_frame
	print("GARAGE: %d failures" % failures)
	for player in root.get_node("AudioManager").players.values(): player.stop()
	await settle()
	quit(failures)
