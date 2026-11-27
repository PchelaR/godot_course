class_name Enemy
extends PathFollow2D

@export var speed: float = 60.0


func _physics_process(delta: float) -> void:
	progress += speed * delta
	if progress_ratio >= 1.0:
		queue_free()
