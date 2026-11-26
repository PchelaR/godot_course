extends CharacterBody2D

@export var speed: float = 350.0
@export var turn_speed: float = 3.5


func _physics_process(delta: float) -> void:
	var turn: float = Input.get_axis("move_left", "move_right")
	var drive: float = Input.get_axis("move_down", "move_up")
	rotation += turn * turn_speed * delta
	velocity = transform.x * drive * speed
	move_and_slide()
