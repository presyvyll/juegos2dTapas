class_name RacingCatalog
extends RefCounted

static func caps() -> Array[CapDefinition]:
	return (load("res://data/catalog.tres") as RacingCatalogData).caps

static func circuits() -> Array[CircuitDefinition]:
	return (load("res://data/catalog.tres") as RacingCatalogData).circuits

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
