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

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	root = Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.theme = RacingUI.theme()
	add_child(root)
	var top := HBoxContainer.new()
	top.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	top.offset_left = 24
	top.offset_right = -24
	top.offset_top = 20
	root.add_child(top)
	var panel := PanelContainer.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(panel)
	var column := VBoxContainer.new()
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(column)
	info = RacingUI.label("")
	column.add_child(info)
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
		bottom.offset_top = -safe.w - 76
	get_viewport().size_changed.connect(update_margins)
	update_margins.call()
	var hints := RacingUI.label("◀ Izquierda                 Derecha ▶\nToca cada mitad · Desliza para impulso · A/D o flechas")
	hints.add_theme_font_size_override("font_size", 17)
	hints.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bottom.add_child(hints)
	var boost_column := VBoxContainer.new()
	boost_column.custom_minimum_size.x = 230
	bottom.add_child(boost_column)
	boost_button = RacingUI.button("BOOST · Espacio", func() -> void: player.controls.boost_requested = true)
	boost_button.action_mode = BaseButton.ACTION_MODE_BUTTON_PRESS
	boost_button.focus_mode = Control.FOCUS_NONE
	pause_button.focus_mode = Control.FOCUS_NONE
	boost_column.add_child(boost_button)
	boost_bar = ProgressBar.new()
	boost_bar.custom_minimum_size.y = 14
	boost_bar.show_percentage = false
	boost_column.add_child(boost_bar)
	countdown_label = RacingUI.label("3", 68)
	countdown_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	countdown_label.offset_left = -180
	countdown_label.offset_right = 180
	countdown_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(countdown_label)
	session.countdown_changed.connect(func(value: int) -> void: countdown_label.text = str(value) if value > 0 else "¡YA!")
	session.started.connect(func() -> void:
		get_tree().create_timer(0.7).timeout.connect(func() -> void: countdown_label.hide())
	)
	set_mouse_passthrough(root)

func set_mouse_passthrough(node: Node) -> void:
	if node is Control and not node is BaseButton:
		node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for child in node.get_children():
		set_mouse_passthrough(child)

func _process(delta: float) -> void:
	tick += delta
	if tick < 0.1 or not is_instance_valid(player):
		return
	tick = 0
	player.controls.excluded_rects = [boost_button.get_global_rect(), pause_button.get_global_rect()]
	var place := session.standings().find(player) + 1
	var shown_time := player.finish_time if player.finished else session.elapsed
	info.text = "%d/%d   ·   Vuelta %d/%d   ·   %d u/s   ·   %.1f s" % [place, session.caps.size(), player.lap, session.circuit.laps, player.velocity.length(), shown_time]
	boost_bar.value = player.boost_energy * 100
	boost_button.disabled = player.boost_energy < 0.45 or not player.active or player.finished or get_tree().paused
	player.controls.boost_touch_rect = boost_button.get_global_rect()
	player.controls.boost_touch_enabled = not boost_button.disabled
	progress_bar.value = session.progress(player) / (session.circuit.length * session.circuit.laps) * 100
	if is_instance_valid(result_rows):
		update_results()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_ESCAPE:
		pause_requested.emit()
		get_viewport().set_input_as_handled()

func modal(title: String) -> VBoxContainer:
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
	var content := modal("¡Victoria!" if place == 1 else "¡Meta! · Puesto %d/4" % place)
	content.add_child(RacingUI.label("Tiempo: %.2f s  ·  +%d monedas" % [time, reward]))
	result_rows = RacingUI.label("")
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
