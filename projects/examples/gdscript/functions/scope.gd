extends Node

var score: int = 0


func _ready() -> void:
	add_points(10)
	add_points(5)
	print(score)


func add_points(amount: int) -> void:
	var bonus: int = 1
	score += amount + bonus
