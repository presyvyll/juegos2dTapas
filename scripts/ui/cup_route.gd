extends Control

signal selected(index: int)
var cup: ChampionshipDefinition
var completed := 0
var rounds: Array = []
var selected_index := 0
var available := false
var markers: Array[Button] = []

func _ready() -> void:
	custom_minimum_size = Vector2(860, 132)
	resized.connect(queue_redraw)
	for i in range(cup.track_ids.size()):
		var title := cup.track_ids[i]
		for entry in RacingCatalog.circuits():
			if entry.id == title: title = entry.display_name
		var marker := RacingUI.button(("FINAL" if i == cup.track_ids.size() - 1 else str(i + 1)) + "\n" + title, func() -> void: selected.emit(i))
		marker.add_theme_font_size_override("font_size", 14)
		marker.custom_minimum_size = Vector2(154, 56)
		var ratio := float(i) / maxf(1, cup.track_ids.size() - 1)
		marker.anchor_left = ratio
		marker.anchor_right = ratio
		marker.offset_left = -154 * ratio
		marker.offset_right = 154 * (1 - ratio)
		marker.offset_top = 25 + sin(i * 1.8) * 17
		marker.offset_bottom = marker.offset_top + 56
		marker.tooltip_text = "Completada" if i < completed else ("Siguiente carrera" if i == completed and available else "Completa las carreras anteriores")
		if i == selected_index:
			marker.add_theme_stylebox_override("normal", RacingUI.box(Color("69e7d4"), 12))
		elif i > completed or not available:
			marker.add_theme_stylebox_override("normal", RacingUI.box(Color("729591"), 12))
		add_child(marker)
		markers.append(marker)
		marker.modulate.a = 0
		var tween := create_tween()
		tween.tween_property(marker, "modulate:a", 1.0, 0.20).set_delay(i * 0.025)
		if i == completed and available:
			tween.tween_property(marker, "self_modulate", Color("caffed"), 0.15)
			tween.tween_property(marker, "self_modulate", Color.WHITE, 0.15)

func _draw() -> void:
	for i in range(markers.size() - 1):
		var a := markers[i].get_rect().get_center()
		var b := markers[i + 1].get_rect().get_center()
		var path := PackedVector2Array()
		for step in range(17):
			var t := float(step) / 16
			path.append(a.lerp(b, t) + Vector2(0, sin(t * PI) * 22))
		draw_polyline(path, Color("69e7d4") if i < completed else Color("456669"), 5, true)
