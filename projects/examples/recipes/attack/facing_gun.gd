extends Node2D

@export var bullet_scene: PackedScene

var facing: float = 1.0

@onready var muzzle: Marker2D = $Muzzle


func _process(_delta: float) -> void:
	var axis: float = Input.get_axis("move_left", "move_right")
	if axis != 0.0:
		facing = signf(axis)
	scale.x = facing


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("shoot"):
		shoot()


func shoot() -> void:
	var bullet: Node2D = bullet_scene.instantiate()
	bullet.global_position = muzzle.global_position
	bullet.rotation = 0.0 if facing > 0.0 else PI
	get_tree().current_scene.add_child(bullet)
