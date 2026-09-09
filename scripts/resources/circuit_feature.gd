class_name CircuitFeature
extends Resource
## Placement of a shared scene. Zero overrides preserve its existing defaults.
@export var scene: PackedScene
@export_range(0, 100000) var distance: float = 1000.0
@export_range(-0.8, 0.8) var lane: float = 0.0
@export_group("Rock")
@export_range(0, 150) var rock_radius: float = 0.0
@export_group("Current")
@export var current_direction := Vector2.ZERO
@export_range(0, 800) var current_strength: float = 0.0
@export_range(0, 2) var speed_modifier: float = 0.0
@export var current_size := Vector2.ZERO
@export_range(-1, 150) var turbulence: float = -1.0
@export_group("Whirlpool")
@export_range(0, 200) var whirlpool_radius: float = 0.0
@export_range(-1, 300) var attraction: float = -1.0
@export_range(0, 0.8) var pulse_depth: float = 0.0
@export_range(1, 12) var pulse_period: float = 4.0
@export_group("Moving obstacle")
@export_range(-1, 150) var travel: float = -1.0
@export_range(0, 2) var frequency: float = 0.0
