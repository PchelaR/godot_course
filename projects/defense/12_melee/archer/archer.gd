extends Tower

@export var arrow_scene: PackedScene


func _on_reload_timeout() -> void:
	var target: Enemy = first_enemy()
	if target == null:
		return
	var arrow: Arrow = arrow_scene.instantiate()
	arrow.target = target
	arrow.position = global_position
	add_child(arrow)
