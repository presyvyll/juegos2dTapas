extends Node2D

const CAP_SCENE := preload("res://scenes/actors/player_cap.tscn")
var track: RaceTrack
var session: RaceSession
var hud: RaceHUD
var player: RacingCap
var rewarded := false

func _ready() -> void:
	var circuit := RacingCatalog.circuits()[0]
	for item in RacingCatalog.circuits():
		if item.id == SaveManager.selected_circuit:
			circuit = item
	track = RaceTrack.new()
	track.definition = circuit
	track.high_quality = SaveManager.settings.quality == "high"
	add_child(track)
	session = RaceSession.new()
	session.circuit = circuit
	add_child(session)
	spawn_racers()
	for index in range(session.checkpoint_count):
		var checkpoint := RaceCheckpoint.new()
		checkpoint.index = index
		var y := -circuit.length * (index + 1) / session.checkpoint_count
		checkpoint.position = Vector2(track.center_at(y), y)
		checkpoint.width = track.width_at(y) + 80
		checkpoint.finish_line = index == session.checkpoint_count - 1
		checkpoint.crossed.connect(session.cross_checkpoint)
		add_child(checkpoint)
	hud = RaceHUD.new()
	hud.session = session
	hud.player = player
	add_child(hud)
	hud.pause_requested.connect(toggle_pause)
	hud.restart_requested.connect(restart)
	hud.menu_requested.connect(menu)
	session.player_finished.connect(on_finish)
	AudioManager.set_racing(true)
	get_window().focus_exited.connect(pause_on_focus_loss)

func spawn_racers() -> void:
	var definitions := RacingCatalog.caps()
	for index in range(4):
		var cap: RacingCap = CAP_SCENE.instantiate()
		cap.active = false
		cap.track = track
		cap.position = Vector2((index - 1.5) * 85, 40)
		add_child(cap)
		session.caps.append(cap)
		if index == 0:
			player = cap
			for definition in definitions:
				if definition.id == SaveManager.selected_cap:
					cap.apply_definition(definition, SaveManager.selected_skin == "perla")
			cap.wall_hit.connect(func(_speed: float) -> void:
				AudioManager.play("collisions")
				SaveManager.haptic(25)
			)
			cap.boosted.connect(func() -> void:
				AudioManager.play("boost")
				SaveManager.haptic(35)
			)
		else:
			cap.get_node("Camera2D").enabled = false
			cap.controls.set_process_unhandled_input(false)
			cap.racer_name = ["", "Lola", "Coco", "Nico"][index]
			cap.apply_definition(definitions[index])
			var controller := CapAIController.new()
			controller.cap = cap
			controller.track = track
			controller.difficulty = SaveManager.settings.difficulty
			controller.rng.seed = track.definition.seed_value + index * 173
			cap.ai = controller
			cap.add_child(controller)
			cap.motion.config.current_speed *= 0.94 if controller.difficulty == "easy" else (1.035 if controller.difficulty == "hard" else 1.0)
	player.get_node("Camera2D").make_current()
	player.get_node("Camera2D").global_position = player.position

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_R:
		restart()

func toggle_pause() -> void:
	if rewarded:
		return
	get_tree().paused = not get_tree().paused
	player.controls.clear()
	if get_tree().paused:
		hud.show_pause()
	else:
		hud.hide_pause()

func pause_on_focus_loss() -> void:
	if not get_tree().paused and not rewarded:
		toggle_pause()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_PAUSED and is_instance_valid(player):
		pause_on_focus_loss()
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		if rewarded:
			menu()
		else:
			toggle_pause()

func on_finish(place: int, time: float) -> void:
	if rewarded:
		return
	rewarded = true
	player.controls.clear()
	player.controls.set_process_unhandled_input(false)
	var key := "%s_%s_%d" % [track.definition.id, SaveManager.settings.difficulty, track.definition.laps]
	var reward := SaveManager.record_result(key, time, place)
	AudioManager.play("victory")
	AudioManager.set_racing(false)
	SaveManager.haptic(80)
	hud.show_results(place, time, reward)

func restart() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()

func menu() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://ui/main_menu.tscn")

func _exit_tree() -> void:
	get_tree().paused = false
	AudioManager.set_racing(false)
