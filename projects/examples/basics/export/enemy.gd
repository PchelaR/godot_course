extends Node

enum Kind { SLIME, BAT }

@export var title: String = "Враг"
@export var health: int = 100
@export var kind: Kind = Kind.SLIME


func _init() -> void:
	print("_init: ", title, " ", health)


func _ready() -> void:
	print("_ready: ", title, " ", health)
	print(kind == Kind.BAT)
