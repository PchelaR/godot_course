extends CharacterBody2D

const PLATFORM_LAYER: int = 2

@export var ladders: Array[Area2D] = []
@export var speed: float = 360.0
@export var acceleration: float = 2400.0
@export var friction: float = 2800.0
@export var jump_speed: float = 720.0
@export var gravity: float = 2000.0
@export var climb_speed: float = 220.0
@export var drop_time: float = 0.25

var climbing: bool = false
var drop_left: float = 0.0


func _physics_process(delta: float) -> void:
	var axis: float = Input.get_axis("move_left", "move_right")
	var vertical: float = Input.get_axis("move_up", "move_down")
	if not on_ladder():
		climbing = false
	elif vertical != 0.0:
		climbing = true
	drop_left -= delta
	set_collision_mask_value(PLATFORM_LAYER, drop_left <= 0.0 and not climbing)
	if climbing:
		climb(axis, vertical)
	else:
		walk(axis, vertical, delta)
	move_and_slide()


func on_ladder() -> bool:
	for ladder: Area2D in ladders:
		if ladder.overlaps_body(self):
			return true
	return false


func climb(axis: float, vertical: float) -> void:
	velocity = Vector2(axis * speed * 0.5, vertical * climb_speed)
	if Input.is_action_just_pressed("jump"):
		climbing = false
		velocity.y = -jump_speed


func walk(axis: float, vertical: float, delta: float) -> void:
	var rate: float = acceleration if axis != 0.0 else friction
	velocity.x = move_toward(velocity.x, axis * speed, rate * delta)
	if not is_on_floor():
		velocity.y += gravity * delta
	if is_on_floor() and Input.is_action_just_pressed("jump"):
		if vertical > 0.0:
			drop_left = drop_time
		else:
			velocity.y = -jump_speed
