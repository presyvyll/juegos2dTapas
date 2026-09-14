extends Node

signal changed
signal save_failed
const SAVE_PATH := "user://tapa_racing_v1.json"
const PROGRESSION: ProgressionConfig = preload("res://data/progression/default.tres")
var cap_progress: Dictionary = {}
var save_path := SAVE_PATH
var coins: int = 0
var unlocked_caps: Array = ["sol", "coral"]
var unlocked_circuits: Array = ["fuente"]
var unlocked_skins: Array = ["original"]
var best_times: Dictionary = {}
var settings: Dictionary = {"music": 0.35, "effects": 0.65, "vibration": true, "quality": "high", "fps": 60, "difficulty": "normal", "race_laps": 1}
var selected_cap := "sol"
var selected_circuit := "fuente"
var selected_skin := "original"
var last_save_ok := true
var championships: Dictionary = {"active": {}, "completed": {}}
## Transient launch intent: free play never advances a saved cup.
var cup_race_requested := false
var seen_champion_intros: Array = []
const DEFAULT_SETTINGS := {"music": 0.35, "effects": 0.65, "vibration": true, "quality": "high", "fps": 60, "difficulty": "normal", "race_laps": 1}

func _ready() -> void:
	get_tree().quit_on_go_back = false
	load_save()
	apply_settings()

func snapshot() -> Dictionary:
	return {"version": 2, "cap_progress": cap_progress, "coins": coins, "caps": unlocked_caps, "circuits": unlocked_circuits, "skins": unlocked_skins, "best_times": best_times, "settings": settings, "selected_cap": selected_cap, "selected_circuit": selected_circuit, "selected_skin": selected_skin, "championships": championships, "seen_champion_intros": seen_champion_intros}

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
	if not parsed is Dictionary or parsed.get("version") not in [1, 2]:
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
	unlocked_caps = valid_ids(parsed.get("caps", []), RacingCatalog.cap_ids(), ["sol", "coral"])
	unlocked_circuits = valid_ids(parsed.get("circuits", []), RacingCatalog.circuit_ids(), ["fuente"])
	unlocked_skins = valid_ids(parsed.get("skins", []), ["original", "perla"], ["original"])
	cap_progress = {}
	var saved_progress: Variant = parsed.get("cap_progress", {})
	if saved_progress is Dictionary:
		for id in unlocked_caps:
			var entry: Variant = saved_progress.get(id, {})
			if not entry is Dictionary: continue
			var xp: Variant = entry.get("xp", 0)
			var level: Variant = entry.get("level", 1)
			if not CupProgress.numeric(xp, 0, 9999999) or not CupProgress.numeric(level, 1, PROGRESSION.max_level()): continue
			cap_progress[id] = {"xp": int(xp), "level": mini(int(level), PROGRESSION.eligible_level(int(xp)))}
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
		var saved_laps: Variant = saved_settings.get("race_laps", 1)
		settings.race_laps = int(saved_laps) if (saved_laps is float or saved_laps is int) and float(saved_laps) in [1.0, 2.0, 3.0] else 1
	settings.music = clampf(float(settings.music), 0, 1)
	settings.effects = clampf(float(settings.effects), 0, 1)
	if settings.quality not in ["low", "high"]:
		settings.quality = "high"
	if settings.difficulty not in ["easy", "normal", "hard", "expert"]:
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
	championships = CupProgress.sanitize(parsed.get("championships", {}))
	var champion_ids: Array = []
	for cup in RacingCatalog.championships(): champion_ids.append(cup.champion_id)
	seen_champion_intros = valid_ids(parsed.get("seen_champion_intros", []), champion_ids, [])
	if not championships.active.is_empty() and championships.active.cap_id not in unlocked_caps:
		championships.active = {}
	return true

func cup_transaction(next: Dictionary, reward: int = 0, xp_cap: String = "", xp: int = 0) -> bool:
	var previous := championships
	var previous_coins := coins
	var previous_progress := cap_progress.duplicate(true)
	championships = next
	coins += reward
	add_cap_xp(xp_cap, xp)
	if save(): return true
	championships = previous
	coins = previous_coins
	cap_progress = previous_progress
	changed.emit()
	return false

func mark_champion_intro_seen(id: String) -> bool:
	if id in seen_champion_intros: return true
	var known := false
	for cup in RacingCatalog.championships():
		if cup.champion_id == id: known = true
	if not known: return false
	seen_champion_intros.append(id)
	if save(): return true
	seen_champion_intros.erase(id)
	return false

func start_cup(id: String) -> bool:
	var cup := RacingCatalog.championship(id)
	if cup == null or not championships.active.is_empty() or not CupProgress.unlocked(cup, championships.completed): return false
	var next := championships.duplicate(true)
	next.active = {"cup_id": id, "cap_id": selected_cap, "phase": "ready", "rounds": []}
	return cup_transaction(next)

func begin_cup_race() -> bool:
	if championships.active.is_empty() or championships.active.phase not in ["ready", "racing"]: return false
	var next := championships.duplicate(true)
	next.active.phase = "racing"
	if not cup_transaction(next): return false
	cup_race_requested = true
	return true

func submit_cup_round(round_index: int, rows: Array) -> bool:
	var active: Dictionary = championships.active
	if active.is_empty() or active.phase != "racing" or active.rounds.size() != round_index: return false
	var cup := RacingCatalog.championship(active.cup_id)
	var normalized := CupProgress.normalize_round(rows, cup)
	if normalized.is_empty(): return false
	var next := championships.duplicate(true)
	next.active.rounds.append(normalized)
	next.active.phase = "results"
	var reward := 0
	if next.active.rounds.size() == cup.track_ids.size():
		next.active.phase = "complete"
		var table := CupProgress.standings(cup, next.active.rounds)
		var place := 4
		for index in range(table.size()):
			if table[index].id == "player": place = index + 1
		var previous_place := int(next.completed.get(cup.id, 4))
		if place <= 3 and previous_place > 3: reward = cup.coin_reward
		next.completed[cup.id] = mini(previous_place, place)
	var xp := 0
	for index in range(normalized.size()):
		if normalized[index].id == "player" and normalized[index].finished:
			xp = PROGRESSION.reward(index + 1)
	return cup_transaction(next, reward, active.cap_id, xp)

func continue_cup() -> bool:
	if championships.active.is_empty() or championships.active.phase not in ["results", "complete"]: return false
	var next := championships.duplicate(true)
	if next.active.phase == "complete": next.active = {}
	else: next.active.phase = "ready"
	return cup_transaction(next)

func abandon_cup() -> bool:
	var next := championships.duplicate(true)
	next.active = {}
	return cup_transaction(next)

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

func cap_level(id: String) -> int:
	return int(cap_progress.get(id, {}).get("level", 1))

func cap_xp(id: String) -> int:
	return int(cap_progress.get(id, {}).get("xp", 0))

func add_cap_xp(id: String, amount: int) -> void:
	if id not in unlocked_caps or amount <= 0: return
	cap_progress[id] = {"xp": mini(9999999, cap_xp(id) + amount), "level": cap_level(id)}

func upgrade_cap(id: String) -> bool:
	if id not in unlocked_caps: return false
	var level := cap_level(id)
	if level >= PROGRESSION.max_level() or cap_xp(id) < PROGRESSION.xp_thresholds[level]: return false
	var cost := PROGRESSION.upgrade_costs[level - 1]
	if coins < cost: return false
	var previous := cap_progress.duplicate(true)
	var previous_coins := coins
	coins -= cost
	cap_progress[id] = {"xp": cap_xp(id), "level": level + 1}
	if save(): return true
	coins = previous_coins
	cap_progress = previous
	changed.emit()
	return false

func record_result(key: String, time: float, place: int, cap_id: String = "") -> int:
	if not is_finite(time) or time <= 0 or place < 1 or place > 4: return -1
	if cap_id.is_empty(): cap_id = selected_cap
	if cap_id not in unlocked_caps: return -1
	var previous_coins := coins
	var previous_times := best_times.duplicate(true)
	var previous_progress := cap_progress.duplicate(true)
	var reward: int = [80, 45, 25, 15][clampi(place - 1, 0, 3)]
	coins += reward
	add_cap_xp(cap_id, PROGRESSION.reward(place))
	if time < float(best_times.get(key, INF)):
		best_times[key] = time
	if not save():
		coins = previous_coins
		best_times = previous_times
		cap_progress = previous_progress
		changed.emit()
		return -1
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
