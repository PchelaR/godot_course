extends Node

@onready var level: Level = $Level
@onready var maze: Maze = $Level/Maze
@onready var slimes: Node2D = $Level/Maze/Slimes
@onready var red: Slime = $Level/Maze/Slimes/Red
@onready var blue: Slime = $Level/Maze/Slimes/Blue
@onready var orange: Slime = $Level/Maze/Slimes/Orange


func _ready() -> void:
	report()
	for index: int in 30:
		level._on_coins_eaten(10)
	report()
	print(blue.blocked(maze.door), " ", orange.blocked(maze.door))
	red.choose_direction()
	print(red.name, " ", Slime.Mode.keys()[red.mode], " ", red.direction)


func report() -> void:
	var line: PackedStringArray = []
	for slime: Slime in slimes.get_children():
		line.append("%s %s" % [slime.name, Slime.Mode.keys()[slime.mode]])
	print(", ".join(line))
