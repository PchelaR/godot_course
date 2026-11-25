extends Node


func _ready() -> void:
	var text: String = "42"
	var number: int = int(text)
	print(number + 8)
	print("Очки: " + str(number))
	print(float(7) / 2)
	print(int(3.9))
