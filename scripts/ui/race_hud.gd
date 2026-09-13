class_name RaceHUD
extends CanvasLayer

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
var overlay: PanelContainer
var boost_button: Button
var pause_button: Button
var result_rows: Label
var tick := 0.0
var pickup_notice := ""
var pickup_notice_time := 0.0
var position_label: Label
var speed_label: Label
var turbo_label: Label
var countdown_tween: Tween
var result_tween: Tween
var notice: Label
var notice_tween: Tween
var position_tween: Tween
var turbo_tween: Tween
var last_place := 0
var last_lap := 1
var last_progress := 0.0
var notice_priority := 0
var notice_time := 0.0
var pass_cooldown := 0.0
var near_finish_shown := false

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
	var panel := PanelContainer.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var compact_style := RacingUI.box(Color("153e47"), 10)
	compact_style.content_margin_top = 6
	compact_style.content_margin_bottom = 6
	panel.add_theme_stylebox_override("panel", compact_style)
	top.add_child(panel)
	var status_row := HBoxContainer.new()
	panel.add_child(status_row)
	position_label = RacingUI.label("4º", 38)
	position_label.custom_minimum_size.x = 74
	position_label.add_theme_color_override("font_color", Color("ffdc6c"))
	status_row.add_child(position_label)
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
	progress_bar = ProgressBar.new()
	progress_bar.custom_minimum_size.y = 8
	progress_bar.show_percentage = false
	column.add_child(progress_bar)
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
		bottom.offset_left = safe.x
		bottom.offset_right = -safe.z
		bottom.offset_bottom = -safe.w
		bottom.offset_top = -safe.w - 124
	get_viewport().size_changed.connect(update_margins)
	update_margins.call()
	var hints := RacingUI.label("◀ TOCA PARA GIRAR ▶\nDesliza para dar un impulso")
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
	turbo_label = RacingUI.label("TURBO LISTO", 14)
	turbo_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	boost_column.add_child(turbo_label)
	bottom.offset_top = -144
	countdown_label = RacingUI.label("3", 96)
	countdown_label.add_theme_color_override("font_color", Color("ffdd69"))
	countdown_label.add_theme_color_override("font_outline_color", Color("10283b"))
	countdown_label.add_theme_constant_override("outline_size", 12)
	countdown_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	countdown_label.offset_left = -360
	countdown_label.offset_right = 360
	countdown_label.offset_top = -90
	countdown_label.offset_bottom = 90
	countdown_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(countdown_label)
	notice = RacingUI.label("", 28)
	notice.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	notice.add_theme_color_override("font_color", Color("ffdc6c"))
	notice.add_theme_color_override("font_outline_color", Color("10283b"))
	notice.add_theme_constant_override("outline_size", 4)
	notice.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
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
		pickup_notice = effect.display_name
		pickup_notice_time = 2.0
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
	countdown_label.show()
	countdown_label.pivot_offset = countdown_label.size / 2
	countdown_label.scale = Vector2.ONE * 1.35
	countdown_label.modulate.a = 1
	countdown_tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_STOP)
	countdown_tween.tween_property(countdown_label, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if value == 0:
		countdown_tween.tween_interval(0.45)
		countdown_tween.tween_property(countdown_label, "modulate:a", 0.0, 0.2)
		countdown_tween.tween_callback(countdown_label.hide)

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
	player.controls.excluded_rects = [boost_button.get_global_rect(), pause_button.get_global_rect()]
	var place := session.standings().find(player) + 1
	var shown_time := player.finish_time if player.finished else session.elapsed
	position_label.text = "%d.º/%d" % [place, session.caps.size()]
	update_race_feedback(place)
	info.text = "VUELTA %d/%d  ·  %.1f s" % [player.lap, session.circuit.laps, shown_time]
	speed_label.text = "%d u/s" % (0.0 if player.finished else player.velocity.length())
	boost_bar.value = player.boost_energy * 100
	boost_button.disabled = not player.can_boost()
	turbo_label.text = "¡A TODA AGUA!" if player.boost_time > 0 else ("CARGANDO…" if player.boost_energy < player.turbo.energy_cost else "TURBO LISTO")
	if player.shield_time > 0:
		turbo_label.text = "BURBUJA · %.1f s" % player.shield_time
	elif pickup_notice_time > 0:
		turbo_label.text = pickup_notice
	if player.finished: turbo_label.text = "CARRERA TERMINADA"
	player.controls.boost_touch_rect = boost_button.get_global_rect()
	player.controls.boost_touch_enabled = not boost_button.disabled
	progress_bar.value = session.progress(player) / (session.circuit.length * session.circuit.laps) * 100
	if is_instance_valid(result_rows):
		update_results()

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
			if position_tween: position_tween.kill()
			position_label.pivot_offset = position_label.size / 2
			position_label.scale = Vector2.ONE * 1.08
			position_tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_STOP)
			position_tween.tween_property(position_label, "scale", Vector2.ONE, 0.25)
			if place < last_place and session.elapsed > 3 and pass_cooldown <= 0 and absf(progress - last_progress) < 120:
				announce("¡ADELANTAMIENTO!")
				AudioManager.play("ui")
				pass_cooldown = 3.5
		if player.lap > last_lap:
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
	if notice_tween: notice_tween.kill()
	notice.hide()
	notice_priority = 0
	notice_time = 0
	if is_instance_valid(overlay):
		overlay.queue_free()
	overlay = PanelContainer.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	overlay.offset_left = -300
	overlay.offset_right = 300
	overlay.offset_top = -220
	overlay.offset_bottom = 220
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

func show_results(place: int, time: float, reward: int) -> void:
	countdown_label.hide()
	pause_button.disabled = true
	var content := modal("¡VICTORIA!" if place == 1 else "RESULTADO · Puesto %d/%d" % [place, session.caps.size()])
	overlay.pivot_offset = Vector2(300, 220)
	overlay.scale = Vector2.ONE * 0.92
	result_tween = create_tween()
	result_tween.tween_property(overlay, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	content.add_child(RacingUI.label("Tiempo: %.2f s  ·  +%d monedas" % [time, reward]))
	var best := float(SaveManager.best_times.get(session.circuit.record_key(SaveManager.settings.difficulty, session.circuit.laps), time))
	content.add_child(RacingUI.label("Récord local: %.2f s · %s" % [best, "★".repeat(maxi(0, 4 - place)) + "☆".repeat(mini(3, place - 1))], 17))
	var podium := HBoxContainer.new()
	content.add_child(podium)
	var winner: RacingCap = session.standings()[0]
	var portrait := preload("res://scripts/ui/cap_preview.gd").new()
	portrait.appearance = winner.get_node("Visual").appearance
	portrait.tint = winner.get_node("Visual").tint
	podium.add_child(portrait)
	portrait.custom_minimum_size = Vector2(150, 90)
	portrait.art_scale = 1.25
	var winner_text := RacingUI.label("¡GANADOR!\n" + winner.racer_name, 24)
	winner_text.add_theme_color_override("font_color", Color("ffdc6c"))
	podium.add_child(winner_text)
	result_rows = RacingUI.label("")
	result_rows.add_theme_font_size_override("font_size", 18)
	content.add_child(result_rows)
	update_results()
	if not SaveManager.last_save_ok:
		content.add_child(RacingUI.label("No se pudo guardar. Las monedas siguen en memoria.", 16))
	content.add_child(RacingUI.button("Volver a correr", func() -> void: restart_requested.emit()))
	content.add_child(RacingUI.button("Volver al menú", func() -> void: menu_requested.emit()))

func update_results() -> void:
	var rows := ""
	var place := 1
	for cap in session.standings():
		rows += "%d. %s   %s\n" % [place, cap.racer_name, "%.2f s" % cap.finish_time if cap.finished else "en carrera"]
		place += 1
	result_rows.text = rows.strip_edges()
