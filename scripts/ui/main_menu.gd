extends Control

var content: VBoxContainer
var wallet: Label
var heading: Label
var transition: Tween

func _ready() -> void:
	SaveManager.cup_race_requested = false
	theme = RacingUI.theme()
	var background := preload("res://scripts/ui/menu_backdrop.gd").new()
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var update_margins := func() -> void:
		var safe := RacingUI.safe_insets(get_viewport())
		margin.add_theme_constant_override("margin_left", maxi(32, int(safe.x)))
		margin.add_theme_constant_override("margin_top", maxi(32, int(safe.y)))
		margin.add_theme_constant_override("margin_right", maxi(32, int(safe.z)))
		margin.add_theme_constant_override("margin_bottom", maxi(32, int(safe.w)))
	get_viewport().size_changed.connect(update_margins)
	update_margins.call()
	add_child(margin)
	var layout := VBoxContainer.new()
	margin.add_child(layout)
	var top := HBoxContainer.new()
	layout.add_child(top)
	heading = RacingUI.label("TAPA RACING", 28)
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(heading)
	wallet = RacingUI.label("")
	top.add_child(wallet)
	var center := CenterContainer.new()
	RacingUI.expand(center)
	layout.add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size.x = 650
	center.add_child(panel)
	content = VBoxContainer.new()
	panel.add_child(content)
	SaveManager.changed.connect(update_wallet)
	SaveManager.save_failed.connect(update_wallet)
	show_home()
	AudioManager.set_racing(false)

func update_wallet() -> void:
	wallet.text = "%d monedas%s" % [SaveManager.coins, "" if SaveManager.last_save_ok else " · Error al guardar"]

func clear() -> void:
	if transition:
		transition.kill()
	for child in content.get_children():
		content.remove_child(child)
		child.queue_free()
	update_wallet()
	content.modulate.a = 0.55
	transition = create_tween()
	transition.tween_property(content, "modulate:a", 1.0, 0.16)

func show_home() -> void:
	clear()
	heading.text = "TAPA RACING"
	var title := RacingUI.label("¡A TODA AGUA!", 34)
	title.add_theme_color_override("font_color", Color("ffdc6c"))
	content.add_child(title)
	content.add_child(RacingUI.label("El torneo de la fuente · Cuatro tapas, una victoria."))
	content.add_child(RacingUI.button("JUGAR", show_race_setup))
	content.add_child(RacingUI.button("TAPAS", func() -> void: show_selection("caps")))
	content.add_child(RacingUI.button("CIRCUITOS", func() -> void: show_selection("circuits")))
	content.add_child(RacingUI.button("COPAS", show_championships))
	content.add_child(RacingUI.button("CONFIGURACIÓN", show_settings))
	if OS.get_name() != "iOS":
		content.add_child(RacingUI.button("SALIR", func() -> void: get_tree().quit()))

func show_race_setup() -> void:
	SaveManager.cup_race_requested = false
	clear()
	heading.text = "CARRERA"
	content.add_child(RaceSetup.new())
	content.add_child(RacingUI.button("Volver al menú", show_home))

func show_championships() -> void:
	clear()
	heading.text = "COPAS"
	content.add_child(ChampionshipPage.new())
	content.add_child(RacingUI.button("Volver al menú", show_home))

func show_selection(kind: String) -> void:
	clear()
	heading.text = "TAPAS" if kind == "caps" else "CIRCUITOS"
	var page := SelectionPage.new()
	page.kind = kind
	page.rebuild_callback = update_wallet
	content.add_child(page)
	content.add_child(RacingUI.button("Volver al menú", show_home))

func show_settings() -> void:
	clear()
	heading.text = "CONFIGURACIÓN"
	content.add_child(SettingsPage.new())
	content.add_child(RacingUI.button("Guardar y volver", func() -> void:
		SaveManager.apply_settings()
		SaveManager.save()
		show_home()
	))

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST and is_instance_valid(heading) and heading.text != "TAPA RACING":
		SaveManager.save()
		show_home()
