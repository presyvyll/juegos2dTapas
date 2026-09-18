class_name ChallengeDefinition
extends Resource
@export var id := ""
@export var title := ""
@export var description := ""
@export_enum("finishes", "wins", "cups", "best_combo", "perfect_shots", "pickups") var metric := "finishes"
@export_range(1, 1000) var target := 1
@export_range(0, 1000) var coins := 50
