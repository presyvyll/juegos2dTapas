class_name RaceGhost
extends Node2D
## Sampled presentation only: no physics bodies, input or race participation.
const DIRECTORY := "user://ghosts"
const MAX_SAMPLES := 6002
const MAX_BYTES := 1500000
const MAX_FILES := 64
const INTERVAL := 0.1
var session: RaceSession
var racer: RacingCap
var key := ""
var samples: Array = []
var recorded: Array = []
var cursor := 0
var last_sample := -1.0
var exhausted := false
var replay_only := false
var playing := true
var replay_time := 0.0
var best_time := 0.0
var art: CapIllustration
var status := ""

static func context_key(circuit: CircuitDefinition, difficulty: String, laps: int, cap_id: String, level: int) -> String:
	return "%s|ghost1|%s|%s|%d" % [SaveManager.save_path, circuit.record_key(difficulty, laps), cap_id, level]

static func file_path(context: String) -> String:
	return DIRECTORY + "/" + context.sha256_text() + ".json"

static func load_record(context: String) -> Dictionary:
	var file := FileAccess.open(file_path(context), FileAccess.READ)
	if file == null: return {}
	if file.get_length() > MAX_BYTES:
		file.close()
		return {}
	var value: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if not value is Dictionary or value.get("version") != 1 or value.get("key") != context: return {}
	var frames: Variant = value.get("samples")
	if not frames is Array or frames.size() < 2 or frames.size() > MAX_SAMPLES: return {}
	var previous := -1.0
	for frame in frames:
		if not frame is Array or frame.size() != 5: return {}
		for component in frame:
			if not CupProgress.numeric(component, -1000000, 1000000): return {}
		if float(frame[0]) <= previous or frame[0] > 600 or frame[4] < 1 or frame[4] > 3: return {}
		previous = float(frame[0])
	if frames[0][0] != 0 or not CupProgress.numeric(value.get("time"), 0.001, 600): return {}
	if absf(previous - float(value.time)) > 0.001: return {}
	return value

func _ready() -> void:
	art = CapIllustration.new()
	art.appearance = racer.get_node("Visual").appearance
	art.tint = racer.get_node("Visual").tint
	art.modulate = Color(0.7, 1.0, 1.0, 0.35)
	add_child(art)
	var saved := load_record(key)
	if not saved.is_empty():
		samples = saved.samples
		best_time = float(saved.time)
	visible = not samples.is_empty() and SaveManager.ghost_enabled
	session.started.connect(func() -> void: capture(0.0))

func capture(time: float) -> void:
	if exhausted: return
	if recorded.size() >= MAX_SAMPLES or time > 600:
		exhausted = true
		recorded.clear()
		return
	var body: Node2D = racer.get_node("Visual").body
	var point := body.global_position
	var frame := [time, point.x, point.y, body.global_rotation, racer.lap]
	if not recorded.is_empty() and time <= float(recorded.back()[0]):
		recorded[recorded.size() - 1] = frame
	else:
		recorded.append(frame)
	last_sample = time

func _physics_process(delta: float) -> void:
	if replay_only:
		if playing: replay_time = minf(best_time, replay_time + delta)
		if replay_time >= best_time: playing = false
		return
	if session.running and racer.active and not racer.finished and session.elapsed - last_sample >= INTERVAL:
		capture(session.elapsed)

func _process(_delta: float) -> void:
	if samples.is_empty(): return
	var time := replay_time if replay_only else session.elapsed
	visible = replay_only or (SaveManager.ghost_enabled and session.running and not racer.finished and time <= best_time)
	if not visible: return
	while cursor + 1 < samples.size() and float(samples[cursor + 1][0]) <= time: cursor += 1
	var a: Array = samples[cursor]
	var b: Array = samples[mini(cursor + 1, samples.size() - 1)]
	var weight := clampf((time - float(a[0])) / maxf(0.001, float(b[0]) - float(a[0])), 0, 1)
	if a[4] != b[4]: weight = 0.0
	global_position = Vector2(a[1], a[2]).lerp(Vector2(b[1], b[2]), weight)
	art.rotation = lerp_angle(float(a[3]), float(b[3]), weight)
	# The inactive hidden player remains the existing water presentation target.
	if replay_only: racer.global_position = global_position

func restart_replay() -> void:
	cursor = 0
	replay_time = 0.0
	playing = true

func finish(time: float) -> void:
	if replay_only: return
	capture(time)
	if exhausted or recorded.size() < 2:
		status = "Ghost no guardado: límite de grabación."
		return
	if best_time > 0 and time >= best_time:
		status = "Mejor ghost conservado: %.2f s" % best_time
		return
	if DirAccess.make_dir_recursive_absolute(DIRECTORY) != OK:
		status = "No se pudo guardar el ghost."
		return
	var path := file_path(key)
	if not FileAccess.file_exists(path) and DirAccess.get_files_at(DIRECTORY).size() >= MAX_FILES:
		status = "Ghost no guardado: almacenamiento de repeticiones lleno."
		return
	var text := JSON.stringify({"version": 1, "key": key, "time": time, "samples": recorded})
	if text.to_utf8_buffer().size() > MAX_BYTES:
		status = "Ghost no guardado: límite de tamaño."
		return
	var file := FileAccess.open(path + ".tmp", FileAccess.WRITE)
	if file == null:
		status = "No se pudo guardar el ghost."
		return
	file.store_string(text)
	file.flush()
	var error := file.get_error()
	file.close()
	if error != OK or DirAccess.rename_absolute(path + ".tmp", path) != OK:
		status = "No se pudo guardar el ghost; grabación anterior conservada."
		return
	status = "Mejor ghost guardado: %.2f s" % time
