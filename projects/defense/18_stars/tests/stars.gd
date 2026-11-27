extends Node


func _ready() -> void:
	var level: Level = Level.new()
	for lives: int in [20, 18, 17, 10, 9, 1]:
		print(lives, " ", level.stars_for(lives))
	level.free()
