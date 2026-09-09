extends Node2D

const CAP_SCENE := preload("res://scenes/actors/player_cap.tscn")
var track: RaceTrack
var session: RaceSession
var hud: RaceHUD
var player: RacingCap
var rewarded := false
var vfx: WaterVFXPool
var cup: ChampionshipDefinition
var cup_round := 0
var cup_closed := false
var cup_rows: Array = []

func _ready() -> void:
	var selected_id: String = SaveManager.selected_circuit
	if SaveManager.cup_race_requested and not SaveManager.championships.active.is_empty():
		var active: Dictionary = SaveManager.championships.active
		if active.phase == "racing":
			cup = RacingCatalog.championship(active.cup_id)
			cup_round = active.rounds.size()
			selected_id = cup.track_ids[cup_round]
	var circuit := RacingCatalog.circuits()[0]
	for item in RacingCatalog.circuits():
		if item.id == selected_id:
			circuit = item
	circuit = RacingCatalog.load_circuit(circuit)
	if circuit == null:
		get_tree().call_deferred("change_scene_to_file", "res://ui/main_menu.tscn")
		return
	circuit.laps = int(SaveManager.settings.get("race_laps", 1))
	if cup: circuit.laps = cup.laps
	track = RaceTrack.new()
	track.definition = circuit
	track.high_quality = SaveManager.settings.quality == "high"
	add_child(track)
	vfx = WaterVFXPool.new()
	vfx.capacity = 96 if SaveManager.settings.quality == "high" else 48
	add_child(vfx)
	session = RaceSession.new()
	session.circuit = circuit
	add_child(session)
	track.checkpoint_count = session.checkpoint_count
	spawn_racers()
	var water := WaterSurface.new()
	water.track = track
	water.target = player
	track.add_child(water)
	spawn_pickups()
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
	session.countdown_changed.connect(func(value: int) -> void:
		AudioManager.play("ui")
		if value == 0:
			vfx.burst(player.global_position, Vector2.UP, Color("ffdc6c"), 1.3)
			SaveManager.haptic(20)
	)
	player.powerup_received.connect(func(_effect: PowerUpDefinition) -> void:
		AudioManager.play("boost")
		SaveManager.haptic(25)
	)
	AudioManager.set_racing(true)
	get_window().focus_exited.connect(pause_on_focus_loss)

func _physics_process(_delta: float) -> void:
	if cup == null or cup_closed or not is_instance_valid(session) or not session.running: return
	if session.finish_order.size() < 4 and session.elapsed < 180.0 * cup.laps: return
	cup_closed = true
	session.set_physics_process(false)
	session.running = false
	for cap in session.caps:
		cap.active = false
		cap.velocity = Vector2.ZERO
	cup_rows = CupProgress.capture(session, cup)
	save_cup_results()

func save_cup_results() -> void:
	rewarded = true
	player.controls.clear()
	hud.countdown_label.hide()
	hud.pause_button.disabled = true
	AudioManager.set_racing(false)
	var content := hud.modal("Resultados de copa")
	hud.overlay.offset_top = -300
	hud.overlay.offset_bottom = 300
	if SaveManager.submit_cup_round(cup_round, cup_rows):
		var page := ChampionshipPage.new()
		page.race_results = true
		content.add_child(page)
	else:
		content.add_child(RacingUI.label("No se guardó el resultado. Reintenta antes de continuar.", 17))
		content.add_child(RacingUI.button("Reintentar guardado", save_cup_results))
	content.add_child(RacingUI.button("Volver al menú", menu))

func spawn_pickups() -> void:
	var effects: Array[PowerUpDefinition] = [preload("res://data/powerups/shield.tres"), preload("res://data/powerups/recharge.tres")]
	for index in range(8):
		var pickup := RacingPickup.new()
		pickup.definition = effects[index % effects.size()]
		var y := (-1500.0 - index * 1900) * track.definition.length / 18000.0
		pickup.position = track.pickup_position(y, -100 if index % 2 == 0 else 100)
		add_child(pickup)

func spawn_racers() -> void:
	var definitions := RacingCatalog.caps()
	for index in range(4):
		var cap: RacingCap = CAP_SCENE.instantiate()
		cap.active = false
		cap.track = track
		cap.position = Vector2((index - 1.5) * 85, 40)
		add_child(cap)
		cap.get_node("Visual").fx = vfx
		session.caps.append(cap)
		if index == 0:
			player = cap
			var selected_cap: String = SaveManager.championships.active.cap_id if cup else SaveManager.selected_cap
			for definition in definitions:
				if definition.id == selected_cap:
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
			if cup:
				cap.racer_name = cup.rival_names[index - 1]
				for definition in definitions:
					if definition.id == cup.legacy_rival_cap_ids[index - 1]: cap.apply_definition(definition)
			var controller := CapAIController.new()
			controller.cap = cap
			controller.track = track
			controller.difficulty = SaveManager.settings.difficulty
			if cup: controller.difficulty = cup.difficulty
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
	if cup:
		player.controls.clear()
		player.controls.set_process_unhandled_input(false)
		if hud.countdown_tween: hud.countdown_tween.kill()
		hud.countdown_label.add_theme_font_size_override("font_size", 22)
		hud.countdown_label.add_theme_constant_override("outline_size", 3)
		hud.countdown_label.scale = Vector2.ONE
		hud.countdown_label.modulate.a = 1
		hud.countdown_label.text = "Esperando a los demás corredores…"
		hud.countdown_label.show()
		return
	if rewarded:
		return
	rewarded = true
	player.controls.clear()
	player.controls.set_process_unhandled_input(false)
	var key := track.definition.record_key(SaveManager.settings.difficulty, track.definition.laps)
	var reward := SaveManager.record_result(key, time, place)
	AudioManager.play("victory")
	AudioManager.set_racing(false)
	SaveManager.haptic(80)
	for cap in session.finish_order:
		cap.get_node("Visual").victory = true
	vfx.burst(player.global_position, Vector2.UP, Color("ffdc6c"), 1.4)
	if not session.finish_order.is_empty():
		player.get_node("Camera2D").target = session.finish_order[0]
	hud.show_results(place, time, reward)

func restart() -> void:
	if cup_closed: return
	get_tree().paused = false
	get_tree().reload_current_scene()

func menu() -> void:
	SaveManager.cup_race_requested = false
	get_tree().paused = false
	get_tree().change_scene_to_file("res://ui/main_menu.tscn")

func _exit_tree() -> void:
	get_tree().paused = false
	AudioManager.set_racing(false)
