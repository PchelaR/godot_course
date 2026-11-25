extends Node


func _ready() -> void:
	var scores: Array[int] = [10, 25, 7]
	var total: int = 0
	for score in scores:
		total += score
	print(total)
	for i in range(scores.size()):
		print(i, ": ", scores[i])
