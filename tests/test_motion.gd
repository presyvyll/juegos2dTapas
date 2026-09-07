extends SceneTree
## Checks behavior that must stay stable as currents and controllers evolve.

func _init() -> void:
	var motion := CapMotion.new()
	motion.config = CapPhysicsConfig.new()
	var velocity := Vector2.ZERO
	for step in range(600):
		velocity = motion.integrate(velocity, 0.0, 1.0 / 60.0)
	assert(absf(velocity.y + motion.config.current_speed) < 0.01, "Current reaches configured speed")
	assert(is_zero_approx(velocity.x), "No lateral drift without input")
	for step in range(120):
		velocity = motion.integrate(velocity, 1.0, 1.0 / 60.0)
	assert(velocity.x > 0.0, "Right input produces right movement")
	assert(velocity.length() <= motion.config.max_speed + 0.01, "Speed remains bounded")
	for step in range(300):
		velocity = motion.integrate(velocity, 0.0, 1.0 / 60.0)
	assert(absf(velocity.x) < 0.1, "Water dissipates lateral movement")
	motion.free()
	print("PASS: current, steering, speed limit, water resistance")
	quit()
