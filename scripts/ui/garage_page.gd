extends SelectionPage

var portrait: Control
var stage: Control
var name_label: Label
var rarity_label: Label
var state_label: Label
var requirement: Label
var detail: Label
var equip: Button
var unlock: Button
var skin: Button
var bars: Array[ProgressBar] = []
var values: Array[Label] = []
var chips: Array[Button] = []
var bar_motion: Tween
var shown_index := -1
var busy := false
var lock_overlay: Control

func build() -> void:
	index = posmod(index, RacingCatalog.caps().size())
	if not is_instance_valid(portrait): construct()
	if transition: transition.kill()
	busy = false
	apply_cap()
	portrait.position = Vector2.ZERO
	portrait.scale = Vector2.ONE
	portrait.rotation = 0

func construct() -> void:
	custom_minimum_size.x = 900
	add_theme_constant_override("separation", 8)
	var columns := HBoxContainer.new()
	add_child(columns)
	var hero := VBoxContainer.new()
	hero.add_theme_constant_override("separation", 6)
	hero.custom_minimum_size.x = 370
	columns.add_child(hero)
	name_label = RacingUI.label("", 30)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hero.add_child(name_label)
	rarity_label = RacingUI.label("", 17)
	rarity_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hero.add_child(rarity_label)
	var carousel := HBoxContainer.new()
	hero.add_child(carousel)
	var left := RacingUI.button("‹", func() -> void: change_cap(-1))
	left.custom_minimum_size.x = 52
	left.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	carousel.add_child(left)
	stage = Control.new()
	stage.custom_minimum_size = Vector2(230, 180)
	stage.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stage.clip_contents = true
	carousel.add_child(stage)
	portrait = preload("res://scripts/ui/cap_preview.gd").new()
	portrait.animated = true
	portrait.art_scale = 3.0
	portrait.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	stage.add_child(portrait)
	lock_overlay = Control.new()
	lock_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lock_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	stage.add_child(lock_overlay)
	lock_overlay.draw.connect(func() -> void:
		if shown_index < 0 or RacingCatalog.caps()[shown_index].id in SaveManager.unlocked_caps: return
		var center := lock_overlay.size / 2 + Vector2(0, 65)
		lock_overlay.draw_arc(center - Vector2(0, 9), 9, PI, TAU, 16, Color("ffce58"), 4, true)
		lock_overlay.draw_style_box(RacingUI.box(Color("ffce58"), 4), Rect2(center - Vector2(14, 8), Vector2(28, 24)))
		lock_overlay.draw_circle(center + Vector2(0, 2), 3, Color("153e47"))
	)
	var right := RacingUI.button("›", func() -> void: change_cap(1))
	right.custom_minimum_size.x = 52
	right.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	carousel.add_child(right)
	state_label = RacingUI.label("", 20)
	state_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hero.add_child(state_label)
	var stats := VBoxContainer.new()
	stats.add_theme_constant_override("separation", 6)
	stats.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	columns.add_child(stats)
	stats.add_child(RacingUI.label("RENDIMIENTO", 23))
	stats.add_child(RacingUI.label("Nivel: sin progresión de niveles", 16))
	for title in ["Velocidad", "Aceleración", "Control", "Peso", "Resistencia"]:
		var row := HBoxContainer.new()
		stats.add_child(row)
		var label := RacingUI.label(title, 18)
		label.custom_minimum_size.x = 115
		row.add_child(label)
		var bar := ProgressBar.new()
		bar.max_value = 120
		bar.show_percentage = false
		bar.custom_minimum_size.y = 16
		bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(bar)
		bars.append(bar)
		var value := RacingUI.label("", 16)
		value.custom_minimum_size.x = 65
		row.add_child(value)
		values.append(value)
	stats.add_child(RacingUI.label("Habilidad: Turbo de corriente", 18))
	detail = RacingUI.label("Valores base: 100 = estándar. Resistencia individual y mejoras aún no disponibles.", 16)
	detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail.custom_minimum_size.y = 48
	stats.add_child(detail)
	requirement = RacingUI.label("", 17)
	requirement.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(requirement)
	var actions := HBoxContainer.new()
	add_child(actions)
	equip = RacingUI.button("EQUIPAR", equip_cap)
	actions.add_child(equip)
	var upgrade := RacingUI.button("MEJORAR", func() -> void: pass)
	upgrade.disabled = true
	upgrade.tooltip_text = "La progresión de niveles y mejoras todavía no está disponible."
	actions.add_child(upgrade)
	var ability := RacingUI.button("HABILIDAD", func() -> void:
		detail.text = "Turbo de corriente · Usa el control de turbo durante la carrera. Potencia base: %d. No hay habilidades individuales activas." % int(RacingCatalog.caps()[shown_index].boost * 100)
	)
	actions.add_child(ability)
	for button in actions.get_children(): button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	unlock = RacingUI.button("", purchase_cap)
	add_child(unlock)
	var roster := HBoxContainer.new()
	add_child(roster)
	for i in range(RacingCatalog.caps().size()):
		var chip := RacingUI.button(str(i + 1), func() -> void: change_cap(i - index))
		chip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		roster.add_child(chip)
		chips.append(chip)
	skin = RacingUI.button("", change_skin)
	roster.add_child(skin)

func apply_cap() -> void:
	shown_index = index
	var cap := RacingCatalog.caps()[index]
	var owned: bool = cap.id in SaveManager.unlocked_caps
	name_label.text = cap.display_name
	name_label.modulate.a = 1
	rarity_label.text = cap.rarity.replace("_", " ").capitalize()
	portrait.tint = cap.color.lightened(0.25) if SaveManager.selected_skin == "perla" else cap.color
	portrait.appearance = cap.appearance if cap.appearance else CapAppearance.new()
	portrait.modulate = Color.WHITE if owned else Color(0.22, 0.30, 0.33)
	portrait.queue_redraw()
	lock_overlay.queue_redraw()
	state_label.text = "EQUIPADA" if SaveManager.selected_cap == cap.id else ("DISPONIBLE" if owned else "BLOQUEADA")
	state_label.add_theme_color_override("font_color", Color("69e7d4") if owned else Color("ffce58"))
	equip.text = "EQUIPADA" if SaveManager.selected_cap == cap.id else ("EQUIPAR" if owned else "BLOQUEADA")
	equip.disabled = not owned or SaveManager.selected_cap == cap.id
	requirement.text = "Lista para correr" if owned else "Requisito: desbloquea esta tapa por %d monedas" % cap.price
	unlock.text = "DESBLOQUEAR · %d monedas" % cap.price
	unlock.visible = not owned
	unlock.disabled = SaveManager.coins < cap.price
	detail.text = "Valores base: 100 = estándar. Resistencia individual y mejoras aún no disponibles."
	detail.modulate.a = 1
	if not SaveManager.last_save_ok: requirement.text = "No se pudo guardar. Reintenta para conservar el cambio."
	if bar_motion: bar_motion.kill()
	bar_motion = create_tween().set_parallel(true)
	var targets := [cap.speed * 100, cap.acceleration * 100, cap.handling * 100, cap.weight * 100, 0.0]
	for i in range(bars.size()):
		values[i].text = str(int(targets[i])) if i < 4 else "N/D"
		bars[i].modulate.a = 1.0 if i < 4 else 0.35
		bar_motion.tween_property(bars[i], "value", targets[i], 0.30).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	for i in range(chips.size()):
		var entry := RacingCatalog.caps()[i]
		chips[i].text = ("● " if i == index else "○ ") + str(i + 1) + (" ×" if entry.id not in SaveManager.unlocked_caps else "")
		chips[i].tooltip_text = entry.display_name
		chips[i].disabled = i == index
	var has_skin: bool = "perla" in SaveManager.unlocked_skins
	skin.text = ("PERLA · usar original" if SaveManager.selected_skin == "perla" else "ORIGINAL · usar Perla") if has_skin else "PERLA · 75 monedas"
	skin.disabled = not has_skin and SaveManager.coins < 75

func change_cap(step: int) -> void:
	if step == 0: return
	index = posmod(index + step, RacingCatalog.caps().size())
	if transition: transition.kill()
	busy = true
	equip.disabled = true
	unlock.disabled = true
	SaveManager.haptic(12)
	portrait.pivot_offset = portrait.size / 2
	transition = create_tween()
	transition.set_parallel(true)
	transition.tween_property(portrait, "position:x", -sign(step) * 35.0, 0.10)
	transition.tween_property(portrait, "modulate:a", 0.0, 0.10)
	transition.tween_property(name_label, "modulate:a", 0.0, 0.10)
	transition.tween_property(detail, "modulate:a", 0.0, 0.10)
	transition.chain().tween_callback(func() -> void:
		apply_cap()
		portrait.position.x = sign(step) * 35.0
		portrait.scale = Vector2.ONE * 0.90
		portrait.rotation = sign(step) * 0.05
		portrait.modulate.a = 0
		name_label.modulate.a = 0
		detail.modulate.a = 0
	)
	transition.chain().tween_property(portrait, "position:x", 0.0, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	transition.parallel().tween_property(portrait, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	transition.parallel().tween_property(portrait, "rotation", 0.0, 0.25)
	transition.parallel().tween_property(portrait, "modulate:a", 1.0, 0.20)
	transition.parallel().tween_property(name_label, "modulate:a", 1.0, 0.20)
	transition.parallel().tween_property(detail, "modulate:a", 1.0, 0.20)
	transition.chain().tween_callback(func() -> void: busy = false)

func equip_cap() -> void:
	if busy: return
	var cap := RacingCatalog.caps()[shown_index]
	if cap.id not in SaveManager.unlocked_caps: return
	var previous: String = SaveManager.selected_cap
	SaveManager.selected_cap = cap.id
	if not SaveManager.save(): SaveManager.selected_cap = previous
	build()
	if rebuild_callback.is_valid(): rebuild_callback.call()

func purchase_cap() -> void:
	if busy: return
	var cap := RacingCatalog.caps()[shown_index]
	if SaveManager.purchase("caps", cap.id, cap.price): equip_cap()
	else: build()

func change_skin() -> void:
	if busy: return
	if "perla" in SaveManager.unlocked_skins or SaveManager.purchase("skins", "perla", 75):
		var previous: String = SaveManager.selected_skin
		SaveManager.selected_skin = "original" if previous == "perla" else "perla"
		if not SaveManager.save(): SaveManager.selected_skin = previous
	build()
	if rebuild_callback.is_valid(): rebuild_callback.call()

func _input(event: InputEvent) -> void:
	if not is_visible_in_tree(): return
	if event is InputEventScreenTouch:
		if event.pressed and swipe_index == -1 and stage.get_global_rect().has_point(event.position):
			swipe_start = event.position
			swipe_index = event.index
		elif not event.pressed and event.index == swipe_index:
			swipe_index = -1
			var distance: Vector2 = event.position - swipe_start
			if not event.canceled and absf(distance.x) > 60 and absf(distance.x) > absf(distance.y) * 1.5:
				AudioManager.play("ui")
				change_cap(-1 if distance.x > 0 else 1)
				get_viewport().set_input_as_handled()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT: swipe_index = -1
