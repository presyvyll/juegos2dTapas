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
var champion_intro: ChampionIntro
var finish_presented := false
var last_impact_feedback := -1000
var saved_free_reward := -1
var combo := RaceCombo.new()
var ghost: RaceGhost
var replay_mode := false
var challenge_metrics := {"perfect_shots": 0, "pickups": 0}
## Set a positive seed for reproducible QA; zero varies decisions between races.
@export var ai_seed := 0

func _ready() -> void:
	replay_mode = SaveManager.ghost_replay_requested
	SaveManager.ghost_replay_requested = false
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
	hud.combo = combo
	add_child(hud)
	hud.pause_requested.connect(toggle_pause)
	hud.restart_requested.connect(restart)
	hud.menu_requested.connect(menu)
	session.player_finished.connect(on_finish)
	session.countdown_changed.connect(func(value: int) -> void:
		AudioManager.play("boost" if value == 0 else "ui")
		if value == 0:
			vfx.burst(player.global_position, Vector2.UP, Color("ffdc6c"), 1.3)
			for rival in session.caps:
				if rival != player: vfx.burst(rival.global_position, Vector2.DOWN, rival.get_node("Visual").appearance.trail_color, 0.55)
			SaveManager.haptic(20)
	)
	player.powerup_received.connect(func(_effect: PowerUpDefinition) -> void:
		AudioManager.play("boost")
		SaveManager.haptic(25)
	)
	player.shot_graded.connect(func(grade: int) -> void:
		var perfect := grade == PerfectShotConfig.Grade.PERFECT
		AudioManager.play("boost" if perfect else "ui")
		SaveManager.haptic(18 if perfect else 12)
		hud.announce(player.controls.perfect_shot.caption(grade) if grade >= 0 else "¡IMPULSO!", 1)
	)
	player.ability_activated.connect(func(effect: CapAbilityDefinition) -> void:
		AudioManager.play("boost")
		SaveManager.haptic(16)
		hud.announce(effect.display_name.to_upper(), 1)
	)
	player.shot_graded.connect(func(grade: int) -> void:
		if grade == PerfectShotConfig.Grade.PERFECT: register_combo("perfect_shot")
	)
	player.boosted.connect(func() -> void: register_combo("turbo"))
	player.powerup_received.connect(func(_effect: PowerUpDefinition) -> void: register_combo("pickup"))
	player.contact_resolved.connect(func(rival: bool, strength: float) -> void:
		if strength >= combo.config.minimum_impact and strength <= combo.config.maximum_controlled_impact:
			register_combo("rival_hit" if rival else "rebound")
	)
	session.position_gained.connect(func(racer: RacingCap) -> void:
		if racer == player: register_combo("overtake")
	)
	combo.advanced.connect(func(count: int, feedback_allowed: bool) -> void:
		if count < 2: return
		hud.show_combo(feedback_allowed)
		if feedback_allowed:
			AudioManager.play("ui")
			SaveManager.haptic(12)
			if count >= combo.config.mega_threshold:
				vfx.burst(player.global_position, Vector2.UP, Color("ffdc6c"), 0.7)
	)
	AudioManager.set_racing(true)
	get_window().focus_exited.connect(pause_on_focus_loss)
	if cup == null:
		ghost = RaceGhost.new()
		ghost.session = session
		ghost.racer = player
		ghost.key = RaceGhost.context_key(track.definition, SaveManager.settings.difficulty, track.definition.laps, player.definition_id, SaveManager.cap_level(player.definition_id))
		add_child(ghost)
		hud.ghost = ghost
		if replay_mode: start_ghost_replay()
	if cup and cup_round == cup.track_ids.size() - 1:
		show_champion_intro()

func show_champion_intro() -> void:
	var champion_index := cup.rival_ids.find(cup.champion_id) + 1
	if champion_index <= 0: return
	session.set_physics_process(false)
	player.controls.clear()
	player.controls.set_process_unhandled_input(false)
	hud.root.hide()
	var champion: RacingCap = session.caps[champion_index]
	player.get_node("Camera2D").target = champion
	champion_intro = ChampionIntro.new()
	champion_intro.cup = cup
	champion_intro.appearance = champion.get_node("Visual").appearance
	champion_intro.tint = champion.get_node("Visual").tint
	champion_intro.can_skip = cup.champion_id in SaveManager.seen_champion_intros
	champion_intro.completed.connect(finish_champion_intro)
	# Separate from the hidden HUD, but under the same CanvasLayer.
	hud.add_child(champion_intro)

func finish_champion_intro() -> void:
	SaveManager.mark_champion_intro_seen(cup.champion_id)
	player.get_node("Camera2D").target = player
	player.controls.clear()
	player.controls.set_process_unhandled_input(true)
	hud.root.show()
	session.set_physics_process(true)

func register_combo(action: String) -> void:
	if get_tree().paused or not session.running or not player.active or player.finished: return
	if action == "perfect_shot": challenge_metrics.perfect_shots = mini(100000, int(challenge_metrics.perfect_shots) + 1)
	elif action == "pickup": challenge_metrics.pickups = mini(100000, int(challenge_metrics.pickups) + 1)
	combo.register(action)

func result_challenge_metrics() -> Dictionary:
	var result := challenge_metrics.duplicate()
	result["best_combo"] = combo.best
	return result

func start_ghost_replay() -> void:
	session.set_physics_process(false)
	hud.set_process(false)
	hud.set_process_unhandled_input(false)
	for cap in session.caps:
		cap.active = false
		cap.hide()
		cap.controls.set_process_input(false)
		cap.controls.set_process_unhandled_input(false)
		cap.get_node("Camera2D").enabled = false
	hud.root.hide()
	if ghost.samples.is_empty():
		get_tree().call_deferred("change_scene_to_file", "res://ui/main_menu.tscn")
		return
	ghost.replay_only = true
	ghost.art.modulate.a = 0.85
	var camera := Camera2D.new()
	ghost.add_child(camera)
	camera.make_current()
	var layer := CanvasLayer.new()
	add_child(layer)
	var bar := HBoxContainer.new()
	bar.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	var safe := RacingUI.safe_insets(get_viewport())
	bar.offset_left = safe.x
	bar.offset_right = -safe.z
	bar.offset_top = safe.y
	bar.theme = RacingUI.theme()
	layer.add_child(bar)
	bar.add_child(RacingUI.label("REPETICIÓN · %.2f s" % ghost.best_time, 22))
	var pause := RacingUI.button("Pausar / seguir", func() -> void: ghost.playing = not ghost.playing)
	bar.add_child(pause)
	bar.add_child(RacingUI.button("Repetir", ghost.restart_replay))
	bar.add_child(RacingUI.button("Volver", menu))
	AudioManager.set_racing(false)

func _physics_process(_delta: float) -> void:
	if is_instance_valid(player) and player.active and not player.finished and session.running:
		combo.advance(_delta)
	if is_instance_valid(champion_intro) and not champion_intro.finished: return
	if cup == null or cup_closed or not is_instance_valid(session) or not session.running: return
	if session.finish_order.size() < 4 and session.elapsed < 180.0 * cup.laps: return
	cup_closed = true
	session.set_physics_process(false)
	session.running = false
	for cap in session.caps:
		cap.active = false
		cap.velocity = Vector2.ZERO
	combo.end_chain()
	cup_rows = CupProgress.capture(session, cup)
	save_cup_results()

func save_cup_results() -> void:
	rewarded = true
	player.controls.clear()
	hud.countdown_label.hide()
	hud.pause_button.disabled = true
	AudioManager.set_racing(false)
	var content := hud.modal("Resultados de copa")
	content.add_child(RacingUI.label("Mejor combo: x%d" % combo.best, 16))
	hud.overlay.offset_top = -300
	hud.overlay.offset_bottom = 300
	if SaveManager.submit_cup_round(cup_round, cup_rows, result_challenge_metrics()):
		var ready := ChallengeProgress.ready_count(SaveManager.challenges)
		if ready > 0: content.add_child(RacingUI.label("%d desafío(s) para reclamar en Premios" % ready, 16))
		content.add_child(RacingUI.label("Progreso de tapa: %d XP · nivel %d" % [SaveManager.cap_xp(player.definition_id), SaveManager.cap_level(player.definition_id)], 16))
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
	var race_rng := RandomNumberGenerator.new()
	if ai_seed == 0: race_rng.randomize()
	else: race_rng.seed = ai_seed
	var personalities := ["equilibrado", "agresivo", "velocista", "tecnico", "defensivo", "oportunista"]
	var first_profile := race_rng.randi_range(0, personalities.size() - 1)
	for index in range(4):
		var cap: RacingCap = CAP_SCENE.instantiate()
		cap.active = false
		cap.track = track
		cap.position = track.starting_slot(index)
		add_child(cap)
		cap.get_node("Visual").fx = vfx
		session.caps.append(cap)
		if index == 0:
			player = cap
			var selected_cap: String = SaveManager.championships.active.cap_id if cup else SaveManager.selected_cap
			for definition in definitions:
				if definition.id == selected_cap:
					cap.apply_definition(definition, SaveManager.selected_skin == "perla", SaveManager.cap_level(selected_cap))
			cap.impacted.connect(func(_point: Vector2, _normal: Vector2, force: float) -> void:
				var now := Time.get_ticks_msec()
				if now - last_impact_feedback < 120: return
				last_impact_feedback = now
				AudioManager.play("collisions")
				if force > 120: SaveManager.haptic(int(clampf(force / 15, 10, 25)))
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
			controller.rng.seed = race_rng.randi()
			controller.rivals = session.caps
			var profile_id: String = personalities[(first_profile + index - 1) % personalities.size()]
			if cup and ResourceLoader.exists("res://data/ai_profiles/%s.tres" % cup.rival_ids[index - 1]):
				profile_id = cup.rival_ids[index - 1]
			controller.profile = load("res://data/ai_profiles/%s.tres" % profile_id)
			if cup and cup_round == cup.track_ids.size() - 1 and cup.rival_ids[index - 1] == cup.champion_id:
				controller.boss_behavior = cup.boss_behavior
				controller.boss_phase_changed.connect(func(phase_name: String, phase: int) -> void:
					if not is_instance_valid(hud) or player.finished: return
					hud.announce("%s · %s" % [cap.racer_name, phase_name.to_upper()], 1)
					if phase > 0:
						if cap.global_position.distance_squared_to(player.global_position) < 1000000:
							vfx.burst(cap.global_position, Vector2.UP, cup.champion_accent, 0.6)
						AudioManager.play("ui")
				)
			cap.ai = controller
			cap.add_child(controller)
			cap.motion.config.current_speed *= 0.94 if controller.difficulty == "easy" else (1.035 if controller.difficulty in ["hard", "expert"] else 1.0)
	player.get_node("Camera2D").make_current()
	player.get_node("Camera2D").global_position = player.position

func _unhandled_input(event: InputEvent) -> void:
	if replay_mode:
		if event is InputEventKey and event.pressed and not event.echo:
			if event.physical_keycode == KEY_ESCAPE: menu()
			elif event.physical_keycode == KEY_R and is_instance_valid(ghost): ghost.restart_replay()
		return
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_R:
		restart()

func toggle_pause() -> void:
	if replay_mode: return
	if rewarded:
		return
	get_tree().paused = not get_tree().paused
	player.controls.clear()
	if get_tree().paused:
		if is_instance_valid(champion_intro): champion_intro.hide()
		hud.root.show()
		hud.show_pause()
	else:
		hud.hide_pause()
		if is_instance_valid(champion_intro) and not champion_intro.finished:
			hud.root.hide()
			champion_intro.show()

func pause_on_focus_loss() -> void:
	if replay_mode:
		if is_instance_valid(ghost): ghost.playing = false
		return
	if not get_tree().paused and not rewarded:
		toggle_pause()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_PAUSED and is_instance_valid(player):
		pause_on_focus_loss()
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		if replay_mode:
			menu()
			return
		if rewarded:
			menu()
		else:
			toggle_pause()

func on_finish(place: int, time: float) -> void:
	if replay_mode: return
	if finish_presented: return
	if is_instance_valid(ghost): ghost.finish(time)
	combo.end_chain()
	finish_presented = true
	player.get_node("Camera2D").celebrate_finish()
	player.get_node("Visual").victory = place == 1
	hud.celebrate_finish(place)
	hud.announce("¡VICTORIA!" if place == 1 else "¡META! · %d.º/%d" % [place, session.caps.size()], 3)
	AudioManager.play("victory" if place == 1 else "ui")
	SaveManager.haptic(45 if place == 1 else 15)
	vfx.burst(player.global_position, Vector2.UP, Color("ffdc6c") if place == 1 else Color("b2fff4"), 1.2)
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
	saved_free_reward = SaveManager.record_result(key, time, place, player.definition_id, result_challenge_metrics())
	AudioManager.set_racing(false)
	# Persist immediately; only presentation waits. Bound tween dies on scene exit.
	var finish_transition := create_tween()
	finish_transition.tween_interval(0.65)
	finish_transition.tween_callback(func() -> void: show_free_result(place, time))

func show_free_result(place: int, time: float) -> void:
	hud.show_results(place, time, saved_free_reward, func() -> void:
		if saved_free_reward < 0:
			var key := track.definition.record_key(SaveManager.settings.difficulty, track.definition.laps)
			saved_free_reward = SaveManager.record_result(key, time, place, player.definition_id, result_challenge_metrics())
		show_free_result(place, time)
	)

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
