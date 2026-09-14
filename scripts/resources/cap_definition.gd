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
@export_group("Movement tuning")
## Neutral defaults preserve existing resources and saved cap IDs.
@export_range(0.8, 1.2) var bounce: float = 1.0
@export_range(0.8, 1.2) var friction: float = 1.0
## Multiplies lateral water damping, not health or damage resistance.
@export_range(0.8, 1.2) var stability: float = 1.0
@export_range(0.8, 1.2) var lateral_impulse: float = 1.0
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

func resolve_physics(base: CapPhysicsConfig) -> CapPhysicsConfig:
	var result := base.duplicate() as CapPhysicsConfig
	result.current_speed *= speed
	result.acceleration *= acceleration
	result.lateral_force *= handling
	result.weight *= weight
	result.boost_impulse *= boost
	result.wall_bounce = clampf(result.wall_bounce * bounce, 0.0, 1.0)
	result.friction *= friction
	result.water_resistance *= stability
	result.lateral_impulse *= lateral_impulse
	return result

func garage_indices() -> PackedFloat32Array:
	# Relative indices (100 = baseline), not the staged 1–10 designer ratings.
	return PackedFloat32Array([speed * 100, acceleration * 100, handling * 100, weight * 100, boost * 100])

func movement_summary(base: CapPhysicsConfig) -> String:
	var resolved := resolve_physics(base)
	return "Rebote: %.2f · Fricción: %.2f\nEstabilidad lateral: %.2f · Impulso lateral: %.0f" % [resolved.wall_bounce, resolved.friction, resolved.water_resistance, resolved.lateral_impulse]
