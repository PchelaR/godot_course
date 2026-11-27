class_name Citizen
extends Node2D

@export var speed: float = 90.0

var path: PackedVector2Array = []


func _process(delta: float) -> void:
	if path.is_empty():
		queue_free()
		return
	position = position.move_toward(path[0], speed * delta)
	if position == path[0]:
		path.remove_at(0)
