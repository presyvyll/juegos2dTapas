extends PowerUpDefinition

func apply(cap: RacingCap) -> void:
	cap.boost_energy = minf(1.0, cap.boost_energy + amount)
