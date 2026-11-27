class_name ShakeCamera
extends Camera2D

var strength: int = 0
var duration: float = 0.0
var time_left: float = 0.0


func _process(delta: float) -> void:
	if time_left <= 0.0:
		offset = Vector2.ZERO
		return
	time_left -= delta
	var power: int = ceili(strength * maxf(time_left, 0.0) / duration)
	offset = Vector2(randi_range(-power, power), randi_range(-power, power))


func shake(new_strength: int, new_duration: float) -> void:
	strength = new_strength
	duration = new_duration
	time_left = new_duration
