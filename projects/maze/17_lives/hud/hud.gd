class_name Hud
extends Control

@onready var score_label: Label = $Score
@onready var lives_box: HBoxContainer = $Lives


func show_score(score: int) -> void:
	score_label.text = str(score).pad_zeros(5)


func show_lives(count: int) -> void:
	for index: int in lives_box.get_child_count():
		var icon: Control = lives_box.get_child(index)
		icon.visible = index < count
