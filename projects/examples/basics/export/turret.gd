extends Node2D

@export var target: Node2D


func _ready() -> void:
	print(target.name)
	print(position.distance_to(target.position))
