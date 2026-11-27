extends Node

@onready var slime: Slime = $Level/Maze/Slime
@onready var hero: Hero = $Level/Maze/Hero


func _ready() -> void:
	check(Vector2i(12, 5), Vector2i.ZERO, Vector2i(12, 9))
	check(Vector2i(5, 3), Vector2i.RIGHT, Vector2i(5, 9))
	check(Vector2i(3, 3), Vector2i.RIGHT, Vector2i(1, 3))
	check(Vector2i(1, 1), Vector2i.UP, Vector2i(12, 9))


func check(cell: Vector2i, direction: Vector2i, target: Vector2i) -> void:
	hero.cell = target
	slime.cell = cell
	slime.direction = direction
	slime.choose_direction()
	print(cell, " -> ", slime.direction)
