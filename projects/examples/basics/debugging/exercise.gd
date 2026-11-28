extends Node

var chests: Array[int] = [5, 10, 20]


func _ready() -> void:
	print("Всего монет: ", count_coins())


func count_coins() -> int:
	var total: int = 0
	for index: int in range(chests.size()):
		total += chests[index]
	return total
