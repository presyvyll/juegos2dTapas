extends Control

const ICON_PLAY := preload("res://assets/ui/icon_play.svg")
const ICON_CUP := preload("res://assets/ui/icon_cup.svg")
const ICON_FLAG := preload("res://assets/ui/icon_flag.svg")
const ICON_GIFT := preload("res://assets/ui/icon_gift.svg")
const ICON_HOME := preload("res://assets/ui/icon_home.svg")
const ICON_CAP := preload("res://assets/ui/icon_cap.svg")
const ICON_SETTINGS := preload("res://assets/ui/icon_settings.svg")
const ICON_EXIT := preload("res://assets/ui/icon_exit.svg")

var content: VBoxContainer
var wallet: Label
var heading: Label
var heading_area: MarginContainer
var wallet_area: MarginContainer
var transition: Tween
var navigation: HBoxContainer
var backdrop: Control
var home_background: TextureRect
var home_art: Control
var main_panel: PanelContainer
var main_margin: MarginContainer
var home_mode := false
var home_clock := 0.0
var home_cap_preview: Control
var home_cap_name: Label

func _ready() -> void:
	SaveManager.cup_race_requested = false
	theme = RacingUI.menu_theme()
	backdrop = preload("res://scripts/ui/menu_backdrop.gd").new()
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(backdrop)
	home_background = TextureRect.new()
	home_background.texture = preload("res://assets/ui/main_menu_tropical.png")
	home_background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	home_background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	home_background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	home_background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	home_background.hide()
	add_child(home_background)
	home_art = preload("res://scripts/ui/main_menu_home_art.gd").new()
	home_art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	home_art.hide()
	add_child(home_art)
	main_margin = MarginContainer.new()
	main_margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var update_margins := func() -> void:
		var safe := RacingUI.safe_insets(get_viewport())
		main_margin.add_theme_constant_override("margin_left", maxi(32, int(safe.x)))
		main_margin.add_theme_constant_override("margin_top", maxi(32, int(safe.y)))
		main_margin.add_theme_constant_override("margin_right", maxi(32, int(safe.z)))
		main_margin.add_theme_constant_override("margin_bottom", maxi(32, int(safe.w)))
		update_home_layout()
	get_viewport().size_changed.connect(update_margins)
	update_margins.call()
	add_child(main_margin)
	var layout := VBoxContainer.new()
	main_margin.add_child(layout)
	var top := HBoxContainer.new()
	top.custom_minimum_size.y = 44
	layout.add_child(top)
	heading_area = MarginContainer.new()
	heading_area.size_flags_vertical = Control.SIZE_EXPAND_FILL
	top.add_child(heading_area)
	heading = RacingUI.label("TAPA RACING", 28)
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading.size_flags_vertical = Control.SIZE_EXPAND_FILL
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	heading_area.add_child(heading)
	var top_spacer := Control.new()
	top_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(top_spacer)
	wallet_area = MarginContainer.new()
	wallet_area.size_flags_vertical = Control.SIZE_EXPAND_FILL
	wallet_area.add_theme_constant_override("margin_left", 4)
	wallet_area.add_theme_constant_override("margin_right", 4)
	top.add_child(wallet_area)
	wallet = RacingUI.label("")
	wallet.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	wallet.size_flags_vertical = Control.SIZE_EXPAND_FILL
	wallet.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	wallet.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	wallet.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	wallet_area.add_child(wallet)
	var center := CenterContainer.new()
	RacingUI.expand(center)
	layout.add_child(center)
	main_panel = PanelContainer.new()
	main_panel.custom_minimum_size.x = 650
	center.add_child(main_panel)
	content = VBoxContainer.new()
	main_panel.add_child(content)
	navigation = HBoxContainer.new()
	layout.add_child(navigation)
	for entry in [["INICIO", show_home], ["COPAS", show_championships], ["TAPAS", func() -> void: show_selection("caps")], ["AJUSTES", show_settings]]:
		var button := RacingUI.button(entry[0], entry[1])
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		navigation.add_child(button)
	if OS.get_name() != "iOS":
		var exit_button := RacingUI.button("SALIR", func() -> void: get_tree().quit())
		exit_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		navigation.add_child(exit_button)
	SaveManager.changed.connect(update_wallet)
	SaveManager.save_failed.connect(update_wallet)
	if SaveManager.return_to_cups:
		SaveManager.return_to_cups = false
		show_championships()
	else:
		show_home()
	AudioManager.set_racing(false)
	set_process(true)

func _process(delta: float) -> void:
	if not home_mode:
		return
	home_clock += delta
	var drift := Vector2(sin(home_clock * 0.12), cos(home_clock * 0.10)) * 3.0
	home_background.offset_left = -7.0 + drift.x
	home_background.offset_top = -7.0 + drift.y
	home_background.offset_right = 7.0 + drift.x
	home_background.offset_bottom = 7.0 + drift.y

func update_wallet() -> void:
	wallet.text = "Nv. %d · %d XP · %d monedas%s" % [SaveManager.cap_level(SaveManager.selected_cap), SaveManager.cap_xp(SaveManager.selected_cap), SaveManager.coins, "" if SaveManager.last_save_ok else " · Error al guardar"]
	if home_mode and is_instance_valid(home_cap_preview) and is_instance_valid(home_cap_name):
		for cap in RacingCatalog.caps():
			if cap.id != SaveManager.selected_cap:
				continue
			home_cap_preview.tint = cap.color.lightened(0.25) if SaveManager.selected_skin == "perla" else cap.color
			home_cap_preview.appearance = cap.appearance if cap.appearance else CapAppearance.new()
			home_cap_preview.queue_redraw()
			home_cap_name.text = cap.display_name
			break

func clear() -> void:
	set_home_mode(false)
	if transition:
		transition.kill()
	for child in content.get_children():
		content.remove_child(child)
		child.queue_free()
	update_wallet()
	content.modulate.a = 0.55
	transition = create_tween()
	transition.tween_property(content, "modulate:a", 1.0, 0.25)
	# Other pages retain their full available height, including cup results.
	navigation.hide()

func show_home() -> void:
	clear()
	set_home_mode(true)
	heading.text = "TAPA RACING"
	navigation.show()
	var title := RacingUI.label("¡A TODA AGUA!", 30)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", Color("ffdc6c"))
	title.add_theme_color_override("font_outline_color", Color("32170e"))
	title.add_theme_constant_override("outline_size", 7)
	content.add_child(title)
	home_cap_preview = null
	home_cap_name = null
	for cap in RacingCatalog.caps():
		if cap.id != SaveManager.selected_cap: continue
		var preview := preload("res://scripts/ui/cap_preview.gd").new()
		preview.animated = true
		preview.hero_effects = true
		preview.art_scale = 2.55
		preview.custom_minimum_size.y = 150
		preview.tint = cap.color.lightened(0.25) if SaveManager.selected_skin == "perla" else cap.color
		preview.appearance = cap.appearance if cap.appearance else CapAppearance.new()
		content.add_child(preview)
		home_cap_preview = preview
		var name_label := RacingUI.label(cap.display_name, 26)
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_label.add_theme_color_override("font_color", Color("fff8e7"))
		var name_plank := PanelContainer.new()
		name_plank.add_theme_stylebox_override("panel", name_plank_style())
		name_plank.add_child(name_label)
		content.add_child(name_plank)
		home_cap_name = name_label
	var play := RacingUI.button("JUGAR", show_race_setup)
	play.custom_minimum_size.y = 76
	style_home_button(play, true)
	apply_home_icon(play, ICON_PLAY, 46)
	play.call("set_idle_pulse", true)
	content.add_child(play)
	var shortcuts := HBoxContainer.new()
	content.add_child(shortcuts)
	var ready_rewards := ChallengeProgress.ready_count(SaveManager.challenges)
	var rewards_caption := "PREMIOS · %d" % ready_rewards if ready_rewards > 0 else "PREMIOS"
	for entry in [["COPAS", show_championships, ICON_CUP], ["PISTAS", func() -> void: show_selection("circuits"), ICON_FLAG], [rewards_caption, show_rewards, ICON_GIFT]]:
		var button := RacingUI.button(entry[0], entry[1])
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		style_home_button(button)
		apply_home_icon(button, entry[2], 32)
		shortcuts.add_child(button)
	navigation.get_child(0).disabled = true

func set_home_mode(enabled: bool) -> void:
	home_mode = enabled
	if not is_instance_valid(home_background):
		return
	home_background.show()
	home_art.show()
	home_art.call("set_section_mode", not enabled)
	backdrop.hide()
	heading.visible = true
	heading.modulate.a = 0.0 if enabled else 1.0
	update_home_layout()
	if enabled:
		home_clock = 0.0
		home_art.call("restart")
		update_home_layout()
		main_panel.add_theme_stylebox_override("panel", home_panel_style())
		wallet.add_theme_font_size_override("font_size", 21)
		wallet.add_theme_color_override("font_color", Color("fff4d7"))
		var labels := ["INICIO", "COPAS", "TAPAS", "AJUSTES", "SALIR"]
		var icons := [ICON_HOME, ICON_CUP, ICON_CAP, ICON_SETTINGS, ICON_EXIT]
		for index in range(navigation.get_child_count()):
			var button := navigation.get_child(index) as Button
			button.text = labels[index]
			style_home_button(button, false, index == 0)
			apply_home_icon(button, icons[index], 29)
	else:
		home_background.set_offsets_preset(Control.PRESET_FULL_RECT)
		main_panel.add_theme_stylebox_override("panel", section_panel_style())
		wallet.remove_theme_font_size_override("font_size")
		wallet.remove_theme_color_override("font_color")
		var labels := ["INICIO", "COPAS", "TAPAS", "AJUSTES", "SALIR"]
		for index in range(navigation.get_child_count()):
			var button := navigation.get_child(index) as Button
			button.text = labels[index]
			for state in ["normal", "hover", "pressed", "disabled", "focus"]:
				button.remove_theme_stylebox_override(state)
			button.remove_theme_font_size_override("font_size")
			button.remove_theme_color_override("font_color")
			button.remove_theme_color_override("font_disabled_color")
			button.icon = null
			button.expand_icon = false

func style_home_button(button: Button, primary := false, stone := false) -> void:
	var normal_color := Color("aeb4b7") if stone else Color("ffbd2d")
	var hover_color := Color("c9d0d3") if stone else Color("ffd85a")
	var pressed_color := Color("8e979c") if stone else Color("dc8d16")
	button.add_theme_stylebox_override("normal", home_button_box(normal_color, primary))
	button.add_theme_stylebox_override("hover", home_button_box(hover_color, primary))
	button.add_theme_stylebox_override("pressed", home_button_box(pressed_color, primary))
	button.add_theme_stylebox_override("disabled", home_button_box(Color("9ca4a8"), primary))
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	button.add_theme_font_size_override("font_size", 30 if primary else 21)
	button.add_theme_color_override("font_color", Color("351506"))
	button.add_theme_color_override("font_disabled_color", Color("34363b"))
	button.call("set_illustrated", true)

func apply_home_icon(button: Button, icon: Texture2D, max_width: int) -> void:
	button.icon = icon
	button.expand_icon = true
	button.add_theme_constant_override("icon_max_width", max_width)
	button.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.alignment = HORIZONTAL_ALIGNMENT_CENTER

func update_home_layout() -> void:
	if not is_instance_valid(main_panel):
		return
	main_panel.custom_minimum_size.x = clampf(size.x * (0.53 if home_mode else 0.76), 620.0, 980.0)
	if is_instance_valid(heading_area) and is_instance_valid(wallet_area):
		# Coincide con el área interior de los tablones dibujados, sin incluir sus bordes.
		heading_area.custom_minimum_size.x = clampf(size.x * 0.30, 300.0, 470.0) - 20.0
		wallet_area.custom_minimum_size.x = clampf(size.x * 0.29, 320.0, 470.0) - 12.0

func name_plank_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("4b2515")
	style.border_color = Color("241008")
	style.set_border_width_all(4)
	style.set_corner_radius_all(7)
	style.shadow_color = Color(0.02, 0.01, 0.0, 0.65)
	style.shadow_offset = Vector2(0, 5)
	style.content_margin_top = 5
	style.content_margin_bottom = 5
	return style

func home_button_box(color: Color, primary: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = Color("4d230d")
	style.set_border_width_all(4)
	style.set_corner_radius_all(8)
	style.shadow_color = Color(0.08, 0.02, 0.0, 0.7)
	style.shadow_offset = Vector2(0, 7)
	style.shadow_size = 4
	style.content_margin_left = 22
	style.content_margin_right = 22
	style.content_margin_top = 13 if primary else 10
	style.content_margin_bottom = 13 if primary else 10
	return style

func home_panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.16, 0.07, 0.025, 0.82)
	style.border_color = Color("32170e")
	style.set_border_width_all(7)
	style.set_corner_radius_all(12)
	style.shadow_color = Color(0.02, 0.01, 0.0, 0.72)
	style.shadow_offset = Vector2(0, 10)
	style.shadow_size = 8
	style.content_margin_left = 20
	style.content_margin_right = 20
	style.content_margin_top = 17
	style.content_margin_bottom = 17
	return style

func section_panel_style() -> StyleBoxFlat:
	var style := RacingUI.tropical_box(Color(0.14, 0.045, 0.018, 0.92), 13)
	style.border_color = Color("713815")
	style.set_border_width_all(6)
	style.content_margin_left = 22
	style.content_margin_right = 22
	style.content_margin_top = 18
	style.content_margin_bottom = 18
	return style

func show_rewards() -> void:
	clear()
	heading.text = "PREMIOS"
	var ready := ChallengeProgress.ready_count(SaveManager.challenges)
	var challenges := RacingUI.button("RECLAMAR %d RECOMPENSA(S)" % ready if ready > 0 else "VER DESAFÍOS", show_challenges)
	RacingUI.set_primary(challenges, ready > 0)
	content.add_child(challenges)
	content.add_child(RacingUI.label("Tienes %d recompensa(s) lista(s)." % ready if ready > 0 else "Completa objetivos en carrera para ganar monedas.", 17))
	content.add_child(RacingUI.label("Premios de las cinco copas", 28))
	for cup in RacingCatalog.championships():
		var best := int(SaveManager.championships.completed.get(cup.id, 0))
		var earned := best > 0 and best <= 3
		content.add_child(RacingUI.label("%s · %d monedas · %s" % [cup.display_name, cup.coin_reward, "Conseguido" if earned else "Consigue podio"], 19))
	content.add_child(RacingUI.label("Cada premio se entrega automáticamente una sola vez.", 17))
	content.add_child(RacingUI.button("Ver copas", show_championships))
	content.add_child(RacingUI.button("Volver al menú", show_home))

func show_challenges() -> void:
	clear()
	heading.text = "DESAFÍOS"
	content.add_child(ChallengesPage.new())
	content.add_child(RacingUI.button("Volver a premios", show_rewards))

func show_race_setup() -> void:
	SaveManager.cup_race_requested = false
	clear()
	heading.text = "CARRERA"
	var setup := RaceSetup.new()
	setup.change_track_requested.connect(func() -> void: show_selection("circuits", true))
	setup.change_cap_requested.connect(func() -> void: show_selection("caps", true))
	content.add_child(setup)
	content.add_child(RacingUI.button("Volver al menú", show_home))

func show_championships() -> void:
	clear()
	heading.text = "COPAS"
	content.add_child(ChampionshipPage.new())
	content.add_child(RacingUI.button("Volver al menú", show_home))

func show_selection(kind: String, return_to_race_setup := false) -> void:
	clear()
	heading.text = "GARAGE DE TAPAS" if kind == "caps" else "PISTAS"
	var page := preload("res://scripts/ui/garage_page.gd").new() if kind == "caps" else SelectionPage.new()
	page.kind = kind
	page.rebuild_callback = update_wallet
	content.add_child(page)
	content.add_child(RacingUI.button("Volver a preparar carrera" if return_to_race_setup else "Volver al menú", show_race_setup if return_to_race_setup else show_home))

func show_settings() -> void:
	clear()
	heading.text = "AJUSTES"
	content.add_child(SettingsPage.new())
	content.add_child(RacingUI.button("Guardar y volver", func() -> void:
		SaveManager.apply_settings()
		SaveManager.save()
		show_home()
	))

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST and is_instance_valid(heading) and heading.text != "TAPA RACING":
		for child in content.get_children():
			if child is ChampionshipPage and child.go_back(): return
		SaveManager.save()
		show_home()
