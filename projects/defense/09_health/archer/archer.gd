extends Node2D

@export var arrow_scene: PackedScene

@onready var range_area: Area2D = $Range


func pick_target() -> Enemy:
	var best: Enemy = null
	for area: Area2D in range_area.get_overlapping_areas():
		var enemy: Enemy = area.get_parent() as Enemy
		if enemy != null and (best == null or enemy.progress > best.progress):
			best = enemy
	return best


func _on_reload_timeout() -> void:
	var target: Enemy = pick_target()
	if target == null:
		return
	var arrow: Arrow = arrow_scene.instantiate()
	arrow.target = target
	arrow.position = global_position
	add_child(arrow)
