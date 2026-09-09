extends SceneTree
var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(value: bool, message: String) -> void:
	if not value:
		failures += 1
		print("FAIL: " + message)

func press(node: Node, caption: String) -> bool:
	if node is Button and node.text == caption:
		node.pressed.emit()
		return true
	for child in node.get_children():
		if press(child, caption): return true
	return false

func settle() -> void:
	for frame in range(5): await process_frame

func run() -> void:
	var save := root.get_node("SaveManager")
	save.save_path = "user://cup_flow_test.json"
	save.championships = {"active": {}, "completed": {}}
	save.selected_cap = "sol"
	var menu: Node = load("res://ui/main_menu.tscn").instantiate()
	root.add_child(menu)
	current_scene = menu
	check(press(menu, "COPAS"), "open cup menu")
	check(press(menu, "Iniciar copa con tu tapa seleccionada"), "start through UI")
	check(press(menu, "Correr / reanudar"), "launch through UI")
	await settle()
	var race: Node = current_scene
	check(race.cup != null and race.track.definition.id == "fuente", "cup launch chooses track")
	race.session.running = true
	# Player finishes first, rivals continue; no early transition or free-play reward.
	var before_coins: int = save.coins
	race.player.finished = true
	race.player.active = false
	race.player.finish_time = 65
	race.player.checkpoint_index = 12
	race.session.finish_order.append(race.player)
	race.on_finish(1, 65)
	await settle()
	check(not race.cup_closed and save.championships.active.rounds.is_empty() and save.coins == before_coins, "waits for rivals without paying free-play reward")
	for index in range(1, 4):
		var cap: RacingCap = race.session.caps[index]
		cap.finished = true
		cap.active = false
		cap.finish_time = 65 + index
		cap.checkpoint_index = 12
		race.session.finish_order.append(cap)
	await settle()
	check(save.championships.active.phase == "results", "results saved before continue")
	check(press(race.hud.root, "Continuar"), "continue through UI")
	await settle()
	race = current_scene
	check(race.cup_round == 1 and race.track.definition.id == "jardin", "continues once to next track")
	race.menu()
	await settle()
	menu = current_scene
	check(not save.cup_race_requested and save.read_save(save.save_path), "menu preserves resumable cup")
	check(press(menu, "COPAS") and press(menu, "Correr / reanudar"), "resume through UI")
	await settle()
	race = current_scene
	check(race.cup_round == 1 and race.track.definition.id == "jardin", "mid-race resume repeats only pending round")
	# The backup contains the same participation history if the primary is corrupt.
	save.save()
	var file := FileAccess.open(save.save_path, FileAccess.WRITE)
	file.store_string("{corrupt")
	file.close()
	save.championships = {"active": {}, "completed": {}}
	save.load_save()
	check(save.championships.active.rounds.size() == 1 and save.championships.active.phase == "racing", "backup restores cup history")
	race.menu()
	await settle()
	menu = current_scene
	check(press(menu, "JUGAR") and press(menu, "¡A CORRER!"), "free play remains available")
	await settle()
	race = current_scene
	check(race.cup == null and save.championships.active.rounds.size() == 1, "free play leaves saved cup intact")
	race.queue_free()
	await settle()
	for player in root.get_node("AudioManager").players.values(): player.stop()
	await settle()
	print("CUP FLOW: %d failures" % failures)
	quit(failures)
