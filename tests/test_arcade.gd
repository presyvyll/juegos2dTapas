extends SceneTree

var failures := 0

func check(condition: bool, message: String) -> void:
	print(("PASS: " if condition else "FAIL: ") + message)
	if not condition:
		failures += 1

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var styles: Array[int] = []
	for cap in RacingCatalog.caps():
		check(cap.appearance != null, cap.id + " has appearance")
		styles.append(cap.appearance.style)
	styles.sort()
	check(styles == [0, 1, 2, 3, 4, 5], "six distinct visual personalities")
	var turbo: TurboConfig = load("res://data/turbo/default.tres")
	check(is_equal_approx(turbo.energy_cost, 0.45) and is_equal_approx(turbo.duration, 0.9) and is_equal_approx(turbo.speed_multiplier, 1.6) and is_equal_approx(turbo.recharge_per_second, 0.105), "original turbo balance preserved")
	for budget in [48, 96]:
		var pool := WaterVFXPool.new()
		pool.capacity = budget
		root.add_child(pool)
		check(not pool.is_processing(), "empty pool starts asleep")
		for index in range(1000):
			pool.emit_slot(Vector2.ZERO, Vector2.ONE, Color.WHITE, 0.4, 0)
		check(pool.positions.size() == budget and pool.get_child_count() == 0, "effect storage stays bounded at %d" % budget)
		check(pool.is_processing(), "emission wakes the pool")
		pool._process(1.0)
		var expired := true
		for remaining in pool.remaining:
			expired = expired and remaining == 0
		check(expired, "effects expire completely")
		check(not pool.is_processing(), "expired pool stops processing")
		pool.free()
	print("ARCADE: %d failures" % failures)
	quit(failures)
