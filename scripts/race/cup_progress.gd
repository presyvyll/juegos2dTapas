class_name CupProgress
extends RefCounted
## Saved race results are authoritative; aggregate points are always derived.

static func participants(cup: ChampionshipDefinition) -> Array[String]:
	var ids: Array[String] = ["player"]
	ids.append_array(cup.rival_ids)
	return ids

static func numeric(value: Variant, minimum: float, maximum: float) -> bool:
	return (value is float or value is int) and is_finite(float(value)) and value >= minimum and value <= maximum

static func normalize_round(value: Variant, cup: ChampionshipDefinition) -> Array:
	if not value is Array or value.size() != 4:
		return []
	var ids := participants(cup)
	var result: Array = []
	for row in value:
		if not row is Dictionary or row.get("id") not in ids or not row.get("finished") is bool:
			return []
		if not numeric(row.get("time"), 0, 180 * cup.laps) or not numeric(row.get("progress"), 0, 12 * cup.laps):
			return []
		ids.erase(row.id)
		result.append({"id": row.id, "finished": row.finished, "time": float(row.time) if row.finished else 180.0 * cup.laps, "progress": float(row.progress)})
	result.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if a.finished != b.finished: return a.finished
		if a.finished and a.time != b.time: return a.time < b.time
		if not a.finished and a.progress != b.progress: return a.progress > b.progress
		return a.id < b.id
	)
	return result

static func standings(cup: ChampionshipDefinition, rounds: Array) -> Array:
	var table := {}
	for id in participants(cup):
		table[id] = {"id": id, "points": 0, "wins": 0, "seconds": 0, "last": 5, "time": 0.0}
	for result in rounds:
		for index in range(result.size()):
			var row: Dictionary = result[index]
			var total: Dictionary = table[row.id]
			total.points += cup.position_points[index] if row.finished else 0
			total.wins += int(row.finished and index == 0)
			total.seconds += int(row.finished and index == 1)
			total.last = index + 1
			total.time += row.time
	var ordered: Array = table.values()
	ordered.sort_custom(compare)
	return ordered

static func compare(a: Dictionary, b: Dictionary) -> bool:
	for field in ["points", "wins", "seconds"]:
		if a[field] != b[field]: return a[field] > b[field]
	for field in ["last", "time"]:
		if a[field] != b[field]: return a[field] < b[field]
	return a.id < b.id

static func unlocked(cup: ChampionshipDefinition, completed: Dictionary) -> bool:
	return cup.prerequisite_cup_id.is_empty() or int(completed.get(cup.prerequisite_cup_id, 4)) <= 3

static func sanitize(value: Variant) -> Dictionary:
	var result := {"active": {}, "completed": {}, "track_records": {}}
	if not value is Dictionary: return result
	var records: Variant = value.get("track_records", {})
	if records is Dictionary:
		for definition in RacingCatalog.championships():
			var entries: Variant = records.get(definition.id, {})
			if not entries is Dictionary: continue
			var clean_records := {}
			for index in range(definition.track_ids.size()):
				var record: Variant = entries.get(str(index), {})
				if not record is Dictionary: continue
				if numeric(record.get("stars"), 0, 3) and numeric(record.get("best_time"), 0.001, 180 * definition.laps):
					clean_records[str(index)] = {"stars": int(record.stars), "best_time": float(record.best_time)}
			result.track_records[definition.id] = clean_records
	var completed: Variant = value.get("completed", {})
	if completed is Dictionary:
		for cup in RacingCatalog.championships():
			var place: Variant = completed.get(cup.id)
			if numeric(place, 1, 4) and float(place) == int(place) and unlocked(cup, result.completed):
				result.completed[cup.id] = int(place)
	var active: Variant = value.get("active", {})
	if not active is Dictionary or active.is_empty(): return result
	var cup := RacingCatalog.championship(str(active.get("cup_id", "")))
	if cup == null or not unlocked(cup, result.completed): return result
	if active.get("cap_id") not in RacingCatalog.cap_ids() or active.get("phase") not in ["ready", "racing", "results", "complete"]:
		return result
	var rounds: Variant = active.get("rounds")
	if not rounds is Array or rounds.size() > cup.track_ids.size(): return result
	var clean: Array = []
	for round_value in rounds:
		var normalized := normalize_round(round_value, cup)
		if normalized.is_empty(): return result
		clean.append(normalized)
	if (active.phase == "complete") != (clean.size() == cup.track_ids.size()): return result
	if active.phase == "results" and clean.is_empty(): return result
	if active.phase == "complete" and not result.completed.has(cup.id): return result
	result.active = {"cup_id": cup.id, "cap_id": active.cap_id, "phase": active.phase, "rounds": clean}
	# Recover genuine per-track results from an older active participation only.
	for index in range(clean.size()): record_round(result, cup.id, index, clean[index])
	return result

static func record_round(state: Dictionary, cup_id: String, index: int, rows: Array) -> void:
	if not state.has("track_records"): state.track_records = {}
	if not state.track_records.has(cup_id): state.track_records[cup_id] = {}
	for place in range(rows.size()):
		var row: Dictionary = rows[place]
		if row.id != "player" or not row.finished: continue
		var previous: Dictionary = state.track_records[cup_id].get(str(index), {})
		state.track_records[cup_id][str(index)] = {
			"stars": maxi(int(previous.get("stars", 0)), maxi(0, 3 - place)),
			"best_time": minf(float(previous.get("best_time", INF)), float(row.time))
		}

static func track_record(state: Dictionary, cup_id: String, index: int) -> Dictionary:
	return state.get("track_records", {}).get(cup_id, {}).get(str(index), {})

static func capture(session: RaceSession, cup: ChampionshipDefinition) -> Array:
	var rows: Array = []
	var ids := participants(cup)
	for index in range(session.caps.size()):
		var cap := session.caps[index]
		var in_time := cap.finished and cap.finish_time <= 180.0 * cup.laps
		rows.append({"id": ids[index], "finished": in_time, "time": cap.finish_time if in_time else 180.0 * cup.laps, "progress": (cap.lap - 1) * 12 + cap.checkpoint_index})
	return normalize_round(rows, cup)
