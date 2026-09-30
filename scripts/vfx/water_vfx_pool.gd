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

func energy_transfer(from: Vector2, to: Vector2, color: Color) -> void:
	if not enabled or not visible_point(to): return
	var delta := to - from
	var count := 7 if capacity > 48 else 4
	for index in range(count):
		var fraction := float(index) / float(maxi(1, count - 1))
		var point := from.lerp(to, fraction)
		emit_slot(point, delta.normalized() * (80.0 + index * 12.0), color.lightened(fraction * 0.25), 0.30 + fraction * 0.12, 6)
	spark(to)

func wake(point: Vector2, velocity: Vector2, color: Color, turbo: bool) -> void:
	if not enabled or not visible_point(point) or velocity.length_squared() < 1.0:
		return
	var direction := -velocity.normalized()
	var speed := velocity.length()
	var span := lerpf(12.0, 22.0, clampf((speed - 90.0) / 320.0, 0.0, 1.0))
	emit_slot(point + direction.orthogonal() * span, direction * 25, color, 0.38 if turbo else 0.65, 1 if turbo else 2)
	emit_slot(point - direction.orthogonal() * span, direction * 25, color, 0.38 if turbo else 0.65, 1 if turbo else 2)
	if speed > 220.0:
		var foam := color
		foam.a *= 0.7
		emit_slot(point + direction * 10.0, direction * 18, foam, 0.32 if turbo else 0.5, 2)
	if turbo and capacity > 48:
		emit_slot(point, direction * 40, color, 0.28, 1)

func edge_scrape(point: Vector2, normal: Vector2, motion: Vector2, strength: float) -> void:
	if not enabled or not visible_point(point):
		return
	var tangent := motion.slide(normal).normalized()
	if tangent == Vector2.ZERO: tangent = Vector2(-normal.y, normal.x)
	var speed := clampf(strength, 18.0, 80.0)
	for offset in [-10.0, 0.0, 10.0]:
		emit_slot(point + tangent * offset + normal * 18.0, tangent * speed * 0.45, Color("d5fff6"), 0.30, 4)

func edge_rebound(point: Vector2, normal: Vector2, strength: float) -> void:
	if not enabled or not visible_point(point):
		return
	emit_slot(point + normal * 32.0, normal, Color("fff0b8"), 0.38 + clampf(strength / 700.0, 0.0, 0.18), 5)

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
			4:
				var direction := velocities[index].normalized()
				draw_line(point - direction * 4.0, point + direction * (12.0 + fraction * 14.0), color, 3.0, true)
				draw_circle(point, 2.0 + fraction * 2.0, color)
			5:
				var angle := velocities[index].angle()
				var radius := 24.0 + (1.0 - fraction) * 44.0
				draw_arc(point, radius, angle - PI * 0.55, angle + PI * 0.55, 16, color, 3.0 * fraction + 1.0, true)
				var inner := color.lightened(0.28)
				inner.a *= 0.62
				draw_arc(point, maxf(8.0, radius - 8.0), angle - PI * 0.48, angle + PI * 0.48, 14, inner, 2.0, true)
			6:
				var direction := velocities[index].normalized()
				draw_line(point - direction * 13.0, point + direction * 5.0, color, 3.0 * fraction + 1.0, true)
				draw_circle(point, 2.0 + fraction * 3.0, color)
