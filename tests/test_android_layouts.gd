extends SceneTree

var failures := 0

func _initialize() -> void:
	call_deferred("run")

func settle() -> void:
	for frame in range(12):
		await process_frame

func check_controls(node: Node, bounds: Rect2, context: String) -> void:
	if node is Control and node.is_visible_in_tree() and (node is BaseButton or node is Label):
		var rect: Rect2 = node.get_global_rect()
		if not bounds.grow(2).encloses(rect):
			print("FAIL: ", context, " ", node.name, " ", rect, " outside ", bounds)
			failures += 1
	for child in node.get_children():
		check_controls(child, bounds, context)

func run() -> void:
	for resolution in [Vector2i(1280,720), Vector2i(1440,720), Vector2i(1560,720), Vector2i(1600,720), Vector2i(2340,1080)]:
		root.size = resolution
		var menu: Control = load("res://ui/main_menu.tscn").instantiate()
		root.add_child(menu)
		await settle()
		check_controls(menu, root.get_visible_rect(), str(resolution) + " home")
		menu.show_race_setup()
		await settle()
		check_controls(menu, root.get_visible_rect(), str(resolution) + " race setup")
		menu.show_selection("caps")
		await settle()
		check_controls(menu, root.get_visible_rect(), str(resolution) + " caps")
		menu.show_selection("circuits")
		var circuit_page: Control = menu.content.get_child(0)
		for circuit_index in range(RacingCatalog.circuits().size()):
			circuit_page.index = circuit_index
			circuit_page.build()
			await settle()
			check_controls(menu, root.get_visible_rect(), str(resolution) + " circuit " + str(circuit_index))
		menu.show_settings()
		await settle()
		check_controls(menu, root.get_visible_rect(), str(resolution) + " settings")
		menu.queue_free()
		await process_frame
		var race: Node2D = load("res://levels/race.tscn").instantiate()
		root.add_child(race)
		await settle()
		check_controls(race.hud.root, root.get_visible_rect(), str(resolution) + " HUD")
		race.hud.show_pause()
		await settle()
		check_controls(race.hud.root, root.get_visible_rect(), str(resolution) + " pause")
		race.hud.hide_pause()
		race.hud.show_results(1, 70, 80)
		await create_timer(0.5).timeout
		check_controls(race.hud.root, root.get_visible_rect(), str(resolution) + " results")
		if DisplayServer.get_name() != "headless":
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("user://layout_%dx%d.png" % [resolution.x, resolution.y])
		race.queue_free()
		await process_frame
		print("LAYOUT: ", resolution, " checked")
	print("ANDROID LAYOUTS: %d failures" % failures)
	for player in root.get_node("AudioManager").players.values():
		player.stop()
	for frame in range(10):
		await process_frame
	quit(failures)
