class_name ProgressionConfig
extends Resource

@export var xp_thresholds := PackedInt32Array([0, 100, 250, 450, 700])
@export var upgrade_costs := PackedInt32Array([100, 175, 250, 350])
@export var finish_xp := PackedInt32Array([30, 24, 18, 12])
@export_range(0.0, 0.02, 0.001) var gain_per_level := 0.01

func max_level() -> int:
	return mini(xp_thresholds.size(), upgrade_costs.size() + 1)

func multiplier(level: int) -> float:
	return 1.0 + (clampi(level, 1, max_level()) - 1) * gain_per_level

func reward(place: int) -> int:
	return finish_xp[clampi(place - 1, 0, finish_xp.size() - 1)]

func eligible_level(xp: int) -> int:
	var result := 1
	for index in range(1, max_level()):
		if xp < xp_thresholds[index]: break
		result = index + 1
	return result
