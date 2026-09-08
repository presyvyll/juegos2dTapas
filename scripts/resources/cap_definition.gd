class_name CapDefinition
extends Resource

@export var id: String = "sol"
@export var display_name: String = "Sol Caribe"
@export var color: Color = Color("ffce58")
@export var price: int = 0
@export var appearance: CapAppearance
@export_range(0.8, 1.2) var speed: float = 1.0
@export_range(0.8, 1.2) var acceleration: float = 1.0
@export_range(0.8, 1.2) var handling: float = 1.0
@export_range(0.8, 1.2) var weight: float = 1.0
@export_range(0.8, 1.2) var boost: float = 1.0
