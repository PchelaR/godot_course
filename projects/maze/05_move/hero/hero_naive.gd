extends Node2D

@export var maze: Maze
@export var speed: float = 60.0


func _physics_process(delta: float) -> void:
	var input: Vector2 = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var next: Vector2 = position + input * speed * delta
	if not maze.is_wall(maze.local_to_map(next)):
		position = next
