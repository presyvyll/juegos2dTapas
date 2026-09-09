extends SceneTree
var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(value: bool, message: String) -> void:
	if not value:
		failures += 1
		print("FAIL: " + message)

func result(cup: ChampionshipDefinition, player_place: int = 1, dnf := false) -> Array:
	var ids := CupProgress.participants(cup)
	ids.erase("player")
	ids.insert(player_place - 1, "player")
	var rows: Array = []
	for index in range(4):
		rows.append({"id": ids[index], "finished": not dnf, "time": 60.0 + index, "progress": 12 * cup.laps if not dnf else 5 - index})
	return rows

func run() -> void:
	var save := root.get_node("SaveManager")
	save.save_path = "user://championship_unit_test.json"
	save.championships = {"active": {}, "completed": {}}
	save.coins = 0
	save.selected_cap = "sol"
	var cups := RacingCatalog.championships()
	check(cups.size() == 5, "five registered cups")
	check(not save.start_cup("leyenda"), "later cup requires podium")
	var rewards := 0
	for cup in cups:
		var expected_count: int = {"bronce": 3, "plata": 4, "oro": 5, "maestra": 5, "leyenda": 5}.get(cup.id, 0)
		check(cup.track_ids.size() == expected_count and expected_count > 0, "serialized track list: " + cup.id)
		if cup.track_ids.is_empty():
			quit(1)
			return
		check(cup.rival_ids.size() == 3 and cup.rival_names.size() == 3 and cup.legacy_rival_cap_ids.size() == 3, "fixed roster")
		check(cup.champion_id in cup.rival_ids, "champion stays in roster")
		for id in cup.legacy_rival_cap_ids: check(id in RacingCatalog.cap_ids(), "rival uses active cap")
		for id in cup.track_ids: check(id in RacingCatalog.circuit_ids(), "known course")
		check(save.start_cup(cup.id), "start unlocked " + cup.id)
		check(not save.start_cup(cup.id), "cannot overwrite active cup")
		for index in range(cup.track_ids.size()):
			check(save.begin_cup_race(), "persist launch intent")
			check(save.read_save(save.save_path) and save.championships.active.rounds.size() == index, "mid-race restart preserves completed rounds")
			var rows := result(cup)
			check(save.submit_cup_round(index, rows), "commit race " + cup.id)
			var before_coins: int = save.coins
			check(not save.submit_cup_round(index, rows) and save.coins == before_coins, "duplicate submission does not award")
			check(save.read_save(save.save_path) and save.championships.active.rounds.size() == index + 1, "resume results without reracing")
			var table := CupProgress.standings(cup, save.championships.active.rounds)
			check(table[0].id == "player" and table[0].points == 10 * (index + 1), "cumulative points derived from results")
			check(save.continue_cup(), "continue or close")
		rewards += cup.coin_reward
		check(save.coins == rewards and save.championships.completed[cup.id] == 1, "first podium reward saved atomically")
	# Replaying a completed cup cannot mint its bonus again.
	var cup := cups[0]
	save.start_cup(cup.id)
	for index in range(cup.track_ids.size()):
		save.begin_cup_race()
		save.submit_cup_round(index, result(cup, 2))
		save.continue_cup()
	check(save.coins == rewards and save.championships.completed.bronce == 1, "repeat retains best and unique reward")
	# Fourth place does not unlock the next cup or grant a podium bonus.
	save.championships = {"active": {}, "completed": {}}
	save.start_cup("bronce")
	for index in range(3):
		save.begin_cup_race()
		save.submit_cup_round(index, result(cup, 4))
		save.continue_cup()
	check(not save.start_cup("plata") and save.coins == rewards, "fourth place remains locked")
	# Failed writes leave both participation and wallet unchanged, then can retry.
	save.start_cup("bronce")
	save.begin_cup_race()
	var prior: Dictionary = save.championships.duplicate(true)
	var path: String = save.save_path
	save.save_path = "user://missing_cup_test_directory/save.json"
	check(not save.submit_cup_round(0, result(cup)), "write failure reported")
	check(save.championships == prior and save.coins == rewards, "failed transaction rolls back")
	save.save_path = path
	check(save.submit_cup_round(0, result(cup)), "retry commits exactly once")
	# Malformed optional state cannot destroy the rest of a legacy save.
	for invalid in [null, [], {"active": {"cup_id": "unknown"}}, {"active": {"cup_id": "bronce", "phase": "results", "cap_id": "sol", "rounds": []}}]:
		check(CupProgress.sanitize(invalid).active.is_empty(), "malformed cup state discarded")
	var bad_rows := result(cup)
	bad_rows[1].id = bad_rows[0].id
	check(CupProgress.normalize_round(bad_rows, cup).is_empty(), "duplicate participants rejected")
	var dnf := CupProgress.normalize_round(result(cup, 1, true), cup)
	check(dnf[0].id == "player" and dnf[0].time == 180, "DNF uses valid progress and timeout")
	for row in CupProgress.standings(cup, [dnf]): check(row.points == 0, "DNF awards zero points")
	var a := {"id": "a", "points": 10, "wins": 1, "seconds": 0, "last": 2, "time": 100.0}
	for field in ["points", "wins", "seconds", "last", "time"]:
		var b := a.duplicate()
		b[field] += -1 if field in ["points", "wins", "seconds"] else 1
		check(CupProgress.compare(a, b), "tiebreak: " + field)
	var b := a.duplicate()
	b.id = "b"
	check(CupProgress.compare(a, b), "stable ID tiebreak")
	var legacy: Dictionary = save.snapshot().duplicate(true)
	legacy.erase("championships")
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(legacy))
	file.close()
	check(save.read_save(path) and save.championships.active.is_empty() and save.coins == rewards, "legacy v1 save remains compatible")
	print("CHAMPIONSHIPS: %d failures" % failures)
	quit(failures)
