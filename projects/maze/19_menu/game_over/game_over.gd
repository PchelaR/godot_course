extends Control

@onready var score_label: Label = $Score


func _ready() -> void:
	score_label.text = "СЧЁТ " + str(Game.last_score).pad_zeros(5)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		get_tree().change_scene_to_file("res://menu/menu.tscn")
