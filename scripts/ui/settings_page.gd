class_name SettingsPage
extends VBoxContainer

func _ready() -> void:
	for entry in [["music", "Volumen de música"], ["effects", "Volumen de efectos"]]:
		var key: String = entry[0]
		add_child(RacingUI.label(entry[1]))
		var slider := HSlider.new()
		slider.min_value = 0
		slider.max_value = 1
		slider.step = 0.05
		slider.custom_minimum_size.y = 36
		slider.value = SaveManager.settings[key]
		slider.value_changed.connect(func(value: float) -> void:
			SaveManager.settings[key] = value
			AudioManager.apply_settings()
		)
		add_child(slider)
	var vibration := CheckButton.new()
	vibration.text = "Vibración"
	vibration.custom_minimum_size.y = 48
	vibration.button_pressed = SaveManager.settings.vibration
	vibration.toggled.connect(func(value: bool) -> void: SaveManager.settings.vibration = value)
	add_child(vibration)
	add_options("Calidad gráfica", "quality", ["low", "high"], ["Baja", "Alta"])
	add_options("Límite de FPS", "fps", [30, 60], ["30 FPS", "60 FPS"])
	add_options("Dificultad", "difficulty", ["easy", "normal", "hard"], ["Fácil", "Normal", "Difícil"])

func add_options(title: String, key: String, values: Array, labels: Array) -> void:
	var row := HBoxContainer.new()
	var label := RacingUI.label(title)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(label)
	var options := OptionButton.new()
	options.custom_minimum_size = Vector2(230, 48)
	for text in labels:
		options.add_item(text)
	options.select(maxi(0, values.find(SaveManager.settings[key])))
	options.item_selected.connect(func(index: int) -> void:
		SaveManager.settings[key] = values[index]
		SaveManager.apply_settings()
	)
	row.add_child(options)
	add_child(row)
