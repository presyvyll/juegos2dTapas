class_name RaceSetup
extends VBoxContainer

func _ready() -> void:
	add_child(RacingUI.label("PREPARA TU CARRERA", 30))
	var circuit: CircuitDefinition = RacingCatalog.circuits()[0]
	for item in RacingCatalog.circuits():
		if item.id == SaveManager.selected_circuit:
			circuit = item
	add_child(RacingUI.label(circuit.display_name, 24))
	var options := SettingsPage.new()
	options.race_setup_only = true
	add_child(options)
	var record := RacingUI.label("", 18)
	add_child(record)
	var ghost_toggle := CheckButton.new()
	ghost_toggle.text = "Mostrar mi mejor ghost en carrera"
	ghost_toggle.button_pressed = SaveManager.ghost_enabled
	ghost_toggle.toggled.connect(func(enabled: bool) -> void: SaveManager.ghost_enabled = enabled)
	add_child(ghost_toggle)
	var replay := RacingUI.button("VER MEJOR REPETICIÓN", func() -> void:
		SaveManager.ghost_replay_requested = true
		SaveManager.cup_race_requested = false
		SaveManager.save()
		get_tree().change_scene_to_file("res://levels/race.tscn")
	)
	add_child(replay)
	var update_record := func() -> void:
		var key := circuit.record_key(SaveManager.settings.difficulty, SaveManager.settings.race_laps)
		var best := float(SaveManager.best_times.get(key, 0))
		record.text = "Récord local: %.2f s" % best if best > 0 else "Récord local: todavía sin marca"
		var ghost_key := RaceGhost.context_key(circuit, SaveManager.settings.difficulty, SaveManager.settings.race_laps, SaveManager.selected_cap, SaveManager.cap_level(SaveManager.selected_cap))
		var saved := RaceGhost.load_record(ghost_key)
		replay.disabled = saved.is_empty()
		replay.text = "VER REPETICIÓN · %.2f s" % saved.time if not saved.is_empty() else "SIN GRABACIÓN PARA ESTA CONFIGURACIÓN"
	for row in options.get_children():
		if row is HBoxContainer:
			for child in row.get_children():
				if child is OptionButton:
					child.item_selected.connect(func(_index: int) -> void: update_record.call())
	update_record.call()
	add_child(RacingUI.label("Una vuelta: 60–90 s aproximadamente.\nMantén pulsado a izquierda o derecha para girar.\nDesliza rápido y horizontal para un Perfect Shot.\nToca TURBO con energía; recoge burbujas y recargas.", 17))
	add_child(RacingUI.button("¡A CORRER!", func() -> void:
		SaveManager.ghost_replay_requested = false
		SaveManager.save()
		get_tree().change_scene_to_file("res://levels/race.tscn")
	))
