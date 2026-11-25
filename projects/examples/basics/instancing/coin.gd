class_name Coin
extends Node2D

@export var fall_speed: float = 220.0


func _process(delta: float) -> void:
	position.y += fall_speed * delta
	if position.y > 700.0:
		queue_free()
