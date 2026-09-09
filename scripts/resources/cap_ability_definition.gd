class_name CapAbilityDefinition
extends Resource
## Immutable configuration only; execution and per-racer cooldown live elsewhere.
@export var id := ""
@export var display_name := ""
@export_multiline var description := ""
@export_enum("start", "overtake", "impact_received", "current_enter", "near_rival", "light_obstacle", "turbo", "clean_driving", "strong_impact", "precision_zone", "fast_impact", "first_turbo", "strong_drift", "side_overtake", "adverse_current", "full_turbo", "race_midpoint") var trigger := "start"
@export_range(0, 10) var duration: float = 1.0
@export_range(0, 30) var cooldown: float = 8.0
@export_range(0, 5) var max_uses: int = 0
@export var modifiers: Dictionary = {}
@export var radius: float = 0.0
@export var condition_seconds: float = 0.0
@export var threshold: float = 0.0
@export var secondary_duration: float = 0.0
@export var feedback_color := Color.WHITE
@export var activation_audio: AudioStream
@export var art_requirement := ""
