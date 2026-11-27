extends Node2D

@onready var hero: Hero = $Maze/Hero


func _ready() -> void:
	hero.direction = Vector2i.RIGHT
	hero.advance(40.0)
	print(hero.cell, " ", hero.position)
	hero.advance(200.0)
	print(hero.cell, " ", hero.position, " ", hero.direction)
