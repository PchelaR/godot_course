extends Node2D


func _ready() -> void:
	print(position)
	position = Vector2(100, 50)
	print(position)
	print(position.x)
	scale = Vector2(2, 2)
	print(scale)
