extends PathFollow2D

@export var speed: float = 160.0
@export var ping_pong: bool = false

var direction: float = 1.0

@onready var look: Node2D = $Look


func _ready() -> void:
	loop = not ping_pong


func _physics_process(delta: float) -> void:
	progress += speed * direction * delta
	if ping_pong and (progress_ratio >= 1.0 or progress_ratio <= 0.0):
		direction = -direction
	look.scale.x = direction
