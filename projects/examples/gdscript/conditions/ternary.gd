extends Node


func _ready() -> void:
	var health: int = 40
	var status: String = "жив" if health > 0 else "погиб"
	print(status)
