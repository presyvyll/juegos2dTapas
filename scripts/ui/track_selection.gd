extends SelectionPage

var preparing := false

func go_back() -> bool:
	if not preparing: return false
	preparing = false
	build()
	return true

func build() -> void:
	if transition: transition.kill()
	for child in get_children():
		remove_child(child)
		child.queue_free()
	index = posmod(index, RacingCatalog.circuits().size())
	custom_minimum_size.x = 780
	modulate.a = 0.4
	transition = create_tween()
	transition.tween_property(self, "modulate:a", 1.0, 0.25)
	var track := RacingCatalog.circuits()[index]
	if preparing:
		add_child(RaceSetup.new())
		add_child(RacingUI.button("Volver a pistas", go_back))
		return
	add_child(RacingUI.label(track.display_name, 30))
	var preview := preload("res://scripts/ui/circuit_preview.gd").new()
	preview.circuit = track
	add_child(preview)
	add_child(RacingUI.label("Vista ilustrativa · Pista %d/%d · Dificultad %d/10" % [index + 1, RacingCatalog.circuits().size(), track.difficulty_rating], 17))
	var description := RacingUI.label(track.description, 18)
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(description)
	var best := float(SaveManager.best_times.get(track.record_key(SaveManager.settings.difficulty, SaveManager.settings.race_laps), 0))
	add_child(RacingUI.label("Mejor tiempo / récord local: %.2f s" % best if best > 0 else "Mejor tiempo / récord local: sin marca", 18))
	add_child(RacingUI.label("Estrellas: se muestran por resultado dentro de una copa.", 16))
	var nav := HBoxContainer.new()
	add_child(nav)
	for entry in [["‹ Anterior", -1], ["Siguiente ›", 1]]:
		var step: int = entry[1]
		var button := RacingUI.button(entry[0], func() -> void: index += step; build())
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		nav.add_child(button)
	var owned: bool = track.id in SaveManager.unlocked_circuits
	add_child(RacingUI.label("Disponible" if owned else "Bloqueada · Requisito: %d monedas" % track.price, 18))
	var run := RacingUI.button("CORRER" if owned else "DESBLOQUEAR · %d monedas" % track.price, func() -> void:
		if not owned and not SaveManager.purchase("circuits", track.id, track.price):
			build()
			return
		var previous: String = SaveManager.selected_circuit
		SaveManager.selected_circuit = track.id
		if SaveManager.save(): preparing = true
		else: SaveManager.selected_circuit = previous
		SaveManager.cup_race_requested = false
		build()
		if rebuild_callback.is_valid(): rebuild_callback.call()
	)
	run.disabled = not owned and SaveManager.coins < track.price
	add_child(run)
	if not SaveManager.last_save_ok: add_child(RacingUI.label("No se pudo guardar. Reintenta.", 16))
