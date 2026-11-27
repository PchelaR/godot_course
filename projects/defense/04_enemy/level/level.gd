extends Node2D

@export var enemy_scene: PackedScene

@onready var road: Path2D = $Map/Road


func _on_spawn_timer_timeout() -> void:
	road.add_child(enemy_scene.instantiate())
