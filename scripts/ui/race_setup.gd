class_name RaceSetup
extends VBoxContainer

signal change_track_requested
signal change_cap_requested

func _ready() -> void:
	add_theme_constant_override("separation", 8)
	var heading := RacingUI.label("LISTO PARA CORRER", 28)
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(heading)
	var circuit: CircuitDefinition = RacingCatalog.circuits()[0]
	for item in RacingCatalog.circuits():
		if item.id == SaveManager.selected_circuit:
			circuit = item
	var cap: Resource = RacingCatalog.caps()[0]
	for item in RacingCatalog.caps():
		if item.id == SaveManager.selected_cap:
			cap = item

	var summary_card := PanelContainer.new()
	summary_card.add_theme_stylebox_override("panel", RacingUI.tropical_box(Color("4a2413"), 10))
	add_child(summary_card)
	var summary := HBoxContainer.new()
	summary.add_theme_constant_override("separation", 14)
	summary_card.add_child(summary)
	var preview := preload("res://scripts/ui/circuit_preview.gd").new()
	preview.circuit = circuit
	preview.custom_minimum_size = Vector2(180, 92)
	preview.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	summary.add_child(preview)
	var details := VBoxContainer.new()
	details.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	details.add_theme_constant_override("separation", 1)
	summary.add_child(details)
	var eyebrow := RacingUI.label("PISTA ELEGIDA", 13)
	eyebrow.modulate = Color("78f4e5")
	details.add_child(eyebrow)
	details.add_child(RacingUI.label(circuit.display_name, 24))
	var configuration := RacingUI.label("", 16)
	details.add_child(configuration)
	var record := RacingUI.label("", 16)
	details.add_child(record)
	var cap_label := RacingUI.label("Tapa: %s · Nivel %d" % [cap.display_name, SaveManager.cap_level(cap.id)], 17)
	cap_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(cap_label)

	var selection_actions := HBoxContainer.new()
	selection_actions.add_theme_constant_override("separation", 8)
	add_child(selection_actions)
	var change_track := RacingUI.button("CAMBIAR PISTA", func() -> void: change_track_requested.emit())
	change_track.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	selection_actions.add_child(change_track)
	var change_cap := RacingUI.button("CAMBIAR TAPA", func() -> void: change_cap_requested.emit())
	change_cap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	selection_actions.add_child(change_cap)

	var options := SettingsPage.new()
	options.name = "RaceOptions"
	options.race_setup_only = true
	add_child(options)

	var replay_row := HBoxContainer.new()
	replay_row.add_theme_constant_override("separation", 8)
	add_child(replay_row)
	var ghost_toggle := CheckButton.new()
	ghost_toggle.text = "Mostrar mi mejor repetición"
	ghost_toggle.button_pressed = SaveManager.ghost_enabled
	ghost_toggle.toggled.connect(func(enabled: bool) -> void: SaveManager.ghost_enabled = enabled)
	ghost_toggle.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	replay_row.add_child(ghost_toggle)
	var replay := RacingUI.button("VER MEJOR REPETICIÓN", func() -> void:
		SaveManager.ghost_replay_requested = true
		SaveManager.cup_race_requested = false
		SaveManager.save()
		get_tree().change_scene_to_file("res://levels/race.tscn")
	)
	replay_row.add_child(replay)
	var update_record := func() -> void:
		var key := circuit.record_key(SaveManager.settings.difficulty, SaveManager.settings.race_laps)
		var best := float(SaveManager.best_times.get(key, 0))
		var difficulty_names := {"easy": "Fácil", "normal": "Normal", "hard": "Difícil", "expert": "Experto"}
		configuration.text = "Dificultad %s · %d %s · Objetivo: llegar primero" % [difficulty_names.get(SaveManager.settings.difficulty, "Normal"), SaveManager.settings.race_laps, "vuelta" if SaveManager.settings.race_laps == 1 else "vueltas"]
		record.text = "Récord: %.2f s" % best if best > 0 else "Sin récord · completa una carrera para registrarlo"
		var ghost_key := RaceGhost.context_key(circuit, SaveManager.settings.difficulty, SaveManager.settings.race_laps, SaveManager.selected_cap, SaveManager.cap_level(SaveManager.selected_cap))
		var saved := RaceGhost.load_record(ghost_key)
		replay.disabled = saved.is_empty()
		replay.text = "VER REPETICIÓN · %.2f s" % saved.time if not saved.is_empty() else "SIN REPETICIÓN"
	for row in options.get_children():
		if row is HBoxContainer:
			for child in row.get_children():
				if child is OptionButton:
					child.item_selected.connect(func(_index: int) -> void: update_record.call())
	update_record.call()
	var hint := RacingUI.label("Toca los lados para girar · Desliza rápido para un tiro perfecto", 15)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(hint)
	var run := RacingUI.button("CORRER AHORA", func() -> void:
		SaveManager.ghost_replay_requested = false
		SaveManager.save()
		get_tree().change_scene_to_file("res://levels/race.tscn")
	)
	run.custom_minimum_size.y = 64
	RacingUI.set_primary(run)
	add_child(run)
