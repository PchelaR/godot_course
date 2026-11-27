class_name Soldier
extends Node2D

@export var speed: float = 90.0

var home: Vector2 = Vector2.ZERO


func _physics_process(delta: float) -> void:
	global_position = global_position.move_toward(home, speed * delta)
