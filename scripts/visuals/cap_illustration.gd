class_name CapIllustration
extends Node2D

var appearance := CapAppearance.new()
var tint := Color("ffce58")
var mood := 0

func set_mood(value: int) -> void:
	if mood != value:
		mood = value
		queue_redraw()

func _draw() -> void:
	CapArt.draw_cap(self, appearance, tint, mood)
