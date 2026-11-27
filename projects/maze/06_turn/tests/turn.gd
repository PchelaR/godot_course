extends Node2D

@onready var hero: Hero = $Maze/Hero


func _ready() -> void:
	hero.steer(Vector2i.RIGHT)
	hero.advance(8.0)
	hero.steer(Vector2i.UP)
	hero.steer(Vector2i.ZERO)
	hero.advance(48.0)
	print(hero.cell, " ", hero.position, " ", hero.direction)
	hero.steer(Vector2i.DOWN)
	print(hero.cell, " ", hero.position, " ", hero.direction)
	hero.advance(8.0)
	print(hero.cell, " ", hero.position, " ", hero.direction)
