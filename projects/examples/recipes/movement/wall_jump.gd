extends CharacterBody2D

@export var speed: float = 360.0
@export var acceleration: float = 2400.0
@export var friction: float = 2800.0
@export var jump_speed: float = 720.0
@export var rise_gravity: float = 1800.0
@export var fall_gravity: float = 2600.0
@export var jump_cut: float = 0.5
@export var air_jumps: int = 1
@export var wall_slide_speed: float = 160.0
@export var wall_push: float = 420.0
@export var wall_lock_time: float = 0.18

var jumps_left: int = 0
var lock_left: float = 0.0


func _physics_process(delta: float) -> void:
	var axis: float = Input.get_axis("move_left", "move_right")
	lock_left -= delta
	if lock_left <= 0.0:
		var rate: float = acceleration if axis != 0.0 else friction
		velocity.x = move_toward(velocity.x, axis * speed, rate * delta)
	if is_on_floor():
		jumps_left = air_jumps
	else:
		var gravity: float = rise_gravity if velocity.y < 0.0 else fall_gravity
		velocity.y += gravity * delta
	if is_on_wall_only() and velocity.y > wall_slide_speed:
		velocity.y = wall_slide_speed
	if Input.is_action_just_pressed("jump"):
		jump()
	if Input.is_action_just_released("jump") and velocity.y < 0.0:
		velocity.y *= jump_cut
	move_and_slide()


func jump() -> void:
	if is_on_floor():
		velocity.y = -jump_speed
	elif is_on_wall_only():
		velocity.y = -jump_speed
		velocity.x = get_wall_normal().x * wall_push
		lock_left = wall_lock_time
	elif jumps_left > 0:
		jumps_left -= 1
		velocity.y = -jump_speed
