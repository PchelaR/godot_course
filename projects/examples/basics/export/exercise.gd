extends Sprite2D

@export_range(-6.0, 6.0, 0.5) var turn_speed: float = 2.0
@export_range(0.5, 2.0, 0.1) var size: float = 1.0


func _ready() -> void:
	scale = Vector2(size, size)


func _process(delta: float) -> void:
	rotation += turn_speed * delta
