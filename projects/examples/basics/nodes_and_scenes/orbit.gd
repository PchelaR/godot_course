extends Node2D

var speed: float = 0.8


func _process(delta: float) -> void:
	rotation += speed * delta
