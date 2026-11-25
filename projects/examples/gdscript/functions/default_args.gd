extends Node


func _ready() -> void:
	print(calculate_damage(10))
	print(calculate_damage(10, 3))


func calculate_damage(base: int, multiplier: int = 2) -> int:
	return base * multiplier
