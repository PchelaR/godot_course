extends Node2D

var total: int = 0

@onready var maze: Maze = $Maze
@onready var coins: Coins = $Maze/Coins
@onready var hero: Hero = $Maze/Hero


func _ready() -> void:
	hero.cell = Vector2i(1, 1)
	hero.position = maze.map_to_local(hero.cell)
	hero.steer(Vector2i.RIGHT)
	hero.advance(48.0)
	print(hero.cell, " ", total)
	coins.eat(Vector2i(1, 1))
	coins.eat(Vector2i(1, 1))
	print(total, " ", coins.get_used_cells().size())


func _on_coins_eaten(points: int) -> void:
	total += points
