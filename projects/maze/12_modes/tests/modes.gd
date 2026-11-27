extends Node

@onready var level: Level = $Level
@onready var slime: Slime = $Level/Maze/Slime


func _ready() -> void:
	report()
	level._on_waves_timeout()
	report()
	slime.cell = Vector2i(3, 3)
	slime.direction = Vector2i.RIGHT
	slime.choose_direction()
	print(slime.cell, " -> ", slime.direction, " ", slime.turn_back)


func report() -> void:
	print(Slime.Mode.keys()[slime.mode], " ", slime.target(), " ", level.waves.wait_time)
