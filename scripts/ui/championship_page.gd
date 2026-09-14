class_name ChampionshipPage
extends VBoxContainer

var index := 0
var race_results := false
var selected_track := 0
var preparing := false
var swipe_index := -1
var swipe_start := Vector2.ZERO
var cup_header: Control
var entrance: Tween

func _ready() -> void:
	add_theme_constant_override("separation", 4)
	var active: Dictionary = SaveManager.championships.active
	if active.is_empty():
		for i in range(RacingCatalog.championships().size()):
			if RacingCatalog.championships()[i].id == SaveManager.viewed_cup_id: index = i
	if not active.is_empty():
		for i in range(RacingCatalog.championships().size()):
			if RacingCatalog.championships()[i].id == active.cup_id: index = i
		selected_track = mini(active.rounds.size(), RacingCatalog.championship(active.cup_id).track_ids.size() - 1)
	build()

func line(value: String, size: int = 19) -> void:
	var label := RacingUI.label(value, size)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(label)

func build() -> void:
	var active: Dictionary = SaveManager.championships.active
	if race_results or (not active.is_empty() and active.phase in ["results", "complete"]):
		build_summary()
	else:
		build_map()

func build_summary() -> void:
	if entrance: entrance.kill()
	modulate.a = 1.0
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
			if last[place].id == "player":
				var stars := maxi(0, 3 - place) if last[place].finished else 0
				line("Esta ronda: " + "★".repeat(stars) + "☆".repeat(3 - stars), 21)
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
		line("Siguiente ronda disponible en el mapa.", 16)
		add_child(RacingUI.button("Continuar", func() -> void:
			if SaveManager.continue_cup(): return_to_menu()
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

func build_map() -> void:
	if entrance: entrance.kill()
	modulate.a = 1.0
	for child in get_children():
		remove_child(child)
		child.queue_free()
	custom_minimum_size.x = 860
	var cups := RacingCatalog.championships()
	index = posmod(index, cups.size())
	var cup := cups[index]
	SaveManager.viewed_cup_id = cup.id
	selected_track = clampi(selected_track, 0, cup.track_ids.size() - 1)
	var active: Dictionary = SaveManager.championships.active
	var current := not active.is_empty() and active.cup_id == cup.id
	var completed: int = active.rounds.size() if current else 0
	var available := CupProgress.unlocked(cup, SaveManager.championships.completed)
	cup_header = HBoxContainer.new()
	add_child(cup_header)
	cup_header.add_child(RacingUI.button("‹", func() -> void: change_cup(-1)))
	var trophy := Control.new()
	trophy.custom_minimum_size = Vector2(44, 44)
	trophy.mouse_filter = Control.MOUSE_FILTER_IGNORE
	trophy.draw.connect(func() -> void:
		trophy.draw_colored_polygon(PackedVector2Array([Vector2(11, 7), Vector2(33, 7), Vector2(30, 24), Vector2(22, 30), Vector2(14, 24)]), cup.champion_accent)
		trophy.draw_arc(Vector2(11, 14), 7, PI / 2, PI * 1.5, 12, cup.champion_accent, 3, true)
		trophy.draw_arc(Vector2(33, 14), 7, -PI / 2, PI / 2, 12, cup.champion_accent, 3, true)
		trophy.draw_line(Vector2(22, 28), Vector2(22, 36), cup.champion_accent, 4)
		trophy.draw_line(Vector2(13, 38), Vector2(31, 38), cup.champion_accent, 4)
	)
	cup_header.add_child(trophy)
	var title := RacingUI.label("COPA %d/%d · %s" % [index + 1, cups.size(), cup.display_name], 26)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", cup.champion_accent)
	cup_header.add_child(title)
	cup_header.add_child(RacingUI.button("›", func() -> void: change_cup(1)))
	var stars := 0
	var finished_tracks := 0
	for i in range(cup.track_ids.size()):
		var record := CupProgress.track_record(SaveManager.championships, cup.id, i)
		stars += int(record.get("stars", 0))
		finished_tracks += int(not record.is_empty())
	var state := "DISPONIBLE" if available else "BLOQUEADA"
	if SaveManager.championships.completed.has(cup.id): state = "COMPLETADA · mejor puesto %d/4" % SaveManager.championships.completed[cup.id]
	if current: state = "EN CURSO · ronda %d/%d" % [completed + 1, cup.track_ids.size()]
	line("%s · %d/%d ★ · Pistas terminadas: %d/%d" % [state, stars, cup.track_ids.size() * 3, finished_tracks, cup.track_ids.size()], 17)
	if not available:
		line("Desbloqueo: consigue podio en " + RacingCatalog.championship(cup.prerequisite_cup_id).display_name, 17)
	if not SaveManager.last_save_ok: line("No se pudo guardar. Reintenta para conservar el cambio.", 16)
	if preparing:
		build_preparation(cup)
		return
	var route := preload("res://scripts/ui/cup_route.gd").new()
	route.cup = cup
	route.completed = completed
	route.available = available and (active.is_empty() or current)
	route.selected_index = selected_track
	route.records = SaveManager.championships.get("track_records", {}).get(cup.id, {})
	route.selected.connect(func(value: int) -> void: selected_track = value; build())
	add_child(route)
	var track := track_entry(cup.track_ids[selected_track])
	var card := HBoxContainer.new()
	add_child(card)
	var preview := preload("res://scripts/ui/circuit_preview.gd").new()
	preview.circuit = track
	card.add_child(preview)
	var details := VBoxContainer.new()
	details.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.add_child(details)
	details.add_child(RacingUI.label(track.display_name, 23))
	details.add_child(RacingUI.label("Vista ilustrativa · Dificultad %d/10 · %d vuelta(s)" % [track.difficulty_rating, cup.laps], 16))
	var record := CupProgress.track_record(SaveManager.championships, cup.id, selected_track)
	details.add_child(RacingUI.label("Récord en esta copa: %.2f s" % record.best_time if not record.is_empty() else "Récord en esta copa: sin marca", 16))
	var description := RacingUI.label(track.description, 16)
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	details.add_child(description)
	if selected_track == cup.track_ids.size() - 1:
		build_champion(cup, details)
		if current and selected_track == completed: line("DESAFÍO FINAL DESBLOQUEADO", 19)
	if current:
		var can_run := selected_track == completed and active.phase in ["ready", "racing"]
		var run := RacingUI.button("PREPARAR CARRERA" if can_run else ("RONDA YA DISPUTADA" if selected_track < completed else "COMPLETA LA RONDA ANTERIOR"), func() -> void: preparing = true; build())
		run.disabled = not can_run
		add_child(run)
		var abandon := RacingUI.button("Abandonar esta participación", func() -> void:
			if SaveManager.abandon_cup(): selected_track = 0
			build()
		)
		add_child(abandon)
	elif active.is_empty():
		line("Premio único por podio: %d monedas · Estrellas: 3/2/1 para los tres primeros" % cup.coin_reward, 16)
		var start := RacingUI.button("INICIAR COPA" if available else "COPA BLOQUEADA", func() -> void:
			if SaveManager.start_cup(cup.id): selected_track = 0
			build()
		)
		start.disabled = not available
		add_child(start)
	else:
		add_child(RacingUI.button("Volver a la copa en curso", func() -> void:
			for i in range(cups.size()):
				if cups[i].id == active.cup_id: index = i
			selected_track = active.rounds.size()
			build()
		))
	modulate.a = 0.65
	entrance = create_tween()
	entrance.tween_property(self, "modulate:a", 1.0, 0.25)

func track_entry(id: String) -> CircuitDefinition:
	for entry in RacingCatalog.circuits():
		if entry.id == id: return entry
	return null

func build_champion(cup: ChampionshipDefinition, parent: VBoxContainer) -> void:
	var slot := cup.rival_ids.find(cup.champion_id)
	if slot < 0: return
	var row := HBoxContainer.new()
	parent.add_child(row)
	var portrait := preload("res://scripts/ui/cap_preview.gd").new()
	portrait.custom_minimum_size = Vector2(72, 65)
	portrait.art_scale = 0.8
	row.add_child(portrait)
	for cap in RacingCatalog.caps():
		if cap.id != cup.legacy_rival_cap_ids[slot]: continue
		portrait.appearance = cap.appearance
		portrait.tint = cap.color
		var text := RacingUI.label("FINAL · " + cup.rival_names[slot] + "\n" + (cap.ability.display_name if cap.ability else "Turbo de corriente"), 17)
		text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		row.add_child(text)

func build_preparation(cup: ChampionshipDefinition) -> void:
	var active: Dictionary = SaveManager.championships.active
	if active.is_empty() or active.cup_id != cup.id or active.phase not in ["ready", "racing"]:
		preparing = false
		build()
		return
	var track := track_entry(cup.track_ids[active.rounds.size()])
	line("PREPARA TU CARRERA · " + track.display_name, 26)
	line("Dificultad: %s · %d vuelta(s) · 3 rivales" % [cup.difficulty, cup.laps], 18)
	for cap in RacingCatalog.caps():
		if cap.id == active.cap_id:
			line("Tu tapa: %s · Nivel %d" % [cap.display_name, SaveManager.cap_level(cap.id)], 19)
	line("Objetivo: suma puntos para lograr podio en la copa.", 18)
	line("Rivales: " + ", ".join(cup.rival_names), 17)
	var record := CupProgress.track_record(SaveManager.championships, cup.id, active.rounds.size())
	line("Récord: %.2f s" % record.best_time if not record.is_empty() else "Récord: sin marca", 18)
	add_child(RacingUI.button("CORRER", launch))
	add_child(RacingUI.button("Volver al mapa", go_back))

func change_cup(step: int) -> void:
	if preparing or race_results: return
	index = posmod(index + step, RacingCatalog.championships().size())
	selected_track = 0
	SaveManager.haptic(10)
	build()

func go_back() -> bool:
	if not preparing: return false
	preparing = false
	build()
	return true

func _input(event: InputEvent) -> void:
	if race_results or preparing or not is_visible_in_tree() or not is_instance_valid(cup_header): return
	if event is InputEventScreenTouch:
		if event.pressed and swipe_index == -1 and cup_header.get_global_rect().has_point(event.position):
			swipe_index = event.index
			swipe_start = event.position
		elif not event.pressed and event.index == swipe_index:
			swipe_index = -1
			var distance := event.position - swipe_start
			if not event.canceled and absf(distance.x) > 60 and absf(distance.x) > absf(distance.y) * 1.5:
				AudioManager.play("ui")
				change_cup(-1 if distance.x > 0 else 1)
				get_viewport().set_input_as_handled()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT: swipe_index = -1

func launch() -> void:
	if SaveManager.begin_cup_race():
		get_tree().paused = false
		get_tree().change_scene_to_file("res://levels/race.tscn")
	else: build()

func return_to_menu() -> void:
	SaveManager.return_to_cups = true
	SaveManager.viewed_cup_id = RacingCatalog.championships()[index].id
	get_tree().paused = false
	get_tree().change_scene_to_file("res://ui/main_menu.tscn")
