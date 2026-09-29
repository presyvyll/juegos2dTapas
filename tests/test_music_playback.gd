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
	for frame in range(4):
		await process_frame
	var audio := root.get_node("AudioManager")
	check(audio.menu_music.resource_path == "res://audio/menu_tropical_racing.wav", "menu stream was not loaded")
	check(audio.players.music.playing, "menu music player is not active")
	var circuit: Resource = load("res://data/circuits/fuente.tres")
	audio.set_racing(true, circuit)
	await process_frame
	check(audio.race_theme == "fuente", "race music theme was not selected")
	check(audio.players.music.stream.resource_path == "res://audio/races/fuente.wav", "baked race stream was not loaded")
	check(audio.players.music.playing, "race music player is not active")
	audio.set_racing(false)
	await process_frame
	check(audio.players.music.stream.resource_path == "res://audio/menu_tropical_racing.wav", "menu stream was not restored")
	check(audio.players.music.playing, "restored menu music is not active")
	print("MUSIC PLAYBACK: failures=%d" % failures)
	quit(failures)
