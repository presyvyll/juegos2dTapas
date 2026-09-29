extends Node
## A bounded voice count: one player per category, with synthesized WAV assets.

const CATEGORIES := ["music", "water", "collisions", "boost", "ui", "victory"]
var players: Dictionary = {}
var menu_music: AudioStream
var race_theme := ""

func _ready() -> void:
	for category in CATEGORIES:
		var player := AudioStreamPlayer.new()
		player.stream = load("res://audio/menu_tropical_racing.wav") if category == "music" else load("res://audio/%s.wav" % category)
		if category in ["music", "water"] and player.stream is AudioStreamWAV:
			player.stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
			player.stream.loop_end = int(player.stream.get_length() * player.stream.mix_rate)
		add_child(player)
		players[category] = player
	menu_music = players.music.stream
	SaveManager.changed.connect(apply_settings)
	apply_settings()
	play("music")

func apply_settings() -> void:
	for category in players:
		var amount: float = float(SaveManager.settings.music if category == "music" else SaveManager.settings.effects)
		players[category].volume_db = linear_to_db(maxf(0.0001, amount)) - (12.0 if category == "water" else 0.0)

func play(category: String) -> void:
	if players.has(category) and DisplayServer.get_name() != "headless":
		players[category].play()

func set_racing(enabled: bool, circuit: CircuitDefinition = null) -> void:
	if enabled:
		play("water")
		if circuit and race_theme != circuit.id and DisplayServer.get_name() != "headless":
			players.music.stop()
			var music_path := "res://audio/races/%s.wav" % circuit.id
			players.music.stream = load(music_path) if ResourceLoader.exists(music_path) else TropicalRaceMusic.build(circuit.theme_id, circuit.seed_value)
			race_theme = circuit.id
			play("music")
	else:
		players.water.stop()
		if race_theme != "":
			players.music.stop()
			players.music.stream = menu_music
			race_theme = ""
			play("music")

func _exit_tree() -> void:
	for player in players.values():
		player.stop()
		player.stream = null
	players.clear()
