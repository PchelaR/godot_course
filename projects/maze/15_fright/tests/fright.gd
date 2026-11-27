extends Node

@onready var level: Level = $Level
@onready var slimes: Node2D = $Level/Maze/Slimes
@onready var red: Slime = $Level/Maze/Slimes/Red
@onready var purple: Slime = $Level/Maze/Slimes/Purple


func _ready() -> void:
	red.mode = Slime.Mode.CHASE
	purple.mode = Slime.Mode.SCATTER
	level._on_coins_powered()
	report()
	print(red.turn_back, " ", red.scared.visible, " ", level.waves.paused, " ", level.fright.wait_time)
	level._on_fright_timeout()
	print(red.scared_body.animation, " ", red.scared_face.animation, " ", level.fright.wait_time)
	level._on_fright_timeout()
	report()
	print(red.scared.visible, " ", level.waves.paused)


func report() -> void:
	var line: PackedStringArray = []
	for slime: Slime in slimes.get_children():
		line.append("%s %s" % [slime.name, Slime.Mode.keys()[slime.mode]])
	print(", ".join(line))
