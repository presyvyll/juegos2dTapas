class_name RaceHUD
extends CanvasLayer

const FINISH_CELEBRATION := preload("res://scripts/ui/finish_celebration.gd")
const RACE_START_SIGNAL := preload("res://scripts/ui/race_start_signal.gd")

signal pause_requested
signal restart_requested
signal menu_requested
var session: RaceSession
var player: RacingCap
var root: Control
var info: Label
var boost_bar: ProgressBar
var progress_bar: ProgressBar
var countdown_label: Label
var start_signal: Control
var start_hint: Label
var overlay: PanelContainer
var boost_button: Button
var pause_button: Button
var result_rows: Label
var result_place_label: Label
var result_stats: HBoxContainer
var finish_celebration: Control
var tick := 0.0
var pickup_notice := ""
var pickup_notice_time := 0.0
var position_label: Label
var speed_label: Label
var turbo_label: Label
var ability_label: Label
var countdown_tween: Tween
var result_tween: Tween
var notice: Label
var notice_tween: Tween
var position_tween: Tween
var lap_tween: Tween
var pickup_tween: Tween
var turbo_tween: Tween
var last_place := 0
var last_lap := 1
var last_progress := 0.0
var notice_priority := 0
var notice_time := 0.0
var pass_cooldown := 0.0
var near_finish_shown := false
var combo: RaceCombo
var combo_label: Label
var combo_tween: Tween
var ghost: RaceGhost
var coins_label: Label
var ranking_labels: Array[Label] = []

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	root = Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.theme = RacingUI.theme()
	add_child(root)
	var speed_fx := preload("res://scripts/ui/race_speed_overlay.gd").new()
	speed_fx.player = player
	speed_fx.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(speed_fx)
	var top := HBoxContainer.new()
	top.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	top.offset_left = 24
	top.offset_right = -24
	top.offset_top = 20
	root.add_child(top)
	combo_label = RacingUI.label("", 20)
	combo_label.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	combo_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	combo_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	combo_label.add_theme_color_override("font_color", Color("ffdc6c"))
	combo_label.add_theme_color_override("font_outline_color", Color("10283b"))
	combo_label.add_theme_constant_override("outline_size", 3)
	combo_label.hide()
	root.add_child(combo_label)
	var panel := PanelContainer.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var compact_style := RacingUI.box(Color("103843"), 18)
	compact_style.border_color = Color("368a8d")
	compact_style.border_width_bottom = 3
	compact_style.content_margin_top = 6
	compact_style.content_margin_bottom = 6
	panel.add_theme_stylebox_override("panel", compact_style)
	top.add_child(panel)
	var status_row := HBoxContainer.new()
	panel.add_child(status_row)
	position_label = RacingUI.label("4º", 38)
	position_label.custom_minimum_size.x = 116
	position_label.add_theme_color_override("font_color", Color("ffdc6c"))
	status_row.add_child(position_label)
	position_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	var column := VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_theme_constant_override("separation", 6)
	status_row.add_child(column)
	var summary := HBoxContainer.new()
	column.add_child(summary)
	info = RacingUI.label("", 17)
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	summary.add_child(info)
	speed_label = RacingUI.label("", 22)
	summary.add_child(speed_label)
	coins_label = RacingUI.label("", 17)
	coins_label.add_theme_color_override("font_color", Color("ffdc6c"))
	summary.add_child(coins_label)
	progress_bar = ProgressBar.new()
	progress_bar.custom_minimum_size.y = 10
	progress_bar.show_percentage = false
	column.add_child(progress_bar)
	var ranking := HBoxContainer.new()
	ranking.add_theme_constant_override("separation", 12)
	column.add_child(ranking)
	for index in range(3):
		var racer := RacingUI.label("", 13)
		racer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		racer.custom_minimum_size.x = 48
		racer.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		ranking.add_child(racer)
		ranking_labels.append(racer)
	pause_button = RacingUI.button("Ⅱ Pausa", func() -> void: pause_requested.emit())
	top.add_child(pause_button)
	var bottom := HBoxContainer.new()
	bottom.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	bottom.offset_left = 24
	bottom.offset_right = -24
	bottom.offset_top = -100
	bottom.offset_bottom = -24
	bottom.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(bottom)
	var update_margins := func() -> void:
		var safe := RacingUI.safe_insets(get_viewport())
		top.offset_left = safe.x
		top.offset_top = safe.y
		top.offset_right = -safe.z
		combo_label.offset_left = safe.x + 100
		combo_label.offset_right = -safe.z - 100
		combo_label.offset_top = safe.y + 78
		combo_label.offset_bottom = safe.y + 110
		bottom.offset_left = safe.x
		bottom.offset_right = -safe.z
		bottom.offset_bottom = -safe.w
		bottom.offset_top = -safe.w - 124
	get_viewport().size_changed.connect(update_margins)
	update_margins.call()
	var hints := RacingUI.label("◀ TOCA PARA GIRAR ▶\nSwipe rápido y recto: Perfect Shot")
	if OS.get_name() != "Android":
		hints.text += " · A/D"
	hints.add_theme_font_size_override("font_size", 17)
	hints.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bottom.add_child(hints)
	var boost_column := VBoxContainer.new()
	boost_column.custom_minimum_size.x = 250
	bottom.add_child(boost_column)
	boost_button = RacingUI.button("¡TURBO!", func() -> void: player.controls.boost_requested = true)
	boost_button.custom_minimum_size.y = 64
	boost_button.action_mode = BaseButton.ACTION_MODE_BUTTON_PRESS
	boost_button.focus_mode = Control.FOCUS_NONE
	pause_button.focus_mode = Control.FOCUS_NONE
	boost_column.add_child(boost_button)
	boost_bar = ProgressBar.new()
	boost_bar.custom_minimum_size.y = 14
	boost_bar.show_percentage = false
	boost_column.add_child(boost_bar)
	var energy_fill := RacingUI.box(Color("ffdc6c"), 6)
	energy_fill.set_content_margin_all(0)
	energy_fill.shadow_size = 0
	boost_bar.add_theme_stylebox_override("fill", energy_fill)
	turbo_label = RacingUI.label("TURBO LISTO", 14)
	turbo_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	boost_column.add_child(turbo_label)
	ability_label = RacingUI.label("", 14)
	ability_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ability_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	boost_column.add_child(ability_label)
	bottom.offset_top = -166
	start_signal = RACE_START_SIGNAL.new()
	start_signal.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	start_signal.offset_left = -110
	start_signal.offset_right = 110
	start_signal.offset_top = -205
	start_signal.offset_bottom = -145
	root.add_child(start_signal)
	start_hint = RacingUI.label("SIGUE LA TRAZADA · PREPARA EL IMPULSO", 14)
	start_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	start_hint.add_theme_color_override("font_color", Color("b9fff3"))
	start_hint.add_theme_color_override("font_outline_color", Color("10283b"))
	start_hint.add_theme_constant_override("outline_size", 3)
	start_hint.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	start_hint.offset_left = -260
	start_hint.offset_right = 260
	start_hint.offset_top = -138
	start_hint.offset_bottom = -108
	root.add_child(start_hint)
	countdown_label = RacingUI.label("3", 72)
	countdown_label.add_theme_color_override("font_color", Color("ffdd69"))
	countdown_label.add_theme_color_override("font_outline_color", Color("10283b"))
	countdown_label.add_theme_constant_override("outline_size", 12)
	countdown_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	countdown_label.offset_left = -360
	countdown_label.offset_right = 360
	countdown_label.offset_top = -125
	countdown_label.offset_bottom = -45
	countdown_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(countdown_label)
	notice = RacingUI.label("", 28)
	notice.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	notice.add_theme_color_override("font_color", Color("ffdc6c"))
	notice.add_theme_color_override("font_outline_color", Color("10283b"))
	notice.add_theme_constant_override("outline_size", 4)
	notice.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	notice.offset_left = 48
	notice.offset_right = -48
	notice.offset_top = 125
	notice.offset_bottom = 170
	notice.hide()
	root.add_child(notice)
	session.countdown_changed.connect(animate_countdown)
	player.boosted.connect(func() -> void:
		if turbo_tween: turbo_tween.kill()
		turbo_label.modulate = Color("69e7d4")
		turbo_tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_STOP)
		turbo_tween.tween_property(turbo_label, "modulate", Color.WHITE, 0.30)
	)
	player.powerup_received.connect(func(effect: PowerUpDefinition) -> void:
		pickup_notice = "+ " + effect.display_name
		pickup_notice_time = 1.5
		animate_pickup(effect)
	)
	player.controls.boost_hit_test = func(point: Vector2) -> bool: return boost_button.get_global_rect().has_point(point)
	player.controls.blocked_touch = func(point: Vector2) -> bool: return boost_button.get_global_rect().has_point(point) or pause_button.get_global_rect().has_point(point)
	if OS.get_name() == "Android":
		pause_button.mouse_filter = Control.MOUSE_FILTER_IGNORE
	get_viewport().size_changed.connect(update_touch_rects)
	call_deferred("update_touch_rects")
	set_mouse_passthrough(root)

func _input(event: InputEvent) -> void:
	if OS.get_name() == "Android" and handle_pause_touch(event):
		get_viewport().set_input_as_handled()

func handle_pause_touch(event: InputEvent) -> bool:
	if event is InputEventScreenTouch and event.pressed:
		if is_instance_valid(pause_button) and not pause_button.disabled and pause_button.get_global_rect().has_point(event.position):
			pause_requested.emit()
			return true
	return false

func update_touch_rects() -> void:
	call_deferred("apply_touch_rects")

func apply_touch_rects() -> void:
	player.controls.excluded_rects = [boost_button.get_global_rect(), pause_button.get_global_rect()]

func animate_countdown(value: int) -> void:
	if countdown_tween:
		countdown_tween.kill()
	countdown_label.text = str(value) if value > 0 else "¡YA!"
	start_signal.set_value(value)
	start_signal.show()
	start_signal.modulate.a = 1.0
	start_hint.text = "SIGUE LA TRAZADA · PREPARA EL IMPULSO" if value > 0 else "¡SALIDA LIMPIA!"
	start_hint.show()
	start_hint.modulate.a = 1.0
	countdown_label.show()
	countdown_label.pivot_offset = countdown_label.size / 2
	countdown_label.scale = Vector2.ONE * 1.35
	countdown_label.modulate.a = 1
	countdown_tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_STOP)
	countdown_tween.tween_property(countdown_label, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if value == 0:
		countdown_tween.tween_interval(0.45)
		countdown_tween.tween_property(countdown_label, "modulate:a", 0.0, 0.2)
		countdown_tween.parallel().tween_property(start_signal, "modulate:a", 0.0, 0.2)
		countdown_tween.parallel().tween_property(start_hint, "modulate:a", 0.0, 0.2)
		countdown_tween.tween_callback(func() -> void:
			countdown_label.hide()
			start_signal.hide()
			start_hint.hide()
		)

func set_mouse_passthrough(node: Node) -> void:
	if node is Control and not node is BaseButton:
		node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for child in node.get_children():
		set_mouse_passthrough(child)

func _process(delta: float) -> void:
	if get_tree().paused: return
	pickup_notice_time = maxf(0, pickup_notice_time - delta)
	pass_cooldown = maxf(0, pass_cooldown - delta)
	notice_time = maxf(0, notice_time - delta)
	if notice_time <= 0: notice_priority = 0
	tick += delta
	if tick < 0.1 or not is_instance_valid(player):
		return
	tick = 0
	if combo != null:
		combo_label.visible = session.running and player.active and not player.finished and combo.actions.size() >= 2 and combo.remaining > 0
		if combo_label.visible:
			combo_label.text = combo.caption() + " · %.1f s" % combo.remaining
			combo_label.modulate.a = clampf(combo.remaining / 0.3, 0.0, 1.0)
	player.controls.excluded_rects = [boost_button.get_global_rect(), pause_button.get_global_rect()]
	var standings := session.standings()
	var place := standings.find(player) + 1
	coins_label.text = "MONEDAS %d" % SaveManager.coins
	# A read-only podium; the player's own position always stays in the large badge.
	for index in range(ranking_labels.size()):
		var label := ranking_labels[index]
		label.visible = index < standings.size()
		if not label.visible: continue
		var racer: RacingCap = standings[index]
		label.text = "%d  %s" % [index + 1, "TÚ" if racer == player else racer.racer_name]
		label.add_theme_color_override("font_color", Color("ffdc6c") if racer == player else Color("a4d8d7"))
	var shown_time := player.finish_time if player.finished else session.elapsed
	position_label.text = "%d.º/%d" % [place, session.caps.size()]
	update_race_feedback(place)
	info.text = "VUELTA %d/%d  ·  %.1f s" % [player.lap, session.circuit.laps, shown_time]
	speed_label.text = "%d u/s" % (0.0 if player.finished else player.velocity.length())
	boost_bar.value = player.boost_energy * 100
	ability_label.text = "" if player.finished else player.ability.status()
	if player.ability.definition:
		ability_label.tooltip_text = player.ability.definition.description
	boost_button.disabled = not player.can_boost()
	turbo_label.text = "¡A TODA AGUA!" if player.boost_time > 0 else ("CARGANDO…" if player.boost_energy < player.turbo.energy_cost else "TURBO LISTO")
	if pickup_notice_time > 0:
		turbo_label.text = pickup_notice
	elif player.shield_time > 0:
		turbo_label.text = "BURBUJA · %.1f s" % player.shield_time
	if player.finished: turbo_label.text = "CARRERA TERMINADA"
	player.controls.boost_touch_rect = boost_button.get_global_rect()
	player.controls.boost_touch_enabled = not boost_button.disabled
	progress_bar.value = session.progress(player) / (session.circuit.length * session.circuit.laps) * 100
	if is_instance_valid(result_rows):
		update_results()

func show_combo(animate: bool = true) -> void:
	if combo == null or combo.actions.size() < 2: return
	combo_label.text = combo.caption()
	combo_label.show()
	combo_label.modulate.a = 1.0
	if not animate: return
	if combo_tween: combo_tween.kill()
	combo_label.pivot_offset = combo_label.size / 2
	combo_label.scale = Vector2.ONE * 0.94
	combo_tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_STOP)
	combo_tween.tween_property(combo_label, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func animate_pickup(effect: PowerUpDefinition) -> void:
	if pickup_tween: pickup_tween.kill()
	turbo_label.text = pickup_notice
	turbo_label.pivot_offset = turbo_label.size / 2
	turbo_label.scale = Vector2.ONE * 0.82
	turbo_label.modulate = effect.color.lightened(0.18)
	boost_bar.modulate = effect.color
	pickup_tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_STOP).set_parallel(true)
	pickup_tween.tween_property(turbo_label, "scale", Vector2.ONE, 0.30).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	pickup_tween.tween_property(turbo_label, "modulate", Color.WHITE, 0.42)
	pickup_tween.tween_property(boost_bar, "modulate", Color.WHITE, 0.42)

func animate_position_change(improved: bool) -> void:
	if position_tween: position_tween.kill()
	position_label.pivot_offset = position_label.size / 2
	position_label.scale = Vector2.ONE * (1.16 if improved else 0.92)
	position_label.rotation = -0.035 if improved else 0.035
	position_label.modulate = Color("82fff0") if improved else Color("ff907d")
	position_tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_STOP).set_parallel(true)
	position_tween.tween_property(position_label, "scale", Vector2.ONE, 0.32).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	position_tween.tween_property(position_label, "rotation", 0.0, 0.26).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	position_tween.tween_property(position_label, "modulate", Color.WHITE, 0.38)

func animate_lap_change() -> void:
	if lap_tween: lap_tween.kill()
	info.pivot_offset = info.size / 2
	info.scale = Vector2.ONE * 1.12
	info.modulate = Color("ffe27a")
	lap_tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_STOP).set_parallel(true)
	lap_tween.tween_property(info, "scale", Vector2.ONE, 0.38).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	lap_tween.tween_property(info, "modulate", Color.WHITE, 0.48)

func announce(text: String, priority: int = 1) -> void:
	if priority < notice_priority or get_tree().paused: return
	if notice_tween: notice_tween.kill()
	notice_priority = priority
	notice_time = 1.5
	notice.text = text
	notice.show()
	notice.pivot_offset = notice.size / 2
	notice.scale = Vector2.ONE * 0.94
	notice.modulate.a = 0
	notice_tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_STOP)
	notice_tween.tween_property(notice, "modulate:a", 1.0, 0.2)
	notice_tween.parallel().tween_property(notice, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	notice_tween.tween_interval(0.95)
	notice_tween.tween_property(notice, "modulate:a", 0.0, 0.25)
	notice_tween.tween_callback(notice.hide)

func update_race_feedback(place: int) -> void:
	var progress := session.progress(player)
	if session.running and not player.finished:
		if place != last_place and last_place > 0:
			animate_position_change(place < last_place)
			if place < last_place and session.elapsed > 3 and pass_cooldown <= 0 and absf(progress - last_progress) < 120:
				announce("¡ADELANTAMIENTO!")
				AudioManager.play("ui")
				pass_cooldown = 3.5
		if player.lap > last_lap:
			animate_lap_change()
			announce("ÚLTIMA VUELTA" if player.lap == session.circuit.laps else "VUELTA %d/%d" % [player.lap, session.circuit.laps], 2)
			AudioManager.play("boost")
		if player.lap == session.circuit.laps and player.checkpoint_index == session.checkpoint_count - 1 and not near_finish_shown:
			announce("¡META A LA VISTA!", 2)
			near_finish_shown = true
	last_place = place
	last_lap = player.lap
	last_progress = progress

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_ESCAPE:
		pause_requested.emit()
		get_viewport().set_input_as_handled()

func modal(title: String) -> VBoxContainer:
	if combo_tween: combo_tween.kill()
	combo_label.hide()
	if notice_tween: notice_tween.kill()
	notice.hide()
	notice_priority = 0
	notice_time = 0
	if is_instance_valid(overlay):
		overlay.queue_free()
	overlay = PanelContainer.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	var viewport_size := get_viewport().get_visible_rect().size
	var panel_size := Vector2(minf(600.0, viewport_size.x - 48.0), minf(660.0, viewport_size.y - 48.0))
	overlay.offset_left = -panel_size.x * 0.5
	overlay.offset_right = panel_size.x * 0.5
	overlay.offset_top = -panel_size.y * 0.5
	overlay.offset_bottom = panel_size.y * 0.5
	root.add_child(overlay)
	var content := VBoxContainer.new()
	overlay.add_child(content)
	content.add_child(RacingUI.label(title, 32))
	return content

func show_pause() -> void:
	var content := modal("Un respiro en la orilla")
	content.add_child(RacingUI.button("Continuar", func() -> void:
		overlay.queue_free()
		pause_requested.emit()
	))
	content.add_child(RacingUI.button("Reiniciar carrera", func() -> void: restart_requested.emit()))
	content.add_child(RacingUI.button("Volver al menú", func() -> void: menu_requested.emit()))

func hide_pause() -> void:
	if is_instance_valid(overlay):
		overlay.queue_free()

func celebrate_finish(place: int) -> void:
	if is_instance_valid(finish_celebration): finish_celebration.queue_free()
	finish_celebration = FINISH_CELEBRATION.new()
	finish_celebration.configure(place)
	root.add_child(finish_celebration)
	root.move_child(finish_celebration, notice.get_index())

func result_stat(title: String, value: String, color: Color) -> PanelContainer:
	var card := PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var style := RacingUI.box(Color("102f3a"), 9)
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 7
	style.content_margin_bottom = 7
	style.shadow_size = 0
	card.add_theme_stylebox_override("panel", style)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 1)
	card.add_child(column)
	var caption := RacingUI.label(title, 12)
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caption.modulate = Color("b9d5d2")
	column.add_child(caption)
	var amount := RacingUI.label(value, 20)
	amount.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	amount.add_theme_color_override("font_color", color)
	column.add_child(amount)
	return card

func show_results(place: int, time: float, reward: int, retry_save: Callable = Callable()) -> void:
	countdown_label.hide()
	pause_button.disabled = true
	var content := modal("¡VICTORIA!" if place == 1 else "CARRERA COMPLETADA")
	content.add_theme_constant_override("separation", 8)
	var result_height := minf(540.0, get_viewport().get_visible_rect().size.y - 48.0)
	overlay.offset_top = -result_height * 0.5
	overlay.offset_bottom = result_height * 0.5
	var heading := content.get_child(0) as Label
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.add_theme_color_override("font_color", Color("ffdc6c") if place == 1 else Color("78f4e5"))
	overlay.pivot_offset = overlay.size * 0.5
	overlay.scale = Vector2.ONE * 0.92
	overlay.modulate.a = 0.0
	result_tween = create_tween().set_parallel(true)
	result_tween.tween_property(overlay, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	result_tween.tween_property(overlay, "modulate:a", 1.0, 0.18)
	var hero := HBoxContainer.new()
	hero.alignment = BoxContainer.ALIGNMENT_CENTER
	content.add_child(hero)
	var portrait := preload("res://scripts/ui/cap_preview.gd").new()
	portrait.appearance = player.get_node("Visual").appearance
	portrait.tint = player.get_node("Visual").tint
	portrait.custom_minimum_size = Vector2(112, 78)
	portrait.art_scale = 1.12
	hero.add_child(portrait)
	var summary := VBoxContainer.new()
	summary.add_theme_constant_override("separation", 0)
	hero.add_child(summary)
	var eyebrow := RacingUI.label("TU RESULTADO", 13)
	eyebrow.modulate = Color("b9d5d2")
	summary.add_child(eyebrow)
	result_place_label = RacingUI.label("%d.º DE %d" % [place, session.caps.size()], 34)
	result_place_label.add_theme_color_override("font_color", Color("ffdc6c") if place <= 3 else Color("eefaf1"))
	summary.add_child(result_place_label)
	var stars := "★".repeat(maxi(0, 4 - place)) + "☆".repeat(mini(3, place - 1))
	summary.add_child(RacingUI.label(stars, 19))
	result_stats = HBoxContainer.new()
	result_stats.add_theme_constant_override("separation", 8)
	content.add_child(result_stats)
	result_stats.add_child(result_stat("TIEMPO", "%.2f s" % time, Color("eefaf1")))
	result_stats.add_child(result_stat("MONEDAS", "+%d" % maxi(0, reward) if reward >= 0 else "ERROR", Color("ffdc6c") if reward >= 0 else Color("ff907d")))
	result_stats.add_child(result_stat("XP", "+%d" % SaveManager.PROGRESSION.reward(place) if reward >= 0 else "—", Color("78f4e5")))
	var detail_lines: Array[String] = []
	var best := float(SaveManager.best_times.get(session.circuit.record_key(SaveManager.settings.difficulty, session.circuit.laps), time))
	detail_lines.append("Récord local %.2f s" % best)
	if combo != null: detail_lines.append("Mejor combo x%d" % combo.best)
	if reward >= 0:
		var ready := ChallengeProgress.ready_count(SaveManager.challenges)
		detail_lines.append("Nivel %d · %d XP totales%s" % [SaveManager.cap_level(player.definition_id), SaveManager.cap_xp(player.definition_id), " · %d premio(s) listos" % ready if ready > 0 else ""])
	var detail_text := "  ·  ".join(detail_lines)
	if is_instance_valid(ghost): detail_text += "\n" + ghost.status
	var details := RacingUI.label(detail_text, 14)
	details.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	details.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	content.add_child(details)
	var standings_title := RacingUI.label("CLASIFICACIÓN", 14)
	standings_title.add_theme_color_override("font_color", Color("78f4e5"))
	content.add_child(standings_title)
	result_rows = RacingUI.label("")
	result_rows.add_theme_font_size_override("font_size", 16)
	content.add_child(result_rows)
	update_results()
	if reward < 0:
		content.add_child(RacingUI.label("Resultado sin guardar. Reintenta antes de salir.", 16))
		if retry_save.is_valid(): content.add_child(RacingUI.button("Reintentar guardado", retry_save))
	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 8)
	content.add_child(actions)
	var retry := RacingUI.button("Volver a correr", func() -> void: restart_requested.emit())
	retry.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	actions.add_child(retry)
	var exit := RacingUI.button("Volver al menú", func() -> void: menu_requested.emit())
	exit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	actions.add_child(exit)

func update_results() -> void:
	var rows := ""
	var place := 1
	for cap in session.standings():
		var marker := "▶ " if cap == player else "   "
		rows += "%s%d. %s  ·  %s\n" % [marker, place, cap.racer_name, "%.2f s" % cap.finish_time if cap.finished else "en carrera"]
		place += 1
	result_rows.text = rows.strip_edges()
