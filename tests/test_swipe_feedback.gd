extends SceneTree

var failures := 0

func _initialize() -> void: call_deferred("run")

func check(value: bool, message: String) -> void:
	if not value:
		failures += 1
		print("FAIL: ", message)

func run() -> void:
	var save := root.get_node("SaveManager")
	save.save_path = "user://swipe_feedback_test.json"
	save.cup_race_requested = false
	save.selected_cap = "sol"
	save.selected_circuit = "fuente"
	var race: Node2D = load("res://levels/race.tscn").instantiate()
	race.ai_seed = 177
	root.add_child(race)
	race.session.set_physics_process(false)
	for cap in race.session.caps: cap.set_physics_process(false)
	var player: RacingCap = race.player
	var events: Array[float] = []
	player.swiped.connect(func(value: float) -> void: events.append(value))
	player.controls.pending_swipe = 1
	player._physics_process(1.0 / 60)
	check(events.is_empty() and player.velocity == Vector2.ZERO, "countdown blocks swipe and feedback")
	player.active = true
	player.currents.clear()
	var flow: Vector2 = race.track.flow_at(player.position.y)
	var impulse := Vector2(-flow.y, flow.x) * player.motion.config.lateral_impulse
	var expected := player.motion.integrate(impulse, 0, 1.0 / 60, flow)
	player._physics_process(1.0 / 60)
	check(events == [1.0] and player.velocity.is_equal_approx(expected), "one signal accompanies unchanged impulse")
	check(race.hud.notice.text == "¡IMPULSO!", "HUD receives applied swipe")
	player.controls.pending_swipe = -1
	player._physics_process(1.0 / 60)
	check(events.size() == 1, "cooldown does not emit misleading feedback")
	player.swipe_cooldown = 0
	player.controls.pending_swipe = -1
	player._physics_process(1.0 / 60)
	check(events == [1.0, -1.0], "both directions supported")
	check(race.vfx.capacity <= 96, "existing effect pool remains bounded")
	race.queue_free()
	await process_frame
	for player_audio in root.get_node("AudioManager").players.values(): player_audio.stop()
	for frame in range(10): await process_frame
	print("SWIPE FEEDBACK: ", failures, " failures")
	quit(failures)
