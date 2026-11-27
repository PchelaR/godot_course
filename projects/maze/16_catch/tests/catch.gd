extends Node

@onready var level: Level = $Level
@onready var maze: Maze = $Level/Maze
@onready var red: Slime = $Level/Maze/Slimes/Red
@onready var purple: Slime = $Level/Maze/Slimes/Purple


func _ready() -> void:
	red.mode = Slime.Mode.CHASE
	purple.mode = Slime.Mode.SCATTER
	level._on_coins_powered()
	level._on_slime_touched(red)
	report(red)
	level._on_slime_touched(purple)
	report(purple)
	level._on_slime_touched(red)
	report(red)
	print(red.blocked(maze.door), " ", red.body.visible, " ", red.eyes.visible, " ", red.speed_factor())
	red.cell = maze.house_center()
	red.direction = Vector2i.DOWN
	red.choose_direction()
	print(Slime.Mode.keys()[red.mode], " ", red.body.visible, " ", red.direction)


func report(slime: Slime) -> void:
	print(slime.name, " ", Slime.Mode.keys()[slime.mode], " ", level.score)
