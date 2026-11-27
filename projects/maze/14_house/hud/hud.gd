class_name Hud
extends Control

@onready var score_label: Label = $Score


func show_score(score: int) -> void:
	score_label.text = str(score).pad_zeros(5)
