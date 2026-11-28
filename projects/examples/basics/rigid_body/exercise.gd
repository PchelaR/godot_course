extends Node2D

@export var box_scene: PackedScene
@export var ball_scene: PackedScene


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("build"):
		spawn(box_scene)
	elif event.is_action_pressed("demolish"):
		spawn(ball_scene)


func spawn(scene: PackedScene) -> void:
	var body: RigidBody2D = scene.instantiate()
	body.position = get_global_mouse_position()
	add_child(body)
