extends CharacterBody2D

@export var target: Node2D
@export var speed: float = 220.0
@export var strafe_speed: float = 150.0
@export var min_distance: float = 200.0
@export var max_distance: float = 320.0

var strafe_side: float = 1.0


func _physics_process(_delta: float) -> void:
	var offset: Vector2 = target.global_position - global_position
	var toward: Vector2 = offset.normalized()
	var distance: float = offset.length()
	if distance > max_distance:
		velocity = toward * speed
	elif distance < min_distance:
		velocity = -toward * speed
	else:
		velocity = toward.orthogonal() * strafe_side * strafe_speed
	move_and_slide()
	if get_slide_collision_count() > 0:
		strafe_side = -strafe_side
	look_at(target.global_position)
