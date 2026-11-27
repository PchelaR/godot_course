class_name Level
extends Node2D

var score: int = 0

@onready var hud: Hud = $Hud


func _ready() -> void:
	hud.show_score(score)


func _on_coins_eaten(points: int) -> void:
	score += points
	hud.show_score(score)
