extends Node2D

@export var thrust: float = 600.0
@export var turn_speed: float = 4.0
@export var max_speed: float = 520.0
@export var drag: float = 0.5
@export var field: Vector2 = Vector2(1152, 648)

var velocity: Vector2 = Vector2.ZERO

@onready var flame: Polygon2D = $Flame


func _physics_process(delta: float) -> void:
	rotation += Input.get_axis("move_left", "move_right") * turn_speed * delta
	var thrusting: bool = Input.is_action_pressed("move_up")
	if thrusting:
		velocity += transform.x * thrust * delta
	velocity -= velocity * drag * delta
	velocity = velocity.limit_length(max_speed)
	position += velocity * delta
	position = Vector2(fposmod(position.x, field.x), fposmod(position.y, field.y))
	flame.visible = thrusting
