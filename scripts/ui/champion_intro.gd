class_name ChampionIntro
extends Control
## Shared presentation only. The race owns the countdown and camera lifecycle.
signal completed
const DURATION := 2.5
var cup: ChampionshipDefinition
var appearance: CapAppearance
var tint: Color
var can_skip := false
var elapsed := 0.0
var finished := false
var panel: PanelContainer
var portrait: Control
var skip_button: Button

func _ready() -> void:
	theme = RacingUI.theme()
	process_mode = Node.PROCESS_MODE_PAUSABLE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var shade := ColorRect.new()
	shade.color = Color(0.02, 0.08, 0.14, 0.72)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(shade)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	panel = PanelContainer.new()
	var frame := RacingUI.box(Color("153e47"), 18)
	frame.border_color = cup.champion_accent
	panel.add_theme_stylebox_override("panel", frame)
	panel.custom_minimum_size = Vector2(640, 380)
	center.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	panel.add_child(box)
	var heading := RacingUI.label("FINAL · " + cup.display_name, 22)
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(heading)
	var name_label := RacingUI.label(cup.rival_names[cup.rival_ids.find(cup.champion_id)], 38)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_color_override("font_color", cup.champion_accent)
	box.add_child(name_label)
	portrait = preload("res://scripts/ui/cap_preview.gd").new()
	portrait.appearance = appearance
	portrait.tint = tint
	box.add_child(portrait)
	var quote := RacingUI.label("«" + cup.champion_line + "»", 23)
	quote.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	quote.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(quote)
	var hint := RacingUI.label("Su desafío: acaba por delante y consigue podio en la copa.", 17)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(hint)
	if can_skip:
		skip_button = RacingUI.button("Saltar presentación", finish)
		box.add_child(skip_button)
	else:
		var soon := RacingUI.label("La final comienza en un instante…", 17)
		soon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		box.add_child(soon)
	panel.modulate.a = 0
	queue_redraw()

func _process(delta: float) -> void:
	if finished: return
	elapsed = minf(elapsed + delta, DURATION)
	panel.modulate.a = minf(elapsed / 0.2, (DURATION - elapsed) / 0.2)
	portrait.art_scale = 2.05 + 0.15 * sin(minf(elapsed / 0.5, 1.0) * PI / 2)
	portrait.queue_redraw()
	queue_redraw()
	if elapsed >= DURATION: finish()

func _draw() -> void:
	if cup == null: return
	var pulse := fposmod(elapsed / DURATION, 1.0)
	var color := cup.champion_accent
	color.a = 0.35 * (1.0 - pulse)
	# One ring; no particles, shader or physical body.
	draw_arc(size / 2, 160 + pulse * 300, 0, TAU, 48, color, 6, true)

func finish() -> void:
	if finished: return
	finished = true
	set_process(false)
	completed.emit()
	queue_free()
