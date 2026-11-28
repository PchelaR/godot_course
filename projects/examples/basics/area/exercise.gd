extends Area2D

@export var factor: float = 0.5


func _on_body_entered(body: Node2D) -> void:
	var runner: Runner = body as Runner
	if runner != null:
		runner.speed *= factor


func _on_body_exited(body: Node2D) -> void:
	var runner: Runner = body as Runner
	if runner != null:
		runner.speed /= factor
