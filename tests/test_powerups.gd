extends SceneTree

var failures := 0

func check(value: bool, message: String) -> void:
	print(("PASS: " if value else "FAIL: ") + message)
	if not value:
		failures += 1

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var cap: RacingCap = load("res://scenes/actors/player_cap.tscn").instantiate()
	root.add_child(cap)
	cap.set_physics_process(false)
	var shield: PowerUpDefinition = load("res://data/powerups/shield.tres")
	var recharge: PowerUpDefinition = load("res://data/powerups/recharge.tres")
	shield.apply(cap)
	cap.velocity = Vector2.ZERO
	cap.receive_push(Vector2(100,0))
	check(cap.velocity == Vector2.ZERO, "shield blocks rival push")
	cap.shield_time = 0.01
	cap._physics_process(0.02)
	var before := cap.velocity
	cap.receive_push(Vector2(100,0))
	check(is_equal_approx(cap.velocity.x, before.x + 100), "expired shield restores pushes")
	cap.boost_energy = 0.8
	recharge.apply(cap)
	check(cap.boost_energy == 1, "recharge clamps to full energy")
	var pickup := RacingPickup.new()
	pickup.definition = recharge
	root.add_child(pickup)
	cap.position = Vector2(500,500)
	cap.boost_energy = 0
	cap.active = false
	pickup.collect(cap)
	check(cap.boost_energy == 0, "countdown cannot collect pickups")
	cap.active = true
	pickup.collect(cap)
	pickup.collect(cap)
	check(cap.boost_energy == 0.5 and pickup.cooldown == 8, "pickup collected exactly once during cooldown")
	pickup._process(8.1)
	pickup.collect(cap)
	check(cap.boost_energy == 1, "pickup can be reused after respawn")
	cap.boost_energy = 0
	cap.finished = true
	pickup.cooldown = 0
	pickup.collect(cap)
	check(cap.boost_energy == 0, "finished racers cannot collect")
	pickup.queue_free()
	await process_frame
	cap.finished = false
	var sensor := RacingPickup.new()
	sensor.definition = recharge
	sensor.position = cap.position
	root.add_child(sensor)
	await physics_frame
	await physics_frame
	await physics_frame
	check(cap.boost_energy == 0.5 and sensor.cooldown > 0, "physical overlap triggers pickup on racer layer")
	sensor.queue_free()
	cap.queue_free()
	await process_frame
	var fresh: RacingCap = load("res://scenes/actors/player_cap.tscn").instantiate()
	check(fresh.shield_time == 0, "new race has no lingering shield")
	fresh.free()
	print("POWERUPS: %d failures" % failures)
	quit(failures)
