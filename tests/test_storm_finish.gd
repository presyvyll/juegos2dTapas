extends "res://tests/test_matrix.gd"
## Regression: Coco missed a gate and looped beyond the finish in this race.
func run() -> void:
	var save := root.get_node("SaveManager")
	save.save_path = "user://storm_finish_test.json"
	save.coins = 0
	save.best_times = {}
	save.selected_circuit = "tormenta"
	save.selected_cap = "menta"
	save.settings.difficulty = "normal"
	save.settings.race_laps = 1
	await simulate(save, 1)
	print("STORM FINISH: %d failures" % failures)
	quit(failures)
