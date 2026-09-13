extends SceneTree

var failures := 0

func _initialize() -> void: call_deferred("run")

func check(value: bool, message: String) -> void:
	if not value:
		failures += 1
		print("FAIL: ", message)

func run() -> void:
	var save := root.get_node("SaveManager")
	save.save_path = "user://ai_decisions_test.json"
	save.cup_race_requested = false
	save.selected_circuit = "fuente"
	save.settings.difficulty = "expert"
	save.save()
	save.settings.difficulty = "normal"
	save.load_save()
	check(save.settings.difficulty == "expert", "expert difficulty persists")
	var race: Node2D = load("res://levels/race.tscn").instantiate()
	race.ai_seed = 1234
	root.add_child(race)
	race.session.set_physics_process(false)
	for cap in race.session.caps: cap.set_physics_process(false)
	var cap: RacingCap = race.session.caps[1]
	var ai: CapAIController = cap.ai
	ai.set_physics_process(false)
	check(ai.rivals.size() == 4, "roster shared including later spawns")
	var speed: float = cap.motion.config.current_speed
	var gate: int = cap.checkpoint_index
	var lap: int = cap.lap
	cap.active = true
	var safe := Vector2(race.track.center_at(-100), -100)
	ai.last_safe_position = safe
	cap.position = Vector2(9000, -100)
	for i in range(70): ai._physics_process(1.0 / 60)
	check(cap.position == safe and ai.recovery_count == 1, "outside recovery uses existing safe point")
	check(cap.checkpoint_index == gate and cap.lap == lap, "recovery never grants progress")
	var snapshots: Array = []
	for repeat in range(2):
		var controller := CapAIController.new()
		controller.cap = cap
		controller.track = race.track
		controller.profile = load("res://data/ai_profiles/tecnico.tres")
		controller.rivals = race.session.caps
		controller.rng.seed = 5678
		cap.add_child(controller)
		controller.set_physics_process(false)
		controller._physics_process(0.35)
		snapshots.append([controller.lane, controller.error, controller.target_position, controller.temperament])
		controller.queue_free()
	check(snapshots[0] == snapshots[1], "fixed seed reproduces decisions")
	for difficulty in ["easy", "normal", "hard", "expert"]:
		ai.difficulty = difficulty
		ai.think_timer = 0
		ai._physics_process(0.35)
		check(ai.think_timer >= 0.16 and ai.think_timer <= 0.35, "decision interval bounded")
	var start := Time.get_ticks_usec()
	for i in range(1000): ai._physics_process(0.35)
	var micros := Time.get_ticks_usec() - start
	check(cap.motion.config.current_speed == speed, "decisions never change speed config")
	check(absf(ai.axis) <= 1 and absf(ai.desired_axis) <= 1, "steering bounded")
	cap.active = false
	ai.boost_requested = true
	ai._physics_process(0.35)
	check(not ai.consume_boost(), "no queued turbo while inactive")
	print("AI DECISION CPU: ", micros / 1000.0, " us/decision (desktop, stationary fixture)")
	race.queue_free()
	await process_frame
	for cup in RacingCatalog.championships():
		save.championships.active = {"cup_id": cup.id, "cap_id": "sol", "phase": "racing", "rounds": []}
		save.cup_race_requested = true
		var cup_race: Node2D = load("res://levels/race.tscn").instantiate()
		cup_race.ai_seed = 1234
		root.add_child(cup_race)
		for i in range(1, 4):
			check(cup_race.session.caps[i].ai.profile.id == cup.rival_ids[i - 1], "cup rival uses authored profile")
		cup_race.queue_free()
		await process_frame
	save.cup_race_requested = false
	for player in root.get_node("AudioManager").players.values(): player.stop()
	for frame in range(10): await process_frame
	print("AI DECISIONS: ", failures, " failures")
	quit(failures)
