extends "res://tests/test_android_layouts.gd"

func run() -> void:
	var save := root.get_node("SaveManager")
	save.save_path = "user://water_culling_test.json"
	save.selected_circuit = "fuente"
	save.cup_race_requested = false
	for resolution in [Vector2i(1280,720), Vector2i(1600,720), Vector2i(2340,1080)]:
		root.size = resolution
		var race: Node2D = load("res://levels/race.tscn").instantiate()
		root.add_child(race)
		race.session.set_physics_process(false)
		var surface: WaterSurface
		for child in race.track.get_children():
			if child is WaterSurface: surface = child
		for y in [0.0, -6000.0, -17800.0]:
			race.player.position = Vector2(race.track.center_at(y), y)
			race.player.get_node("Camera2D").global_position = race.player.position
			await settle()
			var rows := surface.wave_row_range()
			if rows.x < 0 or rows.y > 100 or rows.y <= rows.x or rows.y - rows.x > 16:
				failures += 1
				print("FAIL: wave range ", resolution, " ", y, " ", rows)
			print("WAVE ROWS: ", resolution, " ", y, " -> ", rows)
		race.queue_free()
		await process_frame
	for player in root.get_node("AudioManager").players.values(): player.stop()
	await settle()
	print("WATER CULLING: ", failures, " failures")
	quit(failures)
