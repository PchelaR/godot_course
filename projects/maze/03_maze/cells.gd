extends Node2D

@onready var maze: Maze = $Maze


func _ready() -> void:
	print(maze.map_to_local(Vector2i(0, 0)))
	print(maze.map_to_local(Vector2i(1, 1)))
	print(maze.local_to_map(Vector2(30, 20)))
	print(maze.is_wall(Vector2i(0, 0)))
	print(maze.is_wall(Vector2i(1, 1)))
	print(maze.is_wall(Vector2i(-1, 5)))
