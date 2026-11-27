class_name Result
extends Control

@export var earned_color: Color = Color(0.9098, 0.3333, 0.1843, 1)
@export var missing_color: Color = Color(0.4902, 0.4157, 0.3529, 1)

@onready var title: Label = $Box/Title
@onready var stars: Array[ColorRect] = [$Box/Stars/Star1, $Box/Stars/Star2, $Box/Stars/Star3]


func show_result(won: bool, earned: int) -> void:
	title.text = "ПОБЕДА" if won else "ПОРАЖЕНИЕ"
	for index: int in stars.size():
		stars[index].color = earned_color if index < earned else missing_color
	visible = true


func _on_retry_pressed() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()
