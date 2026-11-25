extends Node


func _ready() -> void:
	var start: Vector2 = Vector2(0, 0)
	var goal: Vector2 = Vector2(30, 40)
	var offset: Vector2 = goal - start
	print(offset.length())
	print(offset.normalized())
	print(start.distance_to(goal))
	print(start.direction_to(goal))
	print(start.direction_to(goal) * 100)
