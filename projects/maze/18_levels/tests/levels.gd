extends Node

@onready var level: Level = $Level
@onready var coins: Coins = $Level/Maze/Coins
@onready var red: Slime = $Level/Maze/Slimes/Red


func _ready() -> void:
	report()
	coins.eat(Vector2i(2, 1))
	coins.eat(Vector2i(3, 1))
	report()
	level.next_level()
	report()
	level.next_level()
	level.next_level()
	report()


func report() -> void:
	print(level.level_number, " ", red.speed, " ", level.difficulty().fright_time, " ", coins.get_used_cells().size())
