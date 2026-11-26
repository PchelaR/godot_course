extends Camera2D

@export var distance: float = 200.0
@export var smoothing: float = 3.0
@export var min_speed: float = 40.0

var facing: float = 1.0

@onready var body: CharacterBody2D = get_parent()


func _process(delta: float) -> void:
	if absf(body.velocity.x) > min_speed:
		facing = signf(body.velocity.x)
	var wanted: Vector2 = Vector2(facing * distance, 0.0)
	offset = offset.lerp(wanted, 1.0 - exp(-smoothing * delta))
