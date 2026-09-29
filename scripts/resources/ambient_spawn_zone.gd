class_name AmbientSpawnZone
extends Resource

enum Kind { SPECTATOR, ANIMAL, COMMERCE, MIXED }
enum Density { LOW, MEDIUM, HIGH }

@export var kind: Kind = Kind.SPECTATOR
@export_range(300.0, 30000.0, 50.0) var distance_start := 600.0
@export_range(300.0, 30000.0, 50.0) var distance_end := 4000.0
@export_range(-1, 1) var side := 0
@export_range(90.0, 500.0, 5.0) var offset_min := 125.0
@export_range(100.0, 650.0, 5.0) var offset_max := 280.0
@export var density: Density = Density.MEDIUM

