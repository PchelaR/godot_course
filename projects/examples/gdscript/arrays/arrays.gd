extends Node


func _ready() -> void:
	var items: Array[String] = ["меч", "щит"]
	print(items)
	print(items[0])
	print(items.size())
	items.append("зелье")
	print(items)
	items[1] = "лук"
	print(items)
	items.erase("меч")
	print(items)
	print(items[-1])
	print(items.has("зелье"))
