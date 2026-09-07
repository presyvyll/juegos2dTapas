extends Node

signal changed
signal save_failed
const SAVE_PATH := "user://tapa_racing_v1.json"
var save_path := SAVE_PATH
var coins: int = 0
var unlocked_caps: Array = ["sol", "coral"]
var unlocked_circuits: Array = ["fuente"]
var unlocked_skins: Array = ["original"]
var best_times: Dictionary = {}
var settings: Dictionary = {"music": 0.35, "effects": 0.65, "vibration": true, "quality": "high", "fps": 60, "difficulty": "normal"}
var selected_cap := "sol"
var selected_circuit := "fuente"
var selected_skin := "original"
var last_save_ok := true
const DEFAULT_SETTINGS := {"music": 0.35, "effects": 0.65, "vibration": true, "quality": "high", "fps": 60, "difficulty": "normal"}

func _ready() -> void:
	get_tree().quit_on_go_back = false
	load_save()
	apply_settings()

func snapshot() -> Dictionary:
	return {"version": 1, "coins": coins, "caps": unlocked_caps, "circuits": unlocked_circuits, "skins": unlocked_skins, "best_times": best_times, "settings": settings, "selected_cap": selected_cap, "selected_circuit": selected_circuit, "selected_skin": selected_skin}

func load_save() -> void:
	if not read_save(save_path):
		read_save(save_path + ".bak")

func read_document(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var parser := JSON.new()
	if parser.parse(FileAccess.get_file_as_string(path)) != OK:
		return {}
	var parsed: Variant = parser.data
	if not parsed is Dictionary or parsed.get("version") != 1:
		return {}
	var balance: Variant = parsed.get("coins", 0)
	if not (balance is float or balance is int) or not is_finite(float(balance)):
		return {}
	return parsed

func read_save(path: String) -> bool:
	var parsed := read_document(path)
	if parsed.is_empty():
		return false
	coins = clampi(int(parsed.get("coins", 0)), 0, 9999999)
	unlocked_caps = valid_ids(parsed.get("caps", []), ["sol", "coral", "menta", "oceano", "uva", "coco"], ["sol", "coral"])
	unlocked_circuits = valid_ids(parsed.get("circuits", []), ["fuente", "cascada"], ["fuente"])
	unlocked_skins = valid_ids(parsed.get("skins", []), ["original", "perla"], ["original"])
	best_times = {}
	settings = DEFAULT_SETTINGS.duplicate()
	var times: Variant = parsed.get("best_times", {})
	if times is Dictionary:
		for key in times:
			if (times[key] is float or times[key] is int) and is_finite(float(times[key])) and float(times[key]) > 0:
				best_times[str(key)] = float(times[key])
	var saved_settings: Variant = parsed.get("settings", {})
	if saved_settings is Dictionary:
		for key in settings:
			if saved_settings.has(key) and typeof(saved_settings[key]) == typeof(settings[key]):
				settings[key] = saved_settings[key]
		# JSON numbers deserialize as floats.
		var saved_fps: Variant = saved_settings.get("fps", 60)
		settings.fps = 30 if (saved_fps is float or saved_fps is int) and saved_fps == 30 else 60
	settings.music = clampf(float(settings.music), 0, 1)
	settings.effects = clampf(float(settings.effects), 0, 1)
	if settings.quality not in ["low", "high"]:
		settings.quality = "high"
	if settings.difficulty not in ["easy", "normal", "hard"]:
		settings.difficulty = "normal"
	selected_cap = str(parsed.get("selected_cap", "sol"))
	selected_circuit = str(parsed.get("selected_circuit", "fuente"))
	selected_skin = str(parsed.get("selected_skin", "original"))
	if selected_cap not in unlocked_caps:
		selected_cap = "sol"
	if selected_circuit not in unlocked_circuits:
		selected_circuit = "fuente"
	if selected_skin not in unlocked_skins:
		selected_skin = "original"
	return true

func valid_ids(value: Variant, allowed: Array, defaults: Array) -> Array:
	var result := defaults.duplicate()
	if value is Array:
		for id in value:
			if id in allowed and id not in result:
				result.append(id)
	return result

func save() -> bool:
	var file := FileAccess.open(save_path + ".tmp", FileAccess.WRITE)
	if file == null:
		return failure()
	file.store_string(JSON.stringify(snapshot()))
	file.flush()
	var error := file.get_error()
	file.close()
	if error != OK:
		return failure()
	# Never replace a healthy backup with a corrupt primary after recovery.
	if not read_document(save_path).is_empty():
		if DirAccess.copy_absolute(save_path, save_path + ".bak") != OK:
			return failure()
	if DirAccess.rename_absolute(save_path + ".tmp", save_path) != OK:
		return failure()
	last_save_ok = true
	changed.emit()
	return true

func failure() -> bool:
	last_save_ok = false
	save_failed.emit()
	return false

func purchase(kind: String, id: String, price: int) -> bool:
	var collection: Array
	match kind:
		"caps": collection = unlocked_caps
		"circuits": collection = unlocked_circuits
		"skins": collection = unlocked_skins
		_: return false
	if id in collection:
		return true
	if price < 0 or coins < price:
		return false
	coins -= price
	collection.append(id)
	if not save():
		coins += price
		collection.erase(id)
		return false
	return true

func record_result(key: String, time: float, place: int) -> int:
	var reward: int = [80, 45, 25, 15][clampi(place - 1, 0, 3)]
	coins += reward
	if time < float(best_times.get(key, INF)):
		best_times[key] = time
	save()
	return reward

func apply_settings() -> void:
	Engine.max_fps = int(settings.fps)
	RenderingServer.set_default_clear_color(Color("164b48"))

func haptic(duration: int) -> void:
	if settings.vibration and OS.get_name() in ["Android", "iOS"]:
		Input.vibrate_handheld(duration)

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_PAUSED:
		save()
