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
	var fingerprints := {}
	var circuit_count := 0
	var total_usec := 0
	check(ResourceLoader.exists("res://audio/menu_tropical_racing.wav"), "menu music asset is missing")
	var menu_stream := load("res://audio/menu_tropical_racing.wav") as AudioStreamWAV
	check(menu_stream != null and menu_stream.get_length() > 6.0, "menu music asset is invalid")
	for file_name in DirAccess.get_files_at("res://data/circuits"):
		if not file_name.ends_with(".tres"):
			continue
		var circuit: Resource = load("res://data/circuits/" + file_name)
		var baked_path := "res://audio/races/%s.wav" % circuit.id
		check(ResourceLoader.exists(baked_path), file_name + " baked music asset is missing")
		var baked_stream := load(baked_path) as AudioStreamWAV
		check(baked_stream != null and baked_stream.get_length() >= 1.5, file_name + " baked music asset is invalid")
		var started := Time.get_ticks_usec()
		var stream := TropicalRaceMusic.build(circuit.theme_id, circuit.seed_value)
		total_usec += Time.get_ticks_usec() - started
		circuit_count += 1
		check(stream.loop_mode == AudioStreamWAV.LOOP_FORWARD, file_name + " music must loop")
		check(stream.stereo, file_name + " music must be stereo")
		check(stream.mix_rate == 16000, file_name + " uses an unexpected mix rate")
		check(stream.get_length() >= 1.5 and stream.get_length() <= 2.1, file_name + " loop length is outside the mobile budget")
		check(stream.data.size() < 140000, file_name + " loop exceeds the memory budget")
		var peak := 0
		for offset in range(0, stream.data.size() - 1, 400):
			peak = maxi(peak, absi(stream.data.decode_s16(offset)))
		check(peak > 1500, file_name + " generated silent or inaudible music")
		fingerprints[hash(stream.data)] = true
	check(circuit_count == 15, "expected 15 circuit music loops")
	check(fingerprints.size() == circuit_count, "every circuit must produce a distinct melody")
	var average_ms := total_usec / maxf(1.0, circuit_count * 1000.0)
	check(average_ms < 450.0, "music generation is too slow: %.2f ms" % average_ms)
	print("TROPICAL MUSIC: circuits=%d unique=%d average_generation_ms=%.2f failures=%d" % [circuit_count, fingerprints.size(), average_ms, failures])
	quit(failures)
