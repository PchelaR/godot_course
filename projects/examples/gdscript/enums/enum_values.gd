extends Node

enum Difficulty { EASY = 1, NORMAL = 2, HARD = 5 }


func _ready() -> void:
	var difficulty: Difficulty = Difficulty.HARD
	print(difficulty)
	print(Difficulty.NORMAL * 10)
