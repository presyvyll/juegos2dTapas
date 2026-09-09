extends SceneTree
## Full-course regression matrix. Uses a separate save file; does not benchmark mobile FPS.

var failures := 0
var rows: Array[Dictionary] = []

func _init() -> void:
	call_deferred("run")

func run() -> void:
	var save := root.get_node("SaveManager")
	save.save_path = "user://matrix_test_save.json"
	save.coins = 0
	save.best_times = {}
	var baseline := root.get_child_count()
	var circuit_ids := RacingCatalog.circuit_ids()
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--circuit="):
			var requested := argument.trim_prefix("--circuit=")
			if requested not in circuit_ids:
				push_error("Unknown circuit: " + requested)
				quit(1)
				return
			circuit_ids = [requested]
	for circuit in circuit_ids:
		for difficulty in ["easy", "normal", "hard"]:
			for cap_id in ["sol", "coral", "menta", "oceano", "uva", "coco"]:
				save.selected_circuit = circuit
				save.selected_cap = cap_id
				save.settings.difficulty = difficulty
				await simulate(save, 1)
	for circuit in circuit_ids:
		save.selected_circuit = circuit
		save.selected_cap = "sol"
		save.settings.difficulty = "normal"
		await simulate(save, 3)
	await process_frame
	if root.get_child_count() != baseline:
		failures += 1
	var file := FileAccess.open("user://matrix_results.json", FileAccess.WRITE)
	file.store_string(JSON.stringify({"failures": failures, "cases": rows}, "  "))
	file.close()
	print("MATRIX: %d races, %d failures. Report: %s" % [rows.size(), failures, ProjectSettings.globalize_path("user://matrix_results.json")])
	quit(1 if failures else 0)

func simulate(save: Node, laps: int) -> void:
	var race: Node2D = load("res://levels/race.tscn").instantiate()
	root.add_child(race)
	await process_frame
	# Rendering is covered separately; preserve all race and hazard physics here.
	if DisplayServer.get_name() == "headless":
		disable_presentation(race)
		race.hud.set_process(false)
	Engine.max_fps = 0
	var session: RaceSession = race.session
	session.circuit = session.circuit.duplicate() as CircuitDefinition
	session.circuit.laps = laps
	session.running = true
	for cap in session.caps:
		cap.active = true
	var controller := CapAIController.new()
	controller.cap = race.player
	controller.track = race.track
	controller.difficulty = save.settings.difficulty
	controller.rng.seed = 997
	race.player.ai = controller
	race.player.add_child(controller)
	for frame in range(8400 * laps):
		await physics_frame
		if session.finish_order.size() == 4:
			break
	var times: Array[float] = []
	for cap in session.caps:
		times.append(cap.finish_time)
		if not cap.finished or not cap.position.is_finite():
			failures += 1
			push_error("Did not finish: %s / %s / %s / %s at %s, checkpoint %d, lap %d" % [save.selected_circuit, save.settings.difficulty, save.selected_cap, cap.racer_name, cap.position, cap.checkpoint_index, cap.lap])
	rows.append({"circuit": save.selected_circuit, "difficulty": save.settings.difficulty, "cap": save.selected_cap, "laps": laps, "finish_times": times, "finished": session.finish_order.size()})
	print("CASE: %s/%s/%s x%d: %s" % [save.selected_circuit, save.settings.difficulty, save.selected_cap, laps, times])
	race.queue_free()
	await process_frame

func disable_presentation(node: Node) -> void:
	if node is CapPresentation or node is AmbientMotion or node is WaterSurface or node is WaterVFXPool:
		node.set_process(false)
	for child in node.get_children():
		disable_presentation(child)
