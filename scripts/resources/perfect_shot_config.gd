class_name PerfectShotConfig
extends Resource
## Grades an accepted lateral swipe; never changes movement or rewards.

enum Grade { WEAK, GOOD, GREAT, PERFECT }

@export_range(1, 299, 1) var perfect_duration_ms: int = 140
@export_range(0.0, 1.0, 0.01) var perfect_alignment: float = 0.96
@export_range(1, 299, 1) var great_duration_ms: int = 210
@export_range(0.0, 1.0, 0.01) var great_alignment: float = 0.90
@export_range(1, 299, 1) var good_duration_ms: int = 280
@export_range(0.0, 1.0, 0.01) var good_alignment: float = 0.75

func classify(displacement: Vector2, elapsed_ms: float) -> int:
	if elapsed_ms <= 0 or displacement.length_squared() <= 0:
		return Grade.WEAK
	var alignment := absf(displacement.x) / displacement.length()
	if elapsed_ms <= perfect_duration_ms and alignment >= perfect_alignment:
		return Grade.PERFECT
	if elapsed_ms <= great_duration_ms and alignment >= great_alignment:
		return Grade.GREAT
	if elapsed_ms <= good_duration_ms and alignment >= good_alignment:
		return Grade.GOOD
	return Grade.WEAK

func caption(grade: int) -> String:
	match grade:
		Grade.PERFECT: return "¡PERFECT SHOT!"
		Grade.GREAT: return "¡GENIAL!"
		Grade.GOOD: return "¡BUEN IMPULSO!"
	return "IMPULSO DÉBIL"
