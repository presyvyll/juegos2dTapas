class_name PowerUpDefinition
extends Resource

@export var id := ""
@export var display_name := ""
@export var color := Color.WHITE
@export var duration := 0.0
@export var amount := 0.5

func apply(_cap: RacingCap) -> void:
	pass
