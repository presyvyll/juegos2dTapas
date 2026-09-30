class_name TrackAmbientSpawner
extends Node2D
## Batched, collision-free ambient life for the banks of a race track.

static var session_sequence := 0

var track: RaceTrack
var profile: Resource
var seed_override := -1
var run_seed := 0
var quality := AmbientProfile.AmbientQuality.HIGH
var instances: Array[Dictionary] = []
var visible_count := 0
var clock := 0.0
var refresh_left := 0.0
var camera_y := 0.0
var target: RacingCap
var events: Array[Dictionary] = []
var boost_pulse := 0.0
var overtake_pulse := 0.0
var finish_pulse := 0.0

func _ready() -> void:
	if not track or not profile:
		set_process(false)
		return
	quality = AmbientProfile.AmbientQuality.HIGH if track.high_quality else AmbientProfile.AmbientQuality.LOW
	if seed_override >= 0:
		run_seed = seed_override
	else:
		run_seed = track.definition.seed_value + session_sequence * 7919
		session_sequence += 1
	_generate()
	queue_redraw()

func _process(delta: float) -> void:
	clock += delta
	boost_pulse = maxf(0.0, boost_pulse - delta * 1.4)
	overtake_pulse = maxf(0.0, overtake_pulse - delta * 1.8)
	finish_pulse = maxf(0.0, finish_pulse - delta * 0.45)
	_update_events(delta)
	refresh_left -= delta
	if refresh_left > 0.0:
		return
	refresh_left = 0.08 if quality == AmbientProfile.AmbientQuality.HIGH else 0.16
	var inverse := get_viewport().get_canvas_transform().affine_inverse()
	camera_y = target.global_position.y if is_instance_valid(target) else (inverse * (get_viewport_rect().size * 0.5)).y
	queue_redraw()

func bind_target(value: RacingCap) -> void:
	target = value
	if not is_instance_valid(target): return
	target.boosted.connect(func() -> void: boost_pulse = 1.0)
	target.race_power.activated.connect(func(_id: String) -> void: boost_pulse = 0.75)

func react_to_overtake() -> void:
	overtake_pulse = 1.0

func start_final_sprint() -> void:
	overtake_pulse = 1.25

func celebrate_finish() -> void:
	finish_pulse = 2.2

func _generate() -> void:
	instances.clear()
	events.clear()
	var rng := RandomNumberGenerator.new()
	rng.seed = run_seed
	var last_variant := ""
	var limit: int = profile.limit_for(quality)
	var zones: Array = profile.resolved_zones(track.definition.length)
	for zone in zones:
		if instances.size() >= limit:
			break
		var density_scale: float = [1.45, 1.0, 0.72][zone.density]
		var spacing: float = profile.quality_spacing(quality) * density_scale
		var distance: float = zone.distance_start + rng.randf_range(0.0, spacing * 0.55)
		while distance <= zone.distance_end and instances.size() < limit:
			if rng.randf() <= profile.spawn_probability:
				var side_value := float(zone.side)
				if zone.side == 0:
					side_value = -1.0 if rng.randi_range(0, 1) == 0 else 1.0
				var kind := _resolve_kind(zone.kind, rng)
				var pool := _pool_for(kind)
				var variant := _pick_without_repeat(pool, last_variant, rng)
				last_variant = variant
				var y: float = -distance
				var edge := track.center_at(y) + side_value * track.width_at(y) * 0.5
				var safe_offset: float = maxf(zone.offset_min, profile.track_safe_margin)
				var offset := rng.randf_range(safe_offset, maxf(safe_offset + 1.0, zone.offset_max))
				var animations := _animations_for(kind)
				var animation := animations[rng.randi_range(0, animations.size() - 1)] if rng.randf() <= profile.animation_probability else "idle"
				instances.append({
					"kind": kind,
					"variant": variant,
					"position": Vector2(edge + side_value * offset, y),
					"side": side_value,
					"scale": rng.randf_range(0.88, 1.12),
					"phase": rng.randf_range(0.0, TAU),
					"animation": animation,
					"event": profile.special_events[rng.randi_range(0, profile.special_events.size() - 1)],
					"group": rng.randi_range(1, 3) if kind == "person" else 1,
				})
			distance += spacing * rng.randf_range(0.82, 1.22)
	var event_count := 1 if quality == AmbientProfile.AmbientQuality.LOW else rng.randi_range(2, 3)
	var event_types := PackedStringArray(["birds", "leaves", "festival"])
	for index in range(event_count):
		var fraction := (index + 1.0) / (event_count + 1.0) + rng.randf_range(-0.055, 0.055)
		var y := -track.definition.length * clampf(fraction, 0.18, 0.82)
		events.append({
			"type": event_types[(index + rng.randi_range(0, event_types.size() - 1)) % event_types.size()],
			"position": Vector2(track.center_at(y), y),
			"side": -1.0 if rng.randi_range(0, 1) == 0 else 1.0,
			"triggered": false,
			"elapsed": 0.0,
			"phase": rng.randf_range(0.0, TAU),
		})

func _update_events(delta: float) -> void:
	if not is_instance_valid(target): return
	for index in range(events.size()):
		var event := events[index]
		if not event.triggered and target.active and absf(target.global_position.y - event.position.y) < 310.0:
			event.triggered = true
			event.elapsed = 0.001
		if event.triggered:
			event.elapsed = float(event.elapsed) + delta
		events[index] = event

func _resolve_kind(zone_kind: AmbientSpawnZone.Kind, rng: RandomNumberGenerator) -> String:
	match zone_kind:
		AmbientSpawnZone.Kind.ANIMAL: return "animal"
		AmbientSpawnZone.Kind.COMMERCE: return "commerce"
		AmbientSpawnZone.Kind.MIXED: return ["person", "animal", "commerce"][rng.randi_range(0, 2)]
		_: return "person"

func _pool_for(kind: String) -> PackedStringArray:
	match kind:
		"animal": return profile.animal_pool
		"commerce": return profile.commerce_pool
		_: return profile.people_pool

func _pick_without_repeat(pool: PackedStringArray, previous: String, rng: RandomNumberGenerator) -> String:
	if pool.is_empty():
		return "ambient"
	var choice := pool[rng.randi_range(0, pool.size() - 1)]
	if pool.size() > 1 and choice == previous:
		choice = pool[(pool.find(choice) + 1 + rng.randi_range(0, pool.size() - 2)) % pool.size()]
	return choice

func _animations_for(kind: String) -> PackedStringArray:
	match kind:
		"animal": return PackedStringArray(["idle", "walk", "look", "run", "fly"])
		"commerce": return PackedStringArray(["idle", "wave"])
		_: return PackedStringArray(["idle", "cheer", "wave", "jump", "look", "photo"])

func _draw() -> void:
	if not track or instances.is_empty():
		return
	var inverse := get_viewport().get_canvas_transform().affine_inverse()
	var bounds := Rect2(inverse * Vector2.ZERO, Vector2.ZERO)
	bounds = bounds.expand(inverse * get_viewport_rect().size).grow(320.0)
	visible_count = 0
	for layer_kind in ["commerce", "person", "animal"]:
		for item in instances:
			if item.kind != layer_kind or not bounds.has_point(item.position):
				continue
			visible_count += 1
			var reaction := 1.0 - clampf(absf(item.position.y - camera_y) / 390.0, 0.0, 1.0)
			reaction = clampf(reaction + boost_pulse * 0.45 + overtake_pulse * 0.55 + finish_pulse * 0.65, 0.0, 1.8)
			match layer_kind:
				"commerce": _draw_commerce(item, reaction)
				"animal": _draw_animal(item, reaction)
				_: _draw_people(item, reaction)
	_draw_events(bounds)

func _draw_events(bounds: Rect2) -> void:
	for event in events:
		if not event.triggered or float(event.elapsed) > 2.4 or not bounds.grow(420.0).has_point(event.position): continue
		var progress := clampf(float(event.elapsed) / 2.4, 0.0, 1.0)
		var fade := smoothstep(0.0, 0.12, progress) * (1.0 - smoothstep(0.72, 1.0, progress))
		var origin: Vector2 = event.position
		var side: float = event.side
		match event.type:
			"birds":
				for bird in range(7 if quality == AmbientProfile.AmbientQuality.HIGH else 4):
					var point := origin + Vector2((bird - 3) * 35.0 + side * progress * 260.0, -80.0 - progress * 190.0 - absf(bird - 3) * 10.0)
					var flap := sin(clock * 11.0 + bird) * 8.0
					var color := Color(0.94, 0.98, 1.0, fade)
					draw_arc(point, 13.0, PI + 0.15, TAU - 0.25 + flap * 0.012, 7, color, 3.0, true)
					draw_arc(point + Vector2(21, 0), 13.0, PI + 0.25 - flap * 0.012, TAU - 0.15, 7, color, 3.0, true)
			"leaves":
				for leaf in range(14 if quality == AmbientProfile.AmbientQuality.HIGH else 7):
					var sweep := Vector2(side * (progress * 520.0 - 250.0), sin(clock * 4.0 + leaf) * 85.0 + (leaf - 7) * 13.0)
					var color: Color = [Color("77a84f"), Color("ffd166"), Color("3eb489")][leaf % 3]
					color.a = fade * 0.85
					draw_set_transform(origin + sweep, clock * 4.0 + leaf, Vector2.ONE)
					draw_rect(Rect2(-5, -2, 10, 4), color)
				draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
			_:
				var edge := track.width_at(origin.y) * 0.5 + 95.0
				for piece in range(12 if quality == AmbientProfile.AmbientQuality.HIGH else 6):
					var direction := -1.0 if piece % 2 == 0 else 1.0
					var point := origin + Vector2(direction * edge + sin(piece) * 48.0, -progress * 160.0 + fposmod(piece * 43.0, 110.0))
					var color: Color = [profile.accent_color, Color("55d6e8"), Color("ff6b6b")][piece % 3]
					color.a = fade
					draw_circle(point, 4.0, color)

func _draw_commerce(item: Dictionary, reaction: float) -> void:
	var spot: Vector2 = item.position
	var side: float = item.side
	var scale_value: float = item.scale
	var width := 150.0 * scale_value
	var height := 112.0 * scale_value
	spot.x += side * 35.0
	var commerce_color: Color = profile.commerce_color
	var accent_color: Color = profile.accent_color
	draw_rect(Rect2(spot - Vector2(width * 0.5, height), Vector2(width, height)), commerce_color)
	draw_rect(Rect2(spot - Vector2(width * 0.43, height * 0.82), Vector2(width * 0.86, height * 0.42)), accent_color)
	for stripe in range(5):
		var stripe_width := width / 5.0
		draw_rect(Rect2(spot + Vector2(-width * 0.5 + stripe * stripe_width, -height - 18), Vector2(stripe_width, 24)), Color("ef5350") if stripe % 2 == 0 else Color("fff4d6"))
	draw_rect(Rect2(spot + Vector2(-width * 0.32, -height * 0.34), Vector2(width * 0.24, height * 0.34)), Color("2f7673"))
	draw_rect(Rect2(spot + Vector2(width * 0.08, -height * 0.34), Vector2(width * 0.24, height * 0.34)), Color("2f7673"))
	draw_rect(Rect2(spot + Vector2(-width * 0.48, -height - 48), Vector2(width * 0.96, 28)), Color("3b1b11"))
	draw_string(ThemeDB.fallback_font, spot + Vector2(-width * 0.43, -height - 28), item.variant, HORIZONTAL_ALIGNMENT_CENTER, width * 0.86, 14, Color("fff1c2"))
	if item.event == "leaves" and reaction > 0.15:
		for leaf in range(3):
			var drift := Vector2(side * reaction * (18.0 + leaf * 7.0), sin(clock * 2.0 + leaf) * 12.0)
			draw_circle(spot + Vector2(0, -height) + drift, 4.0, Color("77a84f"))

func _draw_people(item: Dictionary, reaction: float) -> void:
	var count: int = item.group
	for member in range(count):
		var local_phase: float = item.phase + member * 1.7
		var spot: Vector2 = item.position + Vector2((member - (count - 1) * 0.5) * 31.0, 0)
		var scale_value: float = item.scale * (0.93 + member * 0.035)
		var bounce := 0.0
		if item.animation in ["cheer", "jump"]:
			bounce = -absf(sin(clock * 4.2 + local_phase)) * 10.0 * maxf(0.25, reaction)
		spot.y += bounce
		var skin: Color = [Color("6f3c27"), Color("a76642"), Color("d69a68"), Color("78482f")][posmod(item.variant.hash() + member, 4)]
		var accent: Color = profile.accent_color
		var shirt: Color = [Color("1bb7b0"), Color("ef5f55"), accent, Color("4f79d8"), Color("8d62c7")][posmod(item.variant.hash() + member * 2, 5)]
		draw_circle(spot + Vector2(0, -48) * scale_value, 10.0 * scale_value, skin)
		draw_colored_polygon(PackedVector2Array([
			spot + Vector2(-12, -37) * scale_value,
			spot + Vector2(12, -37) * scale_value,
			spot + Vector2(17, -5) * scale_value,
			spot + Vector2(-17, -5) * scale_value,
		]), shirt)
		var arm_lift := reaction if item.animation in ["cheer", "wave", "photo"] else reaction * 0.35
		var wave := sin(clock * 6.0 + local_phase) * 7.0 * arm_lift
		draw_line(spot + Vector2(-10, -31) * scale_value, spot + Vector2(-20 - wave, -22 - arm_lift * 25) * scale_value, skin, 5.0 * scale_value, true)
		draw_line(spot + Vector2(10, -31) * scale_value, spot + Vector2(20 + wave, -22 - arm_lift * 25) * scale_value, skin, 5.0 * scale_value, true)
		draw_line(spot + Vector2(-7, -5) * scale_value, spot + Vector2(-8, 18) * scale_value, Color("25384a"), 6.0 * scale_value, true)
		draw_line(spot + Vector2(7, -5) * scale_value, spot + Vector2(8, 18) * scale_value, Color("25384a"), 6.0 * scale_value, true)
		if item.variant == "fotografo" or item.animation == "photo":
			draw_rect(Rect2(spot + Vector2(-7, -35) * scale_value, Vector2(14, 9) * scale_value), Color("17222d"))
			if reaction > 0.82 and sin(clock * 9.0 + local_phase) > 0.72:
				draw_circle(spot + Vector2(0, -35) * scale_value, 13.0 * scale_value, Color(1.0, 0.95, 0.65, 0.55))

func _draw_animal(item: Dictionary, reaction: float) -> void:
	var spot: Vector2 = item.position
	var side: float = item.side
	var phase: float = item.phase
	var move := reaction * (26.0 if item.animation in ["run", "fly"] else 8.0)
	spot += Vector2(side * move, sin(clock * 2.8 + phase) * 3.0)
	var scale_value: float = item.scale
	if item.variant == "ave":
		spot.y -= reaction * 52.0
		var flap := sin(clock * 7.0 + phase) * 10.0
		draw_arc(spot, 16.0 * scale_value, PI + 0.2, TAU - 0.2 + flap * 0.01, 8, Color("edf3e5"), 4.0, true)
		draw_arc(spot + Vector2(25, 0), 16.0 * scale_value, PI + 0.2 - flap * 0.01, TAU - 0.2, 8, Color("edf3e5"), 4.0, true)
		return
	var fur := Color("bd793f") if item.variant in ["perro", "gallina"] else Color("59626b")
	draw_ellipse(spot + Vector2(0, -13), Vector2(21, 13) * scale_value, fur)
	draw_circle(spot + Vector2(side * 18, -20) * scale_value, 10.0 * scale_value, fur)
	draw_line(spot + Vector2(-10, -4) * scale_value, spot + Vector2(-10, 10) * scale_value, fur.darkened(0.18), 4.0, true)
	draw_line(spot + Vector2(9, -4) * scale_value, spot + Vector2(9, 10) * scale_value, fur.darkened(0.18), 4.0, true)
	if item.variant == "gallina":
		draw_circle(spot + Vector2(side * 18, -31) * scale_value, 4.0 * scale_value, Color("e94d45"))
	else:
		draw_line(spot + Vector2(-18 * side, -15) * scale_value, spot + Vector2(-29 * side, -27) * scale_value, fur, 4.0, true)

func draw_ellipse(center: Vector2, radii: Vector2, color: Color) -> void:
	var points := PackedVector2Array()
	for index in range(16):
		var angle := TAU * index / 16.0
		points.append(center + Vector2(cos(angle) * radii.x, sin(angle) * radii.y))
	draw_colored_polygon(points, color)

func all_instances_clear_of_track() -> bool:
	for item in instances:
		var point: Vector2 = item.position
		var edge_distance := absf(point.x - track.center_at(point.y)) - track.width_at(point.y) * 0.5
		if edge_distance < profile.track_safe_margin - 0.1:
			return false
	return true

func distribution_signature() -> String:
	var parts := PackedStringArray()
	for item in instances:
		parts.append("%s:%s:%d:%d" % [item.kind, item.variant, roundi(item.position.x), roundi(item.position.y)])
	return "|".join(parts)
