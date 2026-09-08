class_name TurboConfig
extends Resource
## Defaults preserve the existing gameplay exactly.

@export_range(0.05, 1.0) var energy_cost: float = 0.45
@export_range(0.1, 3.0) var duration: float = 0.9
@export_range(0.01, 1.0) var recharge_per_second: float = 0.105
@export_range(1.0, 2.0) var speed_multiplier: float = 1.6
