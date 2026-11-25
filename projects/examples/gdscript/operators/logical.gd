extends Node


func _ready() -> void:
	var has_key: bool = true
	var door_locked: bool = true
	print(door_locked and has_key)
	print(has_key or door_locked)
	print(not has_key)
