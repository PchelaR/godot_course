class_name Walker
extends Node2D

signal cell_entered(cell: Vector2i)

@export var maze: Maze
@export var start_cell: Vector2i = Vector2i.ZERO
@export var speed: float = 60.0

var cell: Vector2i
var direction: Vector2i = Vector2i.ZERO


func _ready() -> void:
	cell = start_cell
	position = maze.map_to_local(cell)


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
		cell_entered.emit(cell)


func choose_direction() -> void:
	pass
