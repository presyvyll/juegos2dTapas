extends PowerUpDefinition

func apply(cap: RacingCap) -> void:
	cap.shield_time = maxf(cap.shield_time, duration)
