extends SceneTree
## Detect eager layout loads, accidental shared state, and pulse regressions.
var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(value: bool, message: String) -> void:
	if not value:
		failures += 1
		print("FAIL: " + message)

func run() -> void:
	var entries := RacingCatalog.circuits()
	check(entries.size() == 15, "fifteen menu entries")
	var ids: Array[String] = []
	for entry in entries:
		check(entry.id not in ids, "unique circuit id")
		ids.append(entry.id)
		check(entry.features.is_empty() and not entry.layout_path.is_empty(), "menu stores metadata only")
		check(not ResourceLoader.has_cached(entry.layout_path), "menu did not load " + entry.id)
	for entry in entries:
		var layout := RacingCatalog.load_circuit(entry)
		check(layout != null and not layout.features.is_empty(), "playable layout: " + entry.id)
		for field in ["id", "display_name", "description", "price", "length", "width", "laps", "record_version", "difficulty_rating", "recommended_level", "theme_id", "water_color"]:
			check(layout.get(field) == entry.get(field), "metadata matches: %s/%s" % [entry.id, field])
		check(layout.layout_path.is_empty(), "no recursive layout references")
		var second := RacingCatalog.load_circuit(entry)
		layout.laps = 3
		check(second.laps == 1 and entry.laps == 1, "race settings remain isolated")
		for other in entries:
			if other.id != entry.id:
				check(not ResourceLoader.has_cached(other.layout_path), "only selected layout is loaded")
		layout = null
		second = null
		await process_frame
		check(not ResourceLoader.has_cached(entry.layout_path), "unused layout released")
	var whirl := WhirlpoolArea.new()
	whirl.pulse_depth = 0.6
	whirl.pulse_period = 4
	root.add_child(whirl)
	whirl.set_physics_process(false)
	whirl.pulse_time = 1
	var weak := whirl.force_at(Vector2(60, 0)).length()
	whirl.pulse_time = 3
	var strong := whirl.force_at(Vector2(60, 0)).length()
	check(is_equal_approx(weak / strong, 0.4), "pulse changes actual force")
	check(whirl.force_at(Vector2(whirl.radius + 1, 0)) == Vector2.ZERO, "pulse does not extend collider")
	whirl.pulse_depth = 0
	check(is_equal_approx(whirl.force_at(Vector2(60, 0)).length(), strong), "zero pulse preserves existing force")
	whirl.queue_free()
	await process_frame
	print("CIRCUIT LOADING: %d failures" % failures)
	quit(failures)
