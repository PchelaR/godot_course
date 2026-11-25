extends Node


func _ready() -> void:
	var player: Dictionary = {
		"name": "Рыцарь",
		"health": 100,
	}
	print(player["name"])
	player["health"] = 80
	player["level"] = 2
	print(player)
	print(player.has("mana"))
	print(player.get("mana", 0))
	player.erase("level")
	print(player.size())
