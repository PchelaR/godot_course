extends Node


func _ready() -> void:
	var player_name: String = "Рыцарь"
	var health: int = 75
	var speed: float = 2.456
	print("%s: %d HP" % [player_name, health])
	print("Скорость: %.1f" % speed)
	print("{name}: {hp} HP".format({"name": player_name, "hp": health}))
	print("Первая строка\nВторая строка")
