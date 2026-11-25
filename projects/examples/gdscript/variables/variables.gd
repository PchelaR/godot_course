extends Node


func _ready() -> void:
	var player_name: String = "Рыцарь"
	var health: int = 100
	var speed: float = 2.5
	var is_alive: bool = true
	print(player_name)
	print(health)
	print(speed)
	print(is_alive)
	health = 75
	print(health)
