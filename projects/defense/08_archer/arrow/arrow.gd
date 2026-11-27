class_name Arrow
extends Node2D

@export var speed: float = 600.0

var target: Enemy = null


func _physics_process(delta: float) -> void:
	if not is_instance_valid(target):
		queue_free()
		return
	var goal: Vector2 = target.global_position
	look_at(goal)
	global_position = global_position.move_toward(goal, speed * delta)
	if global_position == goal:
		queue_free()
