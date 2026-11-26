extends CharacterBody2D

@export var speed: float = 360.0
@export var acceleration: float = 2400.0
@export var friction: float = 2800.0
@export var jump_speed: float = 720.0
@export var rise_gravity: float = 1800.0
@export var fall_gravity: float = 2600.0
@export var jump_cut: float = 0.5


func _physics_process(delta: float) -> void:
	var axis: float = Input.get_axis("move_left", "move_right")
	var rate: float = acceleration if axis != 0.0 else friction
	velocity.x = move_toward(velocity.x, axis * speed, rate * delta)
	if not is_on_floor():
		var gravity: float = rise_gravity if velocity.y < 0.0 else fall_gravity
		velocity.y += gravity * delta
	if is_on_floor() and Input.is_action_just_pressed("jump"):
		velocity.y = -jump_speed
	if Input.is_action_just_released("jump") and velocity.y < 0.0:
		velocity.y *= jump_cut
	move_and_slide()
