extends Node

@onready var level: Level = $Level
@onready var hero: Hero = $Level/Maze/Hero
@onready var red: Slime = $Level/Maze/Slimes/Red
@onready var lives_box: HBoxContainer = $Level/Hud/Lives


func _ready() -> void:
	report()
	level.score = 120
	hero.cell = Vector2i(3, 3)
	red.mode = Slime.Mode.CHASE
	red.cell = Vector2i(3, 3)
	level._on_slime_touched(red)
	report()
	print(hero.is_physics_processing(), " ", red.is_physics_processing())
	level._on_slime_touched(red)
	print(level.lives)
	level.start_round()
	report()
	print(hero.cell, " ", red.cell, " ", Slime.Mode.keys()[red.mode], " ", hero.is_physics_processing())


func report() -> void:
	var shown: int = 0
	for icon: Control in lives_box.get_children():
		if icon.visible:
			shown += 1
	print(level.lives, " ", shown, " ", level.resetting, " ", level.score)
