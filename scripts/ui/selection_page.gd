class_name SelectionPage
extends VBoxContainer

var kind := "caps"
var index := 0
var rebuild_callback: Callable
var transition: Tween
var swipe_start := Vector2.ZERO
var swipe_index := -1

func _ready() -> void:
	var entries: Array = RacingCatalog.caps() if kind == "caps" else RacingCatalog.circuits()
	var selected: String = SaveManager.selected_cap if kind == "caps" else SaveManager.selected_circuit
	for i in range(entries.size()):
		if entries[i].id == selected: index = i
	build()

func _input(event: InputEvent) -> void:
	if kind != "caps" or not is_visible_in_tree(): return
	if event is InputEventScreenTouch:
		var portrait_bounds := Rect2(global_position, Vector2(size.x, 200))
		if event.pressed and swipe_index == -1 and portrait_bounds.has_point(event.position):
			swipe_start = event.position
			swipe_index = event.index
		elif not event.pressed and event.index == swipe_index:
			swipe_index = -1
			var distance: Vector2 = event.position - swipe_start
			if absf(distance.x) > 70 and absf(distance.x) > absf(distance.y) * 1.5:
				index += -1 if distance.x > 0 else 1
				AudioManager.play("ui")
				build()
				get_viewport().set_input_as_handled()

func build() -> void:
	if transition: transition.kill()
	modulate.a = 0.55
	transition = create_tween()
	transition.tween_property(self, "modulate:a", 1.0, 0.25)
	for child in get_children():
		remove_child(child)
		child.queue_free()
	var entries: Array = RacingCatalog.caps() if kind == "caps" else RacingCatalog.circuits()
	index = posmod(index, entries.size())
	var item: Resource = entries[index]
	var title := RacingUI.label(item.display_name, 32)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(title)
	if kind == "caps":
		var preview := preload("res://scripts/ui/cap_preview.gd").new()
		preview.animated = true
		preview.tint = item.color.lightened(0.25) if SaveManager.selected_skin == "perla" else item.color
		preview.appearance = item.appearance if item.appearance else CapAppearance.new()
		add_child(preview)
		var personality := RacingUI.label(item.rarity.replace("_", " ").capitalize() + " · " + preview.appearance.personality + " · Turbo de corriente", 17)
		personality.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		add_child(personality)
		var stats := RacingUI.label("Velocidad %d · Aceleración %d · Manejo %d\nPeso %d · Boost %d" % [item.speed * 100, item.acceleration * 100, item.handling * 100, item.weight * 100, item.boost * 100])
		stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		add_child(stats)
	else:
		var description := RacingUI.label(item.description + "\nPista %d/%d · Dificultad %d/10 · %d vuelta(s)" % [index + 1, entries.size(), item.difficulty_rating, item.laps])
		description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		description.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		add_child(description)
		var key: String = item.record_key(SaveManager.settings.difficulty, item.laps)
		var best := float(SaveManager.best_times.get(key, 0))
		add_child(RacingUI.label("Mejor tiempo: %.2f s" % best if best > 0 else "Mejor tiempo: por descubrir"))
	var navigation := HBoxContainer.new()
	add_child(navigation)
	var previous := RacingUI.button("◀ Anterior", func() -> void: index -= 1; build())
	previous.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	navigation.add_child(previous)
	var next := RacingUI.button("Siguiente ▶", func() -> void: index += 1; build())
	next.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	navigation.add_child(next)
	var unlocked: Array = SaveManager.unlocked_caps if kind == "caps" else SaveManager.unlocked_circuits
	var selected: String = SaveManager.selected_cap if kind == "caps" else SaveManager.selected_circuit
	var owned: bool = item.id in unlocked
	var action_text: String = ("Equipada" if selected == item.id else "Equipar") if owned and kind == "caps" else (("Seleccionada" if selected == item.id else "Seleccionar") if owned else "Bloqueada · Desbloquear por %d monedas" % item.price)
	var action := RacingUI.button(action_text, func() -> void:
		if owned or SaveManager.purchase(kind, item.id, item.price):
			if kind == "caps": SaveManager.selected_cap = item.id
			else: SaveManager.selected_circuit = item.id
			SaveManager.save()
		build()
		rebuild_callback.call()
	)
	action.disabled = (owned and selected == item.id) or (not owned and SaveManager.coins < item.price)
	add_child(action)
	if kind == "caps":
		var has_skin: bool = "perla" in SaveManager.unlocked_skins
		var skin_text := ("Diseño: Perla ✓ · usar original" if SaveManager.selected_skin == "perla" else "Diseño: Original · usar Perla") if has_skin else "Desbloquear diseño Perla · 75 monedas"
		var skin := RacingUI.button(skin_text, func() -> void:
			if has_skin or SaveManager.purchase("skins", "perla", 75):
				SaveManager.selected_skin = "original" if SaveManager.selected_skin == "perla" else "perla"
				SaveManager.save()
			build()
			rebuild_callback.call()
		)
		skin.disabled = not has_skin and SaveManager.coins < 75
		add_child(skin)
