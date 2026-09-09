class_name ChampionshipPage
extends VBoxContainer

var index := 0
var race_results := false

func _ready() -> void:
	add_theme_constant_override("separation", 4)
	build()

func line(value: String, size: int = 19) -> void:
	var label := RacingUI.label(value, size)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(label)

func build() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
	var active: Dictionary = SaveManager.championships.active
	var cups := RacingCatalog.championships()
	index = posmod(index, cups.size())
	var cup: ChampionshipDefinition = RacingCatalog.championship(active.cup_id) if not active.is_empty() else cups[index]
	line(cup.display_name, 28)
	if not SaveManager.last_save_ok:
		line("No se pudo guardar. Reintenta para conservar el progreso.", 16)
	if active.is_empty():
		line("%d carreras · %d vuelta(s) · Premio único por podio: %d monedas" % [cup.track_ids.size(), cup.laps, cup.coin_reward])
		var names: PackedStringArray = []
		for id in cup.track_ids:
			for track in RacingCatalog.circuits():
				if track.id == id: names.append(track.display_name)
		line(" → ".join(names), 17)
		line("Rivales: " + ", ".join(cup.rival_names), 17)
		line("Puntos: 10 / 7 / 4 / 2 · Abandono: 0", 17)
		var nav := HBoxContainer.new()
		add_child(nav)
		nav.add_child(RacingUI.button("◀ Anterior", func() -> void: index -= 1; build()))
		nav.add_child(RacingUI.button("Siguiente ▶", func() -> void: index += 1; build()))
		var available := CupProgress.unlocked(cup, SaveManager.championships.completed)
		if not available:
			line("Consigue podio en " + RacingCatalog.championship(cup.prerequisite_cup_id).display_name, 17)
		elif SaveManager.championships.completed.has(cup.id):
			line("Mejor puesto: %d/4 · El premio por podio no se repite." % SaveManager.championships.completed[cup.id], 17)
		var start := RacingUI.button("Iniciar copa con tu tapa seleccionada", func() -> void:
			SaveManager.start_cup(cup.id)
			build()
		)
		start.disabled = not available
		add_child(start)
		return
	line("Carreras completadas: %d/%d · %d vuelta(s) por carrera" % [active.rounds.size(), cup.track_ids.size(), cup.laps], 18)
	if active.phase in ["results", "complete"]:
		line("Última carrera", 19)
		var last: Array = active.rounds.back()
		for place in range(last.size()):
			var row: Dictionary = last[place]
			line("%d. %s · %s · +%d puntos" % [place + 1, racer_name(cup, row.id), "%.2f s" % row.time if row.finished else "DNF", cup.position_points[place] if row.finished else 0], 16)
	if not active.rounds.is_empty():
		line("Clasificación acumulada", 19)
		var table := CupProgress.standings(cup, active.rounds)
		for place in range(table.size()):
			line("%d. %s · %d puntos" % [place + 1, racer_name(cup, table[place].id), table[place].points], 17)
	if active.phase == "complete":
		line("Copa terminada. Tu mejor puesto queda guardado. El premio por podio se entrega una sola vez.", 16)
		add_child(RacingUI.button("Cerrar copa", func() -> void:
			if SaveManager.continue_cup(): return_to_menu()
			else: build()
		))
	elif active.phase == "results":
		add_child(RacingUI.button("Continuar", func() -> void:
			if SaveManager.continue_cup(): launch()
			else: build()
		))
	else:
		var next_name: String = ""
		for track in RacingCatalog.circuits():
			if track.id == cup.track_ids[active.rounds.size()]: next_name = track.display_name
		line("Siguiente: " + next_name + " · Si cierras a mitad, repetirás esta carrera.", 16)
		add_child(RacingUI.button("Correr / reanudar", launch))
	if not race_results and active.phase in ["ready", "racing"]:
		add_child(RacingUI.button("Abandonar copa y descartar esta participación", func() -> void:
			SaveManager.abandon_cup()
			build()
		))

static func racer_name(cup: ChampionshipDefinition, id: String) -> String:
	if id == "player": return "Tú"
	var rival := cup.rival_ids.find(id)
	return cup.rival_names[rival] if rival >= 0 else id

func launch() -> void:
	if SaveManager.begin_cup_race():
		get_tree().paused = false
		get_tree().change_scene_to_file("res://levels/race.tscn")
	else: build()

func return_to_menu() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://ui/main_menu.tscn")
