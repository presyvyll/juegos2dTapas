class_name BossRaceDefinition
extends Resource
## Tactical preferences only; no physics, energy or checkpoint bonuses.

@export var id := ""
@export_multiline var description := ""
@export var phase_starts := PackedFloat32Array([0.0, 0.3, 0.6])
@export var phase_names := PackedStringArray(["Salida", "Tramo medio", "Cierre"])
@export var phase_preferences: Array[Dictionary] = []

func phase_at(progress: float) -> int:
	var phase := 0
	for index in range(mini(phase_starts.size(), phase_names.size())):
		if progress >= phase_starts[index]: phase = index
	return phase

func profile_for(base: AIProfile, phase: int) -> AIProfile:
	var result := base.duplicate() as AIProfile
	if phase >= phase_preferences.size(): return result
	var overrides := phase_preferences[phase]
	for key in ["aggression", "risk_tolerance", "boost_usage", "overtake_skill", "defensive_skill", "mistake_probability"]:
		if overrides.has(key): result.set(key, clampf(float(overrides[key]), 0.0, 1.0))
	if overrides.has("preferred_line"): result.preferred_line = clampf(float(overrides.preferred_line), -0.6, 0.6)
	if overrides.has("reaction_interval"): result.reaction_interval = clampf(float(overrides.reaction_interval), 0.16, 0.35)
	if overrides.has("corner_anticipation"): result.corner_anticipation = clampf(float(overrides.corner_anticipation), 0.8, 1.35)
	return result
