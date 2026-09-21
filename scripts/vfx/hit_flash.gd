class_name HitFlashEffect
extends RefCounted
## Reusable, allocation-free hit flash controller for a CanvasItem.

const HIT_FLASH_SHADER: Shader = preload("res://shaders/hit_flash.gdshader")
const STRONG_IMPACT := 120.0

var material: ShaderMaterial
var remaining := 0.0
var duration := 0.0


func attach(target: CanvasItem, color := Color("fff4d1")) -> void:
	material = ShaderMaterial.new()
	material.shader = HIT_FLASH_SHADER
	material.set_shader_parameter("flash_color", color)
	material.set_shader_parameter("flash_amount", 0.0)
	target.material = material


func trigger(strength: float) -> bool:
	if strength < STRONG_IMPACT or not is_instance_valid(material):
		return false
	duration = lerpf(0.055, 0.09, clampf((strength - STRONG_IMPACT) / 250.0, 0.0, 1.0))
	remaining = duration
	material.set_shader_parameter("flash_amount", 1.0)
	return true


func update(delta: float) -> void:
	if remaining <= 0.0:
		return
	remaining = maxf(0.0, remaining - delta)
	var amount := pow(clampf(remaining / maxf(duration, 0.001), 0.0, 1.0), 0.65)
	material.set_shader_parameter("flash_amount", amount)


func is_active() -> bool:
	return remaining > 0.0
