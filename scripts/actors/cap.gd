class_name RacingCap
extends CharacterBody2D

signal wall_hit(speed: float)
signal boosted

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
var lap: int = 1
var checkpoint_index: int = 0
var finish_time: float = 0.0
var jump_time: float = 0.0
var jump_duration: float = 0.65

@onready var motion: CapMotion = $Motion
@onready var controls: CapPlayerInput = $PlayerInput

func _physics_process(delta: float) -> void:
	if not active or finished:
		return
	jump_time = maxf(0, jump_time - delta)
	var height := sin(PI * jump_time / jump_duration)
	$Visual.scale = Vector2.ONE * (1 + height * 0.22)
	$Visual.position.y = -height * 14
	var flow: Vector2 = track.flow_at(global_position.y) if is_instance_valid(track) else Vector2.UP
	var steering: float = ai.steering_axis() if is_instance_valid(ai) else controls.steering_axis()
	var wants_boost: bool = ai.consume_boost() if is_instance_valid(ai) else controls.consume_boost()
	if wants_boost:
		try_boost(flow)
	boost_time = maxf(0, boost_time - delta)
	boost_energy = minf(1, boost_energy + delta * 0.105)
	swipe_cooldown = maxf(0, swipe_cooldown - delta)
	collision_cooldown = maxf(0, collision_cooldown - delta)
	if not is_instance_valid(ai):
		var swipe := controls.consume_swipe()
		if swipe != 0 and swipe_cooldown <= 0:
			velocity += Vector2(-flow.y, flow.x) * swipe * motion.config.lateral_impulse
			swipe_cooldown = 0.6
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
		modifier *= 1.6
	velocity = motion.integrate(velocity, steering, delta, flow, external, modifier)
	var collision := move_and_collide(velocity * delta)
	if collision:
		var impact := absf(velocity.dot(collision.get_normal()))
		velocity = velocity.slide(collision.get_normal()) + collision.get_normal() * impact * motion.config.wall_bounce
		var other := collision.get_collider()
		if other is RacingCap:
			other.velocity -= collision.get_normal() * impact * 0.35 / other.motion.config.weight
		if impact > 30.0 and collision_cooldown <= 0:
			wall_hit.emit(impact)
			collision_cooldown = 0.25
	$Visual.rotation += steering * delta * 0.6

func try_boost(flow: Vector2) -> void:
	if boost_energy < 0.45 or boost_time > 0:
		return
	boost_energy -= 0.45
	boost_time = 0.9
	velocity += flow * motion.config.boost_impulse
	boosted.emit()

func apply_definition(definition: CapDefinition, skin: bool = false) -> void:
	motion.config = motion.config.duplicate() as CapPhysicsConfig
	motion.config.current_speed *= definition.speed
	motion.config.acceleration *= definition.acceleration
	motion.config.lateral_force *= definition.handling
	motion.config.weight *= definition.weight
	motion.config.boost_impulse *= definition.boost
	$Visual.tint = definition.color.lightened(0.25) if skin else definition.color
	$Visual.queue_redraw()
