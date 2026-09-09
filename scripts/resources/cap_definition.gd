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
@export_group("Arcade content")
@export var ratings: CapRatings
@export var ability: CapAbilityDefinition
@export var preferred_ai_profile: AIProfile
@export_enum("Equilibrada", "Velocista", "Pesada", "Técnica", "Turbo", "Agresiva", "Especial") var archetype := "Equilibrada"
@export var nickname := ""
@export_multiline var description := ""
@export_enum("comun", "poco_comun", "rara", "epica", "legendaria") var rarity := "comun"
@export_enum("start", "cup_podium", "cup_champion", "coins") var unlock_method := "coins"
@export var unlock_requirement := ""
@export var legacy_ids: PackedStringArray = []
@export var primary_visual_theme := ""
@export var victory_animation_reference := "procedural:existing_victory"
@export var defeat_animation_reference := ""
@export var art_requirement := ""
