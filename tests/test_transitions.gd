extends SceneTree
## Destroy races while countdown timers are pending; catch stale UI callbacks.

func _init() -> void:
	call_deferred("run")

func run() -> void:
	var save := root.get_node("SaveManager")
	save.save_path = "user://transitions_test_save.json"
	save.selected_cap = "sol"
	save.selected_circuit = "fuente"
	Engine.max_fps = 0
	var baseline := int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))
	for index in range(20):
		var race: Node2D = load("res://levels/race.tscn").instantiate()
		root.add_child(race)
		race.session.countdown = 0.01
		await physics_frame
		await physics_frame
		race.toggle_pause()
		race.toggle_pause()
		race.queue_free()
		await process_frame
	for frame in range(90):
		await physics_frame
	var remaining := int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))
	if remaining != baseline:
		push_error("Nodes retained after transitions: %d -> %d" % [baseline, remaining])
		quit(1)
		return
	print("TRANSITIONS: 20 rapid race restarts, no retained nodes")
	quit()
