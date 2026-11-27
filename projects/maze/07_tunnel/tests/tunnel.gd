extends Node2D

@onready var maze: Maze = $Maze
@onready var hero: Hero = $Maze/Hero


func _ready() -> void:
	hero.cell = Vector2i(0, 7)
	hero.position = maze.map_to_local(hero.cell)
	hero.steer(Vector2i.LEFT)
	hero.advance(16.0)
	print(hero.cell, " ", hero.position)
	hero.advance(8.0)
	print(hero.cell, " ", hero.position, " ", hero.direction)
	hero.steer(Vector2i.RIGHT)
	hero.advance(8.0)
	print(hero.cell, " ", hero.position, " ", hero.direction)
	print(maze.is_wall(Vector2i(-2, 7)), " ", maze.is_wall(Vector2i(-1, 6)))
