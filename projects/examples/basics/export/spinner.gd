extends Sprite2D

@export_range(-6.0, 6.0, 0.5) var turn_speed: float = 2.0


func _process(delta: float) -> void:
	rotation += turn_speed * delta
