extends Node2D

signal produced(amount: int)

@export var income: int = 10


func _on_timer_timeout() -> void:
	produced.emit(income)
