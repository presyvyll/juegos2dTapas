class_name CapRatings
extends Resource
## Designer-facing ratings. Never assign these numbers directly to physics.
@export_range(1, 10) var speed: int = 6
@export_range(1, 10) var acceleration: int = 6
@export_range(1, 10) var handling: int = 6
@export_range(1, 10) var weight: int = 6
@export_range(1, 10) var boost: int = 6
@export_range(1, 10) var impact: int = 6

func values() -> Array[int]:
	return [speed, acceleration, handling, weight, boost, impact]

func budget() -> int:
	return speed + acceleration + handling + weight + boost + impact

func multiplier(stat: String) -> float:
	if stat not in ["speed", "acceleration", "handling", "weight", "boost", "impact"]:
		push_error("Unknown rating: " + stat)
		return 1.0
	var rating := clampf(float(get(stat)), 1, 10)
	var low := 0.94 if stat == "speed" else (0.85 if stat == "impact" else 0.8)
	var high := 1.06 if stat == "speed" else (1.15 if stat == "impact" else 1.2)
	return lerpf(low, high, (rating - 1) / 9.0)
