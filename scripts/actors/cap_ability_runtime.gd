class_name CapAbilityRuntime
extends RefCounted
## Per-racer state; shared ability Resources remain immutable.

signal activated(definition: CapAbilityDefinition)
var definition: CapAbilityDefinition
var remaining := 0.0
var cooldown_remaining := 0.0
var uses := 0
var started := false

func configure(value: CapAbilityDefinition) -> void:
	definition = value
	remaining = 0.0
	cooldown_remaining = 0.0
	uses = 0
	started = false

func advance(delta: float) -> void:
	remaining = maxf(0, remaining - delta)
	cooldown_remaining = maxf(0, cooldown_remaining - delta)
	if not started:
		started = true
		trigger("start")

func trigger(event: String) -> bool:
	if definition == null or definition.trigger != event:
		return false
	if remaining > 0 or cooldown_remaining > 0:
		return false
	if definition.max_uses > 0 and uses >= definition.max_uses:
		return false
	uses += 1
	remaining = definition.duration
	cooldown_remaining = definition.cooldown
	activated.emit(definition)
	return true

func value(key: String, fallback: float = 1.0) -> float:
	if definition == null or remaining <= 0:
		return fallback
	return float(definition.modifiers.get(key, fallback))

func status() -> String:
	if definition == null: return ""
	if remaining > 0: return "%s · %.1f s" % [definition.display_name, remaining]
	if definition.max_uses > 0 and uses >= definition.max_uses:
		return "%s · usada" % definition.display_name
	if cooldown_remaining > 0: return "%s · recarga %.0f s" % [definition.display_name, ceilf(cooldown_remaining)]
	return "%s · automática" % definition.display_name
