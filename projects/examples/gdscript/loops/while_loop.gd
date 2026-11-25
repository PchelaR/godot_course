extends Node


func _ready() -> void:
	var energy: int = 10
	while energy > 0:
		print(energy)
		energy -= 4
