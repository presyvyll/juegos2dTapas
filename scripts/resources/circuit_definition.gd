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
@export_range(1, 100) var record_version: int = 1
@export_group("Channel geometry")
@export_range(400, 4000) var curve_period: float = 1450.0
@export_range(300, 2000) var secondary_curve_period: float = 630.0
@export_range(0, 180) var width_variation: float = 85.0
@export var water_color: Color = Color("18b6c4")
@export var storm := false
@export_group("Authored layout")
## False preserves the original seeded courses, including their obstacle order.
@export var authored_layout := false
@export var features: Array[CircuitFeature] = []
## Menu entries reference layouts by path so browsing does not load their scenes.
@export_file("*.tres") var layout_path := ""
@export var section_distances: PackedFloat32Array = []
@export var section_labels: PackedStringArray = []
@export_group("Arcade content metadata")
@export_range(1, 10) var difficulty_rating: int = 1
@export_range(1, 20) var recommended_level: int = 1
@export var theme_id := ""
@export_enum("coins", "start", "cup_podium") var unlock_method := "coins"
@export var unlock_requirement := ""
@export var hazards: PackedStringArray = []
@export var special_zones: PackedStringArray = []
@export_range(-1, 1) var ai_difficulty_modifier: int = 0
@export_range(1, 1.15) var reward_multiplier: float = 1.0
@export var thumbnail: Texture2D
@export_file("*.tscn") var scene_reference := "res://levels/race.tscn"

func record_key(difficulty: String, lap_count: int) -> String:
	var course_key := id if record_version == 1 else "%s_v%d" % [id, record_version]
	return "%s_%s_%d" % [course_key, difficulty, lap_count]
