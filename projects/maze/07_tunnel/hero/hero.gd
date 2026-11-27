class_name Hero
extends Node2D

@export var maze: Maze
@export var start_cell: Vector2i = Vector2i(12, 9)
@export var speed: float = 60.0

var cell: Vector2i
var direction: Vector2i = Vector2i.ZERO
var wanted: Vector2i = Vector2i.ZERO


func _ready() -> void:
	cell = start_cell
	position = maze.map_to_local(cell)


func _physics_process(delta: float) -> void:
	steer(read_input())
	advance(speed * delta)


func steer(input: Vector2i) -> void:
	if input == Vector2i.ZERO:
		return
	wanted = input
	if direction != Vector2i.ZERO and wanted == -direction and position != maze.map_to_local(cell):
		cell += direction
		direction = wanted


func advance(step: float) -> void:
	while step > 0.0:
		if position == maze.map_to_local(cell):
			choose_direction()
			if direction == Vector2i.ZERO:
				return
		var target: Vector2 = maze.map_to_local(cell + direction)
		var left: float = position.distance_to(target)
		if step < left:
			position = position.move_toward(target, step)
			return
		position = target
		cell += direction
		step -= left
		var exit: Vector2i = maze.through_tunnel(cell)
		if exit != cell:
			cell = exit
			position = maze.map_to_local(cell)


func choose_direction() -> void:
	if wanted != Vector2i.ZERO and not maze.is_wall(cell + wanted):
		direction = wanted
	elif maze.is_wall(cell + direction):
		direction = Vector2i.ZERO


func read_input() -> Vector2i:
	if Input.is_action_pressed("move_right"):
		return Vector2i.RIGHT
	if Input.is_action_pressed("move_left"):
		return Vector2i.LEFT
	if Input.is_action_pressed("move_down"):
		return Vector2i.DOWN
	if Input.is_action_pressed("move_up"):
		return Vector2i.UP
	return Vector2i.ZERO
