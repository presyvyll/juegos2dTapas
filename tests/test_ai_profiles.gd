extends "res://tests/test_matrix.gd"

const PROFILES := ["equilibrado", "agresivo", "velocista", "tecnico", "defensivo", "oportunista"]

func run() -> void:
	var save := root.get_node("SaveManager")
	save.save_path = "user://ai_profiles_test.json"
	save.cup_race_requested = false
	save.selected_cap = "sol"
	save.settings.race_laps = 1
	var races := 0
	var total_decisions := 0
	var total_passes := 0
	var total_defenses := 0
	var total_recoveries := 0
	var total_avoidance := 0
	var baseline := root.get_child_count()
	var override := "expert" if "--expert" in OS.get_cmdline_user_args() else ("easy" if "--easy" in OS.get_cmdline_user_args() else "")
	var tracks: Array = ["fuente", "tormenta", "eclipse"] if not override.is_empty() else RacingCatalog.circuit_ids()
	for track_id in tracks:
		for group in range(2):
			save.selected_circuit = track_id
			save.settings.difficulty = "normal" if group == 0 else "hard"
			if not override.is_empty(): save.settings.difficulty = override
			var race: Node2D = load("res://levels/race.tscn").instantiate()
			race.ai_seed = 7100 + group
			root.add_child(race)
			await process_frame
			disable_presentation(race)
			race.hud.set_process(false)
			Engine.max_fps = 0
			var session: RaceSession = race.session
			session.running = true
			for i in range(session.caps.size()):
				var cap: RacingCap = session.caps[i]
				cap.active = true
				if i == 0:
					var controller := CapAIController.new()
					controller.cap = cap
					controller.track = race.track
					controller.rng.seed = 997
					controller.rivals = session.caps
					cap.ai = controller
					cap.add_child(controller)
				else:
					cap.ai.profile = load("res://data/ai_profiles/%s.tres" % PROFILES[group * 3 + i - 1])
					cap.ai.rng.seed = 800 + i
					cap.ai.think_timer = 0
			for frame in range(9000):
				await physics_frame
				if session.finish_order.size() == 4: break
			for cap in session.caps:
				if not cap.finished or not cap.position.is_finite() or cap.checkpoint_index != 12:
					failures += 1
					print("FAIL: ", track_id, " ", cap.ai.profile.id, " gate=", cap.checkpoint_index, " pos=", cap.position)
				total_decisions += cap.ai.decision_count
				total_passes += cap.ai.overtake_count
				total_defenses += cap.ai.defense_count
				total_recoveries += cap.ai.recovery_count
				total_avoidance += cap.ai.avoidance_count
				if cap.ai.decision_count > session.elapsed * 6.3 + 4: failures += 1
			races += 1
			print("AI CASE: ", track_id, " group=", group, " arrivals=", session.finish_order.size(), " seconds=", session.elapsed)
			race.queue_free()
			await process_frame
	if root.get_child_count() != baseline: failures += 1
	if total_passes == 0 or total_defenses == 0 or total_avoidance == 0: failures += 1
	print("AI PROFILES: ", races, " races; decisions=", total_decisions, " overtakes=", total_passes, " defenses=", total_defenses, " avoidance=", total_avoidance, " recoveries=", total_recoveries, "; ", failures, " failures")
	for player in root.get_node("AudioManager").players.values(): player.stop()
	for frame in range(10): await process_frame
	quit(failures)
