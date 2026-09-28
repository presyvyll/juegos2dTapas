extends SceneTree
var failures := 0
func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)

func run() -> void:
	var save := root.get_node("SaveManager")
	save.save_path = "user://sprint_ui_test.json"
	save.settings.race_laps = 1
	for resolution in [Vector2i(1280, 720), Vector2i(2340, 1080)]:
		root.size = resolution
		var race: Node2D = load("res://levels/race.tscn").instantiate()
		root.add_child(race)
		race.session.set_physics_process(false)
		for cap in race.session.caps: cap.set_physics_process(false)
		race.player.active = true
		race.player.race_power.equip("wave", 0, race.player.position)
		var ui: Control = race.hud.power_hud
		ui.refresh()
		await process_frame
		await process_frame
		check(ui.get_global_rect().encloses(ui.activate_button.get_global_rect()), "Small activation target stays onscreen")
		check(not race.hud.info.is_visible_in_tree() and not race.hud.progress_bar.is_visible_in_tree() and not race.hud.speed_label.is_visible_in_tree(), "Permanent race statistics are hidden")
		check(ui.get_child_count() == 1, "No selection menu exists")
		var area: float = ui.activate_button.size.x * ui.activate_button.size.y + race.hud.boost_button.size.x * race.hud.boost_button.size.y + race.hud.pause_button.size.x * race.hud.pause_button.size.y
		check(area / (ui.size.x * ui.size.y) <= 0.05, "Controls occupy at most five percent of screen")
		var event := InputEventScreenTouch.new()
		event.pressed = true
		event.index = 2
		event.position = ui.activate_button.get_global_rect().get_center()
		check(race.player.controls.blocked_touch.call(event.position), "Power selection blocks steering")
		var selected := "wave"
		check(race.session.running == false and not paused, "Selection does not pause tree")
		event.position = ui.activate_button.get_global_rect().get_center()
		ui._input(event)
		check(race.player.race_power.current == selected, "Thumb touch activates prepared power")
		check(not ui.activate_button.get_global_rect().intersects(race.hud.boost_button.get_global_rect()), "Power and turbo touch targets do not overlap")
		check(race.track.power_pickups.size() == 9, "Three physical groups with three choices")
		var pickup = race.track.power_pickups[3]
		pickup.collect(race.player)
		check(race.player.race_power.prepared == pickup.definition.id, "Physical contact equips the visible power")
		race.track.power_pickups[4].collect(race.player)
		check(race.player.race_power.prepared == pickup.definition.id, "Driving into a second option of same row grants nothing")
		race.queue_free()
		await process_frame
	print("SPRINT POWER UI: %d failures" % failures)
	quit(failures)
