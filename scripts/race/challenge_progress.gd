class_name ChallengeProgress
extends RefCounted

static func definitions() -> Array[ChallengeDefinition]:
	var result: Array[ChallengeDefinition] = []
	for path in ["res://data/challenges/finishes.tres", "res://data/challenges/wins.tres", "res://data/challenges/cups.tres", "res://data/challenges/combo.tres", "res://data/challenges/perfect.tres", "res://data/challenges/pickups.tres"]:
		var definition := load(path) as ChallengeDefinition
		if definition != null:
			result.append(definition)
	return result

static func sanitize(value: Variant) -> Dictionary:
	var result := {}
	if not value is Dictionary: return result
	for definition in definitions():
		var entry: Variant = value.get(definition.id, {})
		if not entry is Dictionary: continue
		var progress: Variant = entry.get("progress", 0)
		if not CupProgress.numeric(progress, 0, definition.target): continue
		result[definition.id] = {"progress": int(progress), "claimed": entry.get("claimed") == true and int(progress) == definition.target}
	return result

static func advance(state: Dictionary, metrics: Dictionary) -> Dictionary:
	var result := state.duplicate(true)
	for definition in definitions():
		var amount: Variant = metrics.get(definition.metric, 0)
		if not CupProgress.numeric(amount, 0, 100000): continue
		var entry: Dictionary = result.get(definition.id, {"progress": 0, "claimed": false})
		var progress := maxi(int(entry.progress), int(amount)) if definition.metric == "best_combo" else int(entry.progress) + int(amount)
		entry.progress = mini(definition.target, progress)
		result[definition.id] = entry
	return result

static func ready_count(state: Dictionary) -> int:
	var count := 0
	for definition in definitions():
		var entry: Dictionary = state.get(definition.id, {})
		if int(entry.get("progress", 0)) >= definition.target and not entry.get("claimed", false): count += 1
	return count
