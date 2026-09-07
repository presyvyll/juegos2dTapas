class_name CircuitDefinition
extends Resource

@export var id: String = "fuente"
@export var display_name: String = "Fuente Caribe"
@export var description: String = "Curvas turquesa, islas y chorros de agua."
@export var price: int = 0
@export var length: float = 18000.0
@export var width: float = 620.0
@export var curve_amplitude: float = 210.0
@export var seed_value: int = 42
@export_range(1, 3) var laps: int = 1
