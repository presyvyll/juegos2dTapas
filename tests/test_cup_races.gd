extends "res://tests/test_matrix.gd"
## Real physics, fixed cup rosters, all 22 rounds; isolated from the player save.

func run() -> void:
	var save := root.get_node("SaveManager")
	save.save_path = "user://cup_races_test.json"
	save.selected_cap = "sol"
	save.coins = 0
	save.championships = {"active": {}, "completed": {}}
	var count := 0
	for cup in RacingCatalog.championships():
		# Exercise every cup even if the test autopilot misses a podium.
		if not cup.prerequisite_cup_id.is_empty(): save.championships.completed[cup.prerequisite_cup_id] = 1
		if not save.start_cup(cup.id):
			push_error("Cannot start cup " + cup.id)
			quit(1)
			return
		for index in range(cup.track_ids.size()):
			save.begin_cup_race()
			var race: Node2D = load("res://levels/race.tscn").instantiate()
			root.add_child(race)
			await process_frame
			if is_instance_valid(race.champion_intro):
				await race.champion_intro.completed
			disable_presentation(race)
			race.hud.set_process(false)
			Engine.max_fps = 0
			if race.track.definition.id != cup.track_ids[index] or race.session.circuit.laps != cup.laps: failures += 1
			for rival in range(1, 4):
				if race.session.caps[rival].racer_name != cup.rival_names[rival - 1]: failures += 1
			var controller := CapAIController.new()
			controller.cap = race.player
			controller.track = race.track
			controller.difficulty = cup.difficulty
			controller.rng.seed = 997
			race.player.ai = controller
			race.player.add_child(controller)
			race.session.running = true
			for cap in race.session.caps: cap.active = true
			for frame in range(11000 * cup.laps):
				await physics_frame
				if race.cup_closed: break
			if not race.cup_closed or save.championships.active.rounds.size() != index + 1:
				push_error("Round not persisted: " + cup.id)
				failures += 1
			if race.session.finish_order.size() != 4:
				push_error("Cup racer DNF: " + cup.id + "/" + cup.track_ids[index])
				failures += 1
			count += 1
			print("CUP RACE: %s/%s x%d: %d finishers" % [cup.id, cup.track_ids[index], cup.laps, race.session.finish_order.size()])
			race.queue_free()
			await process_frame
			if not save.read_save(save.save_path): failures += 1
			if not save.continue_cup(): failures += 1
	# Timeout uses DNF without forging finishers; no free-play award is emitted.
	save.start_cup("bronce")
	save.begin_cup_race()
	var race: Node2D = load("res://levels/race.tscn").instantiate()
	root.add_child(race)
	await process_frame
	race.session.running = true
	race.session.elapsed = 180
	await physics_frame
	await process_frame
	if not race.cup_closed or not race.session.finish_order.is_empty(): failures += 1
	for row in save.championships.active.rounds[0]:
		if row.finished or row.time != 180: failures += 1
	race.queue_free()
	await process_frame
	# A saved cup cannot accidentally capture free-play finishes.
	save.cup_race_requested = false
	var free_race: Node2D = load("res://levels/race.tscn").instantiate()
	root.add_child(free_race)
	await process_frame
	if free_race.cup != null: failures += 1
	free_race.queue_free()
	await process_frame
	for player in root.get_node("AudioManager").players.values(): player.stop()
	for frame in range(10): await process_frame
	print("CUP RACES: %d races, %d failures" % [count, failures])
	quit(failures)
