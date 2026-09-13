class_name AIProfile
extends Resource
## Preferences evaluated by the shared controller, not stat bonuses.
@export var id := ""
@export_range(1, 10) var skill_level: int = 5
@export_range(0, 1) var aggression: float = 0.3
@export_range(0, 1) var risk_tolerance: float = 0.4
@export_range(0, 1) var boost_usage: float = 0.5
@export_range(0, 1) var powerup_skill: float = 0.5
@export_range(0, 1) var overtake_skill: float = 0.5
@export_range(0, 1) var defensive_skill: float = 0.5
@export_range(0, 1) var mistake_probability: float = 0.1
@export_range(-0.6, 0.6) var preferred_line: float = 0.0
@export_range(0, 1) var recovery_skill: float = 0.5
@export var strategy := ""
@export_range(0.16, 0.35) var reaction_interval := 0.2
@export_range(0.8, 1.35) var corner_anticipation := 1.0
