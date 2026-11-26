extends CharacterBody2D

@export var target: Node2D
@export var speed: float = 200.0
@export var repath_time: float = 0.25

var repath_left: float = 0.0

@onready var agent: NavigationAgent2D = $Agent


func _physics_process(delta: float) -> void:
	repath_left -= delta
	if repath_left <= 0.0:
		repath_left = repath_time
		agent.target_position = target.global_position
	if agent.is_navigation_finished():
		velocity = Vector2.ZERO
	else:
		velocity = global_position.direction_to(agent.get_next_path_position()) * speed
	move_and_slide()
