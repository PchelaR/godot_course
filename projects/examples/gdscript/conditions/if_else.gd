extends Node


func _ready() -> void:
	var health: int = 25
	if health <= 0:
		print("Персонаж погиб")
	elif health < 30:
		print("Мало здоровья")
	else:
		print("Всё в порядке")
