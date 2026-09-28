class_name RacePower
extends Node2D
## One shared inventory and rule set for players and rivals; no scene spawning.
signal activated(id: String)
signal collected(id: String, point: Vector2)
const SPEED_FACTORS := {"turbo": 1.28, "super": 1.6, "dash": 1.75, "recovery": 1.15}
const HINTS := {"turbo": "+28% velocidad", "shield": "Bloquea un impacto", "wave": "Empuja a 240 u", "magnet": "Recoge a 220 u", "dash": "Impulso inmediato", "whirlpool": "Desvía rivales cercanos", "super": "+60% durante 0.8 s", "ghost": "Reduce corrientes e impactos", "heavy": "70% menos empuje", "recovery": "Recupera velocidad ×2"}
const POWERS := {
	"turbo": ["TURBO", "VELOCIDAD", 2.0, "ffd65b", ">>"],
	"shield": ["ESCUDO", "DEFENSA", 3.0, "8ceaff", "[+]"],
	"wave": ["OLA", "ATAQUE", 0.6, "43cfff", "~"],
	"magnet": ["IMÁN", "CONTROL", 3.0, "ff9ada", "U"],
	"dash": ["DASH", "VELOCIDAD", 0.4, "ffffff", ">"],
	"whirlpool": ["REMOLINO", "CONTROL", 1.5, "ba99ff", "@"],
	"super": ["SUPER TURBO", "VELOCIDAD", 0.8, "ff975c", ">>>"],
	"ghost": ["FANTASMA", "DEFENSA", 2.0, "c9fff1", "<>"],
	"heavy": ["PESO PESADO", "DEFENSA", 3.0, "b6c6dd", "#"],
	"recovery": ["RECUPERACIÓN", "RECUPERACIÓN", 2.0, "a6f58b", "+"]
}
var cap: RacingCap
var rivals: Array[RacingCap] = []
var collected_gates: Array[int] = []
var prepared := ""
var current := ""
var remaining := 0.0
var cooldown := 0.0
var collection_origin := Vector2.ZERO
var collection_time := 0.0
var visual_clock := 0.0
var flash_color := Color.WHITE
var disruption := 0.0
var slow_time := 0.0
var opportunities := 0
var chosen := 0
var uses := 0
var pulse := 0.0
var scan_time := 0.0

func leading() -> bool:
	for rival in rivals:
		if rival != cap and (rival.lap > cap.lap or rival.lap == cap.lap and rival.position.y < cap.position.y): return false
	return true

func equip(id: String, gate: int, origin: Vector2) -> bool:
	if not cap.active or cap.finished or get_tree().paused or not POWERS.has(id) or gate in collected_gates: return false
	collected_gates.append(gate)
	opportunities += 1
	prepared = id
	chosen += 1
	pulse = 0.3
	collection_origin = origin
	collection_time = 0.4
	flash_color = Color(POWERS[id][3])
	var reward := PowerUpDefinition.new()
	reward.id = prepared
	reward.display_name = str(POWERS[prepared][0])
	reward.color = Color(POWERS[prepared][3])
	reward.duration = float(POWERS[prepared][2])
	cap.powerup_received.emit(reward)
	collected.emit(id, origin)
	return true

func use_prepared() -> bool:
	if prepared.is_empty() or remaining > 0 or cooldown > 0 or not cap.active or cap.finished or get_tree().paused: return false
	current = prepared
	prepared = ""
	remaining = float(POWERS[current][2])
	cooldown = remaining + 0.6
	cap.boost_time = 0.0
	uses += 1
	pulse = 0.6
	flash_color = Color(POWERS[current][3])
	if current == "shield": cap.shield_time = remaining
	if current in ["turbo", "super", "dash", "recovery"]:
		var flow: Vector2 = cap.track.flow_at(cap.position.y) if is_instance_valid(cap.track) else Vector2.UP
		cap.velocity += flow * (130.0 if current == "dash" else 65.0)
		cap.boosted.emit()
	if current in ["wave", "whirlpool"]:
		for rival in rivals:
			if rival == cap or rival.finished or rival.lap != cap.lap or rival.position.distance_to(cap.position) > 240: continue
			if rival.race_power.block_attack() or rival.shield_time > 0: continue
			if current == "wave":
				rival.receive_push((rival.position - cap.position).normalized() * 80)
				rival.race_power.slow_time = maxf(rival.race_power.slow_time, 0.7)
			else:
				rival.race_power.disruption = maxf(rival.race_power.disruption, 1.2)
	activated.emit(current)
	return true

func block_attack() -> bool:
	if current == "shield" and remaining > 0:
		remaining = 0.0
		cap.shield_time = 0.0
		pulse = 0.3
		return true
	return false

func resistance() -> float:
	if remaining <= 0: return 1.0
	return 0.3 if current == "heavy" else (0.2 if current == "ghost" else 1.0)

func speed_factor() -> float:
	var factor := 0.85 if slow_time > 0 else 1.0
	if remaining > 0:
		factor *= float(SPEED_FACTORS.get(current, 1.0))
	return factor

func advance(delta: float) -> void:
	visual_clock += delta
	collection_time = maxf(0, collection_time - delta)
	remaining = maxf(0, remaining - delta)
	cooldown = maxf(0, cooldown - delta)
	disruption = maxf(0, disruption - delta)
	slow_time = maxf(0, slow_time - delta)
	pulse = maxf(0, pulse - delta)
	if remaining <= 0: current = ""
	if is_instance_valid(cap.ai) and not prepared.is_empty(): use_prepared()
	if current == "magnet":
		scan_time -= delta
		if scan_time <= 0:
			scan_time = 0.1
			for pickup in get_tree().get_nodes_in_group("race_rewards"):
				if pickup.global_position.distance_squared_to(cap.global_position) < 48400: pickup.collect(cap)
	var screen := get_viewport().get_canvas_transform() * global_position
	if get_viewport_rect().grow(240).has_point(screen): queue_redraw()

func ai_score(id: String) -> float:
	var profile: AIProfile = cap.ai.profile
	var nearby := false
	for rival in rivals:
		if rival != cap and rival.lap == cap.lap and rival.position.distance_squared_to(cap.position) < 57600: nearby = true
	var score := 0.2
	if id in ["wave", "whirlpool"]: score += (1.0 if nearby else -0.5) + profile.aggression
	if id in ["turbo", "dash", "super"]: score += (0.4 if leading() else 1.0) + profile.boost_usage
	if id in ["shield", "heavy", "ghost"]: score += (1.0 if leading() else 0.2) + profile.defensive_skill
	if id == "recovery": score += (2.0 if cap.velocity.length() < 180 else 0.0) + profile.recovery_skill
	if id == "magnet": score += profile.powerup_skill
	return score

func _draw() -> void:
	if not is_instance_valid(cap) or cap.finished: return
	if current.is_empty() and prepared.is_empty() and pulse <= 0 and disruption <= 0: return
	var shown := current if not current.is_empty() else prepared
	var tint := Color(POWERS[shown][3]) if not shown.is_empty() else flash_color
	if collection_time > 0:
		var from := to_local(collection_origin)
		for index in range(6):
			var progress := clampf(1.0 - collection_time / 0.4 + index * 0.06, 0, 1)
			draw_circle(from.lerp(Vector2.ZERO, progress) + Vector2(sin(progress * PI) * 15, 0), 4.0 - index * 0.4, Color(tint, 1.0 - index * 0.1))
	if pulse > 0: draw_circle(Vector2.ZERO, 30, Color(tint, pulse * 0.25))
	if not prepared.is_empty():
		PowerGlyph.paint(self, prepared, Vector2(0, -43), 0.42, visual_clock)
		for index in range(3): draw_circle(Vector2.from_angle(visual_clock * 1.5 + index * TAU / 3) * 34, 2.5, Color(POWERS[prepared][3]))
	var radius := 31.0 + pulse * 24.0
	if current in ["wave", "whirlpool"]: radius = 35.0 + (1.0 - remaining / float(POWERS[current][2])) * 205.0
	draw_arc(Vector2.ZERO, radius + 4, 0, TAU, 24, Color(tint, 0.15), 8, true)
	draw_arc(Vector2.ZERO, radius, 0, TAU, 24, tint, 2, true)
	if not current.is_empty():
		if current in ["turbo", "super", "dash", "recovery"]:
			for side in [-1, 1]: draw_line(Vector2(side * 15, 22), Vector2(side * 23, 85), tint, 3, true)
		if current in ["turbo", "super"]:
			for side in [-1, 1]:
				var spark := sin(visual_clock * 22) * 4
				draw_polyline(PackedVector2Array([Vector2(side * 29, -20), Vector2(side * (36 + spark), -3), Vector2(side * 27, 5), Vector2(side * 35, 22)]), Color(tint, 0.85), 2, true)
		if current == "shield":
			draw_circle(Vector2.ZERO, 36, Color(tint, 0.12))
			draw_arc(Vector2.ZERO, 34, PI + 0.3, TAU - 0.4, 20, Color.WHITE, 2, true)
		if current == "ghost":
			for index in range(3): draw_arc(Vector2(0, index * 9), 28, visual_clock + index, visual_clock + index + PI, 16, Color(tint, 0.25), 3, true)
		if current == "heavy":
			draw_circle(Vector2(0, 9), 32, Color(0, 0.08, 0.12, 0.35))
			for index in range(4): draw_arc(Vector2.ZERO, 33, index * PI / 2 + 0.1, index * PI / 2 + 1.1, 8, tint, 5, true)
		if current == "whirlpool":
			for ring in range(1, 4): draw_arc(Vector2.ZERO, ring * 16, remaining * 6 + ring, remaining * 6 + ring + PI * 1.4, 12, tint, 3, true)
		if current == "magnet": draw_arc(Vector2.ZERO, 60 + sin(remaining * 9) * 8, 0, PI, 16, tint, 3, true)
