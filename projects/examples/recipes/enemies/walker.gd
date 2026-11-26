extends CharacterBody2D

@export var speed: float = 90.0
@export var gravity: float = 1800.0
@export var turn_at_edges: bool = true

var direction: float = 1.0

@onready var floor_check: RayCast2D = $FloorCheck


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * delta
	elif is_on_wall() or (turn_at_edges and not floor_check.is_colliding()):
		turn()
	velocity.x = direction * speed
	move_and_slide()


func turn() -> void:
	direction = -direction
	floor_check.position.x = absf(floor_check.position.x) * direction
