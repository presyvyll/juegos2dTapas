class_name RacingCatalog
extends RefCounted

static func caps() -> Array[CapDefinition]:
	return (load("res://data/catalog.tres") as RacingCatalogData).caps

static func circuits() -> Array[CircuitDefinition]:
	return (load("res://data/catalog.tres") as RacingCatalogData).circuits

static func championships() -> Array[ChampionshipDefinition]:
	return (load("res://data/catalog.tres") as RacingCatalogData).championships

static func championship(id: String) -> ChampionshipDefinition:
	for cup in championships():
		if cup.id == id:
			return cup
	return null

static func load_circuit(entry: CircuitDefinition) -> CircuitDefinition:
	if entry.layout_path.is_empty():
		return entry.duplicate() as CircuitDefinition
	var layout := load(entry.layout_path) as CircuitDefinition
	if layout == null or layout.id != entry.id or not layout.authored_layout:
		push_error("Invalid circuit layout: " + entry.layout_path)
		return null
	return layout.duplicate() as CircuitDefinition

static func cap_ids() -> Array:
	var result: Array = []
	for cap in caps():
		result.append(cap.id)
	return result

static func circuit_ids() -> Array:
	var result: Array = []
	for circuit in circuits():
		result.append(circuit.id)
	return result
