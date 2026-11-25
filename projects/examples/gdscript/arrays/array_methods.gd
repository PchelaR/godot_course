extends Node


func _ready() -> void:
	var numbers: Array[int] = [5, 2, 8]
	numbers.sort()
	print(numbers)
	var last: int = numbers.pop_back()
	print(last)
	print(numbers)
	numbers.insert(0, 1)
	print(numbers)
	numbers.clear()
	print(numbers.is_empty())
