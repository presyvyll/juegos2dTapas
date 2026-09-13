extends Control

var tint: Color = Color("ffce58")
var appearance := CapAppearance.new()
var art_scale := 2.2
var animated := false
var clock := 0.0

func _process(delta: float) -> void:
	if animated and is_visible_in_tree():
		clock += delta
		queue_redraw()

func _ready() -> void:
	custom_minimum_size = Vector2(180, 130)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(animated)
	resized.connect(queue_redraw)

func _draw() -> void:
	var bob := sin(clock * 1.8) * 4.0 if animated else 0.0
	draw_set_transform(size / 2 + Vector2(0, 45), 0, Vector2(1.0, 0.22))
	draw_circle(Vector2.ZERO, 45 - bob * 0.4, Color(0.01, 0.07, 0.10, 0.22))
	draw_set_transform(Vector2(0, bob))
	if appearance.portrait_texture:
		var extent := Vector2.ONE * minf(160, minf(size.x, size.y))
		draw_texture_rect(appearance.portrait_texture, Rect2((size - extent) / 2, extent), false)
		return
	draw_set_transform(size / 2 + Vector2(0, 8 + bob), sin(clock * 1.2) * 0.025 if animated else 0.0, Vector2.ONE * art_scale)
	CapArt.draw_cap(self, appearance, tint)
