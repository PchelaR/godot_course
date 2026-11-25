extends Node


func _ready() -> void:
	var title: String = "Godot Engine"
	print(title.length())
	print(title.to_upper())
	print(title[0])
	print(title.begins_with("Godot"))
	print("Engine" in title)
	print(title.replace("Engine", "4.7"))
	print(title.split(" "))
	print(title)
