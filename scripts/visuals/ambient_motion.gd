class_name AmbientMotion
extends Node
## A shared visual clock. Never changes the parent's physics transform.
var phase := 0.0
var interval := 0.05
var remaining := 0.0
var surface: Node2D

func _ready() -> void:
	surface = get_parent() as Node2D
	var settings_service := get_node("/root/SaveManager")
	interval = 0.05 if settings_service.settings.quality == "high" else 0.1
	phase = fposmod(surface.position.y * 0.013, TAU)

func _process(delta: float) -> void:
	phase = fposmod(phase + delta, TAU * 20)
	remaining -= delta
	if remaining > 0:
		return
	var point := surface.get_global_transform_with_canvas().origin
	if not surface.get_viewport_rect().grow(200).has_point(point):
		remaining = 0.25
		return
	remaining = interval
	surface.queue_redraw()
