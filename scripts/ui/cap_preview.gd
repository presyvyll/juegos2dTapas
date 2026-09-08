extends Control

var tint: Color = Color("ffce58")
var appearance := CapAppearance.new()
var art_scale := 2.2

func _ready() -> void:
	custom_minimum_size = Vector2(180, 130)
	resized.connect(queue_redraw)

func _draw() -> void:
	if appearance.portrait_texture:
		var extent := Vector2.ONE * minf(160, minf(size.x, size.y))
		draw_texture_rect(appearance.portrait_texture, Rect2((size - extent) / 2, extent), false)
		return
	draw_set_transform(size / 2 + Vector2(0, 8), 0, Vector2.ONE * art_scale)
	CapArt.draw_cap(self, appearance, tint)
