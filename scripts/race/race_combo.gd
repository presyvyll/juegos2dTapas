class_name RaceCombo
extends RefCounted
## One race-local chain. It never awards currency or alters movement.

signal advanced(count: int, feedback_allowed: bool)
var config: ComboConfig = preload("res://data/combo/default.tres")
var actions: Array[String] = []
var remaining := 0.0
var feedback_cooldown := 0.0
var best := 0
var last_action := ""

func advance(delta: float) -> void:
	feedback_cooldown = maxf(0, feedback_cooldown - delta)
	remaining = maxf(0, remaining - delta)
	if remaining <= 0:
		actions.clear()
		last_action = ""

func register(action: String) -> void:
	if not config.action_names.has(action) or action in actions or actions.size() >= config.max_chain: return
	actions.append(action)
	last_action = str(config.action_names[action])
	remaining = config.window_seconds
	if actions.size() >= 2: best = maxi(best, actions.size())
	var feedback_allowed := actions.size() >= 2 and feedback_cooldown <= 0
	if feedback_allowed: feedback_cooldown = config.feedback_interval
	advanced.emit(actions.size(), feedback_allowed)

func end_chain() -> void:
	remaining = 0.0
	actions.clear()
	last_action = ""

func caption() -> String:
	var name := "MEGA COMBO" if actions.size() >= config.mega_threshold else "COMBO"
	return "%s x%d · %s" % [name, actions.size(), last_action]
