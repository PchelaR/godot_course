extends Control

@onready var record_label: Label = $Record


func _ready() -> void:
	record_label.text = "РЕКОРД " + str(Game.high_score).pad_zeros(5)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		get_tree().change_scene_to_file("res://level/level.tscn")
