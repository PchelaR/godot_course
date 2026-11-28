class_name Pickup
extends Area2D

@export var value: int = 1


func _on_body_entered(body: Node2D) -> void:
	var runner: Runner = body as Runner
	if runner == null:
		return
	runner.score += value
	print("Очки: ", runner.score)
	queue_free()
