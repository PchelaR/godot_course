extends Node

@onready var hero: Hero = $Level/Maze/Hero
@onready var slimes: Node2D = $Level/Maze/Slimes
@onready var orange: Slime = $Level/Maze/Slimes/Orange


func _ready() -> void:
	hero.cell = Vector2i(12, 9)
	hero.direction = Vector2i.LEFT
	for slime: Slime in slimes.get_children():
		print(slime.name, " ", slime.character.chase_target(slime))
	orange.cell = Vector2i(1, 1)
	print(orange.name, " ", orange.character.chase_target(orange))
