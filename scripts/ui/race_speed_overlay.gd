extends Control
## One bounded drawing node; no particles, textures or per-frame node creation.
var player: RacingCap
var strength := 0.0
var clock := 0.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	process_mode = Node.PROCESS_MODE_PAUSABLE

func _process(delta: float) -> void:
	if not is_instance_valid(player) or not is_visible_in_tree(): return
	var target := clampf((player.velocity.length() - 250) / 280, 0, 1) if player.active and not player.finished else 0.0
	strength = lerpf(strength, target, 1 - exp(-7 * delta))
	if strength < 0.01:
		if strength > 0: strength = 0; queue_redraw()
		return
	clock += delta
	queue_redraw()

func _draw() -> void:
	if strength <= 0: return
	var count := 8 if SaveManager.settings.quality == "low" else 16
	for i in range(count):
		var side := -1.0 if i % 2 == 0 else 1.0
		var y := fposmod(i * 127.0 + clock * (260 + 300 * strength), maxf(1, size.y - 270)) + 125
		var x := size.x * (0.045 if side < 0 else 0.955) + sin(i * 2.1) * 18
		draw_line(Vector2(x, y), Vector2(x + side * 5, y + 18 + strength * 32), Color(0.7, 1, 1, strength * 0.24), 1.5, true)
