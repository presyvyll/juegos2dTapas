class_name RacingCatalog
extends RefCounted

static func caps() -> Array[CapDefinition]:
	var result: Array[CapDefinition] = []
	for id in ["sol", "coral", "menta", "oceano", "uva", "coco"]:
		result.append(load("res://data/caps/%s.tres" % id) as CapDefinition)
	return result

static func circuits() -> Array[CircuitDefinition]:
	var result: Array[CircuitDefinition] = []
	for id in ["fuente", "cascada"]:
		result.append(load("res://data/circuits/%s.tres" % id) as CircuitDefinition)
	return result
