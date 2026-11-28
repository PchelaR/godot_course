extends CharacterBody2D

@export var speed: float = 300.0
@export var dash_multiplier: float = 2.0


func _physics_process(_delta: float) -> void:
	var direction: Vector2 = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = direction * speed
	if Input.is_action_pressed("dash"):
		velocity *= dash_multiplier
	move_and_slide()
