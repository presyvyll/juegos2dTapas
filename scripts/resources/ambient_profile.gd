class_name AmbientProfile
extends Resource

enum AmbientQuality { LOW, MEDIUM, HIGH }

@export var id := "fuente_promenade"
@export var people_pool := PackedStringArray(["adulto", "joven", "familia", "vendedor", "turista", "fotografo", "sentado"])
@export var animal_pool := PackedStringArray(["perro", "gato", "ave", "gallina"])
@export var commerce_pool := PackedStringArray(["Colmado La Curva", "Frutas del Malecón", "Café La Tapa", "Kiosco Brisa"])
@export var prop_pool := PackedStringArray(["palmera", "banco", "bandera", "cajas_fruta"])
@export var special_events := PackedStringArray(["cheer", "wave", "photo", "birds", "leaves"])
@export_range(0, 2) var spectator_density := 1
@export_range(0, 2) var animal_density := 0
@export_range(0, 2) var commerce_density := 1
@export var commerce_color := Color("743b20")
@export var accent_color := Color("ffd166")
@export_range(0.1, 1.0, 0.05) var spawn_probability := 0.78
@export_range(0.0, 1.0, 0.05) var animation_probability := 0.72
@export_range(240.0, 900.0, 20.0) var base_spacing := 480.0
@export_range(80.0, 300.0, 5.0) var track_safe_margin := 110.0
@export_range(4, 80) var max_low := 18
@export_range(4, 100) var max_medium := 30
@export_range(4, 120) var max_high := 46
@export var zones: Array[AmbientSpawnZone] = []

func limit_for(quality: AmbientQuality) -> int:
	match quality:
		AmbientQuality.LOW: return max_low
		AmbientQuality.MEDIUM: return max_medium
		_: return max_high

func quality_spacing(quality: AmbientQuality) -> float:
	match quality:
		AmbientQuality.LOW: return base_spacing * 1.55
		AmbientQuality.MEDIUM: return base_spacing * 1.18
		_: return base_spacing

func resolved_zones(track_length: float) -> Array[AmbientSpawnZone]:
	if not zones.is_empty():
		return zones
	var generated: Array[AmbientSpawnZone] = []
	generated.append(_zone(AmbientSpawnZone.Kind.SPECTATOR, 650.0, track_length * 0.24, 0, 125.0, 170.0, spectator_density))
	generated.append(_zone(AmbientSpawnZone.Kind.COMMERCE, track_length * 0.27, track_length * 0.47, -1, 120.0, 140.0, commerce_density))
	generated.append(_zone(AmbientSpawnZone.Kind.ANIMAL, track_length * 0.49, track_length * 0.70, 0, 120.0, 180.0, animal_density))
	generated.append(_zone(AmbientSpawnZone.Kind.SPECTATOR, track_length * 0.74, track_length - 400.0, 0, 120.0, 170.0, 2))
	return generated

func _zone(kind: AmbientSpawnZone.Kind, start: float, end: float, side: int, min_offset: float, max_offset: float, density: int) -> AmbientSpawnZone:
	var zone := AmbientSpawnZone.new()
	zone.kind = kind
	zone.distance_start = start
	zone.distance_end = end
	zone.side = side
	zone.offset_min = min_offset
	zone.offset_max = max_offset
	zone.density = density
	return zone
