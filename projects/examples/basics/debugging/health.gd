extends Node

var health: int = 10


func _ready() -> void:
	for damage: int in [3, 4, 5]:
		take_damage(damage)
		print("Урон ", damage, ", здоровье ", health)


func take_damage(damage: int) -> void:
	health = maxi(health - damage, 0)
