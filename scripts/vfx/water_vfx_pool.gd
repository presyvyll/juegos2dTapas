class_name WaterVFXPool
extends Node2D
## Fixed storage, one drawing node. No per-effect node/tween creation during a race.

@export var capacity: int = 96
var positions := PackedVector2Array()
var velocities := PackedVector2Array()
var colors := PackedColorArray()
var remaining := PackedFloat32Array()
var lifetime := PackedFloat32Array()
var kinds := PackedInt32Array()
var cursor := 0
var rng := RandomNumberGenerator.new()
var enabled := true

func _ready() -> void:
	z_index = 5
	capacity = clampi(capacity, 16, 128)
	positions.resize(capacity)
	velocities.resize(capacity)
	colors.resize(capacity)
	remaining.resize(capacity)
	lifetime.resize(capacity)
	kinds.resize(capacity)
	rng.seed = 3817 # Separate from gameplay RNG.
	set_process(false)

func visible_point(point: Vector2) -> bool:
	var screen := get_viewport().get_canvas_transform() * point
	return get_viewport_rect().grow(100).has_point(screen)

func emit_slot(point: Vector2, velocity: Vector2, color: Color, duration: float, kind: int) -> void:
	set_process(true)
	positions[cursor] = point
	velocities[cursor] = velocity
	colors[cursor] = color
	remaining[cursor] = duration
	lifetime[cursor] = duration
	kinds[cursor] = kind
	cursor = (cursor + 1) % capacity

func spark(point: Vector2) -> void:
	if enabled and visible_point(point):
		emit_slot(point, Vector2.ZERO, Color("fff2b0"), 0.18, 3)

func burst(point: Vector2, normal: Vector2, color: Color, strength: float = 1.0) -> void:
	if not enabled or not visible_point(point):
		return
	emit_slot(point, Vector2.ZERO, Color("c2fff2"), 0.45, 2)
	var count := 8 if capacity > 48 else 4
	for index in range(count):
		var direction := normal.rotated(rng.randf_range(-1.8, 1.8))
		emit_slot(point, direction * rng.randf_range(55, 150) * strength, color if index % 2 == 0 else Color("d6fff9"), rng.randf_range(0.25, 0.55), 0)

func wake(point: Vector2, velocity: Vector2, color: Color, turbo: bool) -> void:
	if not enabled or not visible_point(point):
		return
	var direction := -velocity.normalized()
	emit_slot(point + Vector2(-18, 0), direction * 25, color, 0.38 if turbo else 0.65, 1 if turbo else 2)
	emit_slot(point + Vector2(18, 0), direction * 25, color, 0.38 if turbo else 0.65, 1 if turbo else 2)

func _process(delta: float) -> void:
	var changed := false
	var alive := false
	var damping := exp(-2 * delta)
	for index in range(capacity):
		if remaining[index] <= 0:
			continue
		changed = true
		remaining[index] = maxf(0, remaining[index] - delta)
		alive = alive or remaining[index] > 0
		positions[index] += velocities[index] * delta
		velocities[index] *= damping
	if changed:
		queue_redraw()
	if not alive:
		set_process(false)

func _draw() -> void:
	for index in range(capacity):
		if remaining[index] <= 0:
			continue
		var fraction := remaining[index] / lifetime[index]
		var color := colors[index]
		color.a *= fraction * 0.8
		var point := positions[index]
		match kinds[index]:
			0:
				draw_line(point, point - velocities[index].normalized() * (5 + fraction * 7), color, 2 + fraction * 2, true)
			1:
				draw_line(point, point + velocities[index].normalized() * (22 + (1 - fraction) * 15), color, 3 * fraction + 1, true)
			2:
				draw_arc(point, 6 + (1 - fraction) * 24, 0.15, PI - 0.15, 12, color, 1.5, true)
			3:
				var extent := 8 + fraction * 18
				draw_line(point - Vector2(extent, 0), point + Vector2(extent, 0), color, 3, true)
				draw_line(point - Vector2(0, extent), point + Vector2(0, extent), color, 3, true)
