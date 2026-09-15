class_name ChallengesPage
extends VBoxContainer

var page := 0
var entrance: Tween

func _ready() -> void:
	build()

func build() -> void:
	if entrance: entrance.kill()
	for child in get_children():
		remove_child(child)
		child.queue_free()
	add_theme_constant_override("separation", 10)
	add_child(RacingUI.label("DESAFÍOS PERMANENTES", 26))
	add_child(RacingUI.label("Se registran al guardar resultados. Cada premio se reclama una vez.", 16))
	var definitions := ChallengeProgress.definitions()
	var pages := ceili(definitions.size() / 3.0)
	page = posmod(page, pages)
	for index in range(page * 3, mini(definitions.size(), (page + 1) * 3)):
		var definition := definitions[index]
		var entry: Dictionary = SaveManager.challenges.get(definition.id, {})
		var progress := int(entry.get("progress", 0))
		var claimed := bool(entry.get("claimed", false))
		var row := HBoxContainer.new()
		add_child(row)
		var details := VBoxContainer.new()
		details.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(details)
		details.add_child(RacingUI.label(definition.title, 21))
		var description := RacingUI.label(definition.description, 16)
		description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		details.add_child(description)
		details.add_child(RacingUI.label("%d/%d · %d monedas" % [progress, definition.target, definition.coins], 16))
		var bar := ProgressBar.new()
		bar.max_value = definition.target
		bar.value = progress
		bar.show_percentage = false
		bar.custom_minimum_size.y = 10
		details.add_child(bar)
		var claim := RacingUI.button("RECLAMADO" if claimed else ("RECLAMAR" if progress >= definition.target else "EN PROGRESO"), func() -> void:
			if SaveManager.claim_challenge(definition.id): AudioManager.play("ui")
			build()
		)
		claim.disabled = claimed or progress < definition.target
		claim.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(claim)
	if not SaveManager.last_save_ok:
		add_child(RacingUI.label("No se pudo guardar el cambio. Reintenta la operación.", 16))
	var navigation := HBoxContainer.new()
	add_child(navigation)
	navigation.add_child(RacingUI.button("‹", func() -> void: page -= 1; build()))
	var pagination := RacingUI.label("%d / %d" % [page + 1, pages], 18)
	pagination.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pagination.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	navigation.add_child(pagination)
	navigation.add_child(RacingUI.button("›", func() -> void: page += 1; build()))
	modulate.a = 0.5
	entrance = create_tween()
	entrance.tween_property(self, "modulate:a", 1.0, 0.25)
