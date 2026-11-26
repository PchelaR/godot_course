extends Node2D

@onready var tactics: Node2D = $Tactics


func _ready() -> void:
	print(tactics.unit_cell, " ", tactics.came_from.size())
	print(tactics.path_to(Vector2i(3, 2)))
	print(tactics.came_from.has(Vector2i(8, 6)), " ", tactics.came_from.has(Vector2i(7, 6)))
