class_name ComboConfig
extends Resource

@export_range(1.0, 8.0, 0.1) var window_seconds := 4.0
@export_range(2, 6, 1) var max_chain := 6
@export_range(2, 6, 1) var mega_threshold := 5
@export_range(0.1, 1.0, 0.05) var feedback_interval := 0.35
@export var minimum_impact := 60.0
@export var maximum_controlled_impact := 220.0
@export var action_names: Dictionary = {
	"perfect_shot": "Perfect Shot", "turbo": "Turbo", "pickup": "Recogida",
	"overtake": "Adelantamiento", "rebound": "Rebote", "rival_hit": "Golpe a rival"
}
