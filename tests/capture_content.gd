extends SceneTree
## Review sheet of real procedural placeholders, not a new in-game menu.
func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	root.size = Vector2i(1280, 720)
	var roster: RacingCatalogData = load("res://data/arcade_content.tres")
	var ui: GDScript = load("res://scripts/ui/ui_style.gd")
	var surface := Control.new()
	surface.theme = ui.theme()
	root.add_child(surface)
	var title: Label = ui.label("LIGA DE LA FUENTE · 18 TAPAS · PLACEHOLDERS", 25)
	title.position = Vector2(40, 16)
	surface.add_child(title)
	var grid := GridContainer.new()
	grid.columns = 6
	grid.position = Vector2(40, 64)
	grid.add_theme_constant_override("h_separation", 18)
	grid.add_theme_constant_override("v_separation", 10)
	surface.add_child(grid)
	for cap in roster.caps:
		var cell := VBoxContainer.new()
		cell.custom_minimum_size = Vector2(180, 190)
		grid.add_child(cell)
		var preview: Control = load("res://scripts/ui/cap_preview.gd").new()
		preview.appearance = cap.appearance
		preview.tint = cap.color
		preview.art_scale = 1.65
		cell.add_child(preview)
		var name_label: Label = ui.label(cap.display_name, 20)
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		cell.add_child(name_label)
		var stats_label: Label = ui.label("%d/%d/%d/%d/%d/%d" % cap.ratings.values(), 15)
		stats_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		cell.add_child(stats_label)
	for frame in range(15):
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("user://arcade_content.png")
	for player in root.get_node("AudioManager").players.values():
		player.stop()
	for frame in range(10):
		await process_frame
	print("CONTENT CAPTURE: ", ProjectSettings.globalize_path("user://arcade_content.png"))
	quit()
