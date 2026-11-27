class_name Plot
extends Area2D

signal clicked(plot: Plot)

var tower: Node2D = null


func _input_event(_viewport: Viewport, event: InputEvent, _shape_index: int) -> void:
	if event.is_action_pressed("select"):
		clicked.emit(self)
