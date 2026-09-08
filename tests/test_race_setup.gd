extends SceneTree

var failures := 0

func check(value: bool, message: String) -> void:
	print(("PASS: " if value else "FAIL: ") + message)
	if not value:
		failures += 1

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var save := root.get_node("SaveManager")
	save.save_path = "user://race_setup_test.json"
	save.settings.race_laps = 1
	var menu: Control = load("res://ui/main_menu.tscn").instantiate()
	root.add_child(menu)
	menu.show_race_setup()
	var page: Control = menu.content.get_child(0)
	var settings: Control = page.get_child(2)
	var difficulty: OptionButton = settings.get_child(0).get_child(1)
	var laps: OptionButton = settings.get_child(1).get_child(1)
	difficulty.select(2)
	difficulty.item_selected.emit(2)
	laps.select(2)
	laps.item_selected.emit(2)
	check(save.settings.race_laps == 3 and save.settings.difficulty == "hard", "setup controls update race options")
	check(save.save() and save.read_save(save.save_path) and save.settings.race_laps == 3, "three laps persist through JSON round trip")
	var original: CircuitDefinition = RacingCatalog.circuits()[0]
	var old_laps := original.laps
	var race: Node2D = load("res://levels/race.tscn").instantiate()
	root.add_child(race)
	check(race.session.circuit.laps == 3 and race.track.definition.laps == 3, "session and reward circuit use chosen laps")
	check(original.laps == old_laps, "shared circuit resource stays unchanged")
	race.queue_free()
	if DisplayServer.get_name() != "headless":
		for frame in range(12):
			await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("user://race_setup.png")
	menu.queue_free()
	await process_frame
	for invalid in [0, 4, 1.5, "3", true, null]:
		var data: Dictionary = save.snapshot().duplicate(true)
		data.settings.race_laps = invalid
		var file := FileAccess.open(save.save_path, FileAccess.WRITE)
		file.store_string(JSON.stringify(data))
		file.close()
		check(save.read_save(save.save_path) and save.settings.race_laps == 1, "invalid laps default safely: " + str(invalid))
	var legacy: Dictionary = save.snapshot().duplicate(true)
	legacy.settings.erase("race_laps")
	var file := FileAccess.open(save.save_path, FileAccess.WRITE)
	file.store_string(JSON.stringify(legacy))
	file.close()
	check(save.read_save(save.save_path) and save.settings.race_laps == 1, "old saves load with one lap")
	print("RACE SETUP: %d failures" % failures)
	for player in root.get_node("AudioManager").players.values():
		player.stop()
	for frame in range(10):
		await process_frame
	quit(failures)
