extends Node

@onready var level: Level = $Level


func _ready() -> void:
	print(level.hud.score_label.text)
	level._on_coins_eaten(10)
	level._on_coins_eaten(50)
	print(level.score, " ", level.hud.score_label.text)
	level.score = 123450
	level._on_coins_eaten(10)
	print(level.hud.score_label.text)
