class_name CapMotion
extends Node
## Arcade velocity integration, independent from the input source and visuals.

@export var config: CapPhysicsConfig

func integrate(velocity: Vector2, steering: float, delta: float, flow: Vector2 = Vector2.UP, external: Vector2 = Vector2.ZERO, speed_modifier: float = 1.0) -> Vector2:
	var forward := flow.normalized()
	var lateral := Vector2(-forward.y, forward.x)
	var advance := velocity.dot(forward)
	advance = move_toward(advance, config.current_speed * speed_modifier, config.current_speed * config.acceleration * delta)
	var drift := velocity.dot(lateral) * exp(-(config.water_resistance + config.friction) * delta)
	drift += steering * config.lateral_force / config.weight * delta
	return (forward * advance + lateral * drift + external / config.weight * delta).limit_length(config.max_speed * maxf(1.0, speed_modifier))
