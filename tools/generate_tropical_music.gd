extends SceneTree
## Rebuilds deterministic, original techno-tropical WAV assets for menu and races.

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var output_directory := ProjectSettings.globalize_path("res://audio/races")
	var error := DirAccess.make_dir_recursive_absolute(output_directory)
	if error != OK and error != ERR_ALREADY_EXISTS:
		push_error("Cannot create race music directory: %s" % error_string(error))
		quit(1)
		return
	var failures := 0
	var menu_stream := TropicalRaceMusic.build_menu()
	var menu_error := menu_stream.save_to_wav("res://audio/menu_tropical_racing.wav")
	if menu_error != OK:
		push_error("Cannot save menu music: %s" % error_string(menu_error))
		failures += 1
	var generated := 0
	for file_name in DirAccess.get_files_at("res://data/circuits"):
		if not file_name.ends_with(".tres"):
			continue
		var circuit: Resource = load("res://data/circuits/" + file_name)
		var stream := TropicalRaceMusic.build(circuit.theme_id, circuit.seed_value)
		var save_error := stream.save_to_wav("res://audio/races/%s.wav" % circuit.id)
		if save_error != OK:
			push_error("Cannot save %s music: %s" % [circuit.id, error_string(save_error)])
			failures += 1
		else:
			generated += 1
	print("TROPICAL MUSIC ASSETS: menu=%s races=%d failures=%d" % [menu_error == OK, generated, failures])
	quit(failures)

