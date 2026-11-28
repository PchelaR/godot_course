extends RigidBody2D

@export var kick_strength: float = 400.0


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("jump"):
		apply_central_impulse(Vector2(0.0, -kick_strength))
