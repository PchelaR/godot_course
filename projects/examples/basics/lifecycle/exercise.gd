extends Node2D

var lifetime: float = 2.0
var age: float = 0.0


func _process(delta: float) -> void:
	age += delta
	if age >= lifetime:
		queue_free()
