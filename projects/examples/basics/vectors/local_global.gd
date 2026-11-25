extends Node2D


func _ready() -> void:
	var gun: Node2D = $Gun
	print(position)
	print(gun.position)
	print(gun.global_position)
	scale = Vector2(2, 2)
	print(gun.position)
	print(gun.global_position)
