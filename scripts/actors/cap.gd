class_name RacingCap
extends CharacterBody2D

signal wall_hit(speed: float)
signal boosted
signal impacted(point: Vector2, normal: Vector2, strength: float)
signal bank_contact(point: Vector2, normal: Vector2, motion: Vector2, strength: float, rebounded: bool)
signal contact_resolved(rival: bool, strength: float)
signal landed
signal swiped(direction: float)
signal shot_graded(grade: int)
signal ability_activated(definition: CapAbilityDefinition)
signal powerup_received(definition: PowerUpDefinition)
var shield_time := 0.0
@export var turbo: TurboConfig = preload("res://data/turbo/default.tres")

var active := true
var finished := false
var racer_name := "Tú"
var track: Node2D
var ai: Node
var currents: Array[WaterCurrentArea] = []
var boost_energy: float = 1.0
var boost_time: float = 0.0
var swipe_cooldown: float = 0.0
var collision_cooldown: float = 0.0
var bank_feedback_cooldown: float = 0.0
var lap: int = 1
var checkpoint_index: int = 0
var finish_time: float = 0.0
var jump_time: float = 0.0
var jump_duration: float = 0.65
var base_physics: CapPhysicsConfig
var definition_id := ""
var ability := CapAbilityRuntime.new()
var burst_speed_multiplier := 1.6

@onready var motion: CapMotion = $Motion
@onready var controls: CapPlayerInput = $PlayerInput

func _ready() -> void:
	controls.boost_available = can_boost
	ability.activated.connect(func(value: CapAbilityDefinition) -> void: ability_activated.emit(value))
	impacted.connect(func(_point: Vector2, _normal: Vector2, _strength: float) -> void: trigger_ability("impact_received"))
	burst_speed_multiplier = turbo.speed_multiplier

func trigger_ability(event: String) -> bool:
	if not active or finished or get_tree().paused: return false
	return ability.trigger(event)

func can_boost() -> bool:
	return active and not finished and not get_tree().paused and boost_time <= 0 and boost_energy >= turbo.energy_cost

func _physics_process(delta: float) -> void:
	if not active or finished:
		return
	var first_active_frame := not ability.started
	ability.advance(delta)
	if first_active_frame and not currents.is_empty(): trigger_ability("current_enter")
	shield_time = maxf(0, shield_time - delta)
	var was_airborne := jump_time > 0
	jump_time = maxf(0, jump_time - delta)
	if was_airborne and jump_time <= 0:
		landed.emit()
	var flow: Vector2 = track.flow_at(global_position.y) if is_instance_valid(track) else Vector2.UP
	var steering: float = ai.steering_axis() if is_instance_valid(ai) else controls.steering_axis()
	var wants_boost: bool = ai.consume_boost() if is_instance_valid(ai) else controls.consume_boost()
	if wants_boost:
		try_boost(flow)
	boost_time = maxf(0, boost_time - delta)
	boost_energy = minf(1, boost_energy + delta * turbo.recharge_per_second)
	swipe_cooldown = maxf(0, swipe_cooldown - delta)
	collision_cooldown = maxf(0, collision_cooldown - delta)
	bank_feedback_cooldown = maxf(0, bank_feedback_cooldown - delta)
	if not is_instance_valid(ai):
		var swipe := controls.consume_swipe()
		if swipe != 0 and swipe_cooldown <= 0:
			velocity += Vector2(-flow.y, flow.x) * swipe * motion.config.lateral_impulse
			swipe_cooldown = 0.6
			swiped.emit(swipe)
			shot_graded.emit(controls.consumed_shot_grade)
	var external := Vector2.ZERO
	var modifier := 0.0
	var count := 0
	for current in currents:
		if is_instance_valid(current):
			external += current.force_at(global_position)
			modifier += current.max_speed_modifier
			count += 1
	if count > 0:
		external /= count
		modifier /= count
	else:
		modifier = 1.0
	if boost_time > 0:
		modifier *= burst_speed_multiplier
	modifier *= ability.value("speed")
	var lateral := Vector2(-flow.y, flow.x).normalized()
	external += lateral * external.dot(lateral) * (ability.value("current_lateral") - 1.0)
	velocity = motion.integrate(velocity, steering, delta, flow, external, modifier, ability.value("acceleration"))
	var collision := move_and_collide(velocity * delta)
	if collision:
		var impact := absf(velocity.dot(collision.get_normal()))
		velocity = velocity.slide(collision.get_normal()) + collision.get_normal() * impact * motion.config.wall_bounce
		var other := collision.get_collider()
		var hit_bank := false
		if other is Node:
			hit_bank = other.is_in_group("channel_banks")
		if hit_bank and impact > 8.0 and bank_feedback_cooldown <= 0.0:
			var rebounded := impact >= 120.0
			bank_contact.emit(collision.get_position(), collision.get_normal(), velocity, impact, rebounded)
			bank_feedback_cooldown = 0.18 if rebounded else 0.10
		if other is RacingCap:
			other.receive_push(-collision.get_normal() * impact * 0.35 / other.motion.config.weight)
		if impact > 30.0 and collision_cooldown <= 0:
			contact_resolved.emit(other is RacingCap, impact)
			wall_hit.emit(impact)
			impacted.emit(collision.get_position(), collision.get_normal(), impact)
			if other is RacingCap:
				other.impacted.emit(collision.get_position(), -collision.get_normal(), impact)
			collision_cooldown = 0.25

func receive_push(impulse: Vector2) -> void:
	if shield_time <= 0:
		velocity += impulse * ability.value("received_push")

func try_boost(flow: Vector2) -> void:
	if not can_boost():
		return
	trigger_ability("turbo")
	boost_energy -= turbo.energy_cost
	boost_time = ability.value("turbo_duration", turbo.duration)
	burst_speed_multiplier = ability.value("turbo_speed", turbo.speed_multiplier)
	velocity += flow * motion.config.boost_impulse
	boosted.emit()

func apply_definition(definition: CapDefinition, skin: bool = false, level: int = 1) -> void:
	# Cup setup can replace a provisional cap; never compound its multipliers.
	if base_physics == null:
		base_physics = motion.config.duplicate() as CapPhysicsConfig
	definition_id = definition.id
	motion.config = definition.resolve_physics(base_physics, level)
	ability.configure(definition.ability)
	$Visual.configure(definition.appearance, definition.color.lightened(0.25) if skin else definition.color)
