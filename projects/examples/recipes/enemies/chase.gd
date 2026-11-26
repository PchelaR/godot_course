extends CharacterBody2D

enum State { IDLE, CHASE, RETURN }

@export var speed: float = 220.0
@export var forget_time: float = 1.5

var state: State = State.IDLE
var target: Node2D = null
var home: Vector2
var forget_left: float = 0.0


func _ready() -> void:
	home = global_position


func _physics_process(delta: float) -> void:
	match state:
		State.IDLE:
			velocity = Vector2.ZERO
		State.CHASE:
			chase(delta)
		State.RETURN:
			go_home(delta)
	move_and_slide()


func chase(delta: float) -> void:
	velocity = global_position.direction_to(target.global_position) * speed
	if forget_left > 0.0:
		forget_left -= delta
		if forget_left <= 0.0:
			target = null
			state = State.RETURN


func go_home(delta: float) -> void:
	var offset: Vector2 = home - global_position
	if offset.length() < 1.0:
		velocity = Vector2.ZERO
		state = State.IDLE
		return
	velocity = offset.limit_length(speed * delta) / delta


func _on_sight_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		target = body
		forget_left = 0.0
		state = State.CHASE


func _on_sight_body_exited(body: Node2D) -> void:
	if body == target:
		forget_left = forget_time
