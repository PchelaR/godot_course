extends CharacterBody2D

@export var engine_power: float = 800.0
@export var brake_power: float = 1400.0
@export var max_speed: float = 520.0
@export var reverse_speed: float = 180.0
@export var rolling_drag: float = 0.8
@export var steering: float = 2.8
@export var full_steering_speed: float = 160.0
@export var grip: float = 18.0
@export var handbrake_power: float = 500.0
@export var handbrake_grip: float = 1.5
@export var handbrake_steering: float = 1.6


func _physics_process(delta: float) -> void:
	var throttle: float = Input.get_axis("move_down", "move_up")
	var steer: float = Input.get_axis("move_left", "move_right")
	var handbrake: bool = Input.is_action_pressed("handbrake")
	if handbrake:
		velocity = velocity.move_toward(Vector2.ZERO, handbrake_power * delta)
	var forward: Vector2 = transform.x
	var forward_speed: float = velocity.dot(forward)
	var side: Vector2 = velocity - forward * forward_speed
	if not handbrake:
		forward_speed = drive(forward_speed, throttle, delta)
	var current_grip: float = handbrake_grip if handbrake else grip
	side = side.lerp(Vector2.ZERO, minf(current_grip * delta, 1.0))
	velocity = forward * forward_speed + side
	var direction: float = 1.0 if handbrake else signf(forward_speed)
	var turn_rate: float = steering * (handbrake_steering if handbrake else 1.0)
	rotation += steer * turn_rate * delta * minf(velocity.length() / full_steering_speed, 1.0) * direction
	move_and_slide()


func drive(forward_speed: float, throttle: float, delta: float) -> float:
	if throttle > 0.0:
		return move_toward(forward_speed, max_speed, engine_power * delta)
	if throttle < 0.0:
		return move_toward(forward_speed, -reverse_speed, brake_power * delta)
	return forward_speed - forward_speed * rolling_drag * delta
