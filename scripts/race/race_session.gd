class_name RaceSession
extends Node

signal started
signal player_finished(place: int, time: float)
signal countdown_changed(value: int)
var caps: Array[RacingCap] = []
var finish_order: Array[RacingCap] = []
var circuit: CircuitDefinition
var checkpoint_count := 12
var elapsed := 0.0
var countdown := 3.0
var running := false
var announced := -1

func _physics_process(delta: float) -> void:
	if not caps.is_empty() and finish_order.size() == caps.size():
		return
	if not running:
		countdown -= delta
		var number := maxi(0, ceili(countdown))
		if announced != number:
			announced = number
			countdown_changed.emit(number)
		if countdown <= 0:
			running = true
			for cap in caps:
				cap.active = true
			started.emit()
		return
	elapsed += delta

func cross_checkpoint(cap: RacingCap, index: int) -> void:
	if not running or cap.finished or index != cap.checkpoint_index:
		return
	cap.checkpoint_index += 1
	if cap.checkpoint_index < checkpoint_count:
		return
	if cap.lap < circuit.laps:
		cap.lap += 1
		cap.checkpoint_index = 0
		cap.position = Vector2(0, 40)
		cap.currents.clear()
		cap.get_node("Camera2D").global_position = cap.global_position
		return
	cap.finished = true
	cap.active = false
	cap.finish_time = elapsed
	cap.velocity = Vector2.ZERO
	cap.set_deferred("collision_layer", 0)
	finish_order.append(cap)
	if cap == caps[0]:
		player_finished.emit(finish_order.size(), elapsed)

func progress(cap: RacingCap) -> float:
	return (cap.lap - 1) * circuit.length + clampf(-cap.position.y, 0, circuit.length)

func standings() -> Array[RacingCap]:
	var result: Array[RacingCap] = caps.duplicate()
	result.sort_custom(func(a: RacingCap, b: RacingCap) -> bool:
		if a.finished and b.finished:
			return a.finish_time < b.finish_time
		if a.finished != b.finished:
			return a.finished
		return progress(a) > progress(b)
	)
	return result
