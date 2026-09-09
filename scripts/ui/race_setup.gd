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
	var update_record := func() -> void:
		var key := circuit.record_key(SaveManager.settings.difficulty, SaveManager.settings.race_laps)
		var best := float(SaveManager.best_times.get(key, 0))
		record.text = "Récord local: %.2f s" % best if best > 0 else "Récord local: todavía sin marca"
	for row in options.get_children():
		if row is HBoxContainer:
			for child in row.get_children():
				if child is OptionButton:
					child.item_selected.connect(func(_index: int) -> void: update_record.call())
	update_record.call()
	add_child(RacingUI.label("Una vuelta: 60–90 s aproximadamente.\nMantén pulsado a izquierda o derecha para girar.\nDesliza para impulsarte; toca TURBO cuando tenga energía.\nRecoge burbujas y recargas al pasar sobre ellas.", 17))
	add_child(RacingUI.button("¡A CORRER!", func() -> void:
		SaveManager.save()
		get_tree().change_scene_to_file("res://levels/race.tscn")
	))
