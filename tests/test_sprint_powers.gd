extends SceneTree
## Deterministic real-physics races; timing includes the three-second countdown.
var failures := 0

func _initialize() -> void:
	call_deferred("run")

func disable_presentation(node: Node) -> void:
	if node.get_script() != null and node.get_script().resource_path in ["res://scripts/visuals/cap_presentation.gd", "res://scripts/visuals/ambient_motion.gd", "res://scripts/visuals/water_surface.gd", "res://scripts/vfx/water_vfx_pool.gd"]:
		node.set_process(false)
	for child in node.get_children(): disable_presentation(child)

func run() -> void:
	var save := root.get_node("SaveManager")
	save.save_path = "user://sprint25_test.json"
	save.best_times = {}
	save.settings.difficulty = "normal"
	save.settings.quality = "low"
	save.selected_cap = "sol"
	await test_inventory()
	if "--unit-only" in OS.get_cmdline_user_args():
		print("SPRINT POWER RULES: %d failures" % failures)
		quit(failures)
		return
	var sum := 0.0
	var count := 0
	var player_wins := 0
	var min_time := INF
	var max_time := 0.0
	for circuit_id in RacingCatalog.circuit_ids():
		var skip := false
		for argument in OS.get_cmdline_user_args():
			if argument.begins_with("--circuit=") and argument.trim_prefix("--circuit=") != circuit_id: skip = true
		if skip: continue
		for seed_value in [37, 109]:
			var requested_seed := -1
			for argument in OS.get_cmdline_user_args():
				if argument.begins_with("--seed="): requested_seed = int(argument.trim_prefix("--seed="))
			if requested_seed >= 0 and requested_seed != seed_value: continue
			save.selected_circuit = circuit_id
			save.settings.race_laps = 1 if seed_value == 37 else 3
			var race: Node2D = load("res://levels/race.tscn").instantiate()
			race.ai_seed = seed_value
			root.add_child(race)
			await process_frame
			disable_presentation(race)
			var controller := CapAIController.new()
			controller.cap = race.player
			controller.track = race.track
			controller.rivals = race.session.caps
			controller.rng.seed = seed_value + 7
			race.player.ai = controller
			race.player.add_child(controller)
			for frame in range(3600):
				await physics_frame
				if race.session.finish_order.size() == 4: break
			var times: Array[float] = []
			var counts: Array[int] = []
			var recoveries: Array[int] = []
			var impacts: Array[int] = []
			for cap in race.session.caps:
				times.append(snappedf(cap.finish_time + 3, 0.01))
				counts.append(cap.race_power.uses)
				recoveries.append(cap.ai.recovery_count if is_instance_valid(cap.ai) else -1)
				impacts.append(cap.ai.impact_count if is_instance_valid(cap.ai) else -1)
				if not cap.finished or cap.race_power.opportunities > 3 or cap.race_power.uses > cap.race_power.opportunities:
					failures += 1
					push_error("Sprint DNF/power failure: %s %s %s" % [circuit_id, cap.racer_name, counts])
			if not race.session.finish_order.is_empty() and race.session.finish_order[0] == race.player: player_wins += 1
			var time: float = race.player.finish_time + 3
			if time < 22 or time > 28: failures += 1
			sum += time
			min_time = minf(min_time, time)
			max_time = maxf(max_time, time)
			count += 1
			print("SPRINT %s laps=%d total_seconds=%s powers=%s recoveries=%s impacts=%s" % [circuit_id, save.settings.race_laps, times, counts, recoveries, impacts])
			race.queue_free()
			await process_frame
	var average := sum / maxi(1, count)
	if average < 22 or average > 28: failures += 1
	print("SPRINT SUMMARY races=%d mean=%.2f range=%.2f..%.2f player_autopilot_wins=%d ai_wins=%d failures=%d" % [count, average, min_time, max_time, player_wins, count - player_wins, failures])
	quit(1 if failures else 0)

func verify(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)

func test_inventory() -> void:
	var cap: RacingCap = load("res://scenes/actors/player_cap.tscn").instantiate()
	root.add_child(cap)
	cap.set_physics_process(false)
	var rival: RacingCap = load("res://scenes/actors/player_cap.tscn").instantiate()
	root.add_child(rival)
	rival.set_physics_process(false)
	rival.position = Vector2(90, 0)
	cap.race_power.rivals.assign([cap, rival])
	for id in RacePower.POWERS:
		cap.race_power.prepared = id
		verify(cap.race_power.use_prepared(), "Power activates: " + id)
		verify(cap.race_power.current == id, "Power identity: " + id)
		cap.race_power.prepared = "turbo"
		verify(not cap.race_power.use_prepared(), "Cannot stack powers")
		cap.race_power.prepared = ""
		cap.race_power.advance(4)
	verify(rival.race_power.disruption > 0 and rival.race_power.slow_time > 0, "Offensive powers affect nearby rival")
	cap.race_power.prepared = "shield"
	cap.race_power.use_prepared()
	cap.velocity = Vector2.ZERO
	cap.receive_push(Vector2(50, 0))
	verify(cap.velocity == Vector2.ZERO, "Shield blocks one attack")
	cap.receive_push(Vector2(50, 0))
	verify(cap.velocity.x == 50, "Shield is consumed")
	cap.race_power.advance(4)
	verify(cap.race_power.equip("wave", 0, Vector2(90, 0)), "Physical choice stores a power")
	verify(not cap.race_power.equip("turbo", 0, Vector2.ZERO), "Only one choice from each physical row")
	verify(cap.race_power.prepared == "wave", "Other lane cannot overwrite same-row choice")
	cap.race_power.prepared = "heavy"
	cap.race_power.use_prepared()
	cap.velocity = Vector2.ZERO
	cap.receive_push(Vector2(100, 0))
	verify(is_equal_approx(cap.velocity.x, 30), "Heavy reduces push by 70 percent")
	cap.race_power.advance(4)
	cap.race_power.prepared = "ghost"
	cap.race_power.use_prepared()
	cap.velocity = Vector2.ZERO
	cap.receive_push(Vector2(100, 0))
	verify(is_equal_approx(cap.velocity.x, 20), "Ghost reduces push by 80 percent")
	cap.race_power.advance(4)
	var pickup := RacingPickup.new()
	pickup.definition = load("res://data/powerups/recharge.tres")
	pickup.position = Vector2(180, 0)
	root.add_child(pickup)
	cap.boost_energy = 0
	cap.race_power.prepared = "magnet"
	cap.race_power.use_prepared()
	cap.race_power.advance(0.1)
	verify(cap.boost_energy == 0.5, "Magnet collects compatible nearby reward")
	pickup.queue_free()
	cap.race_power.advance(4)
	cap.race_power.prepared = "dash"
	cap.race_power.use_prepared()
	cap.race_power.advance(0.5)
	cap.race_power.prepared = "turbo"
	verify(not cap.race_power.use_prepared(), "Cooldown prevents immediate next power")
	cap.race_power.advance(1)
	verify(cap.race_power.use_prepared(), "Prepared power survives cooldown")
	cap.race_power.advance(4)
	cap.race_power.prepared = ""
	cap.race_power.advance(3.1)
	verify(cap.race_power.prepared.is_empty(), "No automatic or timed menu selection")
	cap.finished = true
	verify(not cap.race_power.use_prepared(), "Finished cap cannot use powers")
	cap.queue_free()
	rival.queue_free()
	await process_frame
