extends Node2D

@export var speed: float = 1.0


func _process(delta: float) -> void:
	for child: Node2D in get_children():
		child.rotation += speed * delta
