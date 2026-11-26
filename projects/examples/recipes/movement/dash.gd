extends CharacterBody2D

@export var speed: float = 360.0
@export var acceleration: float = 2400.0
@export var friction: float = 2800.0
@export var jump_speed: float = 720.0
@export var rise_gravity: float = 1800.0
@export var fall_gravity: float = 2600.0
@export var jump_cut: float = 0.5
@export var dash_speed: float = 1100.0
@export var dash_time: float = 0.14
@export var dash_cooldown: float = 0.4

var facing: float = 1.0
var dash_left: float = 0.0
var cooldown_left: float = 0.0
var air_dash_ready: bool = true

@onready var look: Polygon2D = $Look


func _physics_process(delta: float) -> void:
	var axis: float = Input.get_axis("move_left", "move_right")
	if axis != 0.0:
		facing = signf(axis)
	cooldown_left -= delta
	if is_on_floor():
		air_dash_ready = true
	if Input.is_action_just_pressed("dash") and cooldown_left <= 0.0 and air_dash_ready:
		start_dash()
	if dash_left > 0.0:
		dash_left -= delta
		velocity = Vector2(facing * dash_speed, 0.0)
	else:
		run_and_jump(axis, delta)
	look.scale = Vector2(1.5, 0.7) if dash_left > 0.0 else Vector2.ONE
	move_and_slide()


func start_dash() -> void:
	dash_left = dash_time
	cooldown_left = dash_cooldown
	if not is_on_floor():
		air_dash_ready = false


func run_and_jump(axis: float, delta: float) -> void:
	var rate: float = acceleration if axis != 0.0 else friction
	velocity.x = move_toward(velocity.x, axis * speed, rate * delta)
	if not is_on_floor():
		var gravity: float = rise_gravity if velocity.y < 0.0 else fall_gravity
		velocity.y += gravity * delta
	if is_on_floor() and Input.is_action_just_pressed("jump"):
		velocity.y = -jump_speed
	if Input.is_action_just_released("jump") and velocity.y < 0.0:
		velocity.y *= jump_cut
