extends SceneTree
## A-C authoring validation; never changes the active roster or the real save.
var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(value: bool, message: String) -> void:
	if not value:
		failures += 1
		print("FAIL: " + message)

func run() -> void:
	var live: RacingCatalogData = load("res://data/catalog.tres")
	check(live.caps.size() == 6 and live.circuits.size() == 15, "six active caps and fifteen integrated courses")
	var cup := ChampionshipDefinition.new()
	check(cup.position_points == PackedInt32Array([10, 7, 4, 2]), "cup model matches four racers")
	check(cup.intro_audio == null and cup.race_audio == null and cup.complete_audio == null, "optional audio defaults safely")
	var roster: RacingCatalogData = load("res://data/arcade_content.tres")
	check(roster != null, "authoring manifest loads")
	if roster == null:
		quit(1)
		return
	check(roster.caps.size() == 18, "18 cap resources")
	check(roster.ai_profiles.size() == 10 and roster.rivals.size() == 10, "ten profiles and ten rivals")
	check(roster.circuits.is_empty() and roster.championships.is_empty(), "future tracks and cups are not falsely registered")
	var ids: Array[String] = []
	var archetypes := {}
	var unlocks := {}
	var legacy_ids: Array[String] = []
	var ability_ids: Array[String] = []
	for cap in roster.caps:
		check(cap.id not in ids and not cap.id.is_empty(), "unique cap id")
		ids.append(cap.id)
		archetypes[cap.archetype] = archetypes.get(cap.archetype, 0) + 1
		var milestone := "start" if cap.unlock_method == "start" else cap.unlock_requirement
		unlocks[milestone] = unlocks.get(milestone, 0) + 1
		for old_id in cap.legacy_ids:
			check(old_id not in legacy_ids, "legacy aliases map to exactly one cap")
			legacy_ids.append(old_id)
		check(cap.ratings != null and cap.ratings.budget() == 36, "budget 36: " + cap.id)
		for value in cap.ratings.values():
			check(value >= 1 and value <= 10, "rating range")
		for stat in ["speed", "acceleration", "handling", "weight", "boost"]:
			check(is_equal_approx(float(cap.get(stat)), cap.ratings.multiplier(stat)), "derived multiplier: " + cap.id + "/" + stat)
		check(cap.appearance != null and cap.preferred_ai_profile in roster.ai_profiles, "appearance and AI reference")
		check(cap.ability != null and cap.ability.id not in ability_ids, "separate unique ability resource")
		ability_ids.append(cap.ability.id)
		check(cap.ability.duration >= 0 and cap.ability.duration <= 2, "short ability duration")
		check(cap.ability.cooldown >= 0 and cap.ability.max_uses >= 0, "valid cooldown/uses")
		check(not cap.ability.modifiers.is_empty() and not cap.ability.description.is_empty(), "ability parameters and explanation")
		check(cap.art_requirement.begins_with("TODO_ART_CAP_"), "missing art is explicit")
		check(cap.ability.activation_audio == null, "absent ability audio is safe")
	check(archetypes == {"Equilibrada": 3, "Velocista": 3, "Pesada": 3, "Técnica": 3, "Turbo": 2, "Agresiva": 2, "Especial": 2}, "archetype distribution")
	check(unlocks == {"start": 3, "bronce": 3, "plata": 3, "oro": 3, "maestra": 3, "leyenda": 3}, "18 unlocks across six milestones")
	check(legacy_ids.size() == 6, "six legacy identities have migration candidates")
	for a in roster.caps:
		for b in roster.caps:
			if a == b:
				continue
			var all_at_least := true
			var one_better := false
			for index in range(6):
				all_at_least = all_at_least and a.ratings.values()[index] >= b.ratings.values()[index]
				one_better = one_better or a.ratings.values()[index] > b.ratings.values()[index]
			check(not (all_at_least and one_better), "no cap dominates another in all ratings")
	var profile_ids: Array[String] = []
	for profile in roster.ai_profiles:
		check(profile.id not in profile_ids, "unique profile")
		profile_ids.append(profile.id)
		check(profile.skill_level >= 1 and profile.skill_level <= 10, "profile skill range")
		for field in ["aggression", "risk_tolerance", "boost_usage", "powerup_skill", "overtake_skill", "defensive_skill", "mistake_probability", "recovery_skill"]:
			check(float(profile.get(field)) >= 0 and float(profile.get(field)) <= 1, "profile probability range")
		check(absf(profile.preferred_line) <= 0.6, "profile stays inside channel")
	var champions: Array[String] = []
	var rival_ids: Array[String] = []
	for rival in roster.rivals:
		check(rival.id not in rival_ids, "unique rival id")
		rival_ids.append(rival.id)
		check(rival.favorite_cap in roster.caps and rival.profile in roster.ai_profiles, "rival references use roster resources")
		for powerup in rival.favorite_powerups:
			check(powerup in ["shield", "recharge"], "rival prefers an existing powerup")
		if not rival.champion_cup_id.is_empty():
			check(rival.champion_cup_id not in champions, "one champion per proposed cup")
			champions.append(rival.champion_cup_id)
	check(champions.size() == 5, "five champion identities within the ten rivals")
	check(ResourceSaver.save(roster, "user://arcade_content_roundtrip.tres") == OK, "Resource save succeeds")
	var restored: RacingCatalogData = load("user://arcade_content_roundtrip.tres")
	check(restored != null and restored.caps.size() == 18 and restored.rivals.size() == 10, "typed Resource roundtrip")
	var save := root.get_node("SaveManager")
	save.save_path = "user://content_data_test.json"
	save.selected_cap = "sol"
	save.unlocked_caps = ["sol", "coral", "menta", "oceano", "uva", "coco"]
	check(save.save() and save.read_save(save.save_path), "current player save still loads")
	check(save.selected_cap == "sol" and save.unlocked_caps.size() == 6, "authoring does not migrate or remove existing purchases")
	print("CONTENT DATA: %d failures; 18 caps, 18 abilities, 10 profiles, 10 rivals" % failures)
	quit(failures)
