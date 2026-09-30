extends SceneTree

var failures := 0

func check(condition: bool, message: String) -> void:
	if condition:
		return
	print("FAIL: ", message)
	failures += 1

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var track := RaceTrack.new()
	track.definition = load("res://data/circuits/fuente.tres")
	track.high_quality = true
	var raw_profile := load("res://data/ambient/fuente_promenade.tres")
	var profile: Resource = raw_profile
	check(profile != null and profile.get_script() != null, "ambient profile must retain its script")
	if not profile:
		track.free()
		quit(failures)
		return
	var signatures := {}
	var seen_kinds := {}
	var generation_usec := 0
	for race_index in range(6):
		var spawner := TrackAmbientSpawner.new()
		spawner.track = track
		spawner.profile = profile
		spawner.seed_override = track.definition.seed_value + race_index * 101
		var started := Time.get_ticks_usec()
		root.add_child(spawner)
		await process_frame
		generation_usec += Time.get_ticks_usec() - started
		check(spawner.instances.size() > 8, "race %d has insufficient ambience" % race_index)
		check(spawner.events.size() >= 2 and spawner.events.size() <= 3, "race %d must contain two or three visible ambient events" % race_index)
		check(spawner.instances.size() <= profile.max_high, "race %d exceeds the high-quality budget" % race_index)
		check(spawner.all_instances_clear_of_track(), "race %d placed ambience inside the safety margin" % race_index)
		check(spawner.find_children("*", "CollisionObject2D", true, false).is_empty(), "ambient nodes must not collide")
		var signature := spawner.distribution_signature()
		signatures[signature] = true
		for item in spawner.instances:
			seen_kinds[item.kind] = true
		spawner.react_to_overtake()
		check(spawner.overtake_pulse > 0.0, "overtake reaches ambient crowd")
		spawner.celebrate_finish()
		check(spawner.finish_pulse > 0.0, "finish reaches ambient crowd")
		spawner.queue_free()
		await process_frame
	check(signatures.size() == 6, "six consecutive races must produce six controlled variations")
	for expected in ["person", "animal", "commerce"]:
		check(seen_kinds.has(expected), "missing ambient category: " + expected)
	track.high_quality = false
	var low_spawner := TrackAmbientSpawner.new()
	low_spawner.track = track
	low_spawner.profile = profile
	low_spawner.seed_override = 9001
	root.add_child(low_spawner)
	await process_frame
	check(low_spawner.quality == AmbientProfile.AmbientQuality.LOW, "low quality must select the LOW ambient budget")
	check(low_spawner.instances.size() <= profile.max_low, "low quality exceeds its population budget")
	check(low_spawner.events.size() == 1, "low quality keeps one visible ambient event")
	check(low_spawner.all_instances_clear_of_track(), "low quality placed ambience inside the safety margin")
	low_spawner.queue_free()
	await process_frame
	var profile_ids := {}
	var circuit_count := 0
	for file_name in DirAccess.get_files_at("res://data/circuits"):
		if not file_name.ends_with(".tres"):
			continue
		var circuit: Resource = load("res://data/circuits/" + file_name)
		circuit_count += 1
		check(circuit.ambient_profile != null, file_name + " must define an ambient profile")
		if not circuit.ambient_profile:
			continue
		profile_ids[circuit.ambient_profile.id] = true
		var circuit_track := RaceTrack.new()
		circuit_track.set("definition", circuit)
		circuit_track.high_quality = true
		var circuit_spawner := TrackAmbientSpawner.new()
		circuit_spawner.track = circuit_track
		circuit_spawner.profile = circuit.ambient_profile
		circuit_spawner.seed_override = circuit.seed_value
		root.add_child(circuit_spawner)
		await process_frame
		check(not circuit_spawner.instances.is_empty(), file_name + " generated no ambience")
		check(circuit_spawner.instances.size() <= circuit.ambient_profile.max_high, file_name + " exceeds its population budget")
		check(circuit_spawner.all_instances_clear_of_track(), file_name + " placed ambience inside the safety margin")
		circuit_spawner.queue_free()
		await process_frame
		circuit_track.free()
	check(circuit_count == 15, "expected 15 circuit resources")
	check(profile_ids.size() == circuit_count, "every circuit must use a distinct ambient profile")
	var average_ms := generation_usec / 6000.0
	check(average_ms < 12.0, "average spawn cost is too high: %.2f ms" % average_ms)
	print("AMBIENT: circuits=%d profiles=%d runs=6 variations=%d average_spawn_ms=%.2f failures=%d" % [circuit_count, profile_ids.size(), signatures.size(), average_ms, failures])
	track.free()
	quit(failures)
