extends CharacterBody2D

@export var target: Node2D
@export var gravity: float = 1800.0
@export var jump_speed: float = 620.0
@export var hop_speed: float = 220.0
@export var wait_time: float = 1.0
@export var notice_distance: float = 500.0

var wait_left: float = 0.0

@onready var look: Polygon2D = $Look


func _physics_process(delta: float) -> void:
	var near: bool = global_position.distance_to(target.global_position) < notice_distance
	if is_on_floor():
		velocity.x = 0.0
		if near:
			wait_left -= delta
		if near and wait_left <= 0.0:
			jump()
	else:
		velocity.y += gravity * delta
	var crouching: bool = is_on_floor() and near and wait_left < 0.25
	look.scale = Vector2(1.2, 0.8) if crouching else Vector2.ONE
	move_and_slide()


func jump() -> void:
	wait_left = wait_time
	velocity.y = -jump_speed
	velocity.x = signf(target.global_position.x - global_position.x) * hop_speed
