extends Node2D

@export var box_scene: PackedScene


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("build"):
		var box: RigidBody2D = box_scene.instantiate()
		box.position = get_global_mouse_position()
		add_child(box)
