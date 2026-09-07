class_name CapPhysicsConfig
extends Resource
## Shared tuning; each cap can later provide its own resource.

@export_range(50.0, 800.0) var current_speed: float = 240.0
@export_range(50.0, 2000.0) var lateral_force: float = 650.0
@export_range(0.1, 10.0) var acceleration: float = 2.5
@export_range(0.0, 10.0) var water_resistance: float = 3.0
@export_range(0.2, 3.0) var weight: float = 1.0
@export_range(100.0, 1200.0) var max_speed: float = 420.0
@export_range(0.0, 1.0) var wall_bounce: float = 0.55
@export_range(0.0, 3.0) var friction: float = 0.08
@export_range(50.0, 800.0) var boost_impulse: float = 230.0
@export_range(50.0, 600.0) var lateral_impulse: float = 160.0
